"""Deterministic DSL compilation and SPIRV-Tools validation for forge lesson shaders."""
import argparse,re,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser();p.add_argument('--runner',required=True);p.add_argument('--spirv-val');a=p.parse_args()
 modules=sorted((ROOT/'examples/gpu_port_forge').rglob('*_shaders.das'));names=[];imports=[]
 with tempfile.TemporaryDirectory(prefix='forge-shaders-') as folder:
  root=Path(folder)
  for module in modules:
   source=module.read_text();(root/module.name).write_text(source)
   imports.append(f'require {module.stem}')
   names.extend(re.findall(r'(?:vertex|fragment|compute)_shader\([^)]*?name\s*=\s*"([^"\n]+)"',source))
  assert len(names)==10 and len(names)==len(set(names))
  body='\n'.join(f'write_shader("{(root/(name+".spv")).as_posix()}",{name})' for name in names)
  (root/'check.das').write_text('options gen2\n'+'\n'.join(imports)+r'''
require daslib/fio
require dassdl3/sdl3_shader_dsl
require dassdl3/sdl3_shader_compute

def write_shader(path : string;words : array<uint>) { fopen(path,"wb") $(f){verify(f!=null);verify(fwrite(f,words)==length(words)*4)} }
[export]
def main(smoke : bool) : int {
    let graphics=gpu_dsl_shader_info(environment_fragment_reflect) |> unwrap
    verify(graphics.num_samplers==2u && graphics.num_uniform_buffers==1u)
    let compute=gpu_dsl_compute_info(plasma_compute_reflect,plasma_compute_access) |> unwrap
    verify(compute.num_readwrite_storage_textures==1u && compute.threadcount_x==8u && compute.threadcount_y==8u)
'''+body+'\nreturn 0\n}\n')
  previous=None
  for _ in range(2):
   proc=subprocess.run([a.runner,str(root/'check.das'),'--smoke-test'],text=True,capture_output=True,timeout=90)
   assert proc.returncode==0,proc.stdout+proc.stderr
   current=[(root/(name+'.spv')).read_bytes() for name in names]
   if previous is not None:assert previous==current,'Non-deterministic bytecode'
   previous=current
  if a.spirv_val:
   for name in names:
    proc=subprocess.run([a.spirv_val,'--target-env','vulkan1.1',str(root/(name+'.spv'))],text=True,capture_output=True,timeout=30)
    assert proc.returncode==0,name+': '+proc.stdout+proc.stderr
 print('Forge DSL: 10 shaders, reflection and deterministic bytecode PASS; '+('SPIRV-Tools PASS' if a.spirv_val else 'validator not supplied'))
if __name__=='__main__':main()
