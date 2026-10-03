"""Install and relocate binary/source core packages through upstream daspkg."""
import argparse
import ctypes
import hashlib
import json
import re
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--module", type=Path, required=True)
    parser.add_argument("--das-root", type=Path, required=True)
    parser.add_argument("--cli-module", type=Path)
    parser.add_argument("--source", action="store_true")
    parser.add_argument("--fetch-sdl", action="store_true", help="Cold network install; no prebuilt SDL")
    parser.add_argument("--sdl-dir", type=Path)
    parser.add_argument("--release", action="store_true")
    parser.add_argument("--skip-missing-dependencies", action="store_true",
                        help="Skip deliberate loader failures (macOS may display crash dialogs)")
    parser.add_argument("--llvm-dir", type=Path)
    parser.add_argument("--imgui", action="store_true")
    parser.add_argument("--repository", action="store_true", help="Clean HEAD export plus pending package entry files")
    args = parser.parse_args()
    if args.repository:
        args.source = True
    if args.fetch_sdl:
        if args.sdl_dir:
            parser.error("--fetch-sdl cannot use --sdl-dir")
        args.source = True
    das = args.das_root.resolve()
    (ROOT / "build").mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="daspkg check ", dir=ROOT / "build"))
    package = work / "staged" / "dasSDL3"
    consumer = work / "consumer"
    consumer.mkdir()
    env = dict(os.environ, SDL_VIDEODRIVER="dummy", SDL_AUDIODRIVER="dummy")
    if args.fetch_sdl:
        for key in list(env):
            if key.upper().startswith(("SDL3_", "FETCHCONTENT_")) or key.upper() == "CMAKE_PREFIX_PATH":
                del env[key]
    if args.repository:
        env["DASSDL3_PACKAGE_PROFILE"] = "imgui" if args.imgui else "core"
        if sys.platform == "darwin":
            snapshot = work / "sdk snapshot"
            subprocess.run([sys.executable, str(ROOT / "tools/stage_daspkg.py"),
                            "--source", "--platform", "macos", "--sdk", str(das),
                            "--output", str(snapshot), *(["--with-imgui"] if args.imgui else [])], check=True)
            env["DASSDL3_PACKAGE_SDK_FINGERPRINT"] = str(snapshot / "sdk.sha256")
    if args.source:
        env["CMAKE_GENERATOR"] = "Ninja"
        env["CMAKE_BUILD_PARALLEL_LEVEL"] = "6"
        if args.sdl_dir:
            env["SDL3_DIR"] = str(args.sdl_dir.resolve())
    if args.release:
        if not args.llvm_dir:
            parser.error("--release requires --llvm-dir with the matching native LLVM runtime")
        llvm = args.llvm_dir.resolve()
        for tool in (("LLVM.dll", "lld-link.exe") if os.name == "nt" else ("LLVM.dll",)):
            if not (llvm / tool).is_file():
                parser.error(f"Missing release tool: {llvm / tool}")
        env["DAS_DLL_PATH"] = str(llvm)
        env["PATH"] = str(llvm) + os.pathsep + env.get("PATH", "")
    exe = str(das / "bin" / ("daslang.exe" if os.name == "nt" else "daslang"))

    def run(name, command, cwd):
        result = subprocess.run(command, cwd=cwd, env=env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600)
        (work / f"{name}.log").write_text(result.stdout, encoding="utf-8")
        if result.returncode:
            raise RuntimeError(f"{name} failed ({result.returncode}):\n{result.stdout}")
        return result.stdout

    def verify_licenses(directory):
        for relative in ["LICENSE", "VERSION", *[
                p.relative_to(ROOT).as_posix()
                for p in (ROOT / "licenses").rglob("*") if p.is_file()]]:
            path = directory / relative
            if not path.is_file() or path.read_bytes() != (ROOT / relative).read_bytes():
                raise RuntimeError(f"Missing or altered distribution notice: {path}")
        for entry in json.loads((directory / "licenses/manifest.json").read_text(encoding="utf-8")):
            data = (directory / "licenses" / entry["file"]).read_bytes()
            if hashlib.sha256(data).hexdigest() != entry["sha256"]:
                raise RuntimeError(f"License snapshot hash mismatch: {entry['file']}")

    stage_mode = ["--source", "--sdk", str(das)] if args.source else ["--module", str(args.module.resolve())]
    if sys.platform == "darwin":
        stage_mode += ["--platform", "macos"]
    if args.imgui:
        stage_mode += ["--with-imgui"]
        if not args.source:
            stage_mode += ["--sdk", str(das)]
    if args.repository:
        archive = work / "repository.zip"
        run("archive", ["git", "--no-optional-locks", "-c", f"safe.directory={ROOT.as_posix()}",
                        "-C", str(ROOT), "archive", "--format=zip", f"--output={archive}", "HEAD"], ROOT)
        package.mkdir(parents=True)
        with zipfile.ZipFile(archive) as source_zip:
            source_zip.extractall(package)
        # No commit is made to the user's checkout. Overlay exactly the proposed entry files.
        for name in (".das_package", "CMakeLists.txt", ".gitignore", ".gitattributes", "LICENSE", "VERSION"):
            shutil.copy2(ROOT / name, package / name)
        shutil.copytree(ROOT / "licenses", package / "licenses", dirs_exist_ok=True)
        shutil.copytree(ROOT / "src/package", package / "src/package", dirs_exist_ok=True)
        if (package / "third_party/daScript/bin/daslang.exe").exists():
            raise RuntimeError("Repository fixture unexpectedly contains a built SDK")
        if list(package.rglob("*.shared_module")):
            raise RuntimeError("Repository fixture unexpectedly contains a native module")
    else:
        run("stage", [sys.executable, str(ROOT / "tools/stage_daspkg.py"),
                      *stage_mode, "--output", str(package)], ROOT)
    verify_licenses(package)
    if args.source and not args.repository:
        if list(package.rglob("*.shared_module")):
            raise RuntimeError("Source staging unexpectedly contains a prebuilt module")
        # Deliberately change the expected fingerprint. Configure must reject it before build/fetch.
        fingerprint = package / "sdk.sha256"
        good = fingerprint.read_text(encoding="utf-8")
        fingerprint.write_text("0" * 64 + good[64:], encoding="utf-8")
        bad = subprocess.run(["cmake", "-S", str(package), "-B", str(work / "reject"),
                              "-G", "Ninja", "-DCMAKE_BUILD_TYPE=Release", f"-DDASLANG_DIR={das}"],
                             env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        (work / "sdk-rejection.log").write_text(bad.stdout, encoding="utf-8")
        if bad.returncode == 0 or "SDK fingerprint mismatch" not in bad.stdout:
            raise RuntimeError(f"SDK mismatch was not rejected correctly: {bad.stdout}")
        fingerprint.write_text(good, encoding="utf-8")
    example = "daspkg-imgui-consumer" if args.imgui else "daspkg-consumer"
    receipt = "ImGui backends, context and SDL resources released." if args.imgui else "daspkg SDL core: rendered; resources released."
    shutil.copy2(ROOT / "examples" / example / "main.das", consumer / "main.das")
    cli = [exe, "-dasroot", str(das)]
    if args.cli_module:
        cli += ["-load_module", str(args.cli_module.resolve())]
    cli += [str(das / "utils/daspkg/main.das"), "--"]
    run("install", cli + ["install", str(package), "--root", str(consumer)], consumer)
    verify_licenses(consumer / "modules/dasSDL3")
    if args.repository:
        installed = consumer / "modules/dasSDL3"
        descriptor = installed / ".das_module"
        descriptor.rename(installed / ".das_module.test-original")
        run("rebuild-descriptor", ["cmake", "--build", str(installed / "_build"), "--parallel", "6"], consumer)
        if not descriptor.is_file():
            raise RuntimeError("Incremental build did not restore the module descriptor")
    if args.fetch_sdl:
        native_build = consumer / "modules/dasSDL3/_build"
        checkout = native_build / "_deps/sdl3-src"
        static_lib = native_build / ("_deps/sdl3-build/SDL3-static.lib" if os.name == "nt" else "_deps/sdl3-build/libSDL3.a")
        if not (checkout / ".git").exists() or not static_lib.is_file():
            raise RuntimeError("Cold install did not create its own SDL checkout and static library")
        git = ["git", "-c", f"safe.directory={checkout.as_posix()}", "-C", str(checkout)]
        head = run("sdl-head", git + ["rev-parse", "HEAD"], work).strip()
        tag = run("sdl-tag", git + ["rev-parse", "release-3.4.16^{commit}"], work).strip()
        origin = run("sdl-origin", git + ["remote", "get-url", "origin"], work).strip()
        if head != tag or origin != "https://github.com/libsdl-org/SDL.git":
            raise RuntimeError(f"Unexpected SDL source: {origin} {head} (tag {tag})")
        print(f"Cold SDL fetch/build verified: release-3.4.16 {head}", flush=True)
    descriptor_text = (consumer / "modules/dasSDL3/.das_module").read_text(encoding="utf-8")
    imports = sorted(re.findall(r'register_native_path\("dassdl3", "([^"]+)"', descriptor_text))
    if not imports:
        raise RuntimeError("Package descriptor registered no boost modules")
    (consumer / "all_imports.das").write_text(
        "options gen2\n" + "".join(f"require dassdl3/{name}\n" for name in imports)
        + '\n[export]\ndef main { print("All package imports compiled.\\n") }\n',
        encoding="utf-8")
    import_output = run("all-imports", [exe, "-dasroot", str(das), "all_imports.das"], consumer)
    if "All package imports compiled." not in import_output:
        raise RuntimeError(f"Package import check failed: {import_output}")
    run_args = ["--", "--smoke"] if args.imgui else []
    run("check", cli + ["check", "--root", str(consumer)], consumer)
    output = run("consumer", [exe, "-dasroot", str(das), "main.das", *run_args], consumer)
    if receipt not in output or (args.imgui and "bright pixels verified." not in output):
        raise RuntimeError(f"Missing consumer receipt: {output}")
    if args.release:
        if args.imgui:
            # Upstream standalone retains a build-time fallback path. Shadow ImGui
            # inside this disposable project so moving it makes that fallback absent,
            # without moving or changing the user's SDK (possibly used by a live app).
            local_imgui = consumer / "modules/dasImgui"
            sdk_imgui = das / "modules/dasImgui"
            for source in sdk_imgui.rglob("*"):
                if source.is_file() and (source.suffix in {".das", ".shared_module"}
                                         or source.name in {".das_module", ".das_package"}):
                    target = local_imgui / source.relative_to(sdk_imgui)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(source, target)
        shutil.copy2(ROOT / "examples" / example / ".das_package", consumer / ".das_package")
        run("release", cli + ["release", "--root", str(consumer), "--out", str(work / "out")], consumer)
    # Rename both input package and installed project: absolute source paths must not work.
    package.rename(work / "original-package-moved")
    moved = work / "relocated consumer"
    consumer.rename(moved)
    output = run("relocated", [exe, "-dasroot", str(das), "main.das", *run_args], moved)
    if receipt not in output or (args.imgui and "bright pixels verified." not in output):
        raise RuntimeError(f"Missing relocated receipt: {output}")
    if args.release:
        bundle_name = "sdl3_imgui_demo" if args.imgui else "sdl3_package_demo"
        release = work / "out" / (bundle_name + ".app" if sys.platform == "darwin" else bundle_name)
        if sys.platform == "darwin":
            run("sign-bundle", [sys.executable, str(ROOT / "tools/sign_macos_bundle.py"), str(release)], work)
        # Only the generated distribution is copied, outside the repository.
        portable = Path(tempfile.mkdtemp(prefix="dasSDL3 release "))
        bundle = portable / ("app.app" if sys.platform == "darwin" else "app")
        shutil.copytree(release, bundle, symlinks=True)
        bundle_contents = bundle
        if sys.platform == "darwin":
            import plistlib
            info = plistlib.loads((bundle / "Contents/Info.plist").read_bytes())
            if info['CFBundleExecutable'] != bundle_name:
                raise RuntimeError('Incorrect .app executable declaration')
            bundle = bundle / "Contents/MacOS"
        verify_licenses((bundle_contents / "Contents/Resources" if sys.platform == "darwin" else bundle)
                        / "modules/dasSDL3")
        required = ([bundle_name, "liblibDaScriptDyn.dylib", "liblibDaScriptDyn_runtime.dylib"]
                    if sys.platform == "darwin" else [bundle_name + ".exe", "libDaScriptDyn.dll", "libDaScriptDyn_runtime.dll"])
        required += ["modules/dasSDL3/dasSDL3.shared_module"]
        if args.imgui:
            required += ["modules/dasImgui/dasModuleImgui.shared_module",
                         ("modules/dasClipboard/dasModuleClipboard.shared_module" if sys.platform == "darwin"
                          else "dasModuleClipboard.shared_module")]
        for item in required:
            if not (bundle / item).is_file():
                raise RuntimeError(f"Release omitted {item}")
        if sys.platform == "darwin":
            # The source SDK stays installed: the bundle must not use its paths.
            natives = [bundle / bundle_name, *bundle.rglob('*.dylib'), *bundle.rglob('*.shared_module')]
            for native in natives:
                commands = subprocess.check_output(['otool', '-l', str(native)], text=True)
                for rpath in re.findall(r'cmd LC_RPATH\s+cmdsize \d+\s+path (.*?) \(offset', commands):
                    if not rpath.startswith(('@loader_path', '@executable_path', '@rpath')):
                        raise RuntimeError(f'External bundle rpath: {native}: {rpath}')
                dependencies = subprocess.check_output(['otool', '-L', str(native)], text=True)
                for dependency in dependencies.splitlines()[1:]:
                    name = dependency.strip().split(' (compatibility')[0]
                    if not name.startswith(('@', '/usr/lib/', '/System/Library/')):
                        raise RuntimeError(f'External bundle dependency: {native}: {name}')
            subprocess.run(['codesign', '--verify', '--deep', '--strict', str(bundle_contents)], check=True)
        if list(bundle.rglob("*.das")) or (bundle / "LLVM.dll").exists():
            raise RuntimeError("Unexpected script sources or LLVM runtime in distribution")
        # No SDK, LLVM or compiler search paths are inherited by the application.
        clean = {k: v for k, v in os.environ.items()
                 if k.upper() in {"SYSTEMROOT", "WINDIR", "TEMP", "TMP", "USERPROFILE",
                                  "APPDATA", "LOCALAPPDATA", "COMSPEC"}}
        if os.name == "nt":
            clean["PATH"] = str(Path(os.environ["SystemRoot"]) / "System32")
        else:
            clean = {k: v for k, v in os.environ.items() if k in {"HOME", "TMPDIR", "LANG"}}
            clean["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"
        clean["SDL_VIDEODRIVER"] = "dummy"
        clean["SDL_AUDIODRIVER"] = "dummy"
        cwd = portable / "empty cwd"
        cwd.mkdir()
        # Suppress Windows missing-DLL dialog in negative cases; inherited by children.
        old_mode = ctypes.windll.kernel32.SetErrorMode(0x0001 | 0x8000) if os.name == "nt" else None
        try:
            def portable_run(label):
                result = subprocess.run([str(bundle / required[0]), *(["--smoke"] if args.imgui else [])], cwd=cwd, env=clean,
                                        text=True, errors="replace", stdout=subprocess.PIPE,
                                        stderr=subprocess.STDOUT, timeout=30)
                (work / f"{label}.log").write_text(result.stdout, encoding="utf-8")
                return result
            result = portable_run("standalone")
            if result.returncode or receipt not in result.stdout or (args.imgui and "bright pixels verified." not in result.stdout):
                raise RuntimeError(f"Standalone failed ({result.returncode}): {result.stdout}")
            # The SDK still exists on this host: prove it cannot silently replace omitted DLLs.
            for index, item in enumerate([] if args.skip_missing_dependencies else required[1:]):
                original = bundle / item
                hidden = original.with_name(original.name + ".test-hidden")
                original.rename(hidden)
                try:
                    result = portable_run(f"missing-dependency-{index}")
                    if result.returncode == 0:
                        raise RuntimeError(f"Standalone silently found missing dependency: {item}")
                finally:
                    hidden.rename(original)
        finally:
            if old_mode is not None:
                ctypes.windll.kernel32.SetErrorMode(old_mode)
        print(f"Standalone checks passed: {bundle}; missing-dependency checks "
              + ("skipped" if args.skip_missing_dependencies else "passed"))
    print(f"PASS: daspkg install/check + consumer + relocation; logs: {work}")

if __name__ == "__main__":
    main()
