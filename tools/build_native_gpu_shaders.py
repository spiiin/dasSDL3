"""Offline native compute/MRT example assets; no consumer compiler dependency."""
import argparse,hashlib,json,subprocess,tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--dxc',default='dxc');p.add_argument('--spirv-val',default='spirv-val');p.add_argument('--check',action='store_true')
a=p.parse_args();assets=root/'examples/assets/shaders';hashes={}
with tempfile.TemporaryDirectory() as tmp:
    for name,profile in [('native.comp','cs_6_0'),('attachments.vert','vs_6_0'),('attachments.frag','ps_6_0')]:
        src=assets/(name+'.hlsl');hashes[src.name]=hashlib.sha256(src.read_bytes()).hexdigest()
        for fmt in ['spv','dxil']:
            out=Path(tmp)/(name+'.'+fmt)
            cmd=[a.dxc,'-T',profile,'-E','main','-O3','-Fo',str(out)]
            if fmt=='spv':cmd+=['-spirv','-fspv-target-env=vulkan1.0']
            subprocess.check_call(cmd+[str(src)])
            if fmt=='spv':subprocess.check_call([a.spirv_val,'--target-env','vulkan1.0',str(out)])
            data=out.read_bytes();hashes[out.name]=hashlib.sha256(data).hexdigest()
            if a.check:
                if (assets/out.name).read_bytes()!=data:raise SystemExit('Stale '+out.name)
            else:(assets/out.name).write_bytes(data)
manifest=assets/'native-manifest.json'
if a.check:
    if json.loads(manifest.read_text())!=hashes:raise SystemExit('Stale manifest')
else:manifest.write_text(json.dumps(hashes,indent=2)+'\n',newline='\n')
print('Native GPU shaders: compilation and SPIR-V validation PASS')
