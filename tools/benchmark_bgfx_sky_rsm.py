"""Sequential render-only Vulkan audit. Run after building native and strict-AOT runners."""
import argparse,json,os,re,statistics,subprocess
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--bgfx',type=Path,required=True)
p.add_argument('--runner',required=True)
p.add_argument('--aot-runner',required=True)
p.add_argument('--output',type=Path,required=True)
p.add_argument('--trials',type=int,default=3)
p.add_argument('--case',choices=['all','sky','rsm'],default='all')
a=p.parse_args();root=Path(__file__).resolve().parents[1]
env=dict(os.environ,SDL_GPU_DRIVER='vulkan',VK_LOADER_LAYERS_DISABLE='VK_LAYER_RENDERDOC_Capture',__COMPAT_LAYER='HIGHDPIAWARE')
env.pop('BGFX_AUDIT_CAPTURE',None)
results=[]
for case,number in [('sky','36'),('rsm','31')]:
 if a.case!='all' and case!=a.case:continue
 for trial in range(a.trials):
  for kind in ['bgfx','interpreter','aot']:
   if kind=='bgfx':args=[str(a.bgfx/f'.build/win64_vs2022/bin/audit-{number}-{case}Release.exe'),'--vk'];cwd=a.bgfx/'examples/runtime'
   else:args=[a.runner if kind=='interpreter' else a.aot_runner,str(root/f'tests/benchmark_gpu_{case}.das')];cwd=root
   proc=subprocess.run(args,cwd=cwd,env=env,text=True,capture_output=True,timeout=90)
   assert proc.returncode==0,proc.stdout+proc.stderr
   assert not any(error in proc.stdout+proc.stderr for error in ['VUID-','Validation Error','AOT link failed']),proc.stdout+proc.stderr
   line=next(line for line in proc.stdout.splitlines() if line.startswith('BENCH_RESULT'))
   values=dict(re.findall(r'(\w+)=([0-9.]+)',line))
   results.append(dict(case=case,kind=kind,trial=trial,values={k:float(v) for k,v in values.items()},stdout=proc.stdout,stderr=proc.stderr))
   a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(results,indent=2)+'\n')
   print(case,kind,trial,line,flush=True)
for case in ['sky','rsm']:
 if a.case!='all' and case!=a.case:continue
 for kind in ['bgfx','interpreter','aot']:
  times=[r['values']['ms'] for r in results if r['case']==case and r['kind']==kind]
  print(case,kind,'median_ms=',statistics.median(times),'min=',min(times),'max=',max(times),flush=True)
