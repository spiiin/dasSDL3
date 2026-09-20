options gen2
require daslib/defer
module sdl3_window_io_boost shared public
require dassdl3/sdl3_window_boost public
require dassdl3/sdl3_pixels_boost public

// Owns only a newly created standalone surface. Window surfaces are borrowed.
def public with_surface(w,h : int; format : SDL_PixelFormat; blk : block<(surface : SDL_Surface?) : void>) : bool {
    let surface=SDL_CreateSurface(w,h,format)
    if(surface==null) {return false}
    {defer(){SDL_DestroySurface(surface)};blk(surface);return true}
}
def public window_surface_vsync(window : SDL_Window?; var vsync : int&) : bool {
    return SDL_GetWindowSurfaceVSyncRef(window,vsync)
}
def public update_window_rects(window : SDL_Window?; rects : array<SDL_Rect>) : bool {
    return SDL_UpdateWindowSurfaceRectsArray(window,rects)
}
def public window_icc_profile(window : SDL_Window?; var bytes : array<uint8>) : bool {
    return SDL_GetWindowICCProfileCopy(window,bytes)
}
