"""Stage a local core binary or source package for a matching native SDK."""
import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
OPTIONAL = {
    "sdl3_image_boost", "sdl3_imgui", "sdl3_imgui_widgets", "sdl3_mixer_boost",
    "sdl3_net_boost", "sdl3_sound_boost", "sdl3_ttf_boost",
}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--module", type=Path)
    mode.add_argument("--source", action="store_true")
    parser.add_argument("--sdk", type=Path, help="Matching dynamic SDK required by --source")
    parser.add_argument("--output", type=Path, required=True,
                        help="New or empty directory, normally ending in dasSDL3")
    parser.add_argument("--with-imgui", action="store_true", help="Combined SDL + SDK dasImgui profile")
    parser.add_argument("--platform", choices=("windows", "macos", "linux"),
                        default="windows" if sys.platform == "win32" else "macos" if sys.platform == "darwin" else "linux")
    args = parser.parse_args()
    if args.platform == "linux" and args.with_imgui:
        parser.error("Linux currently supports only core")
    runtime = {"windows": "bin/libDaScriptDyn.dll", "macos": "lib/liblibDaScriptDyn_runtime.dylib",
               "linux": "lib/liblibDaScriptDyn.so"}[args.platform]
    source = args.module.resolve() if args.module else None
    if (args.source or args.with_imgui) and not args.sdk:
        parser.error("--source and --with-imgui require --sdk")
    output = args.output.resolve()
    if source and (not source.is_file() or source.suffix != ".shared_module"):
        parser.error("--module must name the built core .shared_module")
    if output.exists() and any(output.iterdir()):
        parser.error("--output must be empty (existing packages are never overwritten)")
    excluded = OPTIONAL - ({"sdl3_imgui"} if args.with_imgui else set())
    scripts = [p for p in sorted((ROOT / "dassdl3").glob("*.das"))
               if p.stem not in excluded and not p.stem.startswith("sdl3_shader")]
    names = {p.stem for p in scripts}
    for script in scripts:
        for dependency in re.findall(r"(?m)^require dassdl3/(\w+)", script.read_text(encoding="utf-8")):
            if dependency not in names:
                parser.error(f"Core profile is incomplete: {script.name} requires {dependency}")
    output.mkdir(parents=True, exist_ok=True)
    (output / "dassdl3").mkdir()
    shutil.copy2(ROOT / "LICENSE", output / "LICENSE")
    shutil.copy2(ROOT / "VERSION", output / "VERSION")
    shutil.copytree(ROOT / "licenses", output / "licenses")
    if source:
        shutil.copy2(source, output / "dasSDL3.shared_module")
    else:
        sdk = args.sdk.resolve()
        sdk_files = sorted(p for folder in ("include", "3rdparty/fmt/include")
                           for p in (sdk / folder).rglob("*") if p.is_file())
        native_files = {
            "windows": ("lib/libDaScriptDyn.lib", "lib/libDaScriptDyn_runtime.lib",
                        "bin/libDaScriptDyn.dll", "bin/libDaScriptDyn_runtime.dll"),
            "macos": ("lib/liblibDaScriptDyn.dylib", "lib/liblibDaScriptDyn_runtime.dylib"),
            "linux": ("lib/liblibDaScriptDyn.so", "lib/liblibDaScriptDyn_runtime.so"),
        }[args.platform]
        sdk_files += [sdk / name for name in native_files]
        if args.with_imgui:
            sdk_files += sorted(p for p in (sdk / "modules/dasImgui/imgui").rglob("*")
                                if p.is_file() and p.suffix in {".h", ".cpp"})
            sdk_files += [sdk / "modules/dasImgui/dasModuleImgui.shared_module",
                          sdk / "modules/dasClipboard/dasModuleClipboard.shared_module"]
            if args.platform == "windows":
                sdk_files += [sdk / ("lib/dasModuleImgui.lib" if (sdk / "lib/dasModuleImgui.lib").is_file()
                                    else "modules/dasImgui/dasModuleImgui.lib")]
        for path in sdk_files:
            if not path.is_file():
                parser.error(f"Missing SDK input: {path}")
        if not (sdk / "include/daScript/daScript.h").is_file():
            parser.error("Missing daScript headers")
        (output / "sdk.sha256").write_bytes("".join(
            f"{hashlib.sha256(p.read_bytes()).hexdigest()} {p.relative_to(sdk).as_posix()}\n"
            for p in sdk_files).encode("utf-8"))
        (output / "src").mkdir()
        for path in (ROOT / "src").glob("*.h"):
            shutil.copy2(path, output / "src" / path.name)
        shutil.copy2(ROOT / "src/module_sdl3.cpp", output / "src/module_sdl3.cpp")
        shutil.copytree(ROOT / "src/generated", output / "src/generated")
        if args.with_imgui:
            (output / "src/libraries").mkdir()
            for name in ("module_imgui_sdl.cpp", "imgui_sdl.h"):
                shutil.copy2(ROOT / "src/libraries" / name, output / "src/libraries" / name)
        (output / "cmake").mkdir()
        shutil.copy2(ROOT / "src/package/CMakeLists.txt", output / "cmake/native.cmake")
        (output / "CMakeLists.txt").write_text(
            'cmake_minimum_required(VERSION 3.24)\n'
            'project(dasSDL3SourcePackage LANGUAGES C CXX)\n'
            'set(BUILD_TESTING OFF CACHE BOOL "" FORCE)\n'
            'set(DASSDL3_SOURCE_DIR "@D@{CMAKE_CURRENT_SOURCE_DIR}/src")\n'
            'set(DASSDL3_PACKAGE_OUTPUT "@D@{CMAKE_CURRENT_SOURCE_DIR}")\n'
            'set(DASSDL3_SDK_FINGERPRINT "@D@{CMAKE_CURRENT_SOURCE_DIR}/sdk.sha256")\n'
            'set(DASSDL3_PACKAGE_FETCH_SDL ON CACHE BOOL "")\n'
            f'set(DASSDL3_PACKAGE_IMGUI {"ON" if args.with_imgui else "OFF"} CACHE BOOL "")\n'
            'include(cmake/native.cmake)\n'.replace("@D@", chr(36)), encoding="utf-8")
    registrations = []
    if args.with_imgui:
        registrations.append('    register_dynamic_module("{project_path}/dasSDL3.shared_module", "Module_imgui_sdl3")')
    for script in scripts:
        shutil.copy2(script, output / "dassdl3" / script.name)
        registrations.append(
            f'    register_native_path("dassdl3", "{script.stem}", '
            f'"{{project_path}}/dassdl3/{script.name}")')
    (output / ".das_module").write_text(
        'options gen2\nrequire daslib/fio\n\n[export]\n'
        'def initialize(project_path : string) {\n'
        '    register_dynamic_module("{project_path}/dasSDL3.shared_module", "Module_dasSDL3")\n'
        + "\n".join(registrations) + "\n}\n", encoding="utf-8")
    (output / ".das_package").write_text(
        'options gen2\nrequire daslib/daspkg\n\n[export]\ndef package() {\n'
        '    package_name("dasSDL3")\n'
        f'    package_description("SDL3 core bindings: local {args.platform} Release package")\n'
        '    package_license("MIT")\n'
        '    package_min_sdk("0.6.4")\n'
        f'    package_platform("{"darwin" if args.platform == "macos" else args.platform}")\n'
        '    package_tag("sdl3")\n}\n\n[export]\ndef build() {\n    ' + ('cmake_build()' if args.source else 'no_build()') + '\n}\n',
        encoding="utf-8")
    with (output / ".das_package").open("a", encoding="utf-8") as manifest:
        manifest.write('\n[export]\ndef release() {\n    release_include("LICENSE")\n    release_include("VERSION")\n    release_include("licenses/**")\n}\n')
    if args.with_imgui:
        with (output / ".das_package").open("a", encoding="utf-8") as manifest:
            manifest.write('\n[export]\ndef dependencies(version : string) {\n    require_package("dasImgui")\n}\n')
    (output / "profile.json").write_text(json.dumps({
        "version": (ROOT / "VERSION").read_text(encoding="utf-8").strip(),
        "profile": {"macos": "macos-appleclang-release", "windows": "windows-x64-msvc-release-md-avx2",
                    "linux": "linux-x86_64-release"}[args.platform],
        "sdl": "3.4.16", "binding_reference_revision": "ebac0ffe46ab30de6c9536f4b0af7a33ede45902",
        "sdk_runtime_sha256": hashlib.sha256(
            (args.sdk / runtime).read_bytes()).hexdigest() if args.sdk else None,
        "module_sha256": hashlib.sha256(source.read_bytes()).hexdigest() if source else None,
        "kind": "source" if args.source else "binary",
        "features": ["core", "imgui"] if args.with_imgui else ["core"],
        "modules": [s.stem for s in scripts],
        "distribution": "local pilot; requires matching native daScript ABI",
    }, indent=2) + "\n", encoding="utf-8")
    print(f"Staged {len(scripts)} boost modules: {output}")

if __name__ == "__main__":
    main()
