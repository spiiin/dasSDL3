"""Generate the existing allowlist through CppGenBind and compare Clang metadata."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def generate(args, output, allowlist, header):
    result = subprocess.run([str(args.daslang), '-no-module-cache', str(ROOT / 'tools/clangbind_parity.das'),
        '--', str(args.sdl_include), str(args.sdk), str(output), str(allowlist), str(header)],
        capture_output=True, text=True, encoding='utf-8', errors='replace')
    log = result.stdout + result.stderr
    if result.returncode or re.search(r'error:|fatal error:|\[E\]', log):
        raise RuntimeError(log)
    return {name: (output / name).read_text(encoding='utf-8') for name in
            ('functions.inc', 'signatures.tsv', 'types.inc', 'registrations.inc', 'contract.tsv')}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('daslang', 'sdl-include', 'sdk', 'output'):
        parser.add_argument('--' + name, required=True, type=Path)
    parser.add_argument('--snapshot', action='store_true',
                        help='Generate production snapshots independently of the legacy manifest')
    parser.add_argument('--check', action='store_true', help='Check output without modifying it')
    args = parser.parse_args()
    for name in ('daslang', 'sdl_include', 'sdk', 'output'):
        setattr(args, name, getattr(args, name).resolve())
    for path in (args.daslang, args.sdl_include / 'SDL3/SDL.h', args.sdk / 'lib/clang/22/include/stddef.h'):
        if not path.is_file():
            raise FileNotFoundError(path)
    spec = json.loads((ROOT / 'tools/bindings.json').read_text())
    baseline = {} if args.snapshot else json.loads((ROOT / 'src/generated/api.json').read_text())
    # libclang omits this spelling on x64; the das generator explicitly checks CC.
    for record in baseline.values():
        record['signature'] = record['signature'].replace(' __attribute__((cdecl))', '')
    if not args.snapshot and set(spec['functions']) != set(baseline):
        raise RuntimeError('Baseline manifest and bindings.json differ; regenerate production first')
    with tempfile.TemporaryDirectory(prefix='sdl-parity-') as temp:
        root = Path(temp)
        allowlist = root / 'functions.txt'
        policy = ['P\t' + name for name in spec['functions']]
        project_types = json.loads((ROOT / 'tools/api-policy.json').read_text())['project_types']
        policy += ['O\t' + name + ('\tproject' if name in project_types else '') for name in spec['opaque_types']]
        for name, fields in spec['structs'].items():
            policy.append('S\t' + name)
            for field in fields:
                script_name = spec.get('field_names', {}).get(f'{name}.{field}', field)
                policy.append(f'F\t{name}\t{field}\t{script_name}')
        policy += [f'K\t{name}\t{ctype}' for name, ctype in spec['constants'].items()]
        allowlist.write_text('\n'.join(policy), encoding='utf-8')
        header = root / 'parity.h'
        header.write_text('#include <SDL3/SDL.h>\n' + ''.join(
            f'static const {ctype} DASSDL3_CONST_{name} = ({ctype})({name});\n'
            for name, ctype in spec['constants'].items()), encoding='utf-8')
        first, second = root / 'first', root / 'second'
        first.mkdir(); second.mkdir()
        files = generate(args, first, allowlist, header)
        if files != generate(args, second, allowlist, header):
            raise RuntimeError('Parity output is not deterministic')
    actual = {}
    for line in files['signatures.tsv'].splitlines():
        name, signature, *arguments = line.split('\t')
        if name in actual:
            raise RuntimeError(f'Duplicate function {name}')
        actual[name] = {'signature': signature.replace('_Bool', 'bool'), 'arguments': arguments}
    if not args.snapshot and actual != baseline:
        differences = {name: {'baseline': baseline.get(name), 'cppgenbind': actual.get(name)}
                       for name in baseline.keys() | actual.keys() if baseline.get(name) != actual.get(name)}
        raise RuntimeError(json.dumps(differences, indent=2))
    emitted = re.findall(r'\(lib,"(SDL_\w+)"', files['functions.inc'])
    if sorted(emitted) != sorted(spec['functions']):
        raise RuntimeError(f'Generated registrations differ: {emitted}')
    rows = [line.split('\t') for line in files['contract.tsv'].splitlines()]
    if sorted(row[1] for row in rows if row[0] == 'S') != sorted(spec['structs']):
        raise RuntimeError('Struct declarations differ from policy')
    expected_fields = sorted((name, field, spec.get('field_names', {}).get(f'{name}.{field}', field))
                             for name, fields in spec['structs'].items() for field in fields)
    if sorted(tuple(row[1:4]) for row in rows if row[0] == 'F') != expected_fields:
        raise RuntimeError('Fields differ from policy')
    if sorted((row[1], row[2]) for row in rows if row[0] == 'K') != sorted(spec['constants'].items()):
        raise RuntimeError('Constants differ from policy')
    outputs = {
        'parity_functions.inc': files['registrations.inc'] + files['functions.inc'],
        'parity_types.inc': files['types.inc'],
        'parity-contract.tsv': files['contract.tsv'],
        'parity-api.json': json.dumps(actual, indent=2) + '\n',
    }
    if args.snapshot:
        outputs = {name.replace('parity_', 'sdl3_').replace('parity-', ''): value
                   for name, value in outputs.items()}
        inputs = {str(path.relative_to(ROOT)).replace('\\', '/'):
                  hashlib.sha256(path.read_bytes().replace(b'\r\n', b'\n')).hexdigest()
                  for path in (Path(__file__).resolve(), ROOT / 'tools/clangbind_parity.das',
                               ROOT / 'tools/bindings.json', ROOT / 'tools/api-policy.json')}
        headers = {path.name: hashlib.sha256(path.read_bytes().replace(b'\r\n', b'\n')).hexdigest()
                   for path in sorted((args.sdl_include / 'SDL3').glob('*.h'))}
        outputs['profile.json'] = json.dumps({
            'target': 'x86_64-pc-windows-msvc', 'sdl_release': '3.2.18',
            'llvm_sdk': '22.1.5', 'inputs_sha256': inputs, 'headers_sha256': headers,
        }, indent=2) + '\n'
    if args.check:
        stale = [name for name, value in outputs.items()
                 if not (args.output / name).is_file()
                 or (args.output / name).read_text(encoding='utf-8') != value]
        if stale:
            raise RuntimeError('Stale generated bindings: ' + ', '.join(stale))
    else:
        args.output.mkdir(parents=True, exist_ok=True)
        for name, value in outputs.items():
            (args.output / name).write_text(value, encoding='utf-8')
    print(f'CppGenBind parity: {len(actual)} functions, {len(spec["structs"])} records, '
          f'{len(spec["opaque_types"])} opaque types, {len(expected_fields)} fields, '
          f'{len(spec["constants"])} constants; deterministic output PASS')


if __name__ == '__main__':
    main()
