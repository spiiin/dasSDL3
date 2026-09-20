options gen2
require dassdl3/sdl3_renderer_primitives_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let opened=with_window("Software renderer",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window) {
            // Window owns this surface; renderer must be destroyed before the window.
            let surface=SDL_GetWindowSurface(window)
            if(surface==null) {return}
            let created=with_software_renderer(surface) $(renderer) {
                if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return}
                var rects : array<SDL_FRect>;resize(rects,3)
                for(i in 0 .. 3) {rects[i].x=float(30+i*90);rects[i].y=float(40+i*30);rects[i].w=60.0;rects[i].h=80.0}
                if(!SDL_SetRenderDrawColor(renderer,60u,180u,230u,255u) || !SDL_RenderFillRectsArray(renderer,rects)) {return}
                rendered=SDL_FlushRenderer(renderer) && SDL_UpdateWindowSurface(window)
                if(rendered && !smoke) {SDL_Delay(1200u)}
            }
            if(!created) {rendered=false}
        }
        if(!opened) {rendered=false}
    }
    if(!initialized || !rendered) {print("Software rendering failed: {SDL_GetError()}\n");return 1}
    return 0
}
