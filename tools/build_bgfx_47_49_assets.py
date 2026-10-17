"""Convert pinned bgfx pixel-format samples; retain compressed GPU blocks verbatim."""
import argparse,hashlib,json,struct,colorsys,re
from pathlib import Path
import numpy as np
from PIL import Image
from build_bgfx_11_14_assets import PIN

def payload(w,h,bw,bh,bpp,levels):
    out=bytearray(16+len(levels)*16);struct.pack_into('<4I',out,0,w,h,len(levels),0)
    for i,data in enumerate(levels):
        wi=max(1,w>>i);hi=max(1,h>>i);cols=(wi+bw-1)//bw;rows=(hi+bh-1)//bh
        pitch=(cols*bpp+255)//256*256;off=(len(out)+511)//512*512;out.extend(bytes(off-len(out)))
        assert len(data)==cols*rows*bpp,(i,len(data),cols*rows*bpp)
        for row in range(rows):out.extend(data[row*cols*bpp:(row+1)*cols*bpp]);out.extend(bytes(pitch-cols*bpp))
        struct.pack_into('<4I',out,16+i*16,off,pitch//bpp*bw,rows*bh,len(data))
    return bytes(out)
def ktx(b):
    h=struct.unpack_from('<13I',b,12);assert h[0]==0x04030201
    at=64+h[12];levels=[]
    for i in range(h[11]):
        n=struct.unpack_from('<I',b,at)[0];at+=4;levels.append(b[at:at+n]);at+=(n+3)//4*4
    return h[6],h[7],levels

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--bgfx',type=Path,required=True);ap.add_argument('--check',action='store_true');a=ap.parse_args()
    root=Path(__file__).resolve().parents[1];dest=root/'examples/gpu_port_bgfx/assets';src=a.bgfx/'examples/runtime/textures';manifest={'bgfx_commit':PIN,'files':{}}
    def emit(name,data,source):
        b=(a.bgfx/source).read_bytes();manifest['files'][name]={'source':source,'source_sha256':hashlib.sha256(b).hexdigest(),'sha256':hashlib.sha256(data).hexdigest()}
        if a.check:assert (dest/name).read_bytes()==data,name
        else:(dest/name).write_bytes(data)
    b=(src/'aerial_rocks_04_diff_2k.ktx').read_bytes();w,h,levels=ktx(b)
    emit('hextile.tex',payload(w,h,4,4,16,levels),'examples/runtime/textures/aerial_rocks_04_diff_2k.ktx')
    wheel=np.zeros((256,256,4),dtype=np.float32)
    for y in range(256):
        for x in range(256):
            rx=(x-128)/128;ry=(y-128)/128;v=1-min(1,(rx*rx+ry*ry)**.5)
            wheel[y,x]=(*colorsys.hsv_to_rgb((np.arctan2(ry,rx)/(2*np.pi))%1,1,v),v)
    wheel[220:236,:16]=(1,0,0,1);wheel[220:236,16:32]=(0,1,0,1);wheel[220:236,32:48]=(0,0,1,1)
    for x in range(48):wheel[236:252,x]=(1,1,1,1-x/48)
    sources=[('Hue Wheel',wheel,'examples/47-pixelformats/pixelformats.cpp')]
    for name in ['pf_alpha_test.dds','pf_uv_filtering_test.dds','texture_compression_rgba8.dds']:
        sources.append((name,np.asarray(Image.open(src/name).convert('RGBA'),dtype=np.float32)/255,f'examples/runtime/textures/{name}'))
    entries=[]
    for sample,(_,rgba,source) in enumerate(sources):
        h,w=rgba.shape[:2];formats={}
        for bits in (8,16):
            for channels,label in [(1,f'R{bits}'),(2,f'R{bits}G{bits}'),(4,f'R{bits}G{bits}B{bits}A{bits}')]:
                for signed,suffix in [(False,'UNORM'),(True,'SNORM')]:
                    maximum=(1<<(bits-int(signed)))-1;dtype=('<i' if signed else '<u')+str(bits//8)
                    formats[label+'_'+suffix]=np.rint(rgba[:,:,:channels]*maximum).astype(dtype).tobytes()
        formats['A8_UNORM']=np.rint(rgba[:,:,3]*255).astype('u1').tobytes()
        for bits in (16,32):
            for ch,label in [(1,f'R{bits}'),(2,f'R{bits}G{bits}'),(4,f'R{bits}G{bits}B{bits}A{bits}')]:formats[label+'_FLOAT']=rgba[:,:,:ch].astype('<f'+str(bits//8)).tobytes()
        formats['B8G8R8A8_UNORM']=np.rint(rgba[:,:,[2,1,0,3]]*255).astype('u1').tobytes()
        for name,widths,order in [('B5G6R5_UNORM',[5,6,5],[2,1,0]),('B5G5R5A1_UNORM',[5,5,5,1],[2,1,0,3]),('B4G4R4A4_UNORM',[4,4,4,4],[2,1,0,3]),('R10G10B10A2_UNORM',[10,10,10,2],[0,1,2,3])]:
            packed=np.zeros((h,w),dtype=np.uint32);shift=0
            for bits,c in zip(widths,order):packed|=np.rint(rgba[:,:,c]*((1<<bits)-1)).astype(np.uint32)<<shift;shift+=bits
            formats[name]=packed.astype('<u'+str(shift//8)).tobytes()
        packed=np.zeros((h,w),dtype=np.uint32)
        for c,bits,shift in [(0,11,0),(1,11,11),(2,10,22)]:
            half=rgba[:,:,c].astype('<f2').view('<u2').astype(np.uint32);packed|=((half+(1<<(15-bits-1)))>>(15-bits))<<shift
        formats['R11G11B10_UFLOAT']=packed.astype('<u4').tobytes()
        for base in ['R8G8B8A8_UNORM','B8G8R8A8_UNORM']:formats[base+'_SRGB']=formats[base]
        for name,data in formats.items():
            file=f'pf-{sample}-{name}.tex';emit(file,payload(w,h,1,1,len(data)//(w*h),[data]),source);entries.append((sample,name,file,w,h))
    for name,fmt,bw,bh,bpp in [(f'bc{i}',f'BC{i}_RGBA_UNORM',4,4,8 if i==1 else 16) for i in (1,2,3,7)]+[(f'astc_{x}x{y}',f'ASTC_{x}x{y}_UNORM',x,y,16) for x,y in [(4,4),(5,4),(5,5),(6,5),(6,6),(8,5),(8,6),(8,8),(10,5),(10,6),(10,8),(10,10),(12,10),(12,12)]]:
        ext='ktx' if name.startswith('bc') else 'dds';source=f'examples/runtime/textures/texture_compression_{name}.{ext}';b=(a.bgfx/source).read_bytes()
        if ext=='ktx':w,h,levels=ktx(b);data=levels[0]
        else:h,w=struct.unpack_from('<II',b,12);data=b[128:128+((w+bw-1)//bw)*((h+bh-1)//bh)*bpp]
        file=f'pf-3-{fmt}.tex';emit(file,payload(w,h,bw,bh,bpp,[data]),source);entries.append((3,fmt,file,w,h))
    catalog='options gen2\nmodule format_catalog shared public\nrequire dassdl3/sdl3_boost public\nstruct Sample { set_index : int; name,file : string; format : SDL_GPUTextureFormat; width,height : uint }\ndef samples() { return <- array(\n'+',\n'.join(f'Sample(set_index={i},name="{fmt}",file="{file}",format=SDL_GPUTextureFormat.TEXTUREFORMAT_{fmt},width={w}u,height={h}u)' for i,fmt,file,w,h in entries)+'\n) }\n'
    target=root/'examples/gpu_port_bgfx/example_37_pixelformats/format_catalog.das'
    if a.check:assert target.read_text()==catalog
    else:target.write_bytes(catalog.encode())
    path=dest/'ports47-49-manifest.json'
    if a.check:assert json.loads(path.read_text())==manifest
    else:path.write_text(json.dumps(manifest,indent=2)+'\n')
    print(f'{len(entries)} format samples + complete BC7 mip chain: PASS')
if __name__=='__main__':main()
