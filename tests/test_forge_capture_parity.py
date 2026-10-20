"""Compare saved interpreter/strict-AOT captures on the same backend (no GPU launches).
Overlays let a targeted rerun replace earlier frames after a fix.
"""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--interpreter',type=Path,required=True);p.add_argument('--overlay',type=Path,action='append',default=[]);p.add_argument('--aot',type=Path,required=True);a=p.parse_args();results=[]
 for lesson in range(21,53):
  filename=f'{lesson}_default.png';first=a.interpreter/filename
  for folder in a.overlay:
   if (folder/filename).exists():first=folder/filename
  second=a.aot/filename;log=(a.aot/f'{lesson}_default.log').read_text();assert 'main AOT=yes; fallback disabled' in log,lesson
  x=np.asarray(Image.open(first),dtype=np.int16)[:,:,:3];y=np.asarray(Image.open(second),dtype=np.int16)[:,:,:3];difference=np.abs(x-y)
  # Load-duration text is deliberately variable; keep all geometry in the comparison.
  if lesson in [42,51,52]:difference[:500,:365]=0
  mae=float(difference.mean());p99=float(np.percentile(difference,99));entry=dict(lesson=lesson,rgb_mae=round(mae,6),p99=p99);results.append(entry)
  assert mae<.25 and p99<=3,(lesson,mae,p99)
 (a.aot/'parity.json').write_text(json.dumps(results,indent=2)+'\n');print(f'Forge: 32 interpreter/strict-AOT image comparisons PASS; worst RGB MAE {max(r["rgb_mae"] for r in results)}')
if __name__=='__main__':main()
