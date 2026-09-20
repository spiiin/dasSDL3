options gen2
require dassdl3/sdl3_renderer_state_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let opened=with_window("Viewport and clipping",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?) {
            let surface=SDL_GetWindowSurface(window)
            if(surface==null) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
            let created=with_software_renderer(surface) $(renderer : SDL_Renderer?) {
                var w,h : int
                var operation_result_1 <- render_output_size(renderer,w,h)
                if (is_err(operation_result_1)) {return err(unwrap_err(operation_result_1),type<SdlUnit>)}
                if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
                // These coordinates are scaled by two into output pixels.
                if(!SDL_SetRenderScale(renderer,2.0,2.0)) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
                var viewport : SDL_Rect
                viewport.x=10;viewport.y=10;viewport.w=w/2-20;viewport.h=h/2-20
                var clip : SDL_Rect
                clip.x=10;clip.y=10;clip.w=viewport.w-20;clip.h=viewport.h-20
                if(!SDL_SetRenderViewportRef(renderer,viewport) || !SDL_SetRenderClipRectRef(renderer,clip)) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
                if(!SDL_SetRenderDrawColor(renderer,60u,180u,230u,255u)) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
                var rects : array<SDL_FRect>;resize(rects,3)
                for(i in 0 .. 3) {rects[i].x=float(i*45);rects[i].y=float(i*15);rects[i].w=35.0;rects[i].h=65.0}
                if(!SDL_RenderFillRectsArray(renderer,rects)) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
                rendered=SDL_FlushRenderer(renderer) && SDL_UpdateWindowSurface(window)
                if(!rendered) {return err(sdl_error("58_renderer_state"),type<SdlUnit>)}
                if(rendered && !smoke) {SDL_Delay(1200u)}

                return sdl_ok()
            }
            if (is_err(created)) {rendered=false; return err(unwrap_err(created),type<SdlUnit>) }

            return sdl_ok()
        }
        if (is_err(opened)) {rendered=false; return err(unwrap_err(opened),type<SdlUnit>) }

        return sdl_ok()
    }
    if(!is_ok(initialized) || !rendered) {print("Renderer state example failed: {is_err(initialized) ? unwrap_err(initialized).message : SDL_GetErrorCopy()}\n");return 1}
    return 0
}
