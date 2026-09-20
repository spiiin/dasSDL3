"""Offline-only fixtures for tests/gpu_raw.das; consumers do not need DXC."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--dxc', default='dxc')
parser.add_argument('--spirv-val', default='spirv-val')
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
assets = root / 'tests/assets/raw_gpu'
files = {}
with tempfile.TemporaryDirectory(prefix='raw-gpu-shaders-') as temp:
    for stage, profile in [('vert', 'vs_6_0'), ('frag', 'ps_6_0'), ('comp', 'cs_6_0')]:
        source = assets / f'raw.{stage}.hlsl'
        files[source.name] = hashlib.sha256(source.read_bytes()).hexdigest()
        for fmt in ['spv', 'dxil']:
            name = f'raw.{stage}.{fmt}'
            output = Path(temp) / name
            command = [args.dxc, '-T', profile, '-E', 'main', '-O3', '-Fo', str(output)]
            if fmt == 'spv':
                command += ['-spirv', '-fspv-target-env=vulkan1.0']
            subprocess.check_call(command + [str(source)])
            if fmt == 'spv':
                subprocess.check_call([args.spirv_val, '--target-env', 'vulkan1.0', str(output)])
            data = output.read_bytes()
            files[name] = hashlib.sha256(data).hexdigest()
            if args.check:
                if data != (assets / name).read_bytes():
                    raise SystemExit(f'Stale shader: {name}')
            else:
                (assets / name).write_bytes(data)
    manifest = json.dumps(files, indent=2) + '\n'
    if args.check:
        if json.loads((assets / 'manifest.json').read_text()) != files:
            raise SystemExit('Stale manifest')
    else:
        (assets / 'manifest.json').write_text(manifest, newline='\n')
print('Raw GPU shader compilation and SPIR-V validation PASS')
