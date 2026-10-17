"""Offline conversion of pinned bgfx 40-45 assets; no bgfx runtime dependency.
For bunnylod, pass a shared library built from the unmodified 42-bunnylod/progmesh.c
exporting ProgressiveMesh (MIT, Stan Melax / Cloud Wu). Its collapse map is cached
just as in the upstream example; runtime LOD index updates remain CPU operations.
"""
import argparse, ctypes, hashlib, json, struct
from pathlib import Path
from build_bgfx_11_14_assets import obj, PIN

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--bgfx',type=Path,required=True)
    ap.add_argument('--progressive-library',type=Path)
    ap.add_argument('--check',action='store_true')
    args=ap.parse_args()
    target=Path(__file__).resolve().parents[1]/'examples/gpu_port_bgfx/assets'
    manifest={'bgfx_commit':PIN,'files':{}}
    def emit(name,data,source):
        original=(args.bgfx/source).read_bytes()
        manifest['files'][name]={'source':source,'source_sha256':hashlib.sha256(original).hexdigest(),'sha256':hashlib.sha256(data).hexdigest()}
        if args.check: assert (target/name).read_bytes()==data,name
        else: (target/name).write_bytes(data)
    for mesh in ('bunny',):
        source=f'examples/assets/meshes/{mesh}.obj'
        emit(f'post-{mesh}.msh',obj((args.bgfx/source).read_bytes()),source)
    source='examples/runtime/meshes/unit_sphere.bin'
    sphere=(args.bgfx/source).read_bytes()
    assert sphere[:4]==b'VB \x01'
    count,stride=struct.unpack_from('<BH',sphere,108)
    assert count==2 and stride==24
    at=111+count*9
    nv=struct.unpack_from('<H',sphere,at)[0];at+=2
    vertices=[struct.unpack_from('<6f',sphere,at+i*24)+(0.,0.) for i in range(nv)]
    at+=nv*24;assert sphere[at:at+4]==b'IB \x00';at+=4
    ni=struct.unpack_from('<I',sphere,at)[0];at+=4
    ids=struct.unpack_from(f'<{ni}H',sphere,at)
    emit('post-unit_sphere.msh',struct.pack('<4sIII',b'MSH2',nv,ni,32)+b''.join(struct.pack('<8f',*v) for v in vertices)+struct.pack(f'<{ni}I',*ids),source)
    source='examples/assets/meshes/bunny_patched.obj'
    data=obj((args.bgfx/source).read_bytes())
    _,nv,ni,stride=struct.unpack_from('<4sIII',data)
    lookup={};vertices=[];weld=[]
    for i in range(nv):
        v=data[16+i*stride:16+(i+1)*stride]
        if v not in lookup: lookup[v]=len(vertices);vertices.append(v)
        weld.append(lookup[v])
    ids=[weld[i] for i in struct.unpack_from(f'<{ni}I',data,16+nv*stride)]
    n=len(vertices)
    cache=target/'bunnylod-collapse.bin'
    if args.progressive_library:
        lib=ctypes.CDLL(str(args.progressive_library.resolve()))
        floats=(ctypes.c_float*(n*8)).from_buffer_copy(b''.join(vertices))
        triangles=(ctypes.c_int*ni)(*ids); mapping=(ctypes.c_int*n)();permutation=(ctypes.c_int*n)()
        lib.ProgressiveMesh(n,32,floats,ni//3,triangles,mapping,permutation)
        assert sorted(permutation)==list(range(n))
        assert all(0<=mapping[i]<i for i in range(1,n))
        cache_data=struct.pack('<I',n)+struct.pack(f'<{n}I',*mapping)+struct.pack(f'<{n}I',*permutation)
    else:
        cache_data=cache.read_bytes()
        assert struct.unpack_from('<I',cache_data)[0]==n
        mapping=struct.unpack_from(f'<{n}I',cache_data,4)
        permutation=struct.unpack_from(f'<{n}I',cache_data,4+4*n)
    reordered=[None]*n
    for i,v in enumerate(vertices): reordered[permutation[i]]=v
    mesh=struct.pack('<4sIII',b'MSH2',n,ni,32)+b''.join(reordered)+struct.pack(f'<{ni}I',*(permutation[i] for i in ids))
    emit('bunnylod.msh',mesh,source)
    emit('bunnylod-collapse.bin',cache_data,source)
    # Original image data are decoded offline, without changing resolution.
    from PIL import Image
    for src,name in [('8k_mars.jpg','svt-mars'),('dmap.png','tess-height')]:
        source=f'examples/runtime/textures/{src}'
        im=Image.open(args.bgfx/source)
        if src.endswith('.jpg'):
            # Keep the original compressed image; the VT tile builder decodes offline.
            # Independently decodable lossless PNG pages, indexed in bounded 32 MiB chunks.
            # The renderer seeks only requested pages instead of loading the 8K image.
            import io
            image=im.convert('RGB'); records=[]; chunk=bytearray(); part=0
            for mip in range(7):
                width=64>>mip
                import numpy as np
                padded=np.pad(np.asarray(image),((1,1),(1,1),(0,0)),mode='edge')
                for y in range(width):
                    for x in range(width):
                        tile=Image.fromarray(padded[y*128:y*128+130,x*128:x*128+130])
                        out=io.BytesIO(); tile.save(out,format='PNG'); payload=out.getvalue()
                        if len(chunk)+len(payload)>32*1024*1024:
                            emit(f'svt-pages-{part}.bin',bytes(chunk),source); chunk.clear();part+=1
                        records.append((part,len(chunk),len(payload)));chunk.extend(payload)
                if mip<6: image=image.resize((image.width//2,image.height//2),Image.Resampling.BOX)
            emit(f'svt-pages-{part}.bin',bytes(chunk),source)
            emit('svt-pages.idx',struct.pack('<I',len(records))+b''.join(struct.pack('<III',*record) for record in records),source)
        else:
            import numpy as np
            values=np.asarray(im,dtype='<u2')
            emit(name+'.raw',values.tobytes(),source)
    path=target/'ports40-45-manifest.json'
    encoded=json.dumps(manifest,indent=2)+'\n'
    if args.check: assert json.loads(path.read_text())==manifest
    else: path.write_bytes(encoded.encode())
    print('bgfx 40-45 assets verified' if args.check else 'bgfx 40-45 assets generated')
if __name__=='__main__': main()
