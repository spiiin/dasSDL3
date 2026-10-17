"""Convert pinned bgfx 36-sky assets; runtime rendering does not need bgfx.

python tools/build_bgfx_sky_assets.py --bgfx C:/src/bgfx [--check]
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

COMMIT = "7e3060ccb97959dcda3f091b96d82515197028e0"
SOURCES = {
    "meshes/test_scene.bin": "877b33ecdef407be7fd58278da197dae064f24da7b4b3060726d32b44434f79d",
    "textures/lightmap.ktx": "1eb3bb0083ab0647b8728694be625b4097dde9ffbbc93a5b580f916e093a3f70",
}


def mesh(data):
    at = 0
    vertices, indices = [], []
    while at < len(data):
        tag = data[at:at + 4]
        at += 4
        if tag == b"VB \x01":
            at += 104  # sphere, AABB, OBB
            count, stride = struct.unpack_from("<BH", data, at)
            at += 3
            attributes = []
            for _ in range(count):
                attributes.append(struct.unpack_from("<HHBHBB", data, at))
                at += 9
            assert stride == 24 and attributes == [(0, 1, 3, 4, 0, 0), (20, 2, 4, 1, 1, 1), (12, 16, 2, 4, 0, 0)]
            count, = struct.unpack_from("<H", data, at)
            at += 2
            base = len(vertices)
            for i in range(count):
                offset = at + i * stride
                position = struct.unpack_from("<3f", data, offset)
                uv = struct.unpack_from("<2f", data, offset + 12)
                normal = tuple(v / 127.5 - 1 for v in data[offset + 20:offset + 23])
                vertices.append(position + normal + uv)
            at += count * stride
        elif tag == b"IB \x00":
            count, = struct.unpack_from("<I", data, at)
            at += 4
            indices.extend(base + v for v in struct.unpack_from(f"<{count}H", data, at))
            at += count * 2
        elif tag == b"PRI\x00":
            size, = struct.unpack_from("<H", data, at)
            at += 2 + size
            count, = struct.unpack_from("<H", data, at)
            at += 2
            for _ in range(count):
                size, = struct.unpack_from("<H", data, at)
                at += 2 + size + 16 + 104
        else:
            raise ValueError(f"Unexpected mesh chunk {tag!r}")
    assert at == len(data) and len(vertices) == 5247 and len(indices) == 7680
    return (struct.pack("<4sIII", b"MSH2", len(vertices), len(indices), 32)
            + b"".join(struct.pack("<8f", *v) for v in vertices)
            + struct.pack(f"<{len(indices)}I", *indices))


def lightmap(data):
    assert data[:12] == b"\xabKTX 11\xbb\r\n\x1a\n"
    assert struct.unpack_from("<13I", data, 12) == (0x04030201, 0, 1, 0, 0x8229, 0x1903, 1024, 1024, 0, 0, 1, 1, 0)
    assert struct.unpack_from("<I", data, 64)[0] == 1024 * 1024
    assert len(data) == 68 + 1024 * 1024
    return b"".join(bytes((v, v, v, 255)) for v in data[68:])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bgfx", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    source = {}
    for name, digest in SOURCES.items():
        data = (args.bgfx / "examples/runtime" / name).read_bytes()
        if hashlib.sha256(data).hexdigest() != digest:
            raise ValueError(f"Source hash mismatch: {name}; expected bgfx {COMMIT}")
        source[name] = data
    outputs = {"sky-landscape.mesh": mesh(source["meshes/test_scene.bin"]),
               "sky-lightmap.rgba8": lightmap(source["textures/lightmap.ktx"])}
    manifest = {"source": f"https://github.com/bkaradzic/bgfx/tree/{COMMIT}/examples/runtime",
                "license": "../LICENSE-bgfx.txt", "source_sha256": SOURCES,
                "output_sha256": {k: hashlib.sha256(v).hexdigest() for k, v in outputs.items()},
                "mesh": {"vertices": 5247, "indices": 7680, "stride": 32},
                "lightmap": {"width": 1024, "height": 1024, "format": "RGBA8"}}
    outputs["sky-assets.json"] = (json.dumps(manifest, indent=2) + "\n").encode()
    target = Path(__file__).resolve().parents[1] / "examples/gpu_port_bgfx/assets"
    for name, data in outputs.items():
        if args.check:
            assert (target / name).read_bytes() == data, f"Stale asset: {name}"
        else:
            (target / name).write_bytes(data)
    print("sky assets: verified" if args.check else "sky assets: generated")


if __name__ == "__main__":
    main()
