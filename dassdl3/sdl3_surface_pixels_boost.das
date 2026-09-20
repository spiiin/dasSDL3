options gen2
require daslib/defer
module sdl3_surface_pixels_boost shared public
require dassdl3/sdl3_surface_state_boost public

def public with_palette(count : int; blk : block<(palette : SDL_Palette?) : void>) : bool {
    let palette=SDL_CreatePalette(count)
    if(palette==null) {return false}
    {defer(){SDL_DestroyPalette(palette)};blk(palette);return true}
}
def public with_duplicate_surface(source : SDL_Surface?; blk : block<(surface : SDL_Surface?) : void>) : bool {
    let surface=SDL_DuplicateSurface(source)
    if(surface==null) {return false}
    {defer(){SDL_DestroySurface(surface)};blk(surface);return true}
}
def public with_scaled_surface(source : SDL_Surface?; w,h : int; mode : SDL_ScaleMode; blk : block<(surface : SDL_Surface?) : void>) : bool {
    let surface=SDL_ScaleSurface(source,w,h,mode)
    if(surface==null) {return false}
    {defer(){SDL_DestroySurface(surface)};blk(surface);return true}
}
def public with_converted_surface(source : SDL_Surface?; format : SDL_PixelFormat; blk : block<(surface : SDL_Surface?) : void>) : bool {
    let surface=SDL_ConvertSurface(source,format)
    if(surface==null) {return false}
    {defer(){SDL_DestroySurface(surface)};blk(surface);return true}
}
def public with_converted_surface(source : SDL_Surface?; format : SDL_PixelFormat; palette : SDL_Palette?; colorspace : SDL_Colorspace; props : uint; blk : block<(surface : SDL_Surface?) : void>) : bool {
    let surface=SDL_ConvertSurfaceAndColorspace(source,format,palette,colorspace,props)
    if(surface==null) {return false}
    {defer(){SDL_DestroySurface(surface)};blk(surface);return true}
}
def public with_surface_lock(surface : SDL_Surface?; blk : block) : bool {
    if(!SDL_LockSurface(surface)) {return false}
    {defer(){SDL_UnlockSurface(surface)};blk();return true}
}
def public read_surface_pixel(surface : SDL_Surface?; x,y : int; var r,g,b,a : uint&) : bool {return SDL_ReadSurfacePixelRef(surface,x,y,r,g,b,a)}
def public read_surface_pixel_float(surface : SDL_Surface?; x,y : int; var r,g,b,a : float&) : bool {return SDL_ReadSurfacePixelFloatRef(surface,x,y,r,g,b,a)}
