"""Compile-time regression: removed renderer-framework APIs must stay unavailable."""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
forbidden = re.compile(r"SDL_\w*GPU\w*(?:Mesh|Material|Geometry|Scene|Plan|VertexID)|gpu_plan_\w+")
exports = re.findall(r'lib, "(\w+)"', (root / 'src/module_sdl3.cpp').read_text())
assert not [name for name in exports if forbidden.fullmatch(name)]
assert not [name for name in exports if name.startswith(('SDL_Scope', 'SDL_Invoke'))]
for wrapper in (root / 'dassdl3').glob('*.das'):
    source = re.sub(r'//[^\n]*', '', wrapper.read_text())
    assert not re.search(r'\b(?:panic|verify|recover)\s*\(|\btry\s*\{', source), wrapper
for header in (root / 'src').glob('*.h'):
    assert 'runWithCatch' not in header.read_text(), header
for module in ('mesh', 'lit', 'scene', 'batches', 'resources', 'commands', 'render_plan', 'culling', 'instancing'):
    assert not (root / f'dassdl3/sdl3_gpu_{module}_boost.das').exists()

with tempfile.TemporaryDirectory() as directory:
    for name in ('SDL_CreateGPUCommandPlan', 'SDL_CreateGPUMaterial', 'SDL_CreateGPUTexturedMesh',
                 'SDL_CreateGPULitScene', 'SDL_CreateGPUBatchScene',
                 'SDL_InvokeGPUHandle', 'SDL_ScopeWindow', 'SDL_ScopeGPUCommandBuffer'):
        script = Path(directory) / 'removed_api.das'
        script.write_text(f'options gen2\nrequire sdl3\n[export]\ndef main {{ {name}() }}\n')
        result = subprocess.run([sys.argv[1], str(script)], capture_output=True, text=True, timeout=30)
        output = result.stdout + result.stderr
        assert result.returncode != 0 and name in output, output
        assert 'out of 0 total functions' in output.lower(), output
print('GPU public API boundary: removed framework names are unavailable')
