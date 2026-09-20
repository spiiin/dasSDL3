options gen2
require dassdl3/sdl3_renderer_final_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let created=with_window_renderer("Raw geometry",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window,renderer) {
            var xy,uv : array<SDL_FPoint>;resize(xy,3)
            xy[0].x=40.0;xy[0].y=200.0;xy[1].x=160.0;xy[1].y=40.0;xy[2].x=280.0;xy[2].y=200.0
            var colors : array<SDL_FColor>;resize(colors,3)
            colors[0].r=1.0;colors[1].g=1.0;colors[2].b=1.0
            for(c in colors) {c.a=1.0}
            if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return}
            if(!render_geometry_raw(renderer,null,xy,colors,uv)) {return}
            if(!SDL_SetRenderDrawColor(renderer,255u,255u,255u,255u) || !SDL_RenderDebugTextFormatText(renderer,8.0,8.0,"SDL geometry: 100%")) {return}
            rendered=SDL_RenderPresent(renderer)
            if(rendered && !smoke) {SDL_Delay(1200u)}
        }
        if(!created) {rendered=false}
    }
    if(!initialized || !rendered) {print("Raw geometry failed: {SDL_GetError()}\n");return 1}
    return 0
}
