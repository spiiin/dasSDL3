"""Configure-only SDK layout tests; fake SDK files are never compiled or loaded."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sdl-dir', required=True, type=Path)
    args = parser.parse_args()
    work = Path(tempfile.mkdtemp(prefix='sdk-layout-', dir=ROOT / 'build'))
    sdk = work / 'sdk'
    # Only the configure-time contract is under test. Actual daspkg install/load
    # is tested separately by test_daspkg.py.
    for relative in ('include/daScript/daScript.h', 'lib/libDaScriptDyn.lib', 'lib/libDaScriptDyn_runtime.lib'):
        p = sdk / relative
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text('')
    env = dict(os.environ)
    env.pop('DASSDL3_VALIDATE_SDK_FINGERPRINT', None)
    def configure(name, options=(), error=None):
        result = subprocess.run(['cmake', '-S', str(ROOT / 'src/package'), '-B', str(work / name),
            '-G', 'Ninja', '-DCMAKE_BUILD_TYPE=Release', '-DBUILD_TESTING=OFF',
            f'-DDASLANG_DIR={sdk}', f'-DSDL3_DIR={args.sdl_dir.resolve()}', *options],
            env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        (work / (name + '.log')).write_text(result.stdout, encoding='utf-8')
        if error:
            assert result.returncode and error in result.stdout, result.stdout
        else:
            assert result.returncode == 0, result.stdout
        return result.stdout
    configure('missing', error='Missing fmt headers in SDK')
    for i, folder in enumerate(('include', '3rdparty/fmt/include', 'include/fmt/include', 'external/fmt/include')):
        header = sdk / folder / 'fmt/format.h'
        header.parent.mkdir(parents=True, exist_ok=True)
        header.write_text('// configure fixture\n')
        output = configure(f'layout-{i}')
        assert f'SDK fmt headers: {(sdk / folder).as_posix()}' in output, output
        header.rename(header.with_suffix('.hidden'))
    configure('strict-no-profile', ['-DDASSDL3_VALIDATE_SDK_FINGERPRINT=ON'],
              error='Strict SDK validation requires')
    print(f'PASS: four SDK fmt layouts, missing dependency and strict missing profile; logs: {work}')

if __name__ == '__main__':
    main()
