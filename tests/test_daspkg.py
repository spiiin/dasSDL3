"""Install and relocate binary/source core packages through upstream daspkg."""
import argparse
import ctypes
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

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
    parser.add_argument("--llvm-dir", type=Path)
    parser.add_argument("--imgui", action="store_true")
    args = parser.parse_args()
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
    if args.source:
        env["CMAKE_GENERATOR"] = "Ninja"
        env["CMAKE_BUILD_PARALLEL_LEVEL"] = "6"
        if args.sdl_dir:
            env["SDL3_DIR"] = str(args.sdl_dir.resolve())
    if args.release:
        if not args.llvm_dir:
            parser.error("--release requires --llvm-dir with LLVM.dll and lld-link.exe")
        llvm = args.llvm_dir.resolve()
        for tool in ("LLVM.dll", "lld-link.exe"):
            if not (llvm / tool).is_file():
                parser.error(f"Missing release tool: {llvm / tool}")
        env["DAS_DLL_PATH"] = str(llvm)
        env["PATH"] = str(llvm) + os.pathsep + env.get("PATH", "")
    exe = str(das / "bin" / "daslang.exe")

    def run(name, command, cwd):
        result = subprocess.run(command, cwd=cwd, env=env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600)
        (work / f"{name}.log").write_text(result.stdout, encoding="utf-8")
        if result.returncode:
            raise RuntimeError(f"{name} failed ({result.returncode}):\n{result.stdout}")
        return result.stdout

    stage_mode = ["--source", "--sdk", str(das)] if args.source else ["--module", str(args.module.resolve())]
    if args.imgui:
        stage_mode += ["--with-imgui"]
        if not args.source:
            stage_mode += ["--sdk", str(das)]
    run("stage", [sys.executable, str(ROOT / "tools/stage_daspkg.py"),
                  *stage_mode, "--output", str(package)], ROOT)
    if args.source:
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
    if args.fetch_sdl:
        native_build = consumer / "modules/dasSDL3/_build"
        checkout = native_build / "_deps/sdl3-src"
        static_lib = native_build / "_deps/sdl3-build/SDL3-static.lib"
        if not (checkout / ".git").exists() or not static_lib.is_file():
            raise RuntimeError("Cold install did not create its own SDL checkout and static library")
        git = ["git", "-c", f"safe.directory={checkout.as_posix()}", "-C", str(checkout)]
        head = run("sdl-head", git + ["rev-parse", "HEAD"], work).strip()
        tag = run("sdl-tag", git + ["rev-parse", "release-3.4.16^{commit}"], work).strip()
        origin = run("sdl-origin", git + ["remote", "get-url", "origin"], work).strip()
        if head != tag or origin != "https://github.com/libsdl-org/SDL.git":
            raise RuntimeError(f"Unexpected SDL source: {origin} {head} (tag {tag})")
        print(f"Cold SDL fetch/build verified: release-3.4.16 {head}", flush=True)
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
        release = work / "out" / bundle_name
        # Only the generated distribution is copied, outside the repository.
        portable = Path(tempfile.mkdtemp(prefix="dasSDL3 release "))
        bundle = portable / "app"
        shutil.copytree(release, bundle)
        required = [bundle_name + ".exe", "libDaScriptDyn.dll",
                    "libDaScriptDyn_runtime.dll", "modules/dasSDL3/dasSDL3.shared_module"]
        if args.imgui:
            required += ["modules/dasImgui/dasModuleImgui.shared_module",
                         "dasModuleClipboard.shared_module"]
        for item in required:
            if not (bundle / item).is_file():
                raise RuntimeError(f"Release omitted {item}")
        if list(bundle.rglob("*.das")) or (bundle / "LLVM.dll").exists():
            raise RuntimeError("Unexpected script sources or LLVM runtime in distribution")
        # No SDK, LLVM or compiler search paths are inherited by the application.
        clean = {k: v for k, v in os.environ.items()
                 if k.upper() in {"SYSTEMROOT", "WINDIR", "TEMP", "TMP", "USERPROFILE",
                                  "APPDATA", "LOCALAPPDATA", "COMSPEC"}}
        clean["PATH"] = str(Path(os.environ["SystemRoot"]) / "System32")
        clean["SDL_VIDEODRIVER"] = "dummy"
        clean["SDL_AUDIODRIVER"] = "dummy"
        cwd = portable / "empty cwd"
        cwd.mkdir()
        # Suppress Windows missing-DLL dialog in negative cases; inherited by children.
        old_mode = ctypes.windll.kernel32.SetErrorMode(0x0001 | 0x8000)
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
            for index, item in enumerate(required[1:]):
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
            ctypes.windll.kernel32.SetErrorMode(old_mode)
        print(f"Standalone and missing-dependency checks passed: {bundle}")
    print(f"PASS: daspkg install/check + consumer + relocation; logs: {work}")

if __name__ == "__main__":
    main()
