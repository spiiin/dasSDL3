options gen2
require daslib/defer
module sdl3_pixel_views shared public
require dassdl3/sdl3_texture_transfer_boost public

// RGBA32 byte order on this platform; low eight bits of each component.
// The result is one packed four-byte uint, not a uint4.
def public rgba8(r,g,b,a : uint) : uint { return SDL_PackRGBA8(r,g,b,a) }

def public set_pixel(pixels : SdlPixelView#; x,y : int; color : uint4) {
    if(x<0 || y<0 || x>=pixels.width || y>=pixels.height || color.x>255u || color.y>255u || color.z>255u || color.w>255u) {
        return err(SdlError(operation="set_pixel",message="Coordinate or component out of range"),type<SdlUnit>)
    }
    return sdl_status(SDL_SetPixelRGBA8(pixels,x,y,color),"set_pixel")
}

def public with_row(pixels : SdlPixelView#; y : int; blk : block<(var data : array<uint>#) : $Result<auto(TT); SdlError>>) {
    var result : $Result<TT;SdlError>
    if(y<0 || y>=pixels.height) { return err(SdlError(operation="with_row",message="Row out of range"),type<TT>) }
    let success=SDL_WithPixelRowRGBA8(pixels,y) $(var data : array<uint>#) {
        static_if(typeinfo can_copy(type<$Result<TT;SdlError>>)) { result=blk(data) }
        else { result <- blk(data) }
    }
    if(!success) { return err(sdl_error("with_row"),type<TT>) }
    return <- result
}

def public with_pixels(pixels : SdlPixelView#; blk : block<(var data : array<uint8>#) : $Result<auto(TT); SdlError>>) {
    var result : $Result<TT;SdlError>
    let success=SDL_WithPixelBytesRGBA8(pixels) $(var data : array<uint8>#) {
        static_if(typeinfo can_copy(type<$Result<TT;SdlError>>)) { result=blk(data) }
        else { result <- blk(data) }
    }
    if(!success) { return err(sdl_error("with_pixels"),type<TT>) }
    return <- result
}

// The caller supplies a live, locked RGBA32 surface. No ownership is transferred.
def public with_locked_surface_pixels_rgba8(surface : SDL_Surface?;
        blk : block<(pixels : SdlPixelView#) : $Result<auto(TT);SdlError>>) {
    var result : $Result<TT;SdlError>
    let success=SDL_WithSurfacePixelsRGBA8(surface) $(pixels : SdlPixelView#) {
        static_if(typeinfo can_copy(type<$Result<TT;SdlError>>)) { result=blk(pixels) }
        else { result <- blk(pixels) }
    }
    if(!success) { return err(sdl_error("with_locked_surface_pixels_rgba8"),type<TT>) }
    return <- result
}
def public with_texture_pixels_rgba8(texture : SDL_Texture?; rect : SDL_Rect;
        blk : block<(pixels : SdlPixelView#) : $Result<auto(TT);SdlError>>) {
    return <- with_texture_surface(texture,rect) $(surface : SDL_Surface?) {
        return <- with_locked_surface_pixels_rgba8(surface,blk)
    }
}

// SDL_LockSurface is paired with deferred unlock, even for surfaces not requiring it.
def public with_surface_pixels_rgba8(surface : SDL_Surface?;
        blk : block<(pixels : SdlPixelView#) : $Result<auto(TT);SdlError>>) {
    if(!SDL_LockSurface(surface)) { return err(sdl_error("SDL_LockSurface"),type<TT>) }
    var result : $Result<TT;SdlError>
    {
        defer() { SDL_UnlockSurface(surface) }
        result <- with_locked_surface_pixels_rgba8(surface,blk)
    }
    return <- result
}
