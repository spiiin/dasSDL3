"""Prepare pinned forge-gpu meshes and images; runtime/build needs no Python.
Altered asset representation for the dasSDL3 port. See examples/gpu_port_forge/README.md.
"""
import argparse, json, struct, shutil, hashlib
from pathlib import Path
import numpy as np

def main():
 p=argparse.ArgumentParser();p.add_argument('--upstream',required=True,type=Path);a=p.parse_args()
 src=a.upstream.resolve();out=Path(__file__).resolve().parents[1]/'examples/gpu_port_forge/assets';out.mkdir(exist_ok=True)
 # Fail before writing if the supplied checkout is not the pinned asset snapshot.
 expected=json.loads((out/'sources.json').read_text())['inputs']
 for relative,digest in expected.items():
  if hashlib.sha256((src/relative).read_bytes()).hexdigest()!=digest:
   raise RuntimeError(f'Upstream input differs from pinned snapshot: {relative}')
 manifest={}
 def record(path):manifest[path.relative_to(src).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
 def mesh(name,vs,ix):
  data=struct.pack('<4sIII',b'FGM1',len(vs),len(ix),32)+np.asarray(vs,dtype='<f4').tobytes()+np.asarray(ix,dtype='<u4').tobytes()
  (out/(name+'.fgm')).write_bytes(data)
 for name in ['Suzanne','BoxTextured','Duck']:
  base=src/'assets/models'/name;gp=next(base.glob('*.gltf'));g=json.loads(gp.read_text());record(gp)
  bins=[]
  for b in g['buffers']:
   f=base/b['uri'];record(f);bins.append(f.read_bytes())
  def acc(index):
   x=g['accessors'][index];v=g['bufferViews'][x['bufferView']];n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[x['type']];dt={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[x['componentType']]
   return np.ndarray((x['count'],n),dtype=dt,buffer=bins[v['buffer']],offset=v.get('byteOffset',0)+x.get('byteOffset',0),strides=(v.get('byteStride',np.dtype(dt).itemsize*n),np.dtype(dt).itemsize)).copy()
  prim=g['meshes'][0]['primitives'][0];pos=acc(prim['attributes']['POSITION']);norm=acc(prim['attributes']['NORMAL']);uv=acc(prim['attributes']['TEXCOORD_0']);ix=acc(prim['indices']).flatten()
  # Bake the mesh node's parent transform, as forge's glTF loader does.
  def visit(index,parent):
   node=g['nodes'][index];local=np.array(node.get('matrix',np.eye(4).flatten(order='F')),dtype=float).reshape((4,4),order='F');world=parent@local
   if 'mesh' in node:return world
   for c in node.get('children',[]):
    result=visit(c,world)
    if result is not None:return result
  world=None
  for n in g['scenes'][g.get('scene',0)]['nodes']:
   world=visit(n,np.eye(4))
   if world is not None:break
  pos=(np.c_[pos,np.ones(len(pos))]@world.T)[:,:3];norm=norm@np.linalg.inv(world[:3,:3]);norm/=np.linalg.norm(norm,axis=1)[:,None]
  mesh(name,np.c_[pos,norm,uv],ix)
  image=base/g['images'][0]['uri'];record(image);shutil.copy2(image,out/(name+'.png'))
 # Bake every truck node/primitive. Constant glass/trim materials use two
 # extra atlas rows, so this lesson needs one ordinary diffuse binding.
 from PIL import Image
 base=src/'assets/models/CesiumMilkTruck';gp=base/'CesiumMilkTruck.gltf';g=json.loads(gp.read_text());record(gp)
 bins=[]
 for b in g['buffers']:
  f=base/b['uri'];record(f);bins.append(f.read_bytes())
 image=base/g['images'][0]['uri'];record(image);original=Image.open(image).convert('RGBA');w,h=original.size
 atlas=Image.new('RGBA',(w,h+4));atlas.paste(original,(0,0));atlas.paste((0,57,40,255),(0,h,w//2,h+4));atlas.paste((72,72,72,255),(w//2,h,w,h+4));atlas.save(out/'CesiumMilkTruck.png')
 vertices=[];indices=[]
 def truck_node(index,parent):
  node=g['nodes'][index]
  if 'matrix' in node:local=np.array(node['matrix']).reshape((4,4),order='F')
  else:
   x,y,z,q=node.get('rotation',[0,0,0,1]);local=np.eye(4)
   local[:3,:3]=np.array([[1-2*(y*y+z*z),2*(x*y-z*q),2*(x*z+y*q)],[2*(x*y+z*q),1-2*(x*x+z*z),2*(y*z-x*q)],[2*(x*z-y*q),2*(y*z+x*q),1-2*(x*x+y*y)]])@np.diag(node.get('scale',[1,1,1]));local[:3,3]=node.get('translation',[0,0,0])
  world=parent@local
  if 'mesh' in node:
   for prim in g['meshes'][node['mesh']]['primitives']:
    pos=acc(prim['attributes']['POSITION']);n=acc(prim['attributes']['NORMAL']);uv=acc(prim['attributes']['TEXCOORD_0']) if 'TEXCOORD_0' in prim['attributes'] else np.zeros((len(pos),2))
    pos=(np.c_[pos,np.ones(len(pos))]@world.T)[:,:3];n=n@np.linalg.inv(world[:3,:3]);n/=np.linalg.norm(n,axis=1)[:,None]
    mat=g['materials'][prim['material']]['pbrMetallicRoughness']
    if 'baseColorTexture' in mat:uv[:,1]*=h/(h+4)
    else:uv[:]=[0.25 if prim['material']==2 else 0.75,(h+2)/(h+4)]
    ix=acc(prim['indices']).flatten()+len(vertices);vertices.extend(np.c_[pos,n,uv].tolist());indices.extend(ix.tolist())
  for c in node.get('children',[]):truck_node(c,world)
 for n in g['scenes'][g.get('scene',0)]['nodes']:truck_node(n,np.eye(4))
 mesh('CesiumMilkTruck',vertices,indices)
 base=src/'assets/models/space-shuttle';obj=base/'space-shuttle.obj';record(obj)
 ps=[];ns=[];ts=[];vs=[];ix=[];lookup={}
 for line in obj.read_text().splitlines():
  f=line.split()
  if not f:continue
  if f[0]=='v':ps.append([float(x) for x in f[1:4]])
  elif f[0]=='vn':ns.append([float(x) for x in f[1:4]])
  elif f[0]=='vt':ts.append([float(x) for x in f[1:3]])
  elif f[0]=='f':
   face=[]
   for ref in f[1:]:
    if ref not in lookup:
     pp,tt,nn=[int(x) for x in ref.split('/')];lookup[ref]=len(vs);vs.append(ps[pp-1]+ns[nn-1]+[ts[tt-1][0],1-ts[tt-1][1]])
    face.append(lookup[ref])
   for i in range(1,len(face)-1):ix.extend([face[0],face[i],face[i+1]])
 mesh('Shuttle',vs,ix);image=base/'ShuttleDiffuseMap.png';record(image);shutil.copy2(image,out/'Shuttle.png')
 for face in ['px','nx','py','ny','pz','nz']:
  f=src/'assets/skyboxes/milkyway'/(face+'.png');record(f);shutil.copy2(f,out/('sky_'+face+'.png'))
 (out/'sources.json').write_text(json.dumps({'revision':'31f44fce9b69cb124b38c1bc90177ef17f1342c8','inputs':manifest,'outputs':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(out.iterdir()) if f.suffix in ['.fgm','.png']}},indent=2)+'\n',newline='\n')
 shutil.copy2(src/'LICENSE',out.parent/'LICENSE-forge.txt')
 print('Prepared five meshes, five diffuse textures and six cubemap faces.')
if __name__=='__main__':main()
