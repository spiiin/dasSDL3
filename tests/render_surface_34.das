options gen2
require dassdl3/sdl3_render_surface_34_boost
require dassdl3/sdl3_iostream_boost
require daslib/defer

def check_image(surface : SDL_Surface?) {
    verify(surface!=null)
    verify(unwrap(surface_size(surface))==int2(3,2))
    verify(unwrap(read_surface_pixel(surface,0,0))==uint4(255u,0u,0u,255u))
    verify(unwrap(read_surface_pixel(surface,2,1))==uint4(0u,0u,255u,255u))
}
def images {
    let source=SDL_CreateSurface(3,2,SDL_PixelFormat.PIXELFORMAT_RGBA32)
    verify(source!=null)
    defer(){SDL_DestroySurface(source)}
    verify(SDL_ClearSurface(source,0.0,1.0,0.0,1.0))
    verify(SDL_WriteSurfacePixel(source,0,0,255u,0u,0u,255u))
    verify(SDL_WriteSurfacePixel(source,2,1,0u,0u,255u,255u))
    let path="{SDL_GetBasePath()}render34-test.png"
    verify(SDL_SavePNG(source,path))
    {
        defer(){SDL_RemovePath(path)}
        let png=SDL_LoadPNG(path);check_image(png);SDL_DestroySurface(png)
        let generic=SDL_LoadSurface(path);check_image(generic);SDL_DestroySurface(generic)
        verify(is_ok(with_png(path) $(image) { check_image(image); return sdl_ok() }))
        verify(is_ok(with_loaded_surface(path) $(image) { check_image(image); return sdl_ok() }))
        verify(is_ok(save_png(source,path)))
    }
    let io=SDL_IOFromDynamicMem();verify(io!=null)
    defer(){SDL_CloseIO(io)}
    verify(SDL_SavePNG_IO(source,io,false))
    verify(SDL_GetIOSize(io)>8l)
    verify(SDL_SeekIO(io,0l,SDL_IOWhence.IO_SEEK_SET)==0l)
    let png=SDL_LoadPNG_IO(io,false);check_image(png);SDL_DestroySurface(png)
    verify(SDL_SeekIO(io,0l,SDL_IOWhence.IO_SEEK_SET)==0l)
    let auto_image=SDL_LoadSurface_IO(io,false);check_image(auto_image);SDL_DestroySurface(auto_image)
    verify(SDL_SeekIO(io,0l,SDL_IOWhence.IO_SEEK_SET)==0l)
    verify(is_ok(with_png(io) $(image) {check_image(image);return sdl_ok()}))
    verify(SDL_SeekIO(io,0l,SDL_IOWhence.IO_SEEK_SET)==0l)
    verify(is_ok(with_loaded_surface(io) $(image) {check_image(image);return sdl_ok()}))
    verify(SDL_SeekIO(io,0l,SDL_IOWhence.IO_SEEK_SET)==0l)
    verify(is_ok(save_png(source,io)))
    let rotated=SDL_RotateSurface(source,180.0);verify(rotated!=null)
    verify(unwrap(surface_size(rotated))==int2(3,2))
    verify(unwrap(read_surface_pixel(rotated,0,0))==uint4(0u,0u,255u,255u));SDL_DestroySurface(rotated)
    verify(is_ok(with_rotated_surface(source,90.0) $(image) {
        verify(unwrap(surface_size(image))==int2(2,3)); return sdl_ok()
    }))
    // Generic Result scope must move arrays and propagate an early body error.
    var moved <- with_rotated_surface(source,0.0) $(image) {
        var values <- array<int>(7,9); return <- move_ok(values,type<SdlError>)
    }
    verify(is_ok(moved));var values <- move_unwrap(moved);verify(values[1]==9)
    let failed=with_rotated_surface(source,0.0) $(image) {
        return err(SdlError(operation="body",message="preserved"),type<SdlUnit>)
    }
    verify(is_err(failed) && unwrap_err(failed).message=="preserved")
    verify(is_err(with_png("no-such-render34-file.png") $(image) {verify(false);return sdl_ok()}))
    verify(is_err(save_png(null,path)))
    verify(SDL_LoadPNG_IO(null,false)==null && SDL_LoadSurface_IO(null,false)==null)
    verify(SDL_RotateSurface(null,90.0)==null)
}
def renderer {
    let surface=SDL_CreateSurface(16,16,SDL_PixelFormat.PIXELFORMAT_RGBA32);verify(surface!=null)
    defer(){SDL_DestroySurface(surface)}
    let renderer=SDL_CreateSoftwareRenderer(surface);verify(renderer!=null)
    defer(){SDL_DestroyRenderer(renderer)}
    verify(SDL_SetDefaultTextureScaleMode(renderer,SDL_ScaleMode.SCALEMODE_NEAREST))
    var mode : SDL_ScaleMode
    unsafe {verify(SDL_GetDefaultTextureScaleMode(renderer,addr(mode)))}
    verify(mode==SDL_ScaleMode.SCALEMODE_NEAREST && unwrap(default_texture_scale_mode(renderer))==mode)
    verify(is_ok(set_default_texture_scale_mode(renderer,SDL_ScaleMode.SCALEMODE_LINEAR)))
    verify(unwrap(default_texture_scale_mode(renderer))==SDL_ScaleMode.SCALEMODE_LINEAR)
    let texture=SDL_CreateTexture(renderer,SDL_PixelFormat.PIXELFORMAT_RGBA32,SDL_TextureAccess.TEXTUREACCESS_STATIC,3,3)
    verify(texture!=null);defer(){SDL_DestroyTexture(texture)}
    verify(unwrap(texture_scale_mode(texture))==SDL_ScaleMode.SCALEMODE_LINEAR)
    SDL_SetErrorText("stale")
    var palette_result <- texture_palette(texture); var maybe_palette <- move_unwrap(palette_result); verify(is_none(maybe_palette))
    verify(is_err(texture_palette(null)))
    verify(!SDL_SetTexturePalette(texture,null))
    verify(SDL_GetTexturePalette(texture)==null)
    verify(SDL_SetRenderTextureAddressMode(renderer,SDL_TextureAddressMode.TEXTURE_ADDRESS_WRAP,SDL_TextureAddressMode.TEXTURE_ADDRESS_CLAMP))
    var u,v : SDL_TextureAddressMode
    unsafe{verify(SDL_GetRenderTextureAddressMode(renderer,addr(u),addr(v)))}
    let address=unwrap(render_texture_address_mode(renderer));verify(address.u==u && address.v==v)
    verify(u==SDL_TextureAddressMode.TEXTURE_ADDRESS_WRAP && v==SDL_TextureAddressMode.TEXTURE_ADDRESS_CLAMP)
    verify(is_ok(set_render_texture_address_mode(renderer,SDL_TextureAddressMode.TEXTURE_ADDRESS_AUTO,SDL_TextureAddressMode.TEXTURE_ADDRESS_AUTO)))
    let tile=SDL_CreateSurface(3,3,SDL_PixelFormat.PIXELFORMAT_RGBA32);verify(tile!=null)
    defer(){SDL_DestroySurface(tile)}
    verify(SDL_ClearSurface(tile,1.0,0.0,0.0,1.0))
    let image=SDL_CreateTextureFromSurface(renderer,tile);verify(image!=null)
    defer(){SDL_DestroyTexture(image)}
    verify(SDL_SetTextureScaleMode(image,SDL_ScaleMode.SCALEMODE_NEAREST))
    var src=SDL_FRect(w=3.0,h=3.0);var dst=SDL_FRect(x=2.0,y=2.0,w=12.0,h=12.0)
    verify(SDL_SetRenderDrawColor(renderer,0u,0u,0u,255u) && SDL_RenderClear(renderer))
    unsafe{verify(SDL_RenderTexture9GridTiled(renderer,image,addr(src),1.0,1.0,1.0,1.0,1.0,addr(dst),1.0))}
    verify(SDL_FlushRenderer(renderer))
    verify(unwrap(read_surface_pixel(surface,8,8))==uint4(255u,0u,0u,255u))
    verify(unwrap(read_surface_pixel(surface,0,0))==uint4(0u,0u,0u,255u))
    verify(is_ok(render_texture_9grid_tiled(renderer,image,src,1.0,1.0,1.0,1.0,1.0,dst,2.0)))
    verify(SDL_FlushRenderer(renderer))
    verify(is_err(default_texture_scale_mode(null)) && is_err(render_texture_address_mode(null)))
    verify(!SDL_SetDefaultTextureScaleMode(null,mode) && !SDL_SetRenderTextureAddressMode(null,u,v))
}
[export]
def main(smoke : bool) : int {
    verify(SDL_Init(0u));defer(){SDL_Quit()}
    images();renderer()
    print("SDL 3.4 Surface/Renderer: PNG pixels, IO ownership, rotation, defaults and tiled drawing PASS\n")
    return 0
}
