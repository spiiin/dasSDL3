"""Prepare pinned bgfx bump/HDR textures; normal builds use the shipped bytes."""
import argparse
import hashlib
import json
import struct
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMIT = "7e3060ccb97959dcda3f091b96d82515197028e0"
SOURCES = {
    "fieldstone-n.tga": ("examples/06-bump/fieldstone-n.tga", "ec14b58cfca90a0ad61ba39a0cb3b0e33053c27dbf739f17099f992915239976"),
    "fieldstone-rgba.tga": ("examples/06-bump/fieldstone-rgba.tga", "294ece0321ba500339160877f11216acd27703971c871341ce34dc44e65c217f"),
    "uffizi.ktx": ("examples/runtime/textures/uffizi.ktx", "f0a7e3a636632c199f1000165e5a316727c7f1958f0732bfc9d7b28f35f5e615"),
}
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--source-dir", type=Path)
parser.add_argument("--check", action="store_true")
args = parser.parse_args()
dest = ROOT / "examples/gpu/textures"
dest.mkdir(exist_ok=True)
manifest = {}
for name, (source, digest) in SOURCES.items():
    url = f"https://raw.githubusercontent.com/bkaradzic/bgfx/{COMMIT}/{source}"
    data = (args.source_dir / name).read_bytes() if args.source_dir else urllib.request.urlopen(url, timeout=90).read()
    assert hashlib.sha256(data).hexdigest() == digest, name
    if name.endswith(".tga"):
        assert data[0:3] == bytes([0, 0, 2]) and data[16:18] == bytes([24, 0])
        width, height = struct.unpack_from("<HH", data, 12)
        out = bytearray()
        for y in reversed(range(height)):
            for x in range(width):
                b, g, r = data[18 + (y * width + x) * 3:21 + (y * width + x) * 3]
                out.extend((r, g, b, 255))
        target = name.replace(".tga", ".rgba8")
    else:
        header = struct.unpack_from("<13I", data, 12)
        assert data[:12] == b"\xabKTX 11\xbb\r\n\x1a\n" and header[0] == 0x04030201
        assert header[4] == 0x881A and header[6:8] == (512, 512) and header[10:13] == (6, 1, 0)
        assert struct.unpack_from("<I", data, 64)[0] == 512 * 512 * 8
        out = data[68:]
        assert len(out) == 6 * 512 * 512 * 8
        width = height = 512
        target = "uffizi.rgba16f"
    manifest[target] = {"source": url, "source_sha256": digest, "sha256": hashlib.sha256(out).hexdigest(), "width": width, "height": height}
    if args.check:
        assert (dest / target).read_bytes() == out, target
    else:
        (dest / target).write_bytes(out)
if args.check:
    assert json.loads((dest / "manifest.json").read_text()) == manifest
else:
    (dest / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", newline="\n")
print("bgfx bump/HDR assets: PASS")
