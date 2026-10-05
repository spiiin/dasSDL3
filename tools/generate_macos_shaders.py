"""Reproduce saved MSL fixtures using the pinned shadercross CLI."""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--shadercross', type=Path, default=ROOT / 'build/macos-libraries/bin/shadercross')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    fixtures = [(ROOT / 'examples/libraries/shaders', 'ttf.vert', 'vertex'),
                (ROOT / 'examples/libraries/shaders', 'ttf.frag', 'fragment')]
    for name in ['attachments', 'bindings', 'vertex_color', 'mesh']:
        fixtures += [(ROOT / 'examples/assets/shaders', name + '.vert', 'vertex'),
                     (ROOT / 'examples/assets/shaders', name + '.frag', 'fragment')]
    fixtures += [(ROOT / 'examples/assets/shaders', 'render_state.frag', 'fragment'),
                 (ROOT / 'examples/assets/shaders', 'native.comp', 'compute')]
    with tempfile.TemporaryDirectory(prefix='dassdl3-msl-') as temporary:
        for assets, name, stage in fixtures:
            generated = Path(temporary) / f'{name}.msl'
            subprocess.run([str(args.shadercross.resolve()), str(assets / f'{name}.spv'),
                            '-s', 'SPIRV', '-d', 'MSL', '-t', stage, '-e', 'main',
                            '-o', str(generated)], check=True)
            # Canonical EOF; the CLI emits one extra blank line.
            text = generated.read_text(encoding='utf-8').rstrip() + '\n'
            saved = assets / generated.name
            if args.check:
                if not saved.is_file() or saved.read_text(encoding='utf-8') != text:
                    raise SystemExit(f'Stale MSL fixture: {saved}')
            else:
                saved.write_text(text, encoding='utf-8')
    print('MSL fixtures are reproducible.' if args.check else 'MSL fixtures generated.')

if __name__ == '__main__':
    main()
