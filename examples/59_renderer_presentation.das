options gen2
require dassdl3/sdl3_renderer_presentation_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let opened=with_window("Logical presentation",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window) {
            let created=with_renderer(window) $(renderer) {
                print("Renderer: {renderer_name(renderer)}\n")
                if(!SDL_SetRenderLogicalPresentation(renderer,100,100,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_LETTERBOX)) {return}
                if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return}
                var rects : array<SDL_FRect>;resize(rects,3)
                for(i in 0 .. 3) {rects[i].x=float(10+i*30);rects[i].y=float(15+i*15);rects[i].w=20.0;rects[i].h=40.0}
                if(!SDL_SetRenderDrawColor(renderer,60u,180u,230u,255u) || !SDL_RenderFillRectsArray(renderer,rects)) {return}
                var wx,wy : float
                if(!render_to_window(renderer,50.0,50.0,wx,wy)) {return}
                print("Logical center (50,50) in window coordinates: {wx}, {wy}\n")
                rendered=SDL_RenderPresent(renderer)
                if(rendered && !smoke) {SDL_Delay(1200u)}
            }
            if(!created) {rendered=false}
        }
        if(!opened) {rendered=false}
    }
    if(!initialized || !rendered) {print("Presentation failed: {SDL_GetError()}\n");return 1}
    return 0
}
