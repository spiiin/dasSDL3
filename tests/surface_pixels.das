options gen2
require math
require daslib/defer
require dassdl3/sdl3_surface_pixels_boost

def expect_pixel(surface : SDL_Surface?; x,y : int; expected : uint4) {
    var r,g,b,a : uint
    verify(is_ok(read_surface_pixel(surface,x,y,r,g,b,a)) && uint4(r,g,b,a)==expected)
}
def formats_and_palettes {
    let fmt=SDL_PixelFormat.PIXELFORMAT_RGBA32
    var bpp : int;var rm,gm,bm,am : uint
    unsafe {verify(SDL_GetMasksForPixelFormat(fmt,addr(bpp),addr(rm),addr(gm),addr(bm),addr(am)))}
    verify(bpp==32 && SDL_GetPixelFormatForMasks(bpp,rm,gm,bm,am)==fmt)
    verify(SDL_GetMasksForPixelFormatRef(fmt,bpp,rm,gm,bm,am) && bpp==32)
    verify(SDL_GetPixelFormatName(SDL_PixelFormat.PIXELFORMAT_RGB565)=="SDL_PIXELFORMAT_RGB565")
    var info : SDL_PixelFormatDetails;verify(SDL_GetPixelFormatDetailsCopy(fmt,info) && info.bytes_per_pixel==uint8(4))
    let details=SDL_GetPixelFormatDetails(fmt);verify(details!=null)
    var r,g,b,a : uint8
    unsafe {
        let rgb=SDL_MapRGB(details,null,17u,34u,51u)
        SDL_GetRGB(rgb,details,null,addr(r),addr(g),addr(b))
        verify(r==uint8(17) && g==uint8(34) && b==uint8(51))
        let rgba=SDL_MapRGBA(details,null,11u,22u,33u,44u)
        SDL_GetRGBA(rgba,details,null,addr(r),addr(g),addr(b),addr(a))
        verify(r==uint8(11) && g==uint8(22) && b==uint8(33) && a==uint8(44))
    }
    var rr,gg,bb,aa : uint
    let mapped=SDL_MapRGBARef(info,null,11u,22u,33u,44u)
    SDL_GetRGBARef(mapped,info,null,rr,gg,bb,aa);verify(uint4(rr,gg,bb,aa)==uint4(11u,22u,33u,44u))
    SDL_GetRGBRef(SDL_MapRGBRef(info,null,17u,34u,51u),info,null,rr,gg,bb);verify(uint3(rr,gg,bb)==uint3(17u,34u,51u))
    var colors : array<SDL_Color>;resize(colors,2)
    colors[0].r=uint8(255);colors[0].a=uint8(255);colors[1].b=uint8(255);colors[1].a=uint8(255)
    let palette=SDL_CreatePalette(2);verify(palette!=null)
    unsafe {verify(SDL_SetPaletteColors(palette,addr(colors[0]),0,2))}
    let surface=SDL_CreateSurface(2,1,SDL_PixelFormat.PIXELFORMAT_INDEX8);verify(surface!=null)
    verify(SDL_SetSurfacePalette(surface,palette) && SDL_GetSurfacePalette(surface)==palette)
    SDL_DestroyPalette(palette) // Surface retains its own reference.
    verify(SDL_FillSurfaceAll(surface,1u));expect_pixel(surface,0,0,uint4(0u,0u,255u,255u))
    let owned_by_surface=SDL_CreateSurfacePalette(surface);verify(owned_by_surface!=null && owned_by_surface==SDL_GetSurfacePalette(surface))
    verify(SDL_SetPaletteColorsArray(owned_by_surface,colors,0))
    verify(SDL_FillSurfaceAll(surface,0u));expect_pixel(surface,1,0,uint4(255u,0u,0u,255u))
    let indexed=SDL_GetPixelFormatDetails(SDL_PixelFormat.PIXELFORMAT_INDEX8)
    verify(SDL_MapRGB(indexed,owned_by_surface,0u,0u,255u)==1u)
    verify(SDL_SetSurfacePalette(surface,null) && SDL_GetSurfacePalette(surface)==null)
    SDL_DestroySurface(surface)
    var entered=false
    let scoped=with_palette(2) $(p : SDL_Palette?) {entered=true;verify(SDL_SetPaletteColorsArray(p,colors,0));return sdl_ok()} |> is_ok
    verify(scoped && entered)
    verify(!with_palette(0) $(p : SDL_Palette?) {verify(false)
        return sdl_ok()
    } |> is_ok)
    verify(SDL_GetPixelFormatDetailsCopy(SDL_PixelFormat.PIXELFORMAT_UNKNOWN,info) && info.bits_per_pixel==uint8(0))
}
def external_pixels_and_images {
    var bytes : array<uint8>;resize(bytes,24)
    for(i in 0 .. 24) {bytes[i]=uint8(99)}
    var surface : SDL_Surface?
    unsafe {surface=SDL_CreateSurfaceFrom(2,2,SDL_PixelFormat.PIXELFORMAT_RGBA32,addr(bytes[0]),12)}
    verify(surface!=null)
    verify(SDL_LockSurface(surface))
    bytes[0]=uint8(11);bytes[1]=uint8(22);bytes[2]=uint8(33);bytes[3]=uint8(255)
    SDL_UnlockSurface(surface)
    expect_pixel(surface,0,0,uint4(11u,22u,33u,255u))
    let locked=with_surface_lock(surface) {bytes[12]=uint8(44);return sdl_ok()} |> is_ok;verify(locked)
    verify(SDL_WriteSurfacePixel(surface,1,1,50u,60u,70u,80u))
    verify(bytes[16]==uint8(50) && bytes[19]==uint8(80) && bytes[20]==uint8(99))
    var r,g,b,a : uint8
    unsafe {verify(SDL_ReadSurfacePixel(surface,1,1,addr(r),addr(g),addr(b),addr(a)))}
    verify(r==uint8(50) && g==uint8(60) && b==uint8(70) && a==uint8(80))
    verify(SDL_WriteSurfacePixelFloat(surface,0,1,1.0,0.0,0.0,1.0))
    var fr,fg,fb,fa : float
    unsafe {verify(SDL_ReadSurfacePixelFloat(surface,0,1,addr(fr),addr(fg),addr(fb),addr(fa)))}
    verify(fr==1.0 && fg==0.0 && fb==0.0 && fa==1.0)
    verify(is_ok(read_surface_pixel_float(surface,0,1,fr,fg,fb,fa)) && fr==1.0)
    verify(!SDL_WriteSurfacePixel(surface,2,1,0u,0u,0u,0u))
    var er,eg,eb,ea : uint;verify(!is_ok(read_surface_pixel(surface,-1,0,er,eg,eb,ea)))
    verify(!SDL_SurfaceHasAlternateImages(surface))
    let alternate=SDL_CreateSurface(4,4,SDL_PixelFormat.PIXELFORMAT_RGBA32);verify(alternate!=null)
    verify(SDL_ClearSurface(alternate,0.0,1.0,0.0,1.0) && SDL_AddSurfaceAlternateImage(surface,alternate))
    SDL_DestroySurface(alternate) // Parent now owns the retained reference.
    verify(SDL_SurfaceHasAlternateImages(surface))
    unsafe {
        var count : int;let images=SDL_GetSurfaceImages(surface,addr(count))
        verify(images!=null && count==2 && images[0]==surface && images[2]==null)
        expect_pixel(images[1],3,3,uint4(0u,255u,0u,255u));SDL_free(images)
    }
    var copies : array<SDL_Surface?>;verify(SDL_GetSurfaceImagesCopy(surface,copies) && length(copies)==2 && copies[0]==surface)
    expect_pixel(copies[1],3,3,uint4(0u,255u,0u,255u))
    resize(copies,0);SDL_RemoveSurfaceAlternateImages(surface);verify(!SDL_SurfaceHasAlternateImages(surface))
    SDL_DestroySurface(surface)
    bytes[0]=uint8(123);verify(bytes[0]==uint8(123)) // External storage remains ours.
}
def transforms {
    let surface=SDL_CreateSurface(2,2,SDL_PixelFormat.PIXELFORMAT_RGBA32);verify(surface!=null)
    {
        defer(){SDL_DestroySurface(surface)}
        verify(SDL_ClearSurface(surface,0.0,0.0,0.0,1.0))
        verify(SDL_WriteSurfacePixel(surface,0,0,255u,0u,0u,255u))
        verify(SDL_WriteSurfacePixel(surface,1,1,0u,0u,255u,255u))
        verify(SDL_WriteSurfacePixel(surface,1,0,128u,128u,128u,255u))
        verify(SDL_MapSurfaceRGB(surface,255u,0u,0u)==SDL_MapSurfaceRGBA(surface,255u,0u,0u,255u))
        let duplicate=SDL_DuplicateSurface(surface);verify(duplicate!=null)
        verify(SDL_FlipSurface(duplicate,SDL_FlipMode.FLIP_HORIZONTAL));expect_pixel(duplicate,1,0,uint4(255u,0u,0u,255u))
        verify(SDL_FlipSurface(duplicate,SDL_FlipMode.FLIP_VERTICAL));expect_pixel(duplicate,1,1,uint4(255u,0u,0u,255u));SDL_DestroySurface(duplicate)
        expect_pixel(surface,0,0,uint4(255u,0u,0u,255u))
        let scaled=SDL_ScaleSurface(surface,4,4,SDL_ScaleMode.SCALEMODE_NEAREST);verify(scaled!=null)
        expect_pixel(scaled,1,1,uint4(255u,0u,0u,255u));expect_pixel(scaled,3,3,uint4(0u,0u,255u,255u));SDL_DestroySurface(scaled)
        let converted=SDL_ConvertSurface(surface,SDL_PixelFormat.PIXELFORMAT_BGRA32);verify(converted!=null)
        expect_pixel(converted,0,0,uint4(255u,0u,0u,255u));SDL_DestroySurface(converted)
        let linear=SDL_ConvertSurfaceAndColorspace(surface,SDL_PixelFormat.PIXELFORMAT_RGBA128_FLOAT,null,SDL_Colorspace.COLORSPACE_SRGB_LINEAR,0u);verify(linear!=null)
        var r,g,b,a : float;verify(is_ok(read_surface_pixel_float(linear,0,0,r,g,b,a)) && r==1.0 && g==0.0 && a==1.0);verify(is_ok(read_surface_pixel_float(linear,1,0,r,g,b,a)) && abs(r-0.21586)<0.001 && abs(g-r)<0.001);SDL_DestroySurface(linear)
        let dup_ok=with_duplicate_surface(surface) $(s : SDL_Surface?) {expect_pixel(s,0,0,uint4(255u,0u,0u,255u));return sdl_ok()} |> is_ok;verify(dup_ok)
        let scale_ok=with_scaled_surface(surface,4,4,SDL_ScaleMode.SCALEMODE_NEAREST) $(s : SDL_Surface?) {expect_pixel(s,3,3,uint4(0u,0u,255u,255u));return sdl_ok()} |> is_ok;verify(scale_ok)
        let cv_ok=with_converted_surface(surface,SDL_PixelFormat.PIXELFORMAT_RGB24) $(s : SDL_Surface?) {expect_pixel(s,0,0,uint4(255u,0u,0u,255u))
            return sdl_ok()
        } |> is_ok;verify(cv_ok)
        let cs_ok=with_converted_surface(surface,SDL_PixelFormat.PIXELFORMAT_RGBA32,null,SDL_Colorspace.COLORSPACE_SRGB,0u) $(s : SDL_Surface?) {expect_pixel(s,0,0,uint4(255u,0u,0u,255u))
            return sdl_ok()
        } |> is_ok;verify(cs_ok)
        verify(SDL_ClearSurface(surface,1.0,0.0,0.0,0.5) && SDL_PremultiplySurfaceAlpha(surface,false))
        var pr,pg,pb,pa : uint;verify(is_ok(read_surface_pixel(surface,0,0,pr,pg,pb,pa)) && pr==pa && pr>=127u && pr<=128u && pg==0u)
    }
}
def blits {
    let src=SDL_CreateSurface(4,4,SDL_PixelFormat.PIXELFORMAT_RGBA32)
    let dst=SDL_CreateSurface(8,8,SDL_PixelFormat.PIXELFORMAT_RGBA32);verify(src!=null && dst!=null)
    {
        defer(){SDL_DestroySurface(dst);SDL_DestroySurface(src)}
        verify(SDL_ClearSurface(src,1.0,0.0,0.0,1.0) && SDL_SetSurfaceBlendMode(src,SDL_BLENDMODE_NONE))
        for(y in 0 .. 4) {for(x in 2 .. 4) {verify(SDL_WriteSurfacePixel(src,x,y,0u,0u,255u,255u))}}
        var sr,dr : SDL_Rect;sr.w=4;sr.h=4;dr.x=2;dr.y=2;dr.w=4;dr.h=4
        for(op in 0 .. 8) {
            dr.x=2;dr.y=2;dr.w=4;dr.h=4
            if(op>=2 && op<=4) {dr.x=1;dr.y=1;dr.w=6;dr.h=6}
            verify(SDL_ClearSurface(dst,0.0,0.0,0.0,1.0))
            unsafe {
                if(op==0) {verify(SDL_BlitSurface(src,addr(sr),dst,addr(dr)))}
                elif(op==1) {verify(SDL_BlitSurfaceUnchecked(src,addr(sr),dst,addr(dr)))}
                elif(op==2) {verify(SDL_BlitSurfaceScaled(src,addr(sr),dst,addr(dr),SDL_ScaleMode.SCALEMODE_NEAREST))}
                elif(op==3) {verify(SDL_BlitSurfaceUncheckedScaled(src,addr(sr),dst,addr(dr),SDL_ScaleMode.SCALEMODE_NEAREST))}
                elif(op==4) {verify(SDL_StretchSurface(src,addr(sr),dst,addr(dr),SDL_ScaleMode.SCALEMODE_NEAREST))}
                elif(op==5) {verify(SDL_BlitSurfaceTiled(src,addr(sr),dst,addr(dr)))}
                elif(op==6) {verify(SDL_BlitSurfaceTiledWithScale(src,addr(sr),2.0,SDL_ScaleMode.SCALEMODE_NEAREST,dst,addr(dr)))}
                else {verify(SDL_BlitSurface9Grid(src,addr(sr),1,1,1,1,1.0,SDL_ScaleMode.SCALEMODE_NEAREST,dst,addr(dr)))}
            }
            for(y in 0 .. 8) {for(x in 0 .. 8) {
                let inside=x>=dr.x && x<dr.x+dr.w && y>=dr.y && y<dr.y+dr.h
                let red=op==6 || x<dr.x+dr.w/2
                expect_pixel(dst,x,y,uint4(inside && red ? 255u : 0u,0u,inside && !red ? 255u : 0u,255u))
            }}
            verify(SDL_ClearSurface(dst,0.0,0.0,0.0,1.0))
            if(op==0 || op==1) {verify(SDL_BlitSurfaceRefs(src,sr,dst,dr))}
            elif(op==2 || op==3) {verify(SDL_BlitSurfaceScaledRefs(src,sr,dst,dr,SDL_ScaleMode.SCALEMODE_NEAREST))}
            elif(op==4) {verify(SDL_StretchSurfaceRefs(src,sr,dst,dr,SDL_ScaleMode.SCALEMODE_NEAREST))}
            elif(op==5) {verify(SDL_BlitSurfaceTiledRefs(src,sr,dst,dr))}
            elif(op==6) {verify(SDL_BlitSurfaceTiledWithScaleRefs(src,sr,2.0,SDL_ScaleMode.SCALEMODE_NEAREST,dst,dr))}
            else {verify(SDL_BlitSurface9GridRefs(src,sr,1,1,1,1,1.0,SDL_ScaleMode.SCALEMODE_NEAREST,dst,dr))}
            expect_pixel(dst,2,2,uint4(255u,0u,0u,255u));expect_pixel(dst,0,0,uint4(0u,0u,0u,255u))
        }
        verify(SDL_BlitSurfaceAll(src,dst));expect_pixel(dst,0,0,uint4(255u,0u,0u,255u))
        var rects : array<SDL_Rect>;resize(rects,2);rects[0].w=2;rects[0].h=2;rects[1].x=6;rects[1].y=6;rects[1].w=2;rects[1].h=2
        let green=SDL_MapSurfaceRGB(dst,0u,255u,0u)
        unsafe {verify(SDL_FillSurfaceRects(dst,addr(rects[0]),2,green))}
        expect_pixel(dst,0,0,uint4(0u,255u,0u,255u));expect_pixel(dst,7,7,uint4(0u,255u,0u,255u))
        verify(SDL_FillSurfaceRectsArray(dst,rects,SDL_MapSurfaceRGB(dst,0u,0u,255u)));expect_pixel(dst,7,7,uint4(0u,0u,255u,255u))
    }
}
def pixel_buffers {
    let rgba=SDL_PixelFormat.PIXELFORMAT_RGBA32;let bgra=SDL_PixelFormat.PIXELFORMAT_BGRA32
    var src,dst,adapted : array<uint8>;resize(src,24);resize(dst,24);resize(adapted,24)
    for(i in 0 .. 24) {src[i]=uint8(99);dst[i]=uint8(77);adapted[i]=uint8(77)}
    for(y in 0 .. 2) {for(x in 0 .. 2) {let i=y*12+x*4;src[i]=uint8(200);src[i+1]=uint8(100);src[i+2]=uint8(40);src[i+3]=uint8(128)}}
    unsafe {verify(SDL_ConvertPixels(2,2,rgba,addr(src[0]),12,bgra,addr(dst[0]),12))}
    verify(SDL_ConvertPixelsArray(2,2,rgba,src,12,bgra,adapted,12))
    for(i in 0 .. 24) {verify(dst[i]==adapted[i])}
    verify(dst[0]==uint8(40) && dst[2]==uint8(200) && dst[8]==uint8(77))
    unsafe {verify(SDL_ConvertPixelsAndColorspace(2,2,rgba,SDL_Colorspace.COLORSPACE_SRGB,0u,addr(src[0]),12,bgra,SDL_Colorspace.COLORSPACE_SRGB,0u,addr(dst[0]),12))}
    verify(SDL_ConvertPixelsAndColorspaceArray(2,2,rgba,SDL_Colorspace.COLORSPACE_SRGB,0u,src,12,bgra,SDL_Colorspace.COLORSPACE_SRGB,0u,adapted,12))
    for(i in 0 .. 24) {verify(dst[i]==adapted[i])}
    unsafe {verify(SDL_PremultiplyAlpha(2,2,rgba,addr(src[0]),12,rgba,addr(dst[0]),12,false))}
    verify(SDL_PremultiplyAlphaArray(2,2,rgba,src,12,rgba,adapted,12,false))
    for(i in 0 .. 24) {verify(dst[i]==adapted[i])}
    verify(abs(int(dst[0])-100)<=1 && abs(int(dst[1])-50)<=1 && abs(int(dst[2])-20)<=1 && dst[3]==uint8(128) && dst[8]==uint8(77))
    verify(SDL_PremultiplyAlphaArray(2,2,rgba,src,12,rgba,adapted,12,true))
    verify(abs(int(adapted[0])-146)<=2 && adapted[3]==uint8(128))
    resize(adapted,7);verify(!SDL_ConvertPixelsArray(2,2,rgba,src,12,bgra,adapted,12))
    verify(!SDL_PremultiplyAlphaArray(2,2,rgba,src,1,rgba,dst,12,false))
}
def bmp_io {
    let src=SDL_CreateSurface(2,2,SDL_PixelFormat.PIXELFORMAT_RGBA32);verify(src!=null)
    {
        defer(){SDL_DestroySurface(src)}
        verify(SDL_ClearSurface(src,0.0,1.0,0.0,1.0))
        var bytes : array<uint8>;resize(bytes,4096)
        unsafe {
            let io=SDL_IOFromMem(addr(bytes[0]),uint64(length(bytes)));verify(io!=null)
            verify(SDL_SaveBMP_IO(src,io,false) && SDL_SeekIO(io,0l,SDL_IOWhence.IO_SEEK_SET)==0l)
            let loaded=SDL_LoadBMP_IO(io,false);verify(loaded!=null);expect_pixel(loaded,1,1,uint4(0u,255u,0u,255u));SDL_DestroySurface(loaded)
            verify(SDL_CloseIO(io))
            let read=SDL_IOFromConstMem(addr(bytes[0]),uint64(length(bytes)));verify(read!=null)
            let owned=SDL_LoadBMP_IO(read,true);verify(owned!=null);expect_pixel(owned,0,0,uint4(0u,255u,0u,255u));SDL_DestroySurface(owned)
            let write=SDL_IOFromMem(addr(bytes[0]),uint64(length(bytes)));verify(write!=null && SDL_SaveBMP_IO(src,write,true))
            var bad : array<uint8>;resize(bad,4)
            let invalid=SDL_IOFromConstMem(addr(bad[0]),4ul);verify(invalid!=null && SDL_LoadBMP_IO(invalid,true)==null)
        }
        let path="surface-pixels-{SDL_GetTicksNS()}.bmp"
        verify(SDL_SaveBMP(src,path))
        {
            defer(){SDL_RemovePath(path)}
            let loaded=SDL_LoadBMP(path);verify(loaded!=null);expect_pixel(loaded,0,0,uint4(0u,255u,0u,255u));SDL_DestroySurface(loaded)
        }
    }
}
[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {formats_and_palettes();external_pixels_and_images();transforms();blits();pixel_buffers();bmp_io()
        return sdl_ok()
    } |> is_ok
    verify(initialized)
    print("surface/pixels: formats, palettes, ownership, transforms, blits, buffers and BMP passed\n")
    return 0
}
