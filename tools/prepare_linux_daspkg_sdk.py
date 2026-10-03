"""Build and install the pinned Linux core SDK from a configured developer build."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if sys.platform != "linux":
        parser.error("Run inside Linux")
    build, output = args.build.resolve(), args.output.resolve()
    if output.exists():
        parser.error("Use a new output directory")
    targets = ["daslang", "daslang-live", "libDaScript", "libDaScript_runtime",
               "libDasModuleLiveHost", "libDasModuleMinfft", "libDasModulePUGIXML",
               "libDasModuleUnitTest", "arch_extract_daslib",
               *[f"arch_extract_modules_{name}" for name in
                 ("dasLLAMA", "dasMetal", "dasOpenGL", "dasSpirv")]]
    subprocess.run(["cmake", "--build", str(build), "--target", *targets,
                    "--parallel", "6"], check=True)
    subprocess.run(["cmake", "--install", str(build / "third_party/daScript"),
                    "--prefix", str(output)], check=True)
    source = ROOT / "third_party/daScript"
    # This upstream revision's explicit install list omits public transitive
    # headers (including misc/das_asan.h). Keep the complete pinned header tree.
    shutil.copytree(source / "include", output / "include", dirs_exist_ok=True)
    shutil.copytree(source / "3rdparty/fmt/include", output / "3rdparty/fmt/include",
                    dirs_exist_ok=True)
    print(f"Installed Linux SDK: {output}")


if __name__ == "__main__":
    main()
