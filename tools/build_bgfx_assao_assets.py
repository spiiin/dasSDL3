"""Convert original bgfx 39-assao OBJ meshes and DDS ground texture offline."""
import argparse, hashlib, json
from pathlib import Path
from build_bgfx_11_14_assets import obj, dds
PINNED = json.loads(r'''
{
  "bgfx_commit": "7e3060ccb97959dcda3f091b96d82515197028e0",
  "files": {
    "assao-cube.msh": {
      "source": "examples/assets/meshes/cube.obj",
      "source_sha256": "afff12bc06daad03ff9cd0fdd067197c13399256534d3858321fb41437ff8524",
      "sha256": "0e09aa879c882f309b28ef2caff67e3ee7939b4d929dd9e0a944ad03e7faced0"
    },
    "assao-orb.msh": {
      "source": "examples/assets/meshes/orb.obj",
      "source_sha256": "5c85a7639f89fe732b3f352124e5eaee4be005ef3819ade630622143d68bd1cf",
      "sha256": "81ab82d1f9dda21cd73d30f82a422d1de4187465ae6b4ee6e864bd83f890a942"
    },
    "assao-column.msh": {
      "source": "examples/assets/meshes/column.obj",
      "source_sha256": "aacb36ab76aef94846790c98f8b26c8046699f21fb636d8394e9085dd258bcb8",
      "sha256": "d037e90cd9fac2836e46b6bcf0308705895a9df8a9e0294de27e401f02a18c28"
    },
    "assao-bunny_decimated.msh": {
      "source": "examples/assets/meshes/bunny_decimated.obj",
      "source_sha256": "3f87d7ef0b64b046b8d432ebdf2397e039548629d8a7094aa29f9e53fb377fdd",
      "sha256": "db4895117a761a69f3cb6991f28c6fa6ed1fd22547601052b801cc73f015fdd9"
    },
    "assao-tree.msh": {
      "source": "examples/assets/meshes/tree.obj",
      "source_sha256": "89c456975f91c240e81651b4aa212dc8a2dad4be1cd2ca9919ba7e787f421dde",
      "sha256": "13023590337a5766782a1f1706ba5775bff5ff9f8564e9951dea11fd0d1536c6"
    },
    "assao-hollowcube.msh": {
      "source": "examples/assets/meshes/hollowcube.obj",
      "source_sha256": "20f57ed117f4b4ce3f870e7af7b442cdec87570c3d72095adc6d8b8d99b668e6",
      "sha256": "4ab8c351c58c9420239ba3959243d64a4640f217d412796680d094113d9b354a"
    },
    "assao-fieldstone.rgba8": {
      "source": "examples/runtime/textures/fieldstone-rgba.dds",
      "source_sha256": "3e6aecabf01a8dd2c812fec76b15e02e2124df01c1cd7458519880269c0c9104",
      "sha256": "362dbf8e83a056f382e28970593459e72438b550f6fb684d26a5369927e8e0e7",
      "width": 512,
      "height": 512
    }
  }
}
''')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bgfx',type=Path,required=True)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    target=Path(__file__).resolve().parents[1]/'examples/gpu_port_bgfx/assets'
    for name, info in PINNED['files'].items():
        source=(args.bgfx/info['source']).read_bytes()
        assert hashlib.sha256(source).hexdigest()==info['source_sha256'], info['source']
        if name.endswith('.msh'): data=obj(source)
        else:
            data,width,height=dds(source)
            assert (width,height)==(info['width'],info['height'])
        assert hashlib.sha256(data).hexdigest()==info['sha256'],name
        if args.check: assert (target/name).read_bytes()==data,name
        else: (target/name).write_bytes(data)
    manifest=(json.dumps(PINNED,indent=2)+'\n').encode()
    if args.check: assert (target/'assao-manifest.json').read_bytes()==manifest
    else: (target/'assao-manifest.json').write_bytes(manifest)
    print('ASSAO assets: verified' if args.check else 'ASSAO assets: generated')

if __name__=='__main__': main()
