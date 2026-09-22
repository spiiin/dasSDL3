options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_renderer_presentation_boost
def render_example(window : SDL_Window?; renderer : SDL_Renderer?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var rendered=false
    print("Renderer: {renderer_name(renderer)}\n")
    if(!SDL_SetRenderLogicalPresentation(renderer,100,100,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_LETTERBOX)) {return err(sdl_error("59_renderer_presentation"),type<SdlUnit>)}
    if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("59_renderer_presentation"),type<SdlUnit>)}
    var rects : array<SDL_FRect>;resize(rects,3)
    for(i in 0 .. 3) {rects[i]=SDL_FRect(x=float(10+i*30),y=float(15+i*15),w=20.0,h=40.0)}
    if(!SDL_SetRenderDrawColor(renderer,60u,180u,230u,255u) || !SDL_RenderFillRectsArray(renderer,rects)) {return err(sdl_error("59_renderer_presentation"),type<SdlUnit>)}
    var wx,wy : float
    render_to_window(renderer,50.0,50.0,wx,wy) |> sdl_try
    print("Logical center (50,50) in window coordinates: {wx}, {wy}\n")
    rendered=SDL_RenderPresent(renderer)
    if(!rendered) {return err(sdl_error("59_renderer_presentation"),type<SdlUnit>)}
    if(rendered && !smoke) {SDL_Delay(1200u)}

    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let initialized=sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("Logical presentation",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = with_renderer(window) |> sdl_use
        return render_example(window, renderer, smoke)
    }
    if(is_err(initialized)) {print("Presentation failed: {unwrap_err(initialized).message}\n");return 1}
    return 0
}
