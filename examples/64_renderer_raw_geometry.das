options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_renderer_final_boost
def render_example(renderer : SDL_Renderer?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var rendered=false
    var xy,uv : array<SDL_FPoint>;resize(xy,3)
    xy[0].x=40.0;xy[0].y=200.0;xy[1].x=160.0;xy[1].y=40.0;xy[2].x=280.0;xy[2].y=200.0
    var colors : array<SDL_FColor>;resize(colors,3)
    colors[0].r=1.0;colors[1].g=1.0;colors[2].b=1.0
    for(c in colors) {c.a=1.0}
    if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("64_renderer_raw_geometry"),type<SdlUnit>)}
    render_geometry_raw(renderer,null,xy,colors,uv) |> sdl_try
    if(!SDL_SetRenderDrawColor(renderer,255u,255u,255u,255u) || !SDL_RenderDebugTextFormatText(renderer,8.0,8.0,"SDL geometry: 100%")) {return err(sdl_error("64_renderer_raw_geometry"),type<SdlUnit>)}
    rendered=SDL_RenderPresent(renderer)
    if(!rendered) {return err(sdl_error("64_renderer_raw_geometry"),type<SdlUnit>)}
    if(rendered && !smoke) {SDL_Delay(1200u)}

    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let initialized=sdl_scope() {
        with_sdl() |> sdl_use
        return with_window_renderer("Raw geometry",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?; renderer : SDL_Renderer?) {
            return render_example(renderer, smoke)
        }
    }
    if(is_err(initialized)) {print("Raw geometry failed: {unwrap_err(initialized).message}\n");return 1}
    return 0
}
