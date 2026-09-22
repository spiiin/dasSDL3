options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_renderer_state_boost
def render_example(window : SDL_Window?; renderer : SDL_Renderer?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var rendered=false
    let size = render_output_size(renderer) |> sdl_try
    if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
    // These coordinates are scaled by two into output pixels.
    if(!SDL_SetRenderScale(renderer,2.0,2.0)) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
    var viewport = SDL_Rect(x = 10, y = 10, w = size.x/2-20, h = size.y/2-20)
    var clip = SDL_Rect(x = 10, y = 10, w = viewport.w-20, h = viewport.h-20)
    if(!SDL_SetRenderViewportRef(renderer,viewport) || !SDL_SetRenderClipRectRef(renderer,clip)) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
    if(!SDL_SetRenderDrawColor(renderer,60u,180u,230u,255u)) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
    var rects : array<SDL_FRect>;resize(rects,3)
    for(i in 0 .. 3) {rects[i]=SDL_FRect(x=float(i*45),y=float(i*15),w=35.0,h=65.0)}
    if(!SDL_RenderFillRectsArray(renderer,rects)) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
    rendered=SDL_FlushRenderer(renderer) && SDL_UpdateWindowSurface(window)
    if(!rendered) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
    if(rendered && !smoke) {SDL_Delay(1200u)}

    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let initialized=sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("Viewport and clipping",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let surface=SDL_GetWindowSurface(window)
        if(surface==null) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
        let renderer : SDL_Renderer? = with_software_renderer(surface) |> sdl_use
        return render_example(window, renderer, smoke)
    }
    if(is_err(initialized)) {print("Renderer state example failed: {unwrap_err(initialized).message}\n");return 1}
    return 0
}
