"""Compile, legalize and validate SDL resource shaders; reject unsupported storage shapes."""
import argparse
from pathlib import Path
import subprocess
import tempfile

p=argparse.ArgumentParser()
p.add_argument('--runner',required=True)
p.add_argument('--spirv-val')
a=p.parse_args()
root=Path(__file__).resolve().parents[1]
def run(path):
    return subprocess.run([a.runner,str(path),'--smoke-test'],capture_output=True,text=True,timeout=45)
with tempfile.TemporaryDirectory(prefix='sdl-storage-dsl-') as directory:
    folder=Path(directory)
    (folder/'shader_dsl_resource_shaders.das').write_text((root/'tests/shader_dsl_resource_shaders.das').read_text(),encoding='utf-8')
    names=['resource_compute','resource_vertex','resource_fragment','rmw_compute']
    calls=[]
    for name in names:
        calls.append(f'save("{folder.as_posix()}/{name}.spv",{name},{name}_reflect,{name}_access)')
    source=folder/'emit.das'
    source.write_text("""options gen2
require shader_dsl_resource_shaders
require dassdl3/sdl3_shader_storage_spirv
require daslib/fio

def save(path : string; words,reflection,access : array<uint>) {
    var native <- gpu_dsl_storage_spirv(words,reflection,access) |> move_unwrap
    fopen(path,"wb") $(f) {verify(f!=null);verify(fwrite(f,native)==length(native)*4)}
}
[export]
def main(smoke : bool) : int {
"""+'\n'.join(calls)+'\nreturn 0\n}\n',encoding='utf-8')
    for iteration in range(2):
        result=run(source)
        assert result.returncode==0,result.stdout+result.stderr
        current=[(folder/f'{name}.spv').read_bytes() for name in names]
        if iteration: assert current==previous,'Non-deterministic legalized SPIR-V'
        previous=current
    if a.spirv_val:
        for name in names:
            result=subprocess.run([a.spirv_val,'--target-env','vulkan1.1',str(folder/f'{name}.spv')],capture_output=True,text=True,timeout=30)
            assert result.returncode==0,result.stdout+result.stderr
    for field in ['bool','string','array<float>','float3x3[2]','float[2][2]','uint8']:
        source.write_text(f"""options gen2
require dassdl3/sdl3_shader_storage
require math
struct Bad {{ field : {field} }}
[export]
def main(smoke : bool) : int {{
    var values : array<Bad>
    var bytes <- gpu_dsl_storage_bytes(values) |> move_unwrap
    return length(bytes)
}}
""",encoding='utf-8')
        result=run(source)
        assert result.returncode!=0 and ('std430' in result.stdout+result.stderr or 'SDL' in result.stdout+result.stderr),(field,result.stdout,result.stderr)
    for qualifier,operation,diagnostic in [
        ('readonly','imageStore(img,int2(0),float4(1.0))','readonly'),
        ('maybe_readonly','let value=imageLoad(img,int2(0))','maybe_readonly')]:
        source.write_text(f"""options gen2
require dassdl3/sdl3_shader_access
var @{qualifier} @set=0 @binding=0 img : image2D
[compute_shader(name="bad"),sdl_shader_access(name="bad")]
def kernel {{ {operation} }}
[export]
def main(smoke : bool) : int {{ return length(bad)+length(bad_access) }}
""",encoding='utf-8')
        result=run(source)
        assert result.returncode!=0 and diagnostic in result.stdout+result.stderr,(result.stdout,result.stderr)
print('Resource DSL compiler/negative checks PASS; SPIRV-Tools '+('PASS' if a.spirv_val else 'not requested'))
