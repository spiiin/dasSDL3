"""Regenerate the explicit wasm32 subset without touching Windows snapshots."""
import argparse
import subprocess
import sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--emsdk',required=True,type=Path)
p.add_argument('--sdl-include',required=True,type=Path)
p.add_argument('--check',action='store_true')
a=p.parse_args()
clang=a.emsdk/'upstream/bin'/('clang.exe' if sys.platform=='win32' else 'clang')
command=[sys.executable,str(root/'tools/generate_bindings.py'),'--clang',str(clang),
    '--sdl-include',str(a.sdl_include),'--spec',str(root/'tools/bindings-web.json'),
    '--output',str(root/'web/generated'),'--clang-arg=--target=wasm32-unknown-emscripten',
    '--clang-arg=--sysroot='+str(a.emsdk/'upstream/emscripten/cache/sysroot')]
if a.check:command.append('--check')
subprocess.run(command,check=True)
