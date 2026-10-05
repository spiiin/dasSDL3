"""Archive a reference dynamic SDK for the current host platform."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import zipfile
import sys
import tarfile


def stage_linux(sdk, output):
    """Keep the installed ELF SDK layout, permissions and library aliases intact."""
    archive = output.with_suffix(".tar.gz")
    if output.exists() or archive.exists():
        raise RuntimeError("Output directory and archive must not exist")
    for line in (ROOT / "src/package/profiles/linux-x86_64-core.sha256").read_text().splitlines():
        digest, relative = line.split(" ", 1)
        if hashlib.sha256((sdk / relative).read_bytes()).hexdigest() != digest:
            raise RuntimeError(f"SDK fingerprint mismatch: {relative}")
    for name in ("bin/daslang", "lib/liblibDaScriptDyn.so",
                 "lib/liblibDaScriptDyn_runtime.so", "include/daScript/daScript.h",
                 "modules/dasPUGIXML/dasModulePUGIXML.shared_module"):
        if not (sdk / name).is_file():
            raise RuntimeError(f"Missing SDK input: {name}")
    output.mkdir(parents=True)
    for name in ("bin", "lib", "include", "3rdparty", "daslib", "utils", "modules"):
        shutil.copytree(sdk / name, output / name, symlinks=True)
    for path in sdk.iterdir():
        if path.is_file() and any(word in path.name.lower() for word in
                                  ("license", "licence", "copying", "notice")):
            shutil.copy2(path, output / path.name)
    shutil.copytree(ROOT / "licenses", output / "licenses")
    (output / "dassdl3-profiles").mkdir()
    shutil.copy2(ROOT / "src/package/profiles/linux-x86_64-core.sha256",
                 output / "dassdl3-profiles/linux-x86_64-core.sha256")
    (output / "SDK-README.txt").write_text(
        "Linux x86_64 core SDK for dasSDL3, daScript ebac0ffe46ab30de6c9536f4b0af7a33ede45902.\n"
        "Built and tested on Ubuntu 24.04 with GCC 13.3. Other distributions are unvalidated.\n"
        "Keep the layout intact; use this directory as DASLANG_DIR.\n"
        "Run bin/daslang utils/daspkg/main.das -- help. Source builds need CMake, Ninja and GCC.\n"
        "ImGui and standalone release are not part of this Linux profile.\n")
    manifest = {p.relative_to(output).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in sorted(output.rglob("*")) if p.is_file()}
    (output / "SDK-SHA256.json").write_text(json.dumps(manifest, indent=2) + "\n")
    with tarfile.open(archive, "w:gz") as tar:
        tar.add(output, arcname=output.name)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    Path(str(archive) + ".sha256").write_text(f"{digest}  {archive.name}\n")
    print(f"SDK archive: {archive}; SHA256: {digest}")

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    sdk, output = args.sdk.resolve(), args.output.resolve()
    if sys.platform == "linux":
        stage_linux(sdk, output)
        return
    archive = output.with_suffix(".zip")
    if output.exists() or archive.exists():
        parser.error("Output directory and ZIP must not exist")
    files = set()
    for profile in ("core", "imgui"):
        for line in (ROOT / f"src/package/profiles/{profile}.sha256").read_text().splitlines():
            digest, relative = line.split(" ", 1)
            path = sdk / relative
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
                parser.error(f"SDK fingerprint mismatch: {relative}")
            files.add(relative)
    files.update(("bin/daslang.exe", "LICENSE", "THIRD_PARTY_NOTICES.md"))
    for directory in ("daslib", "utils/daspkg"):
        files.update(p.relative_to(sdk).as_posix() for p in (sdk / directory).rglob("*") if p.is_file())
    # Module descriptors, scripts and built modules retain the upstream layout.
    # Native ImGui headers/backends are already included by its fingerprint.
    files.update(p.relative_to(sdk).as_posix() for p in (sdk / "modules").rglob("*")
                 if p.is_file() and (p.suffix in {".das", ".shared_module"} or p.name == ".das_module"))
    # This SDK also carries upstream CLI/native modules (including PUGIXML),
    # whose notices are broader than the SDL package's curated runtime set.
    files.update(p.relative_to(sdk).as_posix() for p in sdk.rglob("*")
                 if p.is_file() and (any(word in p.name.lower() for word in ("license", "licence", "copying", "notice"))
                                     or "licenses" in p.parts))
    required = sdk / "modules/dasPUGIXML/dasModulePUGIXML.shared_module"
    if not required.is_file():
        parser.error("SDK must include the built PUGIXML module for daspkg")
    missing = [name for name in files if not (sdk / name).is_file()]
    if missing:
        parser.error(f"Missing SDK files: {missing}")
    output.mkdir(parents=True)
    for name in sorted(files):
        dest = output / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(sdk / name, dest)
    shutil.copytree(ROOT / "licenses", output / "licenses")
    shutil.copytree(ROOT / "src/package/profiles", output / "dassdl3-profiles")
    (output / "SDK-README.txt").write_text(
        "Reference DLL SDK for dasSDL3 core/ImGui on Windows x64, MSVC /MD, AVX2.\n"
        "daScript revision: ebac0ffe46ab30de6c9536f4b0af7a33ede45902.\n"
        "This is a focused SDK, not the complete upstream module bundle.\n"
        "Keep this directory intact; point DASLANG_DIR at this directory.\n"
        "Run bin/daslang.exe utils/daspkg/main.das -- help for package commands.\n"
        "Source installation requires MSVC x64 and CMake (Visual Studio or Ninja).\n"
        "Building standalone releases additionally requires LLVM tools.\n"
        "The Microsoft VC runtime remains a prerequisite.\n", encoding="utf-8")
    manifest = {p.relative_to(output).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in sorted(output.rglob("*")) if p.is_file()}
    (output / "SDK-SHA256.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as z:
        for path in sorted(output.rglob("*")):
            if path.is_file():
                z.write(path, f"{output.name}/{path.relative_to(output).as_posix()}")
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix(".zip.sha256").write_text(f"{digest}  {archive.name}\n", encoding="utf-8")
    print(f"SDK archive: {archive}; SHA256: {digest}")


if __name__ == "__main__":
    main()
