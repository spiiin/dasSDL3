"""Audit ELF paths and exercise an SDK moved outside the source tree."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk", type=Path, required=True)
    parser.add_argument("--module", type=Path, required=True)
    args = parser.parse_args()
    if sys.platform != "linux":
        parser.error("Linux only")
    sdk = args.sdk.resolve()
    binaries = [sdk / "bin/daslang", *sdk.rglob("*.so"),
                *sdk.rglob("*.shared_module"), args.module.resolve()]
    for binary in binaries:
        dynamic = subprocess.check_output(["readelf", "-d", str(binary)], text=True)
        for line in dynamic.splitlines():
            if any(tag in line for tag in ("(RPATH)", "(RUNPATH)", "(NEEDED)")):
                entry = re.search(r"\[(.*)\]", line).group(1)
                if "(NEEDED)" in line:
                    assert "/" not in entry, (binary, line)
                else:
                    assert all(p.startswith("$ORIGIN") for p in entry.split(":")), (binary, line)
    portable = Path(tempfile.mkdtemp(prefix="daspkg portable sdk "))
    moved = portable / "relocated sdk"
    shutil.copytree(sdk, moved, symlinks=True)
    env = {k: v for k, v in os.environ.items()
           if k not in {"LD_LIBRARY_PATH", "LD_PRELOAD", "DAS_ROOT", "DAS_DYN_MODULE_PATH"}}
    env["PATH"] = "/usr/bin:/bin"
    subprocess.run([sys.executable, str(ROOT / "tests/test_daspkg.py"),
                    "--das-root", str(moved), "--module", str(args.module.resolve())],
                   env=env, check=True)
    runtime = moved / "lib/liblibDaScriptDyn_runtime.so"
    hidden = runtime.with_suffix(".hidden")
    runtime.rename(hidden)
    try:
        result = subprocess.run([str(moved / "bin/daslang"), "--version"],
                                cwd=portable, env=env, capture_output=True, text=True)
        assert result.returncode != 0, "SDK silently resolved a missing runtime outside the bundle"
    finally:
        hidden.rename(runtime)
    print(f"PASS: ELF paths, relocated SDK and missing runtime; {portable}")


if __name__ == "__main__":
    main()
