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
    assets = ROOT / 'examples/libraries/shaders'
    with tempfile.TemporaryDirectory(prefix='dassdl3-msl-') as temporary:
        for stage, suffix in [('vertex', 'vert'), ('fragment', 'frag')]:
            generated = Path(temporary) / f'ttf.{suffix}.msl'
            subprocess.run([str(args.shadercross.resolve()), str(assets / f'ttf.{suffix}.spv'),
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
