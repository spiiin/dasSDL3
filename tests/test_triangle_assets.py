"""Check committed shader/source integrity without requiring a shader compiler."""
import hashlib
import json
from pathlib import Path

assets = Path(__file__).resolve().parents[1] / 'examples/assets/shaders'
for prefix, resources in [('colored_instances','vertex uniform 0: camera columns, 64 bytes; fragment uniform 0: light direction/ambient, 16 bytes; fragment sampler 0'), ('instances','vertex uniform 0: camera columns, 64 bytes; fragment uniform 0: light direction/ambient, 16 bytes; fragment sampler 0'), ('lit','vertex uniform 0: MVP and normal columns, 112 bytes; fragment uniform 0: light direction/ambient, 16 bytes; fragment sampler 0'), ('triangle','none'), ('mesh','fragment sampler 0'), ('transform','vertex uniform 0: two float4 rows, 32 bytes; fragment sampler 0'), ('scene3d','vertex uniform 0: four float4 columns, 64 bytes; no samplers')]:
    manifest = json.loads((assets / f'{prefix}-manifest.json').read_text())
    expected = {f'{prefix}.{stage}.{ext}' for stage in ('vert', 'frag') for ext in ('hlsl', 'spv', 'dxil')}
    assert set(manifest['files']) == expected
    assert manifest['entrypoint'] == 'main' and manifest['resources'] == resources
    for name, digest in manifest['files'].items():
        data = (assets / name).read_bytes()
        assert hashlib.sha256(data).hexdigest() == digest, f'Changed shader asset: {name}'
        if name.endswith('.spv'): assert data[:4] == bytes([3, 2, 35, 7]) and len(data) % 4 == 0
        if name.endswith('.dxil'): assert data[:4] == b'DXBC'
print('Triangle/mesh assets: source/binary hashes and format headers PASS')
