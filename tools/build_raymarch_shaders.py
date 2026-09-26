"""Rebuild the offline raymarch shaders (DXIL and SPIR-V)."""
import argparse, hashlib, json, subprocess, tempfile
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--dxc',default='dxc');p.add_argument('--spirv-val',default='spirv-val');p.add_argument('--check',action='store_true')
a=p.parse_args();assets=Path(__file__).resolve().parents[1]/'examples/gpu/shaders';manifest={}
with tempfile.TemporaryDirectory() as tmp:
    for stage,profile in [('vert','vs_6_0'),('frag','ps_6_0')]:
        source=assets/f'raymarch.{stage}.hlsl'
        manifest[source.name]=hashlib.sha256(source.read_bytes()).hexdigest()
        for fmt in ['spv','dxil']:
            out=Path(tmp)/f'raymarch.{stage}.{fmt}'
            cmd=[a.dxc,'-T',profile,'-E','main','-O3','-Fo',str(out)]
            if fmt=='spv':cmd+=['-spirv','-fspv-target-env=vulkan1.0']
            subprocess.run(cmd+[str(source)],check=True)
            if fmt=='spv':subprocess.run([a.spirv_val,'--target-env','vulkan1.0',str(out)],check=True)
            data=out.read_bytes();manifest[out.name]=hashlib.sha256(data).hexdigest()
            if a.check:assert (assets/out.name).read_bytes()==data, f'Stale {out.name}'
            else:(assets/out.name).write_bytes(data)
f=assets/'raymarch-manifest.json'
if a.check:assert json.loads(f.read_text())==manifest,'Stale manifest'
else:f.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Raymarch shaders: PASS')
