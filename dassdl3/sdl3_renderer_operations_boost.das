options gen2
require daslib/defer
module sdl3_renderer_operations_boost shared public
require dassdl3/sdl3_renderer_yuv_blend_boost public

def public with_window_renderer(title : string; w,h : int; flags : uint64; blk : block<(window : SDL_Window?; renderer : SDL_Renderer?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var window : SDL_Window?;var renderer : SDL_Renderer?
    if(!SDL_CreateWindowAndRendererRef(title,w,h,flags,window,renderer)) {return err(sdl_error("with_window_renderer"), type<TT>)}
    {defer(){SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(window,renderer) } else { scope_result <- blk(window,renderer) }}

    return <- scope_result
}
def public with_renderer_properties(props : uint; blk : block<(renderer : SDL_Renderer?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let renderer=SDL_CreateRendererWithProperties(props)
    if(renderer==null) {return err(sdl_error("with_renderer_properties"), type<TT>)}
    {defer(){SDL_DestroyRenderer(renderer)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(renderer) } else { scope_result <- blk(renderer) }}

    return <- scope_result
}
def public with_read_pixels(renderer : SDL_Renderer?; rect : SDL_Rect; blk : block<(surface : SDL_Surface?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let surface=SDL_RenderReadPixelsRect(renderer,rect)
    if(surface==null) {return err(sdl_error("with_read_pixels"), type<TT>)}
    {defer(){SDL_DestroySurface(surface)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(surface) } else { scope_result <- blk(surface) }}

    return <- scope_result
}
def public render_vsync(renderer : SDL_Renderer?; var vsync : int&) {return sdl_status(SDL_GetRenderVSyncRef(renderer,vsync), "render_vsync")}

def public render_vsync(renderer : SDL_Renderer?) {
    var vsync : int
    let status = render_vsync(renderer,vsync)
    if (is_err(status)) { return err(unwrap_err(status),type<int>) }
    var value = vsync
    return <- move_ok(value,type<SdlError>)
}
