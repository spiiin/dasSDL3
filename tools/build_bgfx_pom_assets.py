"""Decode pinned bgfx POM/particle KTX base levels; no runtime decoder dependency."""
import argparse, hashlib, json, struct
from pathlib import Path
from build_bgfx_11_14_assets import dds
PINS = {'parallax-d': 'b9009b62ba8205ab9d52e263c06fa3d97e68dc3de29c73a9d4462ec42411c9a8', 'parallax-n': 'eb02c6e49d1bade912ead1ddbd183b1cb9ad52f66e423f4b260e882fa4817f2d', 'parallax-h': 'f701a7861ef5788cd0008b71a96641de0b5751a1a20b9b335333c6d376b4bc8d', 'particle': '95d1a189c31d7d94a07ec3a8662a6800ca11c7be63271746805d8f16cef1da29'}

def bc4(block):
    a,b=block[:2];bits=int.from_bytes(block[2:8],'little')
    values=[a,b]+([(a*(7-i)+b*i)//7 for i in range(1,7)] if a>b else [(a*(5-i)+b*i)//5 for i in range(1,5)]+[0,255])
    return [values[(bits>>(3*i))&7] for i in range(16)]

def decode(data):
    assert data[:12]==b'\xabKTX 11\xbb\r\n\x1a\n'
    h=struct.unpack_from('<13I',data,12);assert h[0]==0x04030201
    w,ht=h[6:8];off=64+h[12];size=struct.unpack_from('<I',data,off)[0];payload=data[off+4:off+4+size]
    if h[4]==0x8c4e:
        header=bytearray(128);header[:4]=b'DDS ';struct.pack_into('<II',header,12,ht,w);header[84:88]=b'DXT3'
        return dds(bytes(header)+payload)
    if h[4]==0x8c72:
        out=bytearray(w*ht*4);at=0
        for y in range(0,ht,4):
            for x in range(0,w,4):
                red=bc4(payload[at:at+8]);green=bc4(payload[at+8:at+16]);at+=16
                for j in range(4):
                    for i in range(4):
                        p=((y+j)*w+x+i)*4;k=j*4+i;out[p:p+4]=bytes([red[k],green[k],255,255])
        return bytes(out),w,ht
    if h[4]==0x8229:
        assert len(payload)==w*ht
        return bytes(v for a in payload for v in (a,a,a,255)),w,ht
    assert h[4]==0x8058 and len(payload)==w*ht*4
    return payload,w,ht

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source-dir',type=Path,required=True);p.add_argument('--check',action='store_true');a=p.parse_args()
    dest=Path(__file__).resolve().parents[1]/'examples/gpu_port_bgfx/assets';manifest={}
    for name,digest in PINS.items():
        source=f'examples/runtime/textures/{name}.ktx';data=(a.source_dir/source).read_bytes();assert hashlib.sha256(data).hexdigest()==digest
        output,w,h=decode(data);target=dest/(name+'.rgba8')
        manifest[name]={'source':source,'source_sha256':digest,'sha256':hashlib.sha256(output).hexdigest(),'width':w,'height':h}
        if a.check:assert target.read_bytes()==output
        else:target.write_bytes(output)
    path=dest/'picking-pom-particles-manifest.json'
    if a.check:assert json.loads(path.read_text())==manifest
    else:path.write_text(json.dumps(manifest,indent=2)+'\n',newline='\n')
    print('POM/particle assets: PASS')
if __name__=='__main__':main()
