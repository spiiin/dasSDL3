"""Offline shader assets; normal CMake/consumer builds do not run this tool."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--dxc', default='dxc')
parser.add_argument('--spirv-val', default='spirv-val')
parser.add_argument('--output', type=Path, default=root / 'examples/assets/shaders')
parser.add_argument('--check', action='store_true')
parser.add_argument('--mesh', action='store_true', help='Build fixed float2 position/UV + sampled texture shader ABI')
parser.add_argument('--vertex-color', action='store_true', help='Build resource-free float2 position/float3 color vertex ABI')
parser.add_argument('--bindings', action='store_true', help='Build independent graphics bindings test ABI')
args = parser.parse_args()
sources = root / 'examples/assets/shaders'
version = subprocess.check_output([args.dxc, '--version'], text=True).strip()
prefix = 'bindings' if args.bindings else 'vertex_color' if args.vertex_color else 'mesh' if args.mesh else 'triangle'
manifest = {'entrypoint': 'main', 'resources': 'fragment sampler 0' if args.mesh else 'none', 'vertex_inputs': 'float2 location0 position; float2 location1 uv; stride16' if args.mesh else 'SV_VertexID only',
            'compiler': version, 'spirv_target': 'vulkan1.0', 'files': {}}
with tempfile.TemporaryDirectory() as temp:
    if args.bindings:
        manifest['resources'] = 'vertex sampler 0; vertex uniform 0: two float4 rows, 32 bytes; fragment sampler 0; fragment uniform 0: tint float4, 16 bytes'
        manifest['vertex_inputs'] = 'float2 location0 position; float2 location1 uv; stride16'
    if args.vertex_color:
        manifest['vertex_inputs'] = 'float2 location0 position; float3 location1 color; configurable vertex/instance layouts'
    for stage, profile in [('vert', 'vs_6_0'), ('frag', 'ps_6_0')]:
        source = sources / f'{prefix}.{stage}.hlsl'
        manifest['files'][source.name] = hashlib.sha256(source.read_bytes()).hexdigest()
        for fmt in ['spv', 'dxil']:
            name = f'{prefix}.{stage}.{fmt}'
            output = Path(temp) / name
            command = [args.dxc, '-T', profile, '-E', 'main', '-O3', '-Fo', str(output)]
            if fmt == 'spv':
                command += ['-spirv', '-fspv-target-env=vulkan1.0']
            subprocess.check_call(command + [str(source)])
            if fmt == 'spv': subprocess.check_call([args.spirv_val, '--target-env', 'vulkan1.0', str(output)])
            data = output.read_bytes()
            manifest['files'][name] = hashlib.sha256(data).hexdigest()
            target = args.output / name
            if args.check:
                if target.read_bytes() != data: raise SystemExit(f'Stale shader: {target}')
            else:
                args.output.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
    data = json.dumps(manifest, indent=2) + '\n'
    target = args.output / f'{prefix}-manifest.json'
    if args.check:
        if target.read_text() != data: raise SystemExit('Stale shader manifest/compiler version')
    else: target.write_text(data)
print(f'{prefix} shader compilation and SPIR-V validation PASS')
