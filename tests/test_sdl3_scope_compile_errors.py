"""Scope markers must never execute or silently escape their lexical transform."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

PLACEMENT = 'sdl_use must be a direct statement or the sole initializer'
CASES = {
    'outside': ('def run { let x : int = sdl_use(with_value()); return sdl_ok() }', PLACEMENT),
    'nested_expression': ('def run { return sdl_scope() { let x : int = 1 + sdl_use(with_value()); return sdl_ok() } }', PLACEMENT),
    'assignment': ('def run { return sdl_scope() { var x = 0; x = sdl_use(with_value()); return sdl_ok() } }', PLACEMENT),
    'branch': ('def run { return sdl_scope() { if (true) { let x : int = sdl_use(with_value()) }; return sdl_ok() } }', PLACEMENT),
    'deferred': ('def run { return sdl_scope() { defer() { sdl_use(with_value()) }; return sdl_ok() } }', PLACEMENT),
    'missing_type': ('def run { return sdl_scope() { let x = sdl_use(with_value()); return sdl_ok() } }', 'sdl_use binding needs an explicit callback parameter type'),
    'not_call': ('def run { return sdl_scope() { let x : int = sdl_use(3); return sdl_ok() } }', 'sdl_use expects one scoped function call'),
    'scope_arguments': ('def run { return sdl_scope() $(x : int) { return sdl_ok() } }', 'sdl_scope expects one literal block without parameters'),
    'scope_not_block': ('def run { return sdl_scope(3) }', 'sdl_scope expects one literal block without parameters'),
    'wrong_type': ('def run { return sdl_scope() { let x : string = sdl_use(with_value()); return sdl_ok() } }', 'no matching functions'),
    'missing_callback_parameter': ('def run { return sdl_scope() { sdl_use(with_value()); return sdl_ok() } }', 'no matching functions'),
}

def main():
    runner = str(Path(sys.argv[1]).resolve())
    prefix = '''options gen2
require dassdl3/sdl3_scope
require daslib/defer
def with_value(blk : block<(value : int) : $Result<auto(T); SdlError>>) { return <- blk(42) }
'''
    valid = 'def run { return sdl_scope() { let x : int = sdl_use(with_value()); verify(x == 42); return sdl_ok() } }'
    with tempfile.TemporaryDirectory(prefix='sdl3-scope-errors-') as directory:
        for name, (body, diagnostic) in {'valid': (valid, ''), **CASES}.items():
            path = Path(directory)/(name+'.das')
            path.write_text(prefix + body + '\n[export]\ndef main(smoke : bool) : int { run(); return 0 }\n', encoding='utf-8')
            run = subprocess.run([runner,str(path),'--smoke-test'],capture_output=True,text=True,timeout=30,env={**os.environ,'SDL_VIDEODRIVER':'dummy'})
            output = run.stdout + run.stderr
            assert (run.returncode == 0 if name == 'valid' else run.returncode != 0 and diagnostic in output), (name,output)
            print(name + ': ' + ('accepted' if name == 'valid' else 'rejected'))

if __name__ == '__main__':
    main()
