"""Generate the existing allowlist through CppGenBind and compare Clang metadata."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def generate(args, output, allowlist):
    result = subprocess.run([str(args.daslang), '-no-module-cache', str(ROOT / 'tools/clangbind_parity.das'),
        '--', str(args.sdl_include), str(args.sdk), str(output), str(allowlist)],
        capture_output=True, text=True, encoding='utf-8', errors='replace')
    log = result.stdout + result.stderr
    if result.returncode or re.search(r'error:|fatal error:|\[E\]', log):
        raise RuntimeError(log)
    return {name: (output / name).read_text(encoding='utf-8') for name in ('functions.inc', 'signatures.tsv')}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('daslang', 'sdl-include', 'sdk', 'output'):
        parser.add_argument('--' + name, required=True, type=Path)
    args = parser.parse_args()
    for name in ('daslang', 'sdl_include', 'sdk', 'output'):
        setattr(args, name, getattr(args, name).resolve())
    for path in (args.daslang, args.sdl_include / 'SDL3/SDL.h', args.sdk / 'lib/clang/22/include/stddef.h'):
        if not path.is_file():
            raise FileNotFoundError(path)
    spec = json.loads((ROOT / 'tools/bindings.json').read_text())
    baseline = json.loads((ROOT / 'src/generated/api.json').read_text())
    # libclang omits this spelling on x64; the das generator explicitly checks CC.
    for record in baseline.values():
        record['signature'] = record['signature'].replace(' __attribute__((cdecl))', '')
    if set(spec['functions']) != set(baseline):
        raise RuntimeError('Baseline manifest and bindings.json differ; regenerate production first')
    with tempfile.TemporaryDirectory(prefix='sdl-parity-') as temp:
        root = Path(temp)
        allowlist = root / 'functions.txt'
        allowlist.write_text('\n'.join(spec['functions']), encoding='utf-8')
        first, second = root / 'first', root / 'second'
        first.mkdir(); second.mkdir()
        files = generate(args, first, allowlist)
        if files != generate(args, second, allowlist):
            raise RuntimeError('Parity output is not deterministic')
    actual = {}
    for line in files['signatures.tsv'].splitlines():
        name, signature, *arguments = line.split('\t')
        if name in actual:
            raise RuntimeError(f'Duplicate function {name}')
        actual[name] = {'signature': signature.replace('_Bool', 'bool'), 'arguments': arguments}
    if actual != baseline:
        differences = {name: {'baseline': baseline.get(name), 'cppgenbind': actual.get(name)}
                       for name in baseline.keys() | actual.keys() if baseline.get(name) != actual.get(name)}
        raise RuntimeError(json.dumps(differences, indent=2))
    emitted = re.findall(r'\(lib,"(SDL_\w+)"', files['functions.inc'])
    if sorted(emitted) != sorted(spec['functions']):
        raise RuntimeError(f'Generated registrations differ: {emitted}')
    # Reuse only type/constant registrations, never a production function binding.
    old = (ROOT / 'src/generated/sdl3_functions.inc').read_text()
    prefix = old[:old.index('addExtern<')]
    prefix = prefix[:prefix.rfind('//')]
    if 'addExtern' in prefix or 'makeExtern' in prefix:
        raise RuntimeError('Unexpected function in shared type contract')
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'parity_functions.inc').write_text(prefix + files['functions.inc'], encoding='utf-8')
    (args.output / 'parity-api.json').write_text(json.dumps(actual, indent=2) + '\n', encoding='utf-8')
    print(f'CppGenBind parity: {len(actual)} signatures and argument names match; deterministic output PASS')


if __name__ == '__main__':
    main()
