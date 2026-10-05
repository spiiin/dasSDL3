"""Execute package metadata/hooks with the upstream SDK runner; never publish/build."""
import argparse
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--das-root", type=Path, required=True)
    args = parser.parse_args()
    sdk = args.das_root.resolve()
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    assert re.fullmatch(r"\d+\.\d+\.\d+", version), f"Invalid VERSION: {version!r}"
    major, minor, patch = map(int, version.split("."))
    next_version = f"{major}.{minor}.{patch + 1}"
    (ROOT / "build").mkdir(exist_ok=True)
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
    verify(length(meta.platforms) == 3 && meta.platforms[0] == "windows" && meta.platforms[1] == "darwin" && meta.platforms[2] == "linux")
    verify(!empty(meta.description) && length(meta.tags) == 3)
    for (version in ["", "latest", PACKAGE_VERSION, NEXT_VERSION]) {
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
    verify(run_das_package_deps(path,PACKAGE_VERSION,deps))
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
    source = source.replace("PACKAGE_VERSION", json.dumps(version)).replace("NEXT_VERSION", json.dumps(next_version))
    script = work / "verify.das"
    script.write_text(source, encoding="utf-8")
    for profile in ("core", "imgui"):
        result = subprocess.run([str(sdk / "bin" / ("daslang.exe" if os.name == "nt" else "daslang")), "-dasroot", str(sdk), str(script)],
                                cwd=work, env=dict(os.environ, DASSDL3_PACKAGE_PROFILE=profile),
                                capture_output=True, text=True, timeout=60)
        (work / f"{profile}.log").write_text(result.stdout + result.stderr, encoding="utf-8")
        if result.returncode or "PASS: package metadata" not in result.stdout:
            raise RuntimeError(result.stdout + result.stderr)
        print(f"{profile}: {result.stdout.strip()}")
    # Exercise emitted manifests too. The placeholder native file is never
    # loaded: this test only executes metadata/build/dependency hooks.
    placeholder = work / "metadata-only.shared_module"
    placeholder.write_bytes(b"metadata fixture, not a loadable module")
    for profile, mode in (("core", "binary"), ("imgui", "binary"),
                          ("core", "source"), ("imgui", "source")):
        if profile == "imgui" and sys.platform.startswith("linux"):
            continue
        # A source ImGui fixture needs the built optional SDK module; binary
        # metadata remains testable with the minimal core SDK used by CI.
        if profile == "imgui" and mode == "source" and not (sdk / (
                "modules/dasImgui/dasModuleImgui.shared_module" if sys.platform == "darwin"
                else "lib/dasModuleImgui.lib")).is_file():
            continue
        staged = work / f"staged-{profile}-{mode}"
        command = [sys.executable, str(ROOT / "tools/stage_daspkg.py"),
                   "--output", str(staged), "--sdk", str(sdk)]
        if sys.platform == "darwin":
            command += ["--platform", "macos"]
        command += ["--source"] if mode == "source" else ["--module", str(placeholder)]
        if profile == "imgui":
            command += ["--with-imgui"]
        subprocess.run(command, check=True, capture_output=True, text=True)
        check = '''options gen2
require package_runner
[export]
def main {
    var meta : PackageMeta
    verify(run_das_package_meta(MANIFEST, meta))
    verify(meta.pkg_name == "dasSDL3" && meta.min_sdk == "0.6.4")
    verify(length(meta.platforms) == 1 && meta.platforms[0] == EXPECTED_PLATFORM)
    var info : PackageBuildInfo
    verify(run_das_package_build(MANIFEST, info) && info.is_cmake == SOURCE_BUILD)
    print("PASS: staged platform metadata\\n")
}
'''.replace("MANIFEST", json.dumps((staged / ".das_package").as_posix())).replace(
            "SOURCE_BUILD", "true" if mode == "source" else "false").replace(
            "EXPECTED_PLATFORM", json.dumps("darwin" if sys.platform == "darwin" else "windows" if os.name == "nt" else "linux"))
        staged_script = work / f"verify-staged-{profile}-{mode}.das"
        staged_script.write_text(check, encoding="utf-8")
        result = subprocess.run([str(sdk / "bin" / ("daslang.exe" if os.name == "nt" else "daslang")), "-dasroot", str(sdk), str(staged_script)],
                                cwd=work, capture_output=True, text=True, timeout=60)
        (work / f"staged-{profile}-{mode}.log").write_text(result.stdout + result.stderr, encoding="utf-8")
        if result.returncode or "PASS: staged" not in result.stdout:
            raise RuntimeError(result.stdout + result.stderr)
        print(f"staged {profile} {mode}: {result.stdout.strip()}")
    print(f"Logs: {work}")

if __name__ == "__main__":
    main()
