"""Launch all Forge 21-52 ports, reject validation errors, and check real GPU readbacks.
Optional --captures keeps RGBA/PNG frames for visual review. This is not a pixel-parity claim.
"""
import argparse,json,os,subprocess,tempfile,time
from pathlib import Path
import numpy as np
from PIL import Image
from test_forge_assets import check_assets
ROOT=Path(__file__).resolve().parents[1]

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--runner',required=True);p.add_argument('--driver',default='vulkan');p.add_argument('--aot',action='store_true');p.add_argument('--captures',type=Path);p.add_argument('--lessons',default='21-52');p.add_argument('--variants',action='store_true');a=p.parse_args()
 check_assets()
 numbers=[]
 for segment in a.lessons.split(','):
  bounds=list(map(int,segment.split('-')));numbers.extend(range(bounds[0],bounds[-1]+1))
 with tempfile.TemporaryDirectory(prefix='forge-extended-') as folder:
  out=a.captures or Path(folder);out.mkdir(parents=True,exist_ok=True);results=[]
  for lesson in numbers:
   examples=list((ROOT/'examples/gpu_port_forge').glob(f'example_{lesson}_*/main.das'));assert len(examples)==1,lesson
   frames={}
   variants=['default','changed'] if a.variants else ['default']
   if a.variants and lesson in [23,25,26,27,29,46]:variants+=['mode2']
   for case in variants:
    target=out/f'{lesson}_{case}.rgba';env=dict(os.environ,SDL_GPU_DRIVER=a.driver,SDL_ASSERT='abort',DASSDL3_FORGE_CAPTURE=str(target),DASSDL3_FORGE_VARIANT='' if case=='default' else case)
    args=[a.runner,str(examples[0])]+([] if a.aot else ['--smoke-test']);started=time.monotonic()
    try:
     proc=subprocess.run(args,env=env,capture_output=True,text=True,timeout=180);log=proc.stdout+proc.stderr;(out/f'{lesson}_{case}.log').write_text(log)
     assert proc.returncode==0,log
     if a.aot:assert "main AOT=yes; fallback disabled" in log,log
     assert not any(w in log for w in ['VUID-','Validation Error','D3D12 ERROR','D3D12 CORRUPTION','AOT failure','AOT is not linked']),log
     assert target.exists(),f'No readback: {lesson} {case}'
     image=np.frombuffer(target.read_bytes(),np.uint8).reshape(720,1280,4);frames[case]=image
     visible=int(np.count_nonzero(np.any(image[:,:,:3]!=image[0,0,:3],axis=2)));assert visible>1000,(lesson,case,visible)
     assert np.max(image[:,:,:3])-np.min(image[:,:,:3])>12,(lesson,'flat frame')
     if lesson in [42,51,52]:
      surface=np.max(np.abs(image[200:650,400:1150,:3].astype(int)-image[200:650,-1:,:3].astype(int)),axis=2)
      assert np.count_nonzero(surface>10)>2000,(lesson,'PBR geometry missing outside UI')
     if a.captures:Image.fromarray(image).save(target.with_suffix('.png'))
     entry=dict(lesson=lesson,case=case,status='PASS',visible_pixels=visible,seconds=round(time.monotonic()-started,2))
    except Exception as e:entry=dict(lesson=lesson,case=case,status='FAIL',error=str(e))
    results.append(entry);print(json.dumps(entry),flush=True)
   if len(frames)>1:
    first=frames['default'];delta={case:int(np.count_nonzero(np.max(np.abs(first[:,:,:3].astype(int)-image[:,:,:3].astype(int)),axis=2)>3)) for case,image in frames.items() if case!='default'}
    print(f'Lesson {lesson} changed pixels: {delta}',flush=True)
    if lesson==47:
     mae=float(np.mean(np.abs(first[:,:,:3].astype(float)-frames['changed'][:,:,:3].astype(float))))
     if mae>1.0:results.append(dict(lesson=47,status='FAIL',error=f'Atlas and individual materials differ: RGB MAE {mae}'))
    # The mechanisms controlled by E/time must affect the actual frame.
    if lesson in [21,22,24,25,27,29,31,32,35,36,40,43,44,46,49,50,51]:
     if max(delta.values(),default=0)<(1000 if lesson==35 else 24):results.append(dict(lesson=lesson,status='FAIL',error='Controlled effect/animation did not change pixels'))
  (out/'report.json').write_text(json.dumps(results,indent=2)+'\n');failed=[r for r in results if r['status']!='PASS']
  assert not failed,json.dumps(failed,indent=2)
  print(f'Forge 21-52 {a.driver} '+('strict AOT' if a.aot else 'interpreter')+f': {len(results)} readbacks PASS')
if __name__=='__main__':main()
