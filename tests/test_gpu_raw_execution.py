"""Require actual script call receipts plus data oracles, not exported names."""
import json
import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
contract = json.loads((root / 'tests/gpu_raw_coverage.json').read_text())
inventory = json.loads((root / 'docs/generated/api-windows-x64-msvc.json').read_text())
gpu_functions = {s['name'] for s in inventory['symbols']
                 if s['kind'] == 'function' and s.get('header') == 'SDL_gpu.h'}
if set(contract['functions']) != gpu_functions:
    raise SystemExit('Raw GPU coverage matrix differs from pinned active header census')
assets = root / 'tests/assets/raw_gpu'
for name, digest in json.loads((assets / 'manifest.json').read_text()).items():
    if hashlib.sha256((assets / name).read_bytes()).hexdigest() != digest:
        raise SystemExit(f'Shader asset hash mismatch: {name}')
script = (root / 'tests/gpu_raw.das').read_text()
calls = set(re.findall(r'\b(SDL_\w+)\s*\(', script))
if set(contract['functions']) - calls:
    raise SystemExit('Coverage manifest has functions absent from script calls')
driver = os.environ.get('SDL_GPU_DRIVER', '')
command = [sys.argv[1], str(root / 'tests/gpu_raw.das')]
if 'aot' not in Path(sys.argv[1]).stem:
    command.append('--smoke-test')
env = dict(os.environ, SDL_ASSERT='abort')
result = subprocess.run(command, capture_output=True, text=True, errors='replace', env=env, timeout=80)
output = result.stdout + result.stderr
print(output)
if result.returncode:
    raise SystemExit(f'Raw execution failed: {result.returncode}')
if re.search(r'VUID-|Validation Error|D3D12 (?:ERROR|CORRUPTION)', output):
    raise SystemExit('Backend validation failed')
actual = set(re.findall(r'^RAW_CALL (SDL_\w+)$', output, re.M))
excluded = set(contract['backend_exclusions'].get(driver, []))
expected = set(contract['functions']) - excluded
if expected - actual:
    raise SystemExit(f'Unexecuted raw calls: {sorted(expected - actual)}')
if 'RAW GPU pixels, transfers, direct/indirect compute and swapchain PASS' not in output:
    raise SystemExit('Missing completed data oracles')
print(f'Raw execution coverage: {len(actual & expected)}/{len(contract["functions"])} '
      f'({len(expected)} required on this backend); exclusions: {sorted(excluded)}')
