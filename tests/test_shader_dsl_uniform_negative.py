"""Unsupported uniform types must fail at compile time, before reaching SDL."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--runner", required=True)
args = parser.parse_args()
cases = [
    ("bool", "true"), ("string", '"bad"'), ("array<float>", None),
    ("float3x3[2]", None), ("float[2][2]", None), ("float[4097]", None),
]
with tempfile.TemporaryDirectory(prefix="sdl-uniform-negative-") as directory:
    source = Path(directory) / "invalid.das"
    for field, value in cases:
        text = "options gen2\nrequire dassdl3/sdl3_shader_uniforms\nrequire math\n"
        text += f"struct Bad {{ value : {field} }}\n"
        text += "[export]\ndef main(smoke : bool) : int {\nvar value : Bad\n"
        if value is not None:
            text += f"value.value={value}\n"
        text += "var bytes <- gpu_dsl_uniform_bytes(value)\nreturn length(bytes)\n}\n"
        source.write_text(text, encoding="utf-8")
        result = subprocess.run([args.runner, str(source), "--smoke-test"], capture_output=True, text=True, timeout=20)
        output = result.stdout + result.stderr
        assert result.returncode != 0 and ("SDL uniform" in output or "std140" in output), (field, output)
print("Uniform unsupported types rejected")
