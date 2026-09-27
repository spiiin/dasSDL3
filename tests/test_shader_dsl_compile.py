"""Compile the actual example shaders twice; optionally run SPIRV-Tools."""
from pathlib import Path
import argparse, subprocess, tempfile
p=argparse.ArgumentParser()
p.add_argument('--daslang',required=True)
p.add_argument('--spirv-val')
a=p.parse_args()
root=Path(__file__).resolve().parents[1]
def run(path):
    return subprocess.run([a.daslang,str(path)],capture_output=True,text=True,timeout=90)
with tempfile.TemporaryDirectory(prefix='sdl-shader-dsl-') as tmp:
    folder=Path(tmp)
    for module, prefix in [('dsl_shaders','triangle'),('texture_shaders','texture'),('uniform_shaders','uniform'),('compute_shaders','buffer')]:
        source=(root/f'examples/gpu_dsl/{module}.das').read_text(encoding='utf-8')
        source=source.replace(f'module {module} shared public','require daslib/fio')
        shader=folder/'emit.das'
        writes=[]
        files=[]
        for stage in (['compute'] if prefix == 'buffer' else ['vertex','fragment']):
            name=f'{prefix}_{stage}'
            file=folder/f'{name}.spv'
            files.append(file)
            writes.append(f'fopen("{file.as_posix()}","wb") $(f) {{verify(f!=null);verify(fwrite(f,{name})==length({name})*4)}}')
        shader.write_text(source+'\n[export]\ndef main {\n'+'\n'.join(writes)+'\n}\n',encoding='utf-8')
        first=run(shader)
        assert first.returncode==0,first.stdout+first.stderr
        before=[f.read_bytes() for f in files]
        second=run(shader)
        assert second.returncode==0,second.stdout+second.stderr
        assert before==[f.read_bytes() for f in files], 'Non-deterministic shader output'
        if a.spirv_val:
            for file in files:
                checked=subprocess.run([a.spirv_val,'--target-env','vulkan1.1',str(file)],capture_output=True,text=True,timeout=30)
                assert checked.returncode==0,checked.stdout+checked.stderr
    invalid=folder/'invalid.das'
    invalid.write_text('''options gen2
require spirv/spirv_shader
[fragment_shader(name="bad")]
def fragment { print("Not a GPU operation") }
[export]
def main { print("{length(bad)}") }
''',encoding='utf-8')
    failure=run(invalid)
    output=failure.stdout+failure.stderr
    assert failure.returncode!=0 and 'print' in output and ('SPIR-V' in output or 'spirv' in output),output
print('Shader compiler: deterministic output, unsupported operation rejected; SPIRV-Tools '+('PASS' if a.spirv_val else 'not requested'))

