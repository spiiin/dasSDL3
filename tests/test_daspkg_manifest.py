"""Execute package metadata/hooks with the upstream SDK runner; never publish/build."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--das-root", type=Path, required=True)
    args = parser.parse_args()
    sdk = args.das_root.resolve()
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    assert version == "0.1.0"
    work = Path(tempfile.mkdtemp(prefix="daspkg metadata ", dir=ROOT / "build"))
    shutil.copy2(sdk / "utils/daspkg/package_runner.das", work / "package_runner.das")
    source = r"""options gen2
require package_runner
require daslib/fio

[export]
def main {
    let path = MANIFEST
    var meta : PackageMeta
    verify(run_das_package_meta(path,meta))
    verify(meta.pkg_name == "dasSDL3" && meta.author == "spiiin")
    verify(meta.source == "github.com/spiiin/dasSDL3")
    verify(meta.license == "MIT" && meta.min_sdk == "0.6.4")
    verify(!empty(meta.description) && length(meta.tags) == 3)
    for (version in ["", "latest", "0.1.0", "0.1.1"]) {
        var resolution : ResolveResult
        verify(run_das_package_resolve(path,"0.6.4",version,resolution))
        if (empty(version) || version == "latest") {
            verify(resolution.branch == "main" && empty(resolution.tag))
        } else {
            verify(resolution.tag == "v{version}" && empty(resolution.branch))
        }
    }
    var build : PackageBuildInfo
    verify(run_das_package_build(path,build) && build.is_cmake)
    var deps : array<PackageDependency>
    verify(run_das_package_deps(path,"0.1.0",deps))
    if (get_env_variable("DASSDL3_PACKAGE_PROFILE") == "imgui") {
        verify(length(deps) == 1 && deps[0].source == "dasImgui")
    } else {
        verify(length(deps) == 0)
    }
    var release : PackageReleaseInfo
    verify(run_das_package_release(path,release))
    verify(length(release.include_globs) == 3)
    verify(release.include_globs[0] == "LICENSE")
    verify(release.include_globs[1] == "VERSION")
    verify(release.include_globs[2] == "licenses/**")
    print("PASS: package metadata, resolution, dependencies, build and release declarations.\n")
}
"""
    source = source.replace("MANIFEST", json.dumps((ROOT / ".das_package").as_posix()))
    script = work / "verify.das"
    script.write_text(source, encoding="utf-8")
    for profile in ("core", "imgui"):
        result = subprocess.run([str(sdk / "bin/daslang.exe"), "-dasroot", str(sdk), str(script)],
                                cwd=work, env=dict(os.environ, DASSDL3_PACKAGE_PROFILE=profile),
                                capture_output=True, text=True, timeout=60)
        (work / f"{profile}.log").write_text(result.stdout + result.stderr, encoding="utf-8")
        if result.returncode or "PASS: package metadata" not in result.stdout:
            raise RuntimeError(result.stdout + result.stderr)
        print(f"{profile}: {result.stdout.strip()}")
    print(f"Logs: {work}")

if __name__ == "__main__":
    main()
