"""Optional offline rebuild parity check. Requires pinned Forge checkout and preparation dependencies."""
import argparse,hashlib,json,os,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def snapshot():
 base=ROOT/'examples/gpu_port_forge'
 files=list((base/'assets').rglob('*'))+[base/'common'/n for n in ['extended_assets.das','atlas_names.das','ui_font.das']]
 return {p.relative_to(base).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files if p.is_file()}
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--upstream',required=True);a=p.parse_args();before=snapshot()
 for name in ['extended_assets','misc','terrain','pbr']:
  args=[sys.executable,str(ROOT/'tools'/f'prepare_forge_{name}.py')]+([] if name=='terrain' else ['--upstream',a.upstream])
  result=subprocess.run(args,text=True,capture_output=True,timeout=900)
  assert result.returncode==0,result.stdout+result.stderr
  print(f'{name}: rebuilt',flush=True)
 after=snapshot();changed=[n for n in before.keys()|after.keys() if before.get(n)!=after.get(n)]
 assert not changed,changed
 produced=set();base=ROOT/'examples/gpu_port_forge'
 for name in ['extended_sources.json','pbr_sources.json','misc_sources.json','terrain_sources.json','atlas_sources.json']:
  path=base/'assets'/name;data=json.loads(path.read_text());root=base if name=='misc_sources.json' else base/'assets';produced.add(path.resolve());produced.update((root/n).resolve() for n in data['outputs'])
 print(f'Forge asset rebuild: {len(produced)} generated/copied files reproduced byte-for-byte; {len(after)} total files unchanged')
if __name__=='__main__':main()
