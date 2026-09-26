"""Rebuild bgfx instancing, bump and HDR shaders offline (DXC + spirv-val)."""
import argparse, hashlib, json, subprocess, tempfile
from pathlib import Path
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--check', action='store_true')
p.add_argument('--dxc', default='dxc')
p.add_argument('--spirv-val', default='spirv-val')
a = p.parse_args()
folder = Path(__file__).resolve().parents[1] / 'examples/gpu/shaders'
manifest = {}
with tempfile.TemporaryDirectory() as tmp:
    for source in sorted(folder.glob('bgfx_*.hlsl')):
        manifest[source.name] = hashlib.sha256(source.read_bytes()).hexdigest()
        if source.name.endswith('_common.hlsl'):
            continue
        stage = source.name.split('.')[-2]
        for fmt in ['spv', 'dxil']:
            out = Path(tmp) / (source.stem + '.' + fmt)
            cmd = [a.dxc, '-T', 'vs_6_0' if stage == 'vert' else 'ps_6_0', '-E', 'main', '-O3', '-Fo', str(out)]
            if fmt == 'spv':
                cmd += ['-spirv', '-fspv-target-env=vulkan1.0']
            subprocess.run(cmd + [str(source)], check=True)
            if fmt == 'spv':
                subprocess.run([a.spirv_val, '--target-env', 'vulkan1.0', str(out)], check=True)
            data = out.read_bytes()
            manifest[out.name] = hashlib.sha256(data).hexdigest()
            if a.check:
                assert (folder / out.name).read_bytes() == data, out.name
            else:
                (folder / out.name).write_bytes(data)
dest = folder / 'bgfx-next-manifest.json'
if a.check:
    assert json.loads(dest.read_text()) == manifest
else:
    dest.write_text(json.dumps(manifest, indent=2) + '\n', newline='\n')
print('bgfx instancing/bump/HDR shaders: PASS')
