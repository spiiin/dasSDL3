"""Prepare lesson 15-20 glTF primitives without merging materials or losing tangents.
Offline only; runtime uses checked-in FGM1 files and generated daScript descriptions.
"""
import argparse, hashlib, json, shutil, struct
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--upstream', type=Path, required=True)
    src = parser.parse_args().upstream.resolve()
    out = ROOT/'examples/gpu_port_forge/assets'
    expected=json.loads((out/'advanced_sources.json').read_text())['inputs']
    for relative,digest in expected.items():
        if hashlib.sha256((src/relative).read_bytes()).hexdigest()!=digest:
            raise RuntimeError('Upstream input differs from pinned snapshot: '+relative)
    inputs, outputs, entries = {}, {}, {}
    def record(p):
        inputs[p.relative_to(src).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
    def number(x):
        s = format(float(x), '.9g')
        return s if '.' in s or 'e' in s else s+'.0'
    def vec(xs): return 'float'+str(len(xs))+'('+','.join(map(number,xs))+')'
    def matrix(m): return 'float4x4('+','.join(vec(m[:,i]) for i in range(4))+')'
    def export(name, path, lift=0., tangents=False):
        record(path); g=json.loads(path.read_text()); base=path.parent
        buffers=[]
        for b in g['buffers']:
            p=base/b['uri']; record(p); buffers.append(p.read_bytes())
        def acc(i):
            a=g['accessors'][i]; v=g['bufferViews'][a['bufferView']]
            n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
            dt=np.dtype({5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']])
            return np.ndarray((a['count'],n),dtype=dt,buffer=buffers[v['buffer']],offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',dt.itemsize*n),dt.itemsize)).copy()
        def image(tex):
            if tex is None: return ''
            p=base/g['images'][g['textures'][tex['index']]['source']]['uri'];record(p)
            dest='advanced_'+name+'_'+p.name;shutil.copyfile(p,out/dest);return dest[:-4]
        items=[]; meshes={}
        for mi,mesh in enumerate(g['meshes']):
            for pi,p in enumerate(mesh['primitives']):
                a=p['attributes'];pos=acc(a['POSITION']);norm=acc(a['NORMAL']);uv=acc(a['TEXCOORD_0']) if 'TEXCOORD_0' in a else np.zeros((len(pos),2))
                ix=acc(p['indices']).reshape(-1) if 'indices' in p else np.arange(len(pos),dtype=np.uint32)
                vertices=np.c_[pos,norm,uv]
                if tangents:
                    if 'TANGENT' in a: tangent=acc(a['TANGENT'])
                    else:
                        t=np.zeros_like(pos); b=np.zeros_like(pos)
                        for tri in ix.reshape(-1,3):
                            e1,e2=pos[tri[1]]-pos[tri[0]],pos[tri[2]]-pos[tri[0]]
                            u1,u2=uv[tri[1]]-uv[tri[0]],uv[tri[2]]-uv[tri[0]];d=u1[0]*u2[1]-u2[0]*u1[1]
                            if abs(d)<1e-8:continue
                            t[tri]+=(e1*u2[1]-e2*u1[1])/d;b[tri]+=(e2*u1[0]-e1*u2[0])/d
                        t-=norm*np.sum(norm*t,axis=1)[:,None];length=np.linalg.norm(t,axis=1);t[length<1e-12]=[1,0,0];t/=np.maximum(np.linalg.norm(t,axis=1),1e-12)[:,None]
                        tangent=np.c_[t,np.where(np.sum(np.cross(norm,t)*b,axis=1)<0,-1,1)]
                    vertices=np.c_[vertices,tangent]
                filename=f'advanced_{name}_{mi}_{pi}'
                data=struct.pack('<4sIII',b'FGM1',len(vertices),len(ix),vertices.shape[1]*4)+vertices.astype('<f4').tobytes()+ix.astype('<u4').tobytes()
                (out/(filename+'.fgm')).write_bytes(data)
                mat=g.get('materials',[{}])[p.get('material',0)];pbr=mat.get('pbrMetallicRoughness',{})
                mat=dict(mat);pbr=dict(pbr)
                if 'KHR_materials_transmission' in mat.get('extensions',{}) and mat.get('alphaMode','OPAQUE')=='OPAQUE':
                    mat['alphaMode']='BLEND'
                    color=list(pbr.get('baseColorFactor',[1,1,1,1]));color[3]=.5;pbr['baseColorFactor']=color
                meshes[mi,pi]=(filename,pbr,mat,pos)
        def visit(i,parent):
            node=g['nodes'][i]
            if 'matrix' in node: local=np.array(node['matrix']).reshape((4,4),order='F')
            else:
                x,y,z,w=node.get('rotation',[0,0,0,1]);local=np.eye(4)
                local[:3,:3]=np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])@np.diag(node.get('scale',[1,1,1]));local[:3,3]=node.get('translation',[0,0,0])
            world=parent@local
            if 'mesh' in node:
                for pi,_ in enumerate(g['meshes'][node['mesh']]['primitives']):
                    filename,pbr,mat,pos=meshes[node['mesh'],pi]; lifted=world.copy();lifted[1,3]+=lift
                    wp=(np.c_[pos,np.ones(len(pos))]@lifted.T)[:,:3]
                    items.append('PartSpec(mesh="'+filename+'",diffuse="'+image(pbr.get('baseColorTexture'))+'",normal="'+image(mat.get('normalTexture'))+'",model='+matrix(lifted)+',base='+vec(pbr.get('baseColorFactor',[1,1,1,1]))+',mode='+str({'OPAQUE':0,'MASK':1,'BLEND':2}[mat.get('alphaMode','OPAQUE')])+',cutoff='+number(mat.get('alphaCutoff',.5))+',minimum='+vec(wp.min(axis=0))+',maximum='+vec(wp.max(axis=0))+')')
            for c in node.get('children',[]):visit(c,world)
        for i in g['scenes'][g.get('scene',0)]['nodes']:visit(i,np.eye(4))
        entries[name]=items
    export('blending',src/'lessons/gpu/16-blending/assets/TransmissionOrderTest.gltf',.9)
    export('normal',src/'lessons/gpu/17-normal-maps/assets/NormalTangentMirrorTest.gltf',1.2,True)
    export('truck',src/'assets/models/CesiumMilkTruck/CesiumMilkTruck.gltf')
    export('box',src/'assets/models/BoxTextured/BoxTextured.gltf')
    export('suzanne',src/'assets/models/Suzanne/Suzanne.gltf')
    from PIL import Image
    Image.new('RGBA',(1,1),(255,255,255,255)).save(out/'advanced_white.png')
    Image.new('RGBA',(1,1),(128,128,255,255)).save(out/'advanced_flat.png')
    vertices=np.array([[-50,0,-50,0,1,0,0,0],[50,0,-50,0,1,0,1,0],[-50,0,50,0,1,0,0,1],[50,0,50,0,1,0,1,1]],dtype='<f4')
    (out/'advanced_plane.fgm').write_bytes(struct.pack('<4sIII',b'FGM1',4,6,32)+vertices.tobytes()+np.array([0,2,1,1,2,3],dtype='<u4').tobytes())
    lines=['options gen2','module advanced_assets shared public','require math public','require daslib/shader_lingua_franca','struct PartSpec { mesh,diffuse,normal : string; model : float4x4; base : float4; mode : int; cutoff : float; minimum,maximum : float3 }']
    for name,items in entries.items():lines+=['def '+name+'_parts {','    return <- array(\n        '+',\n        '.join(items)+'\n    )','}']
    (out.parent/'common/advanced_assets.das').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
    for p in sorted(out.glob('advanced_*')):
        if p.suffix not in ['.png','.fgm']:continue
        outputs[p.name]=hashlib.sha256(p.read_bytes()).hexdigest()
    (out/'advanced_sources.json').write_text(json.dumps({'revision':'31f44fce9b69cb124b38c1bc90177ef17f1342c8','inputs':inputs,'outputs':outputs},indent=2)+'\n',newline='\n')
    print('Prepared',sum(map(len,entries.values())),'primitive instances;',len(outputs),'assets')
if __name__=='__main__':main()
