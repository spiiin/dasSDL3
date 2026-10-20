"""Offline glTF extraction for Forge GPU lessons 21-52. No runtime dependency on Python.
Preserves primitive materials, node transforms, texture roles and input/output hashes.
"""
from pathlib import Path
import argparse,base64,hashlib,io,json,struct
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--upstream',required=True,type=Path);a=p.parse_args()
 src=a.upstream.resolve();dst=ROOT/'examples/gpu_port_forge/assets';dst.mkdir(exist_ok=True)
 inputs={};outputs={};functions=[]
 def read(path):
  data=path.read_bytes();inputs[path.relative_to(src).as_posix()]=hashlib.sha256(data).hexdigest();return data
 def output(name,data):
  (dst/name).write_bytes(data);outputs[name]=hashlib.sha256(data).hexdigest()
 def number(n):
  v=format(float(n),'.9g');return v if '.' in v or 'e' in v else v+'.0'
 def vector(v):return f'float{len(v)}('+','.join(map(number,v))+')'
 def matrix(m):return 'float4x4('+','.join(vector(m[:,i]) for i in range(4))+')'
 def export(name,relative):
  path=src/relative;data=read(path);g=json.loads(data);base=path.parent
  buffers=[read(base/b['uri']) if not b['uri'].startswith('data:') else base64.b64decode(b['uri'].split(',')[1]) for b in g['buffers']]
  def acc(i):
   a=g['accessors'][i];v=g['bufferViews'][a['bufferView']];n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
   dt=np.dtype({5126:'<f4',5125:'<u4',5123:'<u2',5122:'<i2',5121:'u1',5120:'i1'}[a['componentType']])
   result=np.ndarray((a['count'],n),dtype=dt,buffer=buffers[v['buffer']],offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',dt.itemsize*n),dt.itemsize)).copy()
   if a.get('normalized'):result=result.astype(float)/np.iinfo(dt).max
   return result
  image_cache={}
  def tex(index,role):
   if index is None:return ''
   i=g['textures'][index['index']]['source']
   if i in image_cache:return image_cache[i]
   image=g['images'][i]
   if 'uri' in image:data=read(base/image['uri'])
   else:
    v=g['bufferViews'][image['bufferView']];data=buffers[v['buffer']][v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
   image=Image.open(io.BytesIO(data)).convert('RGBA');out=io.BytesIO();image.save(out,format='PNG')
   filename=f'extended_{name}_{i}';output(filename+'.png',out.getvalue());image_cache[i]=filename;return filename
  meshes={}
  for mi,mesh in enumerate(g['meshes']):
   for pi,prim in enumerate(mesh['primitives']):
    assert prim.get('mode',4)==4
    att=prim['attributes'];pos=acc(att['POSITION']);normal=acc(att['NORMAL']) if 'NORMAL' in att else np.zeros_like(pos)
    uv=acc(att['TEXCOORD_0']) if 'TEXCOORD_0' in att else np.zeros((len(pos),2))
    ix=acc(prim['indices']).reshape(-1) if 'indices' in prim else np.arange(len(pos),dtype=np.uint32)
    vertices=np.c_[pos,normal,uv]
    if name in ('shaderball','chess'):
     tri=ix.reshape(-1,3);e1=pos[tri[:,1]]-pos[tri[:,0]];e2=pos[tri[:,2]]-pos[tri[:,0]];u1=uv[tri[:,1]]-uv[tri[:,0]];u2=uv[tri[:,2]]-uv[tri[:,0]]
     determinant=u1[:,0]*u2[:,1]-u2[:,0]*u1[:,1];inv=np.where(abs(determinant)>1e-10,1./np.where(abs(determinant)>1e-10,determinant,1.),0.)
     tangent=(e1*u2[:,1,None]-e2*u1[:,1,None])*inv[:,None];bitangent=(e2*u1[:,0,None]-e1*u2[:,0,None])*inv[:,None]
     ts=np.zeros_like(pos);bs=np.zeros_like(pos)
     for c in range(3):np.add.at(ts,tri[:,c],tangent);np.add.at(bs,tri[:,c],bitangent)
     ts-=normal*np.sum(ts*normal,axis=1,keepdims=True);length=np.linalg.norm(ts,axis=1)
     missing=length<1e-8;fallback=np.cross(normal,np.where((abs(normal[:,1])<.9)[:,None],[0,1,0],[1,0,0]));ts[missing]=fallback[missing]
     ts/=np.maximum(np.linalg.norm(ts,axis=1,keepdims=True),1e-8);hand=np.where(np.sum(np.cross(normal,ts)*bs,axis=1)<0,-1,1)
     vertices=np.c_[vertices,ts,hand]
    filename=f'extended_{name}_{mi}_{pi}'
    output(filename+'.fgm',struct.pack('<4sIII',b'FGM1',len(pos),len(ix),vertices.shape[1]*4)+vertices.astype('<f4').tobytes()+ix.astype('<u4').tobytes())
    mat=g.get('materials',[{}])[prim.get('material',0)];pbr=mat.get('pbrMetallicRoughness',{})
    meshes[mi,pi]=(filename,mat,pbr,pos)
  parts=[];part_nodes=[];part_skins=[];part_weights=[];part_morphs=[]
  def visit(index,parent):
   node=g['nodes'][index]
   if 'matrix' in node:m=np.array(node['matrix']).reshape(4,4,order='F')
   else:
    x,y,z,w=node.get('rotation',[0,0,0,1]);m=np.eye(4)
    m[:3,:3]=np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])@np.diag(node.get('scale',[1,1,1]));m[:3,3]=node.get('translation',[0,0,0])
   world=parent@m
   if 'mesh' in node:
    for pi,_ in enumerate(g['meshes'][node['mesh']]['primitives']):
     filename,mat,pbr,pos=meshes[node['mesh'],pi];wp=np.c_[pos,np.ones(len(pos))]@world.T
     prim=g['meshes'][node['mesh']]['primitives'][pi];att=prim['attributes'];weight_file='';morph_file=''
     if 'JOINTS_0' in att:
      joints=acc(att['JOINTS_0']).astype('<u4');weights=acc(att['WEIGHTS_0']).astype('<f4')
      weights/=np.maximum(weights.sum(axis=1,keepdims=True),1e-12)
      packed=np.empty(len(pos),dtype=[('joints','<u4',(4,)),('weights','<f4',(4,))]);packed['joints']=joints;packed['weights']=weights
      weight_file=filename+'.weights';output(weight_file,packed.tobytes())
     if prim.get('targets'):
      deltas=[]
      for target in prim['targets']:
       dp=acc(target['POSITION']) if 'POSITION' in target else np.zeros_like(pos);dn=acc(target['NORMAL']) if 'NORMAL' in target else np.zeros_like(pos)
       deltas.append(np.c_[dp,np.zeros(len(pos)),dn,np.zeros(len(pos))].astype('<f4'))
      morph_file=filename+'.morph';output(morph_file,b''.join(d.tobytes() for d in deltas))
     part_nodes.append(index);part_skins.append(node.get('skin',-1));part_weights.append(weight_file);part_morphs.append(dict(file=morph_file,count=len(prim.get('targets',[])),vertices=len(pos)))
     parts.append('PartSpec(mesh="'+filename+'",diffuse="'+tex(pbr.get('baseColorTexture'),'color')+'",normal="'+tex(mat.get('normalTexture'),'normal')+'",model='+matrix(world)+',base='+vector(pbr.get('baseColorFactor',[1,1,1,1]))+',mode='+str({'OPAQUE':0,'MASK':1,'BLEND':2}[mat.get('alphaMode','OPAQUE')])+',cutoff='+number(mat.get('alphaCutoff',.5))+',minimum='+vector(wp[:,:3].min(axis=0))+',maximum='+vector(wp[:,:3].max(axis=0))+')')
   for child in node.get('children',[]):visit(child,world)
  for index in g['scenes'][g.get('scene',0)]['nodes']:visit(index,np.eye(4))
  parents=[-1]*len(g['nodes'])
  for i,node in enumerate(g['nodes']):
   for child in node.get('children',[]):parents[child]=i
  order=[]
  def ordered(i):
   order.append(i)
   for child in g['nodes'][i].get('children',[]):ordered(child)
  for i,parent in enumerate(parents):
   if parent<0:ordered(i)
  nodes=[]
  for i,node in enumerate(g['nodes']):
   nodes.append(dict(parent=parents[i],translation=node.get('translation',[0,0,0]),rotation=node.get('rotation',[0,0,0,1]),scale=node.get('scale',[1,1,1]),use_matrix='matrix' in node,matrix=[node.get('matrix',np.eye(4).flatten(order='F').tolist())[j:j+4] for j in range(0,16,4)],weights=node.get('weights',g.get('meshes',[{}])[node.get('mesh',0)].get('weights',[]) if g.get('meshes') else [])))
  clips=[]
  for clip in g.get('animations',[]):
   channels=[];duration=0.
   for channel in clip['channels']:
    sampler=clip['samplers'][channel['sampler']];times=acc(sampler['input']).reshape(-1);values=acc(sampler['output']);duration=max(duration,float(times[-1]))
    factor=3 if sampler.get('interpolation')=='CUBICSPLINE' else 1
    channels.append(dict(node=channel['target']['node'],path={'translation':0,'rotation':1,'scale':2,'weights':3}[channel['target']['path']],interpolation={'LINEAR':0,'STEP':1,'CUBICSPLINE':2}[sampler.get('interpolation','LINEAR')],components=int(values.size//len(times)//factor),times=times.tolist(),values=values.reshape(-1).tolist()))
   clips.append(dict(duration=duration,channels=channels))
  skins=[]
  for skin in g.get('skins',[]):
   matrices=acc(skin['inverseBindMatrices']) if 'inverseBindMatrices' in skin else np.tile(np.eye(4).flatten(order='F'),(len(skin['joints']),1))
   skins.append(dict(joints=skin['joints'],inverse_bind=[dict(columns=[m[j:j+4].tolist() for j in range(0,16,4)]) for m in matrices]))
  output('extended_'+name+'.animation.json',(json.dumps(dict(nodes=nodes,order=order,clips=clips,skins=skins,part_nodes=part_nodes,part_skins=part_skins,part_weights=part_weights,part_morphs=part_morphs),separators=(',',':'))+'\n').encode())
  material_specs=[]
  for mat in g.get('materials',[{}]):
   pbr=mat.get('pbrMetallicRoughness',{})
   material_specs.append(dict(base=tex(pbr.get('baseColorTexture'),'color'),normal=tex(mat.get('normalTexture'),'normal'),mr=tex(pbr.get('metallicRoughnessTexture'),'linear'),ao=tex(mat.get('occlusionTexture'),'linear'),emissive=tex(mat.get('emissiveTexture'),'color'),base_factor=pbr.get('baseColorFactor',[1,1,1,1]),emissive_factor=mat.get('emissiveFactor',[0,0,0]),metallic=pbr.get('metallicFactor',1.),roughness=pbr.get('roughnessFactor',1.),normal_scale=mat.get('normalTexture',{}).get('scale',1.),occlusion_strength=mat.get('occlusionTexture',{}).get('strength',1.),alpha_cutoff=mat.get('alphaCutoff',.5) if mat.get('alphaMode')=='MASK' else 0.))
  material_indices=[]
  def visit_material(i):
   node=g['nodes'][i]
   if 'mesh' in node:
    for prim in g['meshes'][node['mesh']]['primitives']:material_indices.append(prim.get('material',0))
   for c in node.get('children',[]):visit_material(c)
  for i in g['scenes'][g.get('scene',0)]['nodes']:visit_material(i)
  output('extended_'+name+'.materials.json',(json.dumps(dict(materials=material_specs,part_materials=material_indices),separators=(',',':'))+'\n').encode())
  functions.append('def '+name+'_parts {\n return <- array(\n  '+',\n  '.join(parts)+'\n )\n}\n')
 for name,path in [
  ('searchlight','lessons/gpu/24-gobo-spotlight/assets/models/Searchlight/scene.gltf'),
  ('boat','lessons/gpu/30-planar-reflections/assets/boat/scene.gltf'),
  ('rocks','lessons/gpu/30-planar-reflections/assets/rocks/scene.gltf'),
  ('track','lessons/gpu/31-transform-animations/assets/track/scene.gltf'),
  ('animated_truck','lessons/gpu/31-transform-animations/assets/CesiumMilkTruck/CesiumMilkTruck.gltf'),
  ('cesiumman','assets/models/CesiumMan/CesiumMan.gltf'),
  ('brainstem','assets/models/BrainStem/BrainStem.gltf'),
  ('animated_cube','assets/models/AnimatedCube/AnimatedCube.gltf'),
  ('animated_box','assets/models/BoxTextured/BoxTextured.gltf'),
  ('morph_cube','assets/models/AnimatedMorphCube/AnimatedMorphCube.gltf'),
  ('simple_morph','assets/models/SimpleMorph/SimpleMorph.gltf'),
  ('shaderball','assets/models/Shaderball/scene.gltf'),
  ('model_suzanne','assets/models/Suzanne/Suzanne.gltf'),
  ('model_duck','assets/models/Duck/Duck.gltf'),
  ('chess','assets/models/ABeautifulGame/ABeautifulGame.gltf')]:export(name,path)
 output('extended_gobo.png',read(src/'lessons/gpu/24-gobo-spotlight/assets/gobo_window.png'))
 generated='options gen2\nmodule extended_assets shared public\n// Generated offline; source/output hashes: assets/extended_sources.json\nrequire advanced_assets public\nrequire daslib/shader_lingua_franca\n'+'\n'.join(functions)
 (ROOT/'examples/gpu_port_forge/common/extended_assets.das').write_bytes(generated.encode())
 outputs['../common/extended_assets.das']=hashlib.sha256(generated.encode()).hexdigest()
 (dst/'extended_sources.json').write_text(json.dumps(dict(repository='https://github.com/Nebulavenus/forge-gpu',commit='31f44fce9b69cb124b38c1bc90177ef17f1342c8',inputs=inputs,outputs=outputs),indent=2)+'\n')
 print(f'Prepared {len(outputs)} outputs from {len(inputs)} pinned inputs.')
if __name__=='__main__':main()
