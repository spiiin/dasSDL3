"""Reproduce small Forge assets from the pinned upstream tree (NumPy/Pillow).
No application/shader generation; copied inputs and produced files are hashed.
"""
from pathlib import Path
import argparse,hashlib,json,math,re,shutil,struct
import numpy as np
from PIL import Image,ImageDraw,ImageFont
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--upstream',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1];base=root/'examples/gpu_port_forge';src=a.upstream
outputs=set();inputs={}
def put(name,s):
 path=base/name;path.parent.mkdir(parents=True,exist_ok=True);
 if not path.exists() or path.read_bytes()!=s.encode():path.write_bytes(s.encode())
 outputs.add(path)
def copy(source,name):
 path=base/name;path.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,path);outputs.add(path);inputs[source.relative_to(src).as_posix()]=hashlib.sha256(source.read_bytes()).hexdigest()
names=re.findall(r'"([a-z_]+)"',(src/'lessons/gpu/47-texture-atlas-rendering/main.c').read_text().split('MATERIAL_NAMES[MATERIAL_COUNT] = {')[1].split('};')[0])
canvas=Image.new('RGBA',(6*264,5*264));manifest={'source_commit':'31f44fce9b69cb124b38c1bc90177ef17f1342c8','inputs':{},'outputs':{}}
for i,name in enumerate(names):
 p=src/'assets/materials'/f'{name}.png';im=Image.open(p).convert('RGBA');assert im.size==(256,256);padded=Image.fromarray(np.pad(np.asarray(im),((4,4),(4,4),(0,0)),mode='edge'));canvas.paste(padded,(i%6*264,i//6*264));out=base/'assets'/f'atlas_{name}.png';shutil.copyfile(p,out);manifest['inputs'][str(p.relative_to(src)).replace('\\','/')]=hashlib.sha256(p.read_bytes()).hexdigest();manifest['outputs'][out.name]=hashlib.sha256(out.read_bytes()).hexdigest()
canvas.save(base/'assets/remaining_atlas.png');manifest['outputs']['remaining_atlas.png']=hashlib.sha256((base/'assets/remaining_atlas.png').read_bytes()).hexdigest();(base/'assets/atlas_sources.json').write_text(json.dumps(manifest,indent=2)+'\n')
put('common/atlas_names.das','options gen2\nmodule atlas_names shared public\ndef atlas_names {return <- array('+','.join('"atlas_'+n+'"' for n in names)+')}\n')

fontpath=src/'assets/fonts/liberation_mono/LiberationMono-Regular.ttf'
font=ImageFont.truetype(str(fontpath),16);atlas=Image.new('L',(256,128));draw=ImageDraw.Draw(atlas);glyphs=[]
for index,ch in enumerate(range(32,127)):
 x=1+(index%16)*16;y=1+(index//16)*20;box=font.getbbox(chr(ch),anchor='lt');w=box[2]-box[0];h=box[3]-box[1]
 draw.text((x-box[0],y-box[1]),chr(ch),font=font,fill=255,anchor='lt')
 glyphs.append(f'UiGlyph(uv=float4({x/256},{y/128},{w/256},{h/128}),size=float2({float(w)},{float(h)}),advance={font.getlength(chr(ch))})')
atlas.putpixel((255,127),255)
(base/'assets/extended_font.r8').write_bytes(atlas.tobytes())
(base/'assets/LICENSE-Liberation.txt').write_bytes(fontpath.with_name('License.txt').read_bytes())
def write(n,s):
 p=base/n;p.parent.mkdir(parents=True,exist_ok=True);
 if not p.exists() or p.read_bytes()!=s.encode():p.write_bytes(s.encode())
 outputs.add(p)
write('common/ui_font.das','options gen2\nmodule ui_font shared public\nrequire math public\nstruct UiGlyph { uv : float4; size : float2; advance : float }\ndef ui_glyphs {return <- array(\n'+',\n'.join(glyphs)+'\n)}\n')

# Deterministic UV sphere matching the original 16 stacks/32 slices.
verts=[];indices=[]
for y in range(17):
 a=math.pi*y/16
 for x in range(33):
  b=math.tau*x/32;v=(math.sin(a)*math.cos(b),math.cos(a),math.sin(a)*math.sin(b));verts.extend((*v,*v,x/32,y/16))
for y in range(16):
 for x in range(32):
  a=y*33+x;b=a+33;indices.extend([a,b,a+1,a+1,b,b+1])
(base/'assets/remaining_sphere.fgm').write_bytes(struct.pack('<4sIII',b'FGM1',len(verts)//8,len(indices),32)+struct.pack('<'+'f'*len(verts),*verts)+struct.pack('<'+'I'*len(indices),*indices))

# Torus from lesson 40: 32 ring slices, 16 tube slices, R=1 and r=.35.
v=[];ix=[]
for i in range(33):
 a=i*math.tau/32
 for j in range(17):
  t=j*math.tau/16;n=(math.cos(a)*math.cos(t),math.sin(t),math.sin(a)*math.cos(t));v.extend(((1+.35*math.cos(t))*math.cos(a),.35*math.sin(t),(1+.35*math.cos(t))*math.sin(a),*n,i/32,j/16))
for i in range(32):
 for j in range(16):
  a=i*17+j;c=a+17;ix.extend((a,c,a+1,a+1,c,c+1))
(base/'assets/remaining_torus.fgm').write_bytes(struct.pack('<4sIII',b'FGM1',len(v)//8,len(ix),32)+struct.pack('<'+'f'*len(v),*v)+struct.pack('<'+'I'*len(ix),*ix))

im=np.full((256,256,4),255,dtype=np.uint8)
for f in range(16):
 t=f/15;r=.15+t*.33;yy,xx=np.mgrid[:64,:64];a=(1-t*.7)*np.exp(-(((xx+.5)/64-.5)**2+((yy+.5)/64-.5)**2)/(2*(r*.5)**2));im[f//4*64:(f//4+1)*64,f%4*64:(f%4+1)*64,3]=np.uint8(np.minimum(a,1)*255)
Image.fromarray(im).save(base/'assets/remaining_particles.png')


def wang(v):
 v=np.asarray(v,dtype=np.uint32);v=(v^np.uint32(61))^(v>>16);v=v*np.uint32(9);v=v^(v>>4);v=v*np.uint32(0x27d4eb2d);return v^(v>>15)
def perlin(x,y,seed):
 ix=np.floor(x).astype(np.uint32);iy=np.floor(y).astype(np.uint32);fx=x-ix.astype(np.float32);fy=y-iy.astype(np.float32);u=fx*fx*fx*(fx*(fx*6-15)+10);v=fy*fy*fy*(fy*(fy*6-15)+10)
 def g(a,b,dx,dy):
  h=wang(a^wang(b^wang(seed)));return np.where(h&1,-dx,dx)+np.where(h&2,-dy,dy)
 a=g(ix,iy,fx,fy);b=g(ix+1,iy,fx-1,fy);c=g(ix,iy+1,fx,fy-1);d=g(ix+1,iy+1,fx-1,fy-1);lo=a+u*(b-a);hi=c+u*(d-c);return lo+v*(hi-lo)
yy,xx=np.mgrid[:256,:256].astype(np.float32);height=np.zeros_like(xx);amp=np.float32(1);frequency=np.float32(1);total=np.float32(0)
with np.errstate(over='ignore'):
 for i in range(4):height+=amp*perlin(xx/np.float32(256)*np.float32(8)*frequency,yy/np.float32(256)*np.float32(8)*frequency,np.uint32(42+i));total+=amp;frequency*=np.float32(2);amp*=np.float32(.5)
height=height/total*np.float32(.5)+np.float32(.5);dirt=np.full((256,256,4),255,dtype=np.uint8)
for channel,(lo,span) in enumerate([(.35,.25),(.30,.20),(.15,.10)]):dirt[:,:,channel]=np.uint8((np.float32(lo)+height*np.float32(span))*np.float32(255))
Image.fromarray(dirt).save(base/'assets/remaining_dirt.png')
for face in ['px','nx','py','ny','pz','nz']:
 copy(src/'lessons/gpu/30-planar-reflections/assets/skybox'/(face+'.png'),'assets/extended_orchard_'+face+'.png')
for name,folder in [('water','lessons/gpu/39-pipeline-processed-assets/assets/WaterBottle'),('box','assets/models/BoxTextured')]:
 for path in (src/folder).iterdir():
  if path.suffix in ('.gltf','.bin','.png'):copy(path,'assets/raw_'+name+'/'+path.name)
for name in ['WaterBottle','BoxTextured']:
 for suffix in ['.fmesh','.fmat']:copy(src/'lessons/gpu/39-pipeline-processed-assets/assets/processed'/(name+suffix),'assets/pipeline_'+name+suffix)
 copy(src/'lessons/gpu/39-pipeline-processed-assets/assets/processed'/(name+'_baseColor.png'),'assets/pipeline_'+name+'_baseColor.png')
v=[];ix=[]
for normal in [(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)]:
 n=np.array(normal,float);up=np.array((0,0,1) if abs(n[1])==1 else (0,1,0),float);right=np.cross(up,n);start=len(v)
 for u,t in [(0,0),(1,0),(1,1),(0,1)]:v.append([*(right*(u-.5)+up*(.5-t)+n*.5),*n,u,t])
 ix.extend([start,start+2,start+1,start,start+3,start+2])
path=base/'assets/remaining_atlas_cube.fgm';path.write_bytes(struct.pack('<4I',0x314d4746,len(v),len(ix),32)+np.asarray(v,dtype='<f4').tobytes()+np.asarray(ix,dtype='<u4').tobytes())

for pattern in ['remaining_*','extended_orchard_*','extended_font.r8','LICENSE-Liberation.txt','atlas_*.png']:
 outputs.update((base/'assets').glob(pattern))
inputs.update(manifest['inputs']);inputs[fontpath.relative_to(src).as_posix()]=hashlib.sha256(fontpath.read_bytes()).hexdigest()
result=dict(source_commit='31f44fce9b69cb124b38c1bc90177ef17f1342c8',inputs=inputs,outputs={p.relative_to(base).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(outputs)})
(base/'assets/misc_sources.json').write_text(json.dumps(result,indent=2)+'\n')
print(f'Misc assets: {len(result["outputs"])} outputs')
