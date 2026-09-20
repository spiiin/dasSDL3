options gen2
require dassdl3/sdl3_renderer_presentation_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let opened=with_window("Logical presentation",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?) {
            let created=with_renderer(window) $(renderer : SDL_Renderer?) {
                print("Renderer: {renderer_name(renderer)}\n")
                if(!SDL_SetRenderLogicalPresentation(renderer,100,100,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_LETTERBOX)) {return err(sdl_error("59_renderer_presentation"),type<SdlUnit>)}
                if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("59_renderer_presentation"),type<SdlUnit>)}
                var rects : array<SDL_FRect>;resize(rects,3)
                for(i in 0 .. 3) {rects[i].x=float(10+i*30);rects[i].y=float(15+i*15);rects[i].w=20.0;rects[i].h=40.0}
                if(!SDL_SetRenderDrawColor(renderer,60u,180u,230u,255u) || !SDL_RenderFillRectsArray(renderer,rects)) {return err(sdl_error("59_renderer_presentation"),type<SdlUnit>)}
                var wx,wy : float
                var operation_result_1 <- render_to_window(renderer,50.0,50.0,wx,wy)
                if (is_err(operation_result_1)) {return err(unwrap_err(operation_result_1),type<SdlUnit>)}
                print("Logical center (50,50) in window coordinates: {wx}, {wy}\n")
                rendered=SDL_RenderPresent(renderer)
                if(!rendered) {return err(sdl_error("59_renderer_presentation"),type<SdlUnit>)}
                if(rendered && !smoke) {SDL_Delay(1200u)}

                return sdl_ok()
            }
            if (is_err(created)) {rendered=false; return err(unwrap_err(created),type<SdlUnit>) }

            return sdl_ok()
        }
        if (is_err(opened)) {rendered=false; return err(unwrap_err(opened),type<SdlUnit>) }

        return sdl_ok()
    }
    if(!is_ok(initialized) || !rendered) {print("Presentation failed: {is_err(initialized) ? unwrap_err(initialized).message : SDL_GetErrorCopy()}\n");return 1}
    return 0
}
