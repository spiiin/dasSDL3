"""Exercise the real offline CLI using isolated outputs; compare stable SPIR-V bytes."""
from pathlib import Path
import subprocess,sys,tempfile,json
cli,source=sys.argv[1:]
with tempfile.TemporaryDirectory(prefix="dassdl3-shadercross-") as tmp:
    root=Path(tmp)
    def compile(src,dest,fmt):
        subprocess.run([cli,str(src),"-s","HLSL" if str(src).endswith(".hlsl") else "SPIRV",
            "-d",fmt,"-t","fragment","-e","main","-o",str(dest)],check=True)
    spv=root/'shader.spv';again=root/'again.spv'
    compile(source,spv,"SPIRV");compile(source,again,"SPIRV")
    assert spv.read_bytes()==again.read_bytes() and spv.read_bytes()[:4]==b'\x03\x02\x23\x07'
    compile(spv,root/'shader.dxil',"DXIL")
    assert (root/'shader.dxil').read_bytes()[:4]==b'DXBC'
    compile(spv,root/'shader.msl',"MSL")
    assert 'fragment' in (root/'shader.msl').read_text()
    compile(spv,root/'shader.json',"JSON")
    assert json.loads((root/'shader.json').read_text())
print('Offline SPIR-V/DXIL/MSL/reflection and reproducible SPIR-V: PASS')
