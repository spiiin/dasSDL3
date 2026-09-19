"""Malformed headers and missing exports must fail before publishing parity output."""
from pathlib import Path
import subprocess
import sys
import tempfile

generator, daslang, sdk = sys.argv[1:]
with tempfile.TemporaryDirectory(prefix='sdl-parity-errors-') as temp:
    root = Path(temp)
    headers = root / 'include' / 'SDL3'
    headers.mkdir(parents=True)
    for source, diagnostic in (
        ('#error deliberate_parity_failure\n', 'error: deliberate_parity_failure'),
        ('int SDL_GetVersion(int wrong_argument);\n', 'wrong_argument'),
    ):
        (headers / 'SDL.h').write_text(source, encoding='utf-8')
        output = root / 'unpublished'
        result = subprocess.run([sys.executable, generator, '--daslang', daslang,
            '--sdl-include', str(headers.parent), '--sdk', sdk, '--output', str(output)],
            capture_output=True, text=True, errors='replace')
        log = result.stdout + result.stderr
        if result.returncode == 0 or diagnostic not in log or output.exists():
            raise SystemExit(f'Invalid header or signature mismatch accepted:\n{log}')
print('Clang errors and missing/changed exports rejected before publishing output')
