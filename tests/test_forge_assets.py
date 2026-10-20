"""Check pinned Forge asset manifests without a GPU, network or upstream checkout."""
import hashlib,json
from pathlib import Path
BASE=Path(__file__).resolve().parents[1]/'examples/gpu_port_forge'
def check_assets():
 count=0
 for name in ['sources.json','advanced_sources.json','extended_sources.json','pbr_sources.json','atlas_sources.json','terrain_sources.json','misc_sources.json']:
  data=json.loads((BASE/'assets'/name).read_text());root=BASE if name=='misc_sources.json' else BASE/'assets'
  for file,record in data['outputs'].items():
   digest=record['sha256'] if isinstance(record,dict) else record
   path=(root/file).resolve();assert path.is_relative_to(BASE.resolve()),('outside example',file)
   assert path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest()==digest,(name,file)
   count+=1
 print(f'Forge assets: {count} output hashes PASS')
 return count
if __name__=='__main__':check_assets()
