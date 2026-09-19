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
parser.add_argument('--transform', action='store_true', help='Build indexed mesh with two vec4 vertex uniform rows')
parser.add_argument('--scene3d', action='store_true', help='Build color-vertex + four-column MVP shader ABI')
parser.add_argument('--lit', action='store_true', help='Build textured 3D + inverse-transpose normals and Lambert lighting')
parser.add_argument('--instancing', action='store_true', help='Build immutable instance model/normal vertex buffer ABI')
parser.add_argument('--colored-instances', action='store_true', help='Build stride128 instance RGBA ABI')
args = parser.parse_args()
if args.colored_instances: args.instancing = True
if args.transform: args.mesh = True
sources = root / 'examples/assets/shaders'
version = subprocess.check_output([args.dxc, '--version'], text=True).strip()
prefix = 'colored_instances' if args.colored_instances else 'instances' if args.instancing else 'lit' if args.lit else 'scene3d' if args.scene3d else 'transform' if args.transform else 'mesh' if args.mesh else 'triangle'
manifest = {'entrypoint': 'main', 'resources': 'fragment sampler 0' if args.mesh else 'none', 'vertex_inputs': 'float2 location0 position; float2 location1 uv; stride16' if args.mesh else 'SV_VertexID only',
            'compiler': version, 'spirv_target': 'vulkan1.0', 'files': {}}
with tempfile.TemporaryDirectory() as temp:
    if args.transform:
        manifest['resources'] = 'vertex uniform 0: two float4 rows, 32 bytes; fragment sampler 0'
    if args.scene3d:
        manifest['resources'] = 'vertex uniform 0: four float4 columns, 64 bytes; no samplers'
        manifest['vertex_inputs'] = 'float4 location0 position; float4 location1 color; stride32'
    if args.lit:
        manifest['resources'] = 'vertex uniform 0: MVP and normal columns, 112 bytes; fragment uniform 0: light direction/ambient, 16 bytes; fragment sampler 0'
        manifest['vertex_inputs'] = 'float4 location0 position; float4 location1 normal; float2 location2 uv; stride48'
    if args.instancing:
        manifest['resources'] = 'vertex uniform 0: camera columns, 64 bytes; fragment uniform 0: light direction/ambient, 16 bytes; fragment sampler 0'
        manifest['vertex_inputs'] = 'buffer0 stride48: position4 normal4 uv2; buffer1 stride112 instance-rate: model4x4 normal3x4; locations0..9'
    if args.colored_instances:
        manifest['vertex_inputs'] = 'buffer0 stride48: position4 normal4 uv2; buffer1 stride128 instance-rate: model4x4 normal3x4 color4; locations0..10'
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
