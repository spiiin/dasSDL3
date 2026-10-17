"""Convert the pinned bgfx hollow cube and tree; CPU conversion is offline only."""
import argparse,hashlib,json
from pathlib import Path
from build_bgfx_11_14_assets import obj
PINS={'examples/assets/meshes/hollowcube.obj': '20f57ed117f4b4ce3f870e7af7b442cdec87570c3d72095adc6d8b8d99b668e6', 'examples/assets/meshes/tree.obj': '89c456975f91c240e81651b4aa212dc8a2dad4be1cd2ca9919ba7e787f421dde'}
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source-dir',type=Path,required=True);p.add_argument('--check',action='store_true');a=p.parse_args()
dest=Path(__file__).resolve().parents[1]/'examples/gpu_port_bgfx/assets'
manifest={}
for source,digest in PINS.items():
 data=(a.source_dir/source).read_bytes();assert hashlib.sha256(data).hexdigest()==digest
 converted=obj(data);name=Path(source).stem+'.msh'
 manifest[name]={'source':source,'source_sha256':digest,'sha256':hashlib.sha256(converted).hexdigest()}
 if a.check:assert (dest/name).read_bytes()==converted
 else:(dest/name).write_bytes(converted)
path=dest/'shadowmaps-manifest.json'
if a.check:assert json.loads(path.read_text())==manifest
else:path.write_text(json.dumps(manifest,indent=2)+'\n')
print('Shadow-map meshes: PASS')
