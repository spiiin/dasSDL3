"""Compile every GPU example shader twice and optionally validate its SPIR-V."""
import argparse
import re
import subprocess
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runner", required=True)
    parser.add_argument("--spirv-val")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    shaders = root / "examples/gpu/shaders"
    modules = sorted(shaders.glob("*_shaders.das"))
    assert len(modules) == 9
    names = []
    with tempfile.TemporaryDirectory(prefix="gpu-example-dsl-") as directory:
        folder = Path(directory)
        imports = []
        for module in modules:
            source = module.read_text(encoding="utf-8")
            (folder / module.name).write_text(source, encoding="utf-8")
            imports.append(f"require {module.stem}")
            names.extend(re.findall(r'(?:vertex|fragment)_shader\(name\s*=\s*"([^"\n]+)"', source))
        assert len(names) == 29 and len(set(names)) == len(names)
        calls = []
        for name in names:
            calls.append(f'save("{folder.as_posix()}/{name}.spv", {name}, {name}_reflect)')
        script = folder / "check.das"
        script.write_text("options gen2\n" + "\n".join(imports) + r'''
require dassdl3/sdl3_shader_dsl
require daslib/fio

def save(path : string; words, reflection : array<uint>) {
    gpu_dsl_shader_info(reflection) |> unwrap
    fopen(path, "wb") $(f) { verify(f != null); verify(fwrite(f, words) == length(words) * 4) }
}
[export]
def main(smoke : bool) : int {
''' + "\n".join(calls) + "\nreturn 0\n}\n", encoding="utf-8")
        previous = None
        for _ in range(2):
            result = subprocess.run([args.runner, str(script), "--smoke-test"],
                                    capture_output=True, text=True, timeout=90)
            assert result.returncode == 0, result.stdout + result.stderr
            current = [(folder / f"{name}.spv").read_bytes() for name in names]
            if previous is not None:
                assert current == previous, "Non-deterministic shader bytecode"
            previous = current
        if args.spirv_val:
            for name in names:
                result = subprocess.run([args.spirv_val, "--target-env", "vulkan1.1",
                                         str(folder / f"{name}.spv")],
                                        capture_output=True, text=True, timeout=30)
                assert result.returncode == 0, name + ": " + result.stdout + result.stderr
    print(f"GPU example DSL: {len(names)} shaders, deterministic compilation; "
          + ("SPIRV-Tools PASS" if args.spirv_val else "SPIRV-Tools not requested"))


if __name__ == "__main__":
    main()
