"""Independent pixel oracle for the five forge-gpu DSL ports."""
import argparse, hashlib, json, math, os, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def smooth(a,b,x):
 t=max(0.,min(1.,(x-a)/(b-a)));return t*t*(3-2*t)
def plasma(x,y,time):
 px=2*x/257.-1;py=2*y/193.-1;r=math.hypot(px,py)
 v=(math.sin(px*3+time*1.2)+math.sin(py*4+time*.8)+math.sin((px+py)*2.5+time*1.5)+math.sin(r*5-time*2)+math.sin(math.atan2(py,px)*3+r*4+time))/10+.5+time*.1
 segment=(v%1)*4;i=int(segment);f=segment%1;s=f*f*(3-2*f)
 palette=[(.063,.533,.871),(.761,.161,.024),(.122,.471,.129),(.395,.055,.481)];bg=(.012,.024,.059)
 fade=1-smooth(.5,1.2,r)
 return [round(255*(bg[k]*(1-fade)+(palette[i][k]*(1-s)+palette[(i+1)%4][k]*s)*fade)) for k in range(3)]
def main():
 p=argparse.ArgumentParser();p.add_argument('--runner',required=True);p.add_argument('--driver',default='vulkan');a=p.parse_args()
 assets=ROOT/'examples/gpu_port_forge/assets';manifest=json.loads((assets/'sources.json').read_text())
 for name,digest in manifest['outputs'].items():assert hashlib.sha256((assets/name).read_bytes()).hexdigest()==digest,name
 with tempfile.TemporaryDirectory(prefix='forge-pixels-') as folder:
  env=dict(os.environ,SDL_GPU_DRIVER=a.driver,SDL_ASSERT='abort',DASSDL3_FORGE_CAPTURE=folder)
  result=subprocess.run([a.runner,str(ROOT/'tests/forge_pixels.das'),'--smoke-test'],env=env,text=True,capture_output=True,timeout=120)
  assert result.returncode==0,result.stdout+result.stderr
  assert not any(x in result.stdout+result.stderr for x in ['VUID-','Validation Error','D3D12 ERROR','D3D12 CORRUPTION']),result.stdout+result.stderr
  print(result.stdout,end='')
  root=Path(folder)
  for number in [10,12,13,14]:
   first=(root/f'forge_{number}_default.rgba').read_bytes();second=(root/f'forge_{number}_changed.rgba').read_bytes()
   assert len(first)==len(second)==320*240*4 and first!=second
  for frame,time in enumerate([0.,1.25]):
   data=(root/f'forge_11_{frame}.rgba').read_bytes();assert len(data)==264*200*4
   for y in range(3,193,19):
    for x in range(2,257,23):
     expected=plasma(x,y,time);actual=data[(y*264+x)*4:(y*264+x)*4+3]
     assert max(abs(a-b) for a,b in zip(actual,expected))<=2,(x,y,time,actual,expected)
  a0=(root/'forge_11_0.rgba').read_bytes();a1=(root/'forge_11_1.rgba').read_bytes();assert a0!=a1
 print(f'Forge {a.driver}: asset hashes and independent plasma CPU oracle PASS')
if __name__=='__main__':main()
