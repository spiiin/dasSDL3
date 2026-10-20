from pathlib import Path
import numpy as np, math, struct, json, hashlib
from PIL import Image
R=Path(__file__).resolve().parents[1];B=R/'examples/gpu_port_forge'
def write_mesh(name,vertices,indices):
 data=struct.pack('<4I',0x314d4746,len(vertices),len(indices),32)+np.asarray(vertices,dtype='<f4').tobytes()+np.asarray(indices,dtype='<u4').tobytes();(B/'assets'/f'{name}.fgm').write_bytes(data)
def wang(v):
 v=np.asarray(v,dtype=np.uint32);v=(v^np.uint32(61))^(v>>16);v=v*np.uint32(9);v=v^(v>>4);v=v*np.uint32(0x27d4eb2d);return v^(v>>15)
def perlin(x,y,seed):
 ix=np.floor(x).astype(np.uint32);iy=np.floor(y).astype(np.uint32);fx=x-ix.astype(np.float32);fy=y-iy.astype(np.float32);u=fx*fx*fx*(fx*(fx*6-15)+10);v=fy*fy*fy*(fy*(fy*6-15)+10)
 def g(a,b,dx,dy):
  h=wang(a^wang(b^wang(seed)));return np.where(h&1,-dx,dx)+np.where(h&2,-dy,dy)
 a=g(ix,iy,fx,fy);b=g(ix+1,iy,fx-1,fy);c=g(ix,iy+1,fx,fy-1);d=g(ix+1,iy+1,fx-1,fy-1);lo=a+u*(b-a);hi=c+u*(d-c);return lo+v*(hi-lo)
for lesson,freq,octaves in [(48,2,6),(49,10,6),(50,1.5,5)]:
 yy,xx=np.mgrid[:256,:256].astype(np.float32);x=xx/np.float32(255)*np.float32(freq);y=yy/np.float32(255)*np.float32(freq);h=np.zeros_like(x);amp=np.float32(1);f=np.float32(1);total=np.float32(0)
 with np.errstate(over='ignore'):
  for i in range(octaves):h+=amp*perlin(x*f,y*f,np.uint32(42+i));total+=amp;f*=np.float32(2);amp*=np.float32(.5)
 h/=total;h=(h-h.min())/(h.max()-h.min());(B/'assets'/f'terrain_{lesson}.f32').write_bytes(h.astype('<f4').tobytes())
for n in [128,64,32,16,8]:
 vertices=[];indices=[]
 for z in range(n+1):
  for x in range(n+1):vertices.append([x/n*2-1,0,z/n*2-1,0,1,0,x/n,z/n])
 for z in range(n):
  for x in range(n):a=z*(n+1)+x;indices.extend([a,a+n+1,a+1,a+1,a+n+1,a+n+2])
 write_mesh(f'terrain_grid_{n}',vertices,indices)
# Cylinder and cone use the original lesson 49 dimensions and slice count.
for kind,radius,height,base in [('trunk',.15,.5,0),('crown',.5,.8,.5)]:
 vertices=[];indices=[];rings=4 if kind=='crown' else 1
 for j in range(rings+1):
  t=j/rings;r=radius*(1-t) if kind=='crown' else radius
  for i in range(13):
   a=i/12*2*math.pi;n=np.array([math.cos(a),radius/height if kind=='crown' else 0,math.sin(a)]);n/=np.linalg.norm(n);vertices.append([r*math.cos(a),base+t*height,r*math.sin(a),*n,i/12,t])
 for j in range(rings):
  for i in range(12):a=j*13+i;indices.extend([a,a+1,a+13,a+1,a+14,a+13])
 write_mesh('terrain_'+kind,vertices,indices)
vertices=[];indices=[]
for plane in range(2):
 c=math.cos(plane*math.pi/2);s=math.sin(plane*math.pi/2);start=len(vertices)
 for x,y,u,v in [(-.15,0,0,1),(.15,0,1,1),(.15,.6,1,0),(-.15,.6,0,0)]:vertices.append([x*c,y,x*s,-s,0,c,u,v])
 indices.extend([start,start+1,start+2,start,start+2,start+3])
write_mesh('terrain_cross',vertices,indices)
write_mesh('terrain_billboard',[[-.5,0,0,0,0,1,0,1],[.5,0,0,0,0,1,1,1],[.5,1,0,0,0,1,1,0],[-.5,1,0,0,0,1,0,0]],[0,1,2,0,2,3])
for segments in [4,3,2,1]:
 vertices=[];indices=[]
 for j in range(segments+1):
  t=j/segments;width=.5*(1-t*.8)
  for side in [-1,1]:vertices.append([side*width,t,0,0,t,1,(side+1)/2,1-t])
 for j in range(segments):a=j*2;indices.extend([a,a+1,a+2,a+1,a+3,a+2])
 write_mesh(f'terrain_blade_{segments}',vertices,indices)
# The source L48 tree is a procedural cross billboard. Alpha mask, no external photo.
y,x=np.mgrid[:128,:64];u=(x+.5)/64;v=1-(y+.5)/128;mask=((abs(u-.5)<.06)&(v<.35))|((v>.25)&(v<.98)&(abs(u-.5)<(.98-v)*.65));image=np.zeros((128,64,4),dtype=np.uint8);image[:,:,:3]=[50,110,30];image[mask,3]=255;Image.fromarray(image).save(B/'assets/terrain_tree.png')
outputs={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (B/'assets').glob('terrain_*') if p.name!='terrain_sources.json'};(B/'assets/terrain_sources.json').write_text(json.dumps({'source_commit':'31f44fce9b69cb124b38c1bc90177ef17f1342c8','algorithm':'Forge Wang/Perlin fBm, float32; source lesson parameters; source tree dimensions; offline meshes','outputs':outputs},indent=2)+'\n')
