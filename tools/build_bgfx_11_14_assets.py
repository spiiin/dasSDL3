"""Convert pinned bgfx LOD OBJ/DDS assets without a bgfx runtime dependency."""
import argparse
import hashlib
import json
import math
import struct
import urllib.request
from pathlib import Path

PIN = "7e3060ccb97959dcda3f091b96d82515197028e0"
ROOT = Path(__file__).resolve().parents[1]

def obj(data):
    positions, normals, uv, vertices, indices, lookup = [], [], [], [], [], {}
    for line in data.decode().splitlines():
        v = line.split()
        if not v: continue
        if v[0] == 'v': positions.append(tuple(map(float, v[1:4])))
        elif v[0] == 'vn': normals.append(tuple(map(float, v[1:4])))
        elif v[0] == 'vt': uv.append(tuple(map(float, v[1:3])))
        elif v[0] == 'f':
            face = []
            for item in v[1:]:
                key = tuple(int(x)-1 if x else -1 for x in item.split('/'))
                assert len(key) == 3 and key[0] >= 0 and key[2] >= 0
                if key not in lookup:
                    lookup[key] = len(vertices)
                    tex = uv[key[1]] if key[1]>=0 else (0.0,0.0)
                    vertices.append(positions[key[0]] + normals[key[2]] + (tex[0], 1.0-tex[1]))
                face.append(lookup[key])
            for i in range(1, len(face)-1): indices.extend((face[0], face[i], face[i+1]))
    assert vertices and indices and all(math.isfinite(x) for v in vertices for x in v)
    return (struct.pack('<4sIII', b'MSH2', len(vertices), len(indices), 32)
            + b''.join(struct.pack('<8f', *v) for v in vertices)
            + struct.pack('<%dI' % len(indices), *indices))

def adjacency(mesh):
    """Weld positions, then require one reversed neighbour per directed edge."""
    magic,nv,ni,stride=struct.unpack_from('<4sIII',mesh)
    assert magic==b'MSH2' and stride==32
    positions=[struct.unpack_from('<3f',mesh,16+i*stride) for i in range(nv)]
    ids=struct.unpack_from('<%dI'%ni,mesh,16+nv*stride)
    edges={}
    for i in range(ni):
        a=positions[ids[i]];b=positions[ids[i//3*3+(i+1)%3]]
        assert a!=b and (a,b) not in edges,'Degenerate or nonmanifold edge'
        edges[a,b]=i
    neighbours=[]
    for i in range(ni):
        a=positions[ids[i]];b=positions[ids[i//3*3+(i+1)%3]]
        assert (b,a) in edges,'Open mesh cannot cast a closed volume'
        neighbours.append(edges[b,a]//3)
    return struct.pack('<4sI',b'SVA1',ni)+struct.pack('<%dI'%ni,*neighbours)

def dds(data):
    assert data[:4] == b'DDS '
    height,width = struct.unpack_from('<II',data,12)
    fourcc=data[84:88];assert fourcc in (b'DXT1',b'DXT3',b'DXT5'),fourcc
    out=bytearray(width*height*4);offset=128
    def rgb(c): return ((c>>11)*255//31,((c>>5)&63)*255//63,(c&31)*255//31)
    for by in range(0,height,4):
        for bx in range(0,width,4):
            alpha=[255]*16
            if fourcc==b'DXT3':
                bits=int.from_bytes(data[offset:offset+8],'little');offset+=8;alpha=[((bits>>(4*i))&15)*17 for i in range(16)]
            if fourcc==b'DXT5':
                a,b=data[offset:offset+2];bits=int.from_bytes(data[offset+2:offset+8],'little');offset+=8
                palette=[a,b]+([(a*(7-i)+b*i)//7 for i in range(1,7)] if a>b else [(a*(5-i)+b*i)//5 for i in range(1,5)]+[0,255])
                alpha=[palette[(bits>>(3*i))&7] for i in range(16)]
            a,b,bits=struct.unpack_from('<HHI',data,offset);offset+=8
            ca,cb=rgb(a),rgb(b);colors=[ca,cb]
            if a>b or fourcc!=b'DXT1':colors += [tuple((2*x+y)//3 for x,y in zip(ca,cb)),tuple((x+2*y)//3 for x,y in zip(ca,cb))]
            else:colors += [tuple((x+y)//2 for x,y in zip(ca,cb)),(0,0,0)]
            for y in range(4):
                for x in range(4):
                    if bx+x>=width or by+y>=height:continue
                    i=y*4+x;k=(bits>>(2*i))&3
                    a8=0 if fourcc==b'DXT1' and a<=b and k==3 else alpha[i]
                    at=((by+y)*width+bx+x)*4;out[at:at+4]=bytes((*colors[k],a8))
    return bytes(out),width,height

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source-dir',type=Path);p.add_argument('--check',action='store_true');args=p.parse_args()
    folder=ROOT/'examples/gpu/assets';folder.mkdir(exist_ok=True)
    manifest={'bgfx_commit':PIN,'files':{}}
    def read(path):
        return (args.source_dir/Path(path).name).read_bytes() if args.source_dir else urllib.request.urlopen(f'https://raw.githubusercontent.com/bkaradzic/bgfx/{PIN}/{path}').read()
    def emit(name,data,source,original,**metadata):
        manifest['files'][name]={'source':source,'source_sha256':hashlib.sha256(original).hexdigest(),'sha256':hashlib.sha256(data).hexdigest(),**metadata}
        if args.check:assert (folder/name).read_bytes()==data,name
        else:(folder/name).write_bytes(data)
    for level in range(3):
        for part in [1,2]:
            name=f'tree1b_lod{level}_{part}';source=f'examples/assets/meshes/{name}.obj';data=read(source)
            emit(name+'.msh',obj(data),source,data)
    for name in ['column','platform','bunny_decimated']:
        source=f'examples/assets/meshes/{name}.obj';data=read(source);mesh=obj(data)
        emit(name+'.msh',mesh,source,data)
        emit(name+'.adj',adjacency(mesh),source,data)
    for name in ['leafs1','bark1','figure-rgba','flare']:
        source=f'examples/runtime/textures/{name}.dds';data=read(source);rgba,w,h=dds(data)
        emit(name+'.rgba8',rgba,source,data,width=w,height=h)
    source='examples/runtime/font/special_elite.ttf';data=read(source);emit('special_elite.ttf',data,source,data)
    if args.check:assert json.loads((folder/'manifest.json').read_text())==manifest
    else:(folder/'manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode())
    print('bgfx 11-14 assets:',len(manifest['files']),'PASS')

if __name__=='__main__':main()
