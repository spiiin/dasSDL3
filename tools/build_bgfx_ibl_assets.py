"""Extract bgfx's prefiltered FP16 IBL cubemaps without regenerating their mips.
Run with --source-dir pointing at a bgfx checkout; --check verifies shipped bytes.
"""
import argparse, hashlib, json, struct
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--source-dir',type=Path,required=True);p.add_argument('--check',action='store_true');a=p.parse_args()
PINS={'examples/runtime/textures/kyoto_lod.dds': '53280151fb969ce6968ca2d8a5f31d6085df8c94ea58bc1f3e7d57b27e404cda', 'examples/runtime/textures/kyoto_irr.dds': 'f7850110ab96c45a4376b64b9271daff72d5c441d74ec9b3518a9a9880ca36dc'}
root=Path(__file__).resolve().parents[1];dest=root/'examples/gpu/textures'
manifest={}
for name in ('kyoto_lod','kyoto_irr'):
 path=Path('examples/runtime/textures')/(name+'.dds');b=(a.source_dir/path).read_bytes()
 assert hashlib.sha256(b).hexdigest()==PINS[path.as_posix()], 'Unexpected upstream asset revision'
 assert b[:4]==b'DDS ' and b[84:88]==b'DX10'
 assert struct.unpack_from('<5I',b,128)==(10,3,4,1,0), 'Expected FP16 cubemap'
 h,w=struct.unpack_from('<II',b,12);levels=struct.unpack_from('<I',b,28)[0]
 payload=b[148:];assert len(payload)==sum(max(1,w>>i)*max(1,h>>i)*8 for i in range(levels))*6
 target=name+'.rgba16f'
 manifest[target]={'source':path.as_posix(),'source_sha256':hashlib.sha256(b).hexdigest(),'sha256':hashlib.sha256(payload).hexdigest(),'width':w,'height':h,'levels':levels,'layout':'face-major, mip-major, RGBA16F, +X -X +Y -Y +Z -Z'}
 if a.check: assert (dest/target).read_bytes()==payload
 else:(dest/target).write_bytes(payload)
mp=dest/'ibl-manifest.json'
if a.check: assert json.loads(mp.read_text())==manifest
else:mp.write_text(json.dumps(manifest,indent=2)+'\n')
print('IBL cubemap mip chains: PASS')
