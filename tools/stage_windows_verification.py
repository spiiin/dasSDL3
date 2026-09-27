"""Prepare a portable core/ImGui release verification kit for another Windows host."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--core", type=Path, required=True)
    parser.add_argument("--imgui", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True, help="New directory; adjacent ZIP is also created")
    args = parser.parse_args()
    output = args.output.resolve()
    archive = output.with_suffix(".zip")
    if output.exists() or archive.exists():
        parser.error("Choose a new output directory and ZIP path")
    sources = {"core": args.core.resolve(), "imgui": args.imgui.resolve()}
    for profile, source in sources.items():
        if source == output or source in output.parents:
            parser.error("Output must be outside input bundles")
        required = ["libDaScriptDyn.dll", "libDaScriptDyn_runtime.dll",
                    "modules/dasSDL3/dasSDL3.shared_module",
                    "sdl3_package_demo.exe" if profile == "core" else "sdl3_imgui_demo.exe"]
        if profile == "imgui":
            required += ["dasModuleClipboard.shared_module", "modules/dasImgui/dasModuleImgui.shared_module"]
        required += ["modules/dasSDL3/LICENSE", *[
            "modules/dasSDL3/" + p.relative_to(ROOT).as_posix()
            for p in (ROOT / "licenses").rglob("*") if p.is_file()]]
        for name in required:
            if not (source / name).is_file():
                parser.error(f"{profile}: missing {name}")
        for name in ["LICENSE", *[
                p.relative_to(ROOT).as_posix() for p in (ROOT / "licenses").rglob("*") if p.is_file()]]:
            if (source / "modules/dasSDL3" / name).read_bytes() != (ROOT / name).read_bytes():
                parser.error(f"{profile}: stale license file {name}")
        if list(source.rglob("*.das")) or (source / "LLVM.dll").exists():
            parser.error(f"{profile}: unexpected build-time sources/runtime")
    output.mkdir(parents=True)
    for profile, source in sources.items():
        shutil.copytree(source, output / profile, ignore=shutil.ignore_patterns("*.map"))
    shutil.copy2(ROOT / "tools/verify_windows_release.ps1", output / "verify.ps1")
    (output / "README.txt").write_text(
        "dasSDL3 Windows x64 release verification\n\n"
        "Copy this entire kit to a separate Windows x64 machine/VM. AVX2 and the\n"
        "Microsoft Visual C++ runtime are prerequisites. No Python, SDK, daslang,\n"
        "LLVM, Git or compiler is needed. This kit installs nothing.\n\n"
        "In 64-bit Windows PowerShell, from the extracted kit directory:\n"
        'powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\\verify.ps1 -RunLabel "clean Windows VM"\n\n'
        "The label is descriptive: the script cannot certify a clean VM.\n"
        "The runner verifies all file hashes, runs core and GUI with dummy SDL\n"
        "drivers, checks GUI pixels and cleanup, and writes report.json plus logs\n"
        "to a new TEMP directory printed on screen. Failure returns exit code 1.\n"
        "Send back that report directory. Do not install development tools to\n"
        "make a failing check pass; record any missing runtime prerequisite first.\n\n"
        "For a separate interactive check, run imgui/sdl3_imgui_demo.exe.\n"
        "Try the counter, demo toggle, window resize and Escape. The automated\n"
        "check does not validate input, physical GPU drivers or Web support.\n\n"
        "Licenses are in each profile's modules/dasSDL3/LICENSE and licenses/.\n"
        "files.json detects accidental changes; it is not a digital signature.\n",
        encoding="utf-8")
    inventory = [
        {"path": p.relative_to(output).as_posix(), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
        for p in sorted(output.rglob("*")) if p.is_file()
    ]
    (output / "files.json").write_text(json.dumps(inventory, indent=2) + "\n", encoding="utf-8")
    shutil.make_archive(str(archive.with_suffix("")), "zip", root_dir=output)
    print(f"Kit: {output}")
    print(f"Archive: {archive}")
    print(f"SHA256: {hashlib.sha256(archive.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    main()
