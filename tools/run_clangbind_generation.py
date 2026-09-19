"""Bounded CppGenBind experiment; never writes production src/generated files."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile
import shutil


def generate(args, output):
    result = subprocess.run([
        str(args.daslang), '-no-module-cache', str(Path(__file__).with_name('clangbind_generate.das')),
        '--', str(args.sdl_include), str(args.sdk), str(output),
    ], capture_output=True, text=True, encoding='utf-8', errors='replace')
    log = result.stdout + result.stderr
    # Upstream CppGenBind reports some parse errors without a failing exit status.
    if result.returncode or re.search(r'error:|fatal error:|\[E\]|defaulting to stdout', log):
        raise RuntimeError(log)
    files = {p.name: p.read_bytes() for p in output.iterdir() if p.is_file()}
    functions = files.get('dasSDL3Probe.func_1.cpp', b'').decode()
    for name in ('SDL_GetRectIntersectionFloat', 'SDL_PointInRect', 'SDL_GetPixelFormatName'):
        if f'lib,"{name}"' not in functions:
            raise RuntimeError(f'Missing selected function {name}\n{log}')
    declarations = files.get('dasSDL3Probe.struct.decl.inc', b'').decode()
    for name in ('SDL_FRect', 'SDL_Rect', 'SDL_Point', 'SDL_FPoint', 'SDL_GUID',
                 'SDL_GPUViewport', 'SDL_GPUVertexInputState',
                 'SDL_GPUVertexAttribute', 'SDL_GPUVertexBufferDescription'):
        if f'({name},{name})' not in declarations:
            raise RuntimeError(f'Missing selected type {name}\n{log}')
    if len(files) != 20:
        raise RuntimeError(f'Unexpected output set: {sorted(files)}')
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('daslang', 'sdl-include', 'sdk', 'output'):
        parser.add_argument('--' + name, required=True, type=Path)
    args = parser.parse_args()
    for name in ('daslang', 'sdl_include', 'sdk', 'output'):
        setattr(args, name, getattr(args, name).resolve())
    for required in (args.daslang, args.sdl_include / 'SDL3/SDL.h',
                     args.sdk / 'lib/clang/22/include/stddef.h',
                     args.sdk / 'lib/cmake/clang/ClangConfig.cmake'):
        if not required.is_file():
            raise FileNotFoundError(f'Required toolchain input is missing: {required}')
    with tempfile.TemporaryDirectory(prefix='sdl-cbind-') as temp:
        first, second = Path(temp) / 'first', Path(temp) / 'second'
        first.mkdir(); second.mkdir()
        files = generate(args, first)
        if files != generate(args, second):
            raise RuntimeError('CppGenBind output differs between two clean directories')
        args.output.mkdir(parents=True, exist_ok=True)
        for name in files:
            shutil.copyfile(first / name, args.output / name)
    print(f'CppGenBind: {len(files)} files, 3 functions, 9 structs; deterministic output PASS')


if __name__ == '__main__':
    main()
