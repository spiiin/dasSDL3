"""Check committed shader/source integrity without requiring a shader compiler."""
import hashlib
import json
from pathlib import Path

assets = Path(__file__).resolve().parents[1] / 'examples/assets/shaders'
manifest = json.loads((assets / 'triangle-manifest.json').read_text())
expected = {f'triangle.{stage}.{ext}' for stage in ('vert', 'frag') for ext in ('hlsl', 'spv', 'dxil')}
assert set(manifest['files']) == expected
assert manifest['entrypoint'] == 'main' and manifest['resources'] == 'none'
for name, digest in manifest['files'].items():
    data = (assets / name).read_bytes()
    assert hashlib.sha256(data).hexdigest() == digest, f'Changed shader asset: {name}'
    if name.endswith('.spv'): assert data[:4] == bytes([3, 2, 35, 7]) and len(data) % 4 == 0
    if name.endswith('.dxil'): assert data[:4] == b'DXBC'
print('Triangle assets: source/binary hashes and format headers PASS')
