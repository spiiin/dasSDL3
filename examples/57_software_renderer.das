options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_renderer_primitives_boost
def render_example(window : SDL_Window?; renderer : SDL_Renderer?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var rendered=false
    if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("57_software_renderer"),type<SdlUnit>)}
    var rects : array<SDL_FRect>;resize(rects,3)
    for(i in 0 .. 3) {rects[i]=SDL_FRect(x=float(30+i*90),y=float(40+i*30),w=60.0,h=80.0)}
    if(!SDL_SetRenderDrawColor(renderer,60u,180u,230u,255u) || !SDL_RenderFillRectsArray(renderer,rects)) {return err(sdl_error("57_software_renderer"),type<SdlUnit>)}
    rendered=SDL_FlushRenderer(renderer) && SDL_UpdateWindowSurface(window)
    if(!rendered) {return err(sdl_error("57_software_renderer"),type<SdlUnit>)}
    if(rendered && !smoke) {SDL_Delay(1200u)}

    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let initialized=sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("Software renderer",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        // Window owns this surface; renderer must be destroyed before the window.
        let surface=SDL_GetWindowSurface(window)
        if(surface==null) {return err(sdl_error("57_software_renderer"),type<SdlUnit>)}
        let renderer : SDL_Renderer? = with_software_renderer(surface) |> sdl_use
        return render_example(window, renderer, smoke)
    }
    if(is_err(initialized)) {print("Software rendering failed: {unwrap_err(initialized).message}\n");return 1}
    return 0
}
