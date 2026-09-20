options gen2
require dassdl3/sdl3_renderer_state_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let opened=with_window("Viewport and clipping",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window) {
            let surface=SDL_GetWindowSurface(window)
            if(surface==null) {return}
            let created=with_software_renderer(surface) $(renderer) {
                var w,h : int
                if(!render_output_size(renderer,w,h)) {return}
                if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return}
                // These coordinates are scaled by two into output pixels.
                if(!SDL_SetRenderScale(renderer,2.0,2.0)) {return}
                var viewport : SDL_Rect
                viewport.x=10;viewport.y=10;viewport.w=w/2-20;viewport.h=h/2-20
                var clip : SDL_Rect
                clip.x=10;clip.y=10;clip.w=viewport.w-20;clip.h=viewport.h-20
                if(!SDL_SetRenderViewportRef(renderer,viewport) || !SDL_SetRenderClipRectRef(renderer,clip)) {return}
                if(!SDL_SetRenderDrawColor(renderer,60u,180u,230u,255u)) {return}
                var rects : array<SDL_FRect>;resize(rects,3)
                for(i in 0 .. 3) {rects[i].x=float(i*45);rects[i].y=float(i*15);rects[i].w=35.0;rects[i].h=65.0}
                if(!SDL_RenderFillRectsArray(renderer,rects)) {return}
                rendered=SDL_FlushRenderer(renderer) && SDL_UpdateWindowSurface(window)
                if(rendered && !smoke) {SDL_Delay(1200u)}
            }
            if(!created) {rendered=false}
        }
        if(!opened) {rendered=false}
    }
    if(!initialized || !rendered) {print("Renderer state example failed: {SDL_GetError()}\n");return 1}
    return 0
}
