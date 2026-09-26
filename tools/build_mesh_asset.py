"""Convert the pinned bgfx bunny OBJ to the example-local MSH1 format."""
import argparse,hashlib,json,math,struct,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
URL="https://raw.githubusercontent.com/bkaradzic/bgfx/7e3060ccb97959dcda3f091b96d82515197028e0/examples/assets/meshes/bunny.obj"
SOURCE_SHA256="008348bca990dcf70f381a8c79bb3470b04cd447099cc3a7ced0bf472a4a0c4a"
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source',type=Path);p.add_argument('--check',action='store_true');a=p.parse_args()
data=a.source.read_bytes() if a.source else urllib.request.urlopen(URL).read()
if hashlib.sha256(data).hexdigest()!=SOURCE_SHA256:raise ValueError('Unexpected source OBJ hash')
positions=[];normals=[];vertices=[];indices=[];lookup={}
for line in data.decode().splitlines():
 parts=line.split()
 if not parts:continue
 if parts[0] in ('v','vn'):
  value=tuple(map(float,parts[1:4]));assert len(value)==3 and all(math.isfinite(x) for x in value)
  (positions if parts[0]=='v' else normals).append(value)
 elif parts[0]=='f':
  assert len(parts)==4,'Pinned asset must contain triangles'
  for token in parts[1:]:
   fields=token.split('/');key=(int(fields[0])-1,int(fields[2])-1)
   assert 0<=key[0]<len(positions) and 0<=key[1]<len(normals)
   if key not in lookup:
    lookup[key]=len(vertices);vertices.append(positions[key[0]]+normals[key[1]])
   indices.append(lookup[key])
output=struct.pack('<4sIII',b'MSH1',len(vertices),len(indices),24)
output+=b''.join(struct.pack('<6f',*v) for v in vertices)
output+=struct.pack('<%dI'%len(indices),*indices)
manifest={'source':URL,'source_sha256':SOURCE_SHA256,'vertices':len(vertices),'indices':len(indices),'stride':24,'sha256':hashlib.sha256(output).hexdigest()}
folder=ROOT/'examples/gpu/models';folder.mkdir(exist_ok=True)
if a.check:
 assert (folder/'bunny.msh').read_bytes()==output,'Stale bunny.msh'
 assert json.loads((folder/'bunny.json').read_text())==manifest,'Stale manifest'
else:
 (folder/'bunny.msh').write_bytes(output);(folder/'bunny.json').write_text(json.dumps(manifest,indent=2)+'\n',newline='\n')
print(f"Bunny: {len(vertices)} vertices, {len(indices)//3} triangles")
