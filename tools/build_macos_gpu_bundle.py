"""Build a local standalone GPU .app with the matching dynamic daScript SDK."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SHADERS = ("bindings.vert.msl", "bindings.frag.msl", "render_state.frag.msl")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--module", type=Path, required=True)
    parser.add_argument("--das-root", type=Path, required=True)
    parser.add_argument("--llvm-dir", type=Path, required=True)
    parser.add_argument("--work", type=Path, required=True, help="New or empty build directory")
    args = parser.parse_args()
    if sys.platform != "darwin":
        parser.error("This workflow builds a native macOS bundle")
    work, das, llvm = args.work.resolve(), args.das_root.resolve(), args.llvm_dir.resolve()
    if work.exists() and any(work.iterdir()):
        parser.error("--work must be new or empty")
    if not (llvm / "LLVM.dll").is_file():
        parser.error("Missing pinned LLVM.dll")
    consumer = work / "consumer"
    consumer.mkdir(parents=True)
    env = dict(os.environ, DAS_DLL_PATH=str(llvm))

    def run(name, command, cwd):
        result = subprocess.run(command, cwd=cwd, env=env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600)
        (work / (name + ".log")).write_text(result.stdout)
        if result.returncode:
            raise RuntimeError(f"{name} failed ({result.returncode}):\n{result.stdout}")

    package = work / "staged/dasSDL3"
    run("stage", [sys.executable, str(ROOT / "tools/stage_daspkg.py"),
                  "--module", str(args.module.resolve()), "--sdk", str(das),
                  "--platform", "macos", "--output", str(package)], ROOT)
    cli = [str(das / "bin/daslang"), "-dasroot", str(das),
           str(das / "utils/daspkg/main.das"), "--"]
    run("install", cli + ["install", str(package), "--root", str(consumer)], consumer)
    for name in ("main.das", ".das_package"):
        shutil.copy2(ROOT / "examples/daspkg-gpu-consumer" / name, consumer / name)
    shutil.copy2(ROOT / "examples/46_gpu_texture_uniform_bindings.das", consumer / "texture_bindings.das")
    shutil.copy2(ROOT / "examples/86_gpu_renderer.das", consumer / "gpu_renderer.das")
    (consumer / "gpu").mkdir()
    shutil.copy2(ROOT / "examples/gpu/file_shader_support.das", consumer / "gpu/file_shader_support.das")
    assets = consumer / "assets/shaders"
    assets.mkdir(parents=True)
    for name in SHADERS:
        shutil.copy2(ROOT / "examples/assets/shaders" / name, assets / name)
    run("check", cli + ["check", "--root", str(consumer)], consumer)
    run("release", cli + ["release", "--root", str(consumer), "--out", str(work / "out")], consumer)
    bundle = work / "out/sdl3_gpu_demo.app"
    run("sign", [sys.executable, str(ROOT / "tools/sign_macos_bundle.py"), str(bundle)], ROOT)
    print(bundle)


if __name__ == "__main__":
    main()
