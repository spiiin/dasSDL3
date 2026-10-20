"""Offline BC7/BC5 FTEX assets for Forge 42/51/52; runtime needs no encoder.
Requires Pillow, NumPy and ispc_texcomp 1.0.1. ISPC replaces the original BasisU
encoder; FTEX wire format and GPU formats are unchanged.
"""
from pathlib import Path
import argparse,hashlib,json,struct,sys
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--upstream',type=Path,required=True);p.add_argument('--materials-only',action='store_true');a=p.parse_args()
 import ispc_texcomp as tex
 src=a.upstream;dst=ROOT/'examples/gpu_port_forge/assets';meta_path=dst/'pbr_sources.json'
 manifest=json.loads(meta_path.read_text()) if meta_path.exists() else dict(inputs={},outputs={},encoder='ispc_texcomp 1.0.1 basic',source_commit='31f44fce9b69cb124b38c1bc90177ef17f1342c8')
 def read(path):
  data=path.read_bytes();manifest['inputs'][path.relative_to(src).as_posix()]=hashlib.sha256(data).hexdigest();return Image.open(path).convert('RGBA')
 def encode(name,image,kind):
  image=image.copy();image.thumbnail((2048,2048),Image.Resampling.LANCZOS)
  fingerprint=hashlib.sha256(image.tobytes()+struct.pack('<3I',*image.size,kind)+b'ispc-basic-v1').hexdigest();path=dst/(name+'.ftex')
  old=manifest['outputs'].get(path.name,{})
  if path.exists() and old.get('input_pixels')==fingerprint and old.get('sha256')==hashlib.sha256(path.read_bytes()).hexdigest():return path.name
  mips=[];sizes=[];current=image
  while True:
   w,h=current.size;pw=max(4,(w+3)//4*4);ph=max(4,(h+3)//4*4)
   pixels=np.asarray(current);padded=np.pad(pixels,((0,ph-h),(0,pw-w),(0,0)),mode='edge')
   surface=tex.RGBASurface(padded.tobytes(),pw,ph)
   blocks=tex.compress_blocks_bc5(surface) if kind==3 else tex.compress_blocks_bc7(surface,tex.BC7EncSettings.from_profile('alpha_basic' if np.any(pixels[:,:,3]!=255) else 'basic'))
   assert len(blocks)==pw//4*(ph//4)*16
   mips.append(blocks);sizes.append((w,h))
   if w==1 and h==1:break
   current=current.resize((max(1,w//2),max(1,h//2)),Image.Resampling.LANCZOS)
   if kind==3:
    n=np.asarray(current,dtype=float)/255.*2-1;n[:,:,:3]/=np.maximum(np.linalg.norm(n[:,:,:3],axis=2,keepdims=True),1e-8);n[:,:,3]=1;current=Image.fromarray(np.uint8(np.clip((n+1)*127.5,0,255)))
  offset=32+len(mips)*16;entries=[]
  for blocks,(w,h) in zip(mips,sizes):entries.append(struct.pack('<4I',offset,len(blocks),w,h));offset+=len(blocks)
  data=struct.pack('<8I',0x58455446,1,kind,*image.size,len(mips),0,0)+b''.join(entries)+b''.join(mips)
  path.write_bytes(data);manifest['outputs'][path.name]=dict(sha256=hashlib.sha256(data).hexdigest(),input_pixels=fingerprint,format=kind,dimensions=image.size,levels=len(mips),payload_bytes=sum(map(len,mips)))
  print(path.name,len(data),flush=True);meta_path.write_text(json.dumps(manifest,indent=2)+'\n');return path.name
 white=Image.new('RGBA',(4,4),(255,255,255,255));black=Image.new('RGBA',(4,4),(0,0,0,255));flat=Image.new('RGBA',(4,4),(128,128,255,255))
 defaults=dict(base=encode('pbr_white_srgb',white,1),normal=encode('pbr_flat_normal',flat,3),mr=encode('pbr_white_linear',white,2),ao='pbr_white_linear.ftex',emissive=encode('pbr_black_srgb',black,1))
 materials=[]
 for i,name in enumerate(['Metal046B','Metal048A','Metal061B','ChristmasTreeOrnament021','Rock026','WoodFloor051']):
  folder=src/'assets/materials'/name;color=read(folder/(name+'_Color.png'));normal=read(folder/(name+'_NormalGL.png'));rough=read(folder/(name+'_Roughness.png')).convert('L')
  metal=read(folder/(name+'_Metalness.png')).convert('L') if (folder/(name+'_Metalness.png')).exists() else Image.new('L',rough.size,0)
  mr=Image.merge('RGBA',(Image.new('L',rough.size,255),rough,metal.resize(rough.size),Image.new('L',rough.size,255)))
  ao=read(folder/(name+'_AmbientOcclusion.png')) if (folder/(name+'_AmbientOcclusion.png')).exists() else white
  m=dict(name=name,base=encode('pbr_'+name+'_base',color,1),normal=encode('pbr_'+name+'_normal',normal,3),mr=encode('pbr_'+name+'_mr',mr,2),ao=encode('pbr_'+name+'_ao',ao,2),emissive=defaults['emissive'],base_factor=[1,1,1,1],emissive_factor=[0,0,0],metallic=1,roughness=1,normal_scale=1,occlusion_strength=1,alpha_cutoff=0)
  if i==0:
   emissive=np.zeros((64,64,4),dtype=np.uint8);emissive[:,:,3]=255
   for y in range(64):
    for x in range(64):
     if x%8==0 or y%8==0:emissive[y,x]=[51,153,255,255]
   m['emissive']=encode('pbr_emissive_grid',Image.fromarray(emissive),1);m['emissive_factor']=[1,1,1]
  materials.append(m)
 (dst/'pbr_material_sets.json').write_text(json.dumps(dict(materials=materials,part_materials=[]),indent=2)+'\n')
 if not a.materials_only:
  path=dst/'extended_chess.materials.json';data=json.loads(path.read_text());cache={}
  for m in data['materials']:
   for role in ['base','normal','mr','ao','emissive']:
    name=m[role]
    if not name:m[role]=defaults[role];continue
    kind=3 if role=='normal' else (1 if role in ('base','emissive') else 2)
    key=name,kind
    if key not in cache:cache[key]=encode(name+('_bc5' if kind==3 else '_bc7s' if kind==1 else '_bc7l'),Image.open(dst/(name+'.png')).convert('RGBA'),kind)
    m[role]=cache[key]
  (dst/'pbr_chess_materials.json').write_text(json.dumps(data,indent=2)+'\n')
 manifest['outputs']['pbr_material_sets.json']=dict(sha256=hashlib.sha256((dst/'pbr_material_sets.json').read_bytes()).hexdigest())
 if (dst/'pbr_chess_materials.json').exists():manifest['outputs']['pbr_chess_materials.json']=dict(sha256=hashlib.sha256((dst/'pbr_chess_materials.json').read_bytes()).hexdigest())
 meta_path.write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__':main()
