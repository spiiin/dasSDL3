"""Audit and relocate the saved-MSL GPU bundle; --run requires a GUI session."""
import argparse
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SHADERS = ("bindings.vert.msl", "bindings.frag.msl", "render_state.frag.msl")


def audit(bundle):
    code = bundle / "Contents/MacOS"
    info = plistlib.loads((bundle / "Contents/Info.plist").read_bytes())
    assert info["CFBundleExecutable"] == "sdl3_gpu_demo"
    executable = code / info["CFBundleExecutable"]
    for relative in ("sdl3_gpu_demo", "liblibDaScriptDyn.dylib",
                     "liblibDaScriptDyn_runtime.dylib", "modules/dasSDL3/dasSDL3.shared_module"):
        assert (code / relative).is_file(), relative
    assert not list(bundle.rglob("*.das")), "Script sources leaked into distribution"
    assert not list(bundle.rglob("LLVM.dll")), "Compiler runtime leaked into distribution"
    for name in SHADERS:
        shipped = bundle / "Contents/Resources/assets/shaders" / name
        expected = ROOT / "examples/assets/shaders" / name
        assert shipped.read_bytes() == expected.read_bytes(), f"Altered/missing shader: {name}"
    for relative in ("LICENSE", "VERSION", *[
            p.relative_to(ROOT).as_posix() for p in (ROOT / "licenses").rglob("*") if p.is_file()]):
        shipped = bundle / "Contents/Resources/modules/dasSDL3" / relative
        assert shipped.read_bytes() == (ROOT / relative).read_bytes(), relative
    for native in (executable, *code.rglob("*.dylib"), *code.rglob("*.shared_module")):
        load = subprocess.check_output(["otool", "-l", str(native)], text=True)
        for path in re.findall(r"cmd LC_RPATH\s+cmdsize \d+\s+path (.*?) \(offset", load):
            assert path.startswith(("@loader_path", "@executable_path", "@rpath")), path
        dependencies = subprocess.check_output(["otool", "-L", str(native)], text=True)
        for line in dependencies.splitlines()[1:]:
            path = line.strip().split(" (compatibility")[0]
            assert path.startswith(("@", "/usr/lib/", "/System/Library/")), path
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(bundle)], check=True)
    return executable


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--run", action="store_true")
    args = parser.parse_args()
    if sys.platform != "darwin":
        parser.error("Native macOS only")
    audit(args.bundle.resolve())
    with tempfile.TemporaryDirectory(prefix="dasSDL3 GPU relocation ") as temporary:
        moved = Path(temporary) / "relocated app.app"
        shutil.copytree(args.bundle, moved, symlinks=True)
        executable = audit(moved)
        cwd = Path(temporary) / "empty cwd"
        cwd.mkdir()
        if args.run:
            clean = {k: v for k, v in os.environ.items() if k in ("HOME", "TMPDIR", "LANG")}
            clean.update(PATH="/usr/bin:/bin:/usr/sbin:/sbin", SDL_VIDEODRIVER="cocoa",
                         SDL_GPU_DRIVER="metal", SDL_AUDIODRIVER="dummy")
            result = subprocess.run([str(executable), "--smoke"], cwd=cwd, env=clean,
                                    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
            print(result.stdout, end="")
            assert result.returncode == 0, result.returncode
            assert "Texture/sampler and uniform bindings: metal" in result.stdout
            assert "GPU Renderer: custom fragment uniforms; resources released." in result.stdout
            assert "Standalone GPU: texture pixels verified; resources released." in result.stdout
    print("PASS: GPU bundle assets, notices, dependencies, signature and relocation" +
          ("; native Metal execution" if args.run else "; native execution pending"))


if __name__ == "__main__":
    main()
