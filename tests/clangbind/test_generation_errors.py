"""Regression: do not publish output when SDK input or Clang diagnostics fail."""
from pathlib import Path
import subprocess
import sys
import tempfile

generator, daslang, sdk = sys.argv[1:]
with tempfile.TemporaryDirectory(prefix='sdl-cbind-errors-') as temp:
    root = Path(temp)
    headers = root / 'include' / 'SDL3'
    headers.mkdir(parents=True)
    (headers / 'SDL.h').write_text('#error deliberate_clangbind_parse_failure\n', encoding='utf-8')
    for toolchain, diagnostic in ((str(root / 'absent-sdk'), 'Required toolchain input is missing'),
                                 (sdk, 'error: deliberate_clangbind_parse_failure')):
        output = root / 'unpublished'
        result = subprocess.run([sys.executable, generator, '--daslang', daslang,
            '--sdl-include', str(headers.parent), '--sdk', toolchain, '--output', str(output)],
            capture_output=True, text=True, errors='replace')
        log = result.stdout + result.stderr
        if result.returncode == 0 or diagnostic not in log or output.exists():
            raise SystemExit(f'Generation accepted invalid input or published files:\n{log}')
print('Missing SDK and Clang error both rejected before publishing output')
