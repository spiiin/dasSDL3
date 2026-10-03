"""Seal a completed local daspkg .app with an ad-hoc macOS signature."""
import argparse
from pathlib import Path
import subprocess
import sys
import shutil
import os
import plistlib


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=Path)
    args = parser.parse_args()
    bundle = args.bundle.resolve()
    if sys.platform != "darwin" or not (bundle / "Contents/Info.plist").is_file():
        parser.error("Expected a completed macOS .app on macOS")
    # Assets and notices are resources. Leaving text in Contents/MacOS
    # makes deep signing attach signatures via xattrs that ordinary copies lose.
    code = bundle / "Contents/MacOS"
    resources = bundle / "Contents/Resources"
    info = plistlib.loads((bundle / "Contents/Info.plist").read_bytes())
    natives = [code / info["CFBundleExecutable"], *code.rglob("*.dylib"),
               *code.rglob("*.shared_module")]
    by_name = {}
    for native in natives:
        if native.name in by_name:
            parser.error(f"Ambiguous bundled native library: {native.name}")
        by_name[native.name] = native
    # Shared modules may import each other by @rpath/basename. daspkg places
    # them in separate module directories; resolve those imports within the
    # final bundle before signing, including ImGui's native Clipboard import.
    for native in natives:
        dependencies = subprocess.check_output(["otool", "-L", str(native)], text=True)
        for line in dependencies.splitlines()[1:]:
            dependency = line.strip().split(" (compatibility")[0]
            target = by_name.get(Path(dependency).name)
            if dependency.startswith("@") and target is not None and target != native:
                relative = os.path.relpath(target, native.parent)
                subprocess.run(["install_name_tool", "-change", dependency,
                                "@loader_path/" + relative, str(native)], check=True)
    for relative in ["assets", ".daspkg_release.manifest", "modules/dasSDL3/LICENSE",
                     "modules/dasSDL3/VERSION", "modules/dasSDL3/licenses"]:
        source = code / relative
        if source.exists():
            target = resources / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(source), str(target))
    # daspkg signs individual Mach-O images before creating Info.plist. Seal the
    # final bundle after shipping all dependencies and resources.
    subprocess.run(["codesign", "--force", "--deep", "--sign", "-", str(bundle)], check=True)
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(bundle)], check=True)


if __name__ == "__main__":
    main()
