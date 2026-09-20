options gen2
require daslib/defer
module sdl3_renderer_operations_boost shared public
require dassdl3/sdl3_renderer_yuv_blend_boost public

def public with_window_renderer(title : string; w,h : int; flags : uint64; blk : block<(window : SDL_Window?; renderer : SDL_Renderer?) : void>) : bool {
    var window : SDL_Window?;var renderer : SDL_Renderer?
    if(!SDL_CreateWindowAndRendererRef(title,w,h,flags,window,renderer)) {return false}
    {defer(){SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window)};blk(window,renderer);return true}
}
def public with_renderer_properties(props : uint; blk : block<(renderer : SDL_Renderer?) : void>) : bool {
    let renderer=SDL_CreateRendererWithProperties(props)
    if(renderer==null) {return false}
    {defer(){SDL_DestroyRenderer(renderer)};blk(renderer);return true}
}
def public with_read_pixels(renderer : SDL_Renderer?; rect : SDL_Rect; blk : block<(surface : SDL_Surface?) : void>) : bool {
    let surface=SDL_RenderReadPixelsRect(renderer,rect)
    if(surface==null) {return false}
    {defer(){SDL_DestroySurface(surface)};blk(surface);return true}
}
def public render_vsync(renderer : SDL_Renderer?; var vsync : int&) : bool {return SDL_GetRenderVSyncRef(renderer,vsync)}
