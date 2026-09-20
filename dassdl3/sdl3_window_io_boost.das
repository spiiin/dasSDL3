options gen2
require daslib/defer
module sdl3_window_io_boost shared public
require dassdl3/sdl3_window_boost public
require dassdl3/sdl3_pixels_boost public

// Owns only a newly created standalone surface. Window surfaces are borrowed.
def public with_surface(w,h : int; format : SDL_PixelFormat; blk : block<(surface : SDL_Surface?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let surface=SDL_CreateSurface(w,h,format)
    if(surface==null) {return err(sdl_error("with_surface"), type<TT>)}
    {defer(){SDL_DestroySurface(surface)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(surface) } else { scope_result <- blk(surface) }}

    return <- scope_result
}
def public window_surface_vsync(window : SDL_Window?; var vsync : int&) {
    return sdl_status(SDL_GetWindowSurfaceVSyncRef(window,vsync), "window_surface_vsync")
}
def public update_window_rects(window : SDL_Window?; rects : array<SDL_Rect>) {
    return sdl_status(SDL_UpdateWindowSurfaceRectsArray(window,rects), "update_window_rects")
}
def public window_icc_profile(window : SDL_Window?; var bytes : array<uint8>) {
    return sdl_status(SDL_GetWindowICCProfileCopy(window,bytes), "window_icc_profile")
}

def public window_surface_vsync(window : SDL_Window?) {
    var vsync : int
    let status = window_surface_vsync(window,vsync)
    if (is_err(status)) { return err(unwrap_err(status),type<int>) }
    var value = vsync
    return <- move_ok(value,type<SdlError>)
}

def public window_icc_profile(window : SDL_Window?) {
    var bytes : array<uint8>
    let status = window_icc_profile(window,bytes)
    if (is_err(status)) { return err(unwrap_err(status),type<array<uint8>>) }
    var value <- bytes
    return <- move_ok(value,type<SdlError>)
}
