options gen2
require daslib/defer
module sdl3_surface_pixels_boost shared public
require dassdl3/sdl3_surface_state_boost public

def public with_palette(count : int; blk : block<(palette : SDL_Palette?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let palette=SDL_CreatePalette(count)
    if(palette==null) {return err(sdl_error("with_palette"), type<TT>)}
    {defer(){SDL_DestroyPalette(palette)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(palette) } else { scope_result <- blk(palette) }}

    return <- scope_result
}
def public with_duplicate_surface(source : SDL_Surface?; blk : block<(surface : SDL_Surface?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let surface=SDL_DuplicateSurface(source)
    if(surface==null) {return err(sdl_error("with_duplicate_surface"), type<TT>)}
    {defer(){SDL_DestroySurface(surface)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(surface) } else { scope_result <- blk(surface) }}

    return <- scope_result
}
def public with_scaled_surface(source : SDL_Surface?; w,h : int; mode : SDL_ScaleMode; blk : block<(surface : SDL_Surface?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let surface=SDL_ScaleSurface(source,w,h,mode)
    if(surface==null) {return err(sdl_error("with_scaled_surface"), type<TT>)}
    {defer(){SDL_DestroySurface(surface)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(surface) } else { scope_result <- blk(surface) }}

    return <- scope_result
}
def public with_converted_surface(source : SDL_Surface?; format : SDL_PixelFormat; blk : block<(surface : SDL_Surface?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let surface=SDL_ConvertSurface(source,format)
    if(surface==null) {return err(sdl_error("with_converted_surface"), type<TT>)}
    {defer(){SDL_DestroySurface(surface)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(surface) } else { scope_result <- blk(surface) }}

    return <- scope_result
}
def public with_converted_surface(source : SDL_Surface?; format : SDL_PixelFormat; palette : SDL_Palette?; colorspace : SDL_Colorspace; props : uint; blk : block<(surface : SDL_Surface?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let surface=SDL_ConvertSurfaceAndColorspace(source,format,palette,colorspace,props)
    if(surface==null) {return err(sdl_error("with_converted_surface"), type<TT>)}
    {defer(){SDL_DestroySurface(surface)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(surface) } else { scope_result <- blk(surface) }}

    return <- scope_result
}
def public with_surface_lock(surface : SDL_Surface?; blk : block<() : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    if(!SDL_LockSurface(surface)) {return err(sdl_error("with_surface_lock"), type<TT>)}
    {defer(){SDL_UnlockSurface(surface)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk() } else { scope_result <- blk() }}

    return <- scope_result
}
def public read_surface_pixel(surface : SDL_Surface?; x,y : int; var r,g,b,a : uint&) {return sdl_status(SDL_ReadSurfacePixelRef(surface,x,y,r,g,b,a), "read_surface_pixel")}
def public read_surface_pixel_float(surface : SDL_Surface?; x,y : int; var r,g,b,a : float&) {return sdl_status(SDL_ReadSurfacePixelFloatRef(surface,x,y,r,g,b,a), "read_surface_pixel_float")}

def public read_surface_pixel(surface : SDL_Surface?; x,y : int) {
    var r : uint
    var g : uint
    var b : uint
    var a : uint
    let status = read_surface_pixel(surface,x,y,r,g,b,a)
    if (is_err(status)) { return err(unwrap_err(status),type<uint4>) }
    var value = uint4(r,g,b,a)
    return <- move_ok(value,type<SdlError>)
}

def public read_surface_pixel_float(surface : SDL_Surface?; x,y : int) {
    var r : float
    var g : float
    var b : float
    var a : float
    let status = read_surface_pixel_float(surface,x,y,r,g,b,a)
    if (is_err(status)) { return err(unwrap_err(status),type<float4>) }
    var value = float4(r,g,b,a)
    return <- move_ok(value,type<SdlError>)
}
