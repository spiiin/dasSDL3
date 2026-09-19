"""Malformed headers and missing exports must fail before publishing parity output."""
from pathlib import Path
import subprocess
import sys
import tempfile
import shutil
import re

generator, daslang, sdk, include = sys.argv[1:]
with tempfile.TemporaryDirectory(prefix='sdl-parity-errors-') as temp:
    root = Path(temp)
    headers = root / 'include' / 'SDL3'
    shutil.copytree(Path(include) / 'SDL3', headers)
    original_header = (headers / 'SDL.h').read_text(encoding='utf-8')
    version = headers / 'SDL_version.h'
    original_version = version.read_text(encoding='utf-8')
    audio = headers / 'SDL_audio.h'
    original_audio = audio.read_text(encoding='utf-8')
    for source, diagnostic, audio_replacement in (
        ('#error deliberate_parity_failure\n' + original_header, 'error: deliberate_parity_failure', None),
        (original_header, 'wrong_argument', None),
        (original_header, 'Fields differ from policy', 'int renamed_channels;'),
        (original_header, 'Unsupported field layout SDL_AudioSpec.channels', 'int channels : 4;'),
    ):
        version.write_text(original_version, encoding='utf-8')
        audio.write_text(original_audio, encoding='utf-8')
        if diagnostic == 'wrong_argument':
            assert 'SDL_GetVersion(void)' in original_version
            version.write_text(original_version.replace('SDL_GetVersion(void)', 'SDL_GetVersion(int wrong_argument)'), encoding='utf-8')
        if audio_replacement:
            modified, count = re.subn(r'\bint\s+channels\s*;', audio_replacement, original_audio)
            assert count == 1
            audio.write_text(modified, encoding='utf-8')
        (headers / 'SDL.h').write_text(source, encoding='utf-8')
        output = root / 'unpublished'
        result = subprocess.run([sys.executable, generator, '--daslang', daslang,
            '--sdl-include', str(headers.parent), '--sdk', sdk, '--output', str(output)],
            capture_output=True, text=True, errors='replace')
        log = result.stdout + result.stderr
        if result.returncode == 0 or diagnostic not in log or output.exists():
            raise SystemExit(f'Invalid header or signature mismatch accepted:\n{log}')
print('Clang errors, changed signatures, missing fields and bitfields rejected before publishing output')
