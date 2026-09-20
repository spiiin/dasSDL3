options gen2
require dassdl3/sdl3_renderer_primitives_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let opened=with_window("Software renderer",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?) {
            // Window owns this surface; renderer must be destroyed before the window.
            let surface=SDL_GetWindowSurface(window)
            if(surface==null) {return err(sdl_error("57_software_renderer"),type<SdlUnit>)}
            let created=with_software_renderer(surface) $(renderer : SDL_Renderer?) {
                if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("57_software_renderer"),type<SdlUnit>)}
                var rects : array<SDL_FRect>;resize(rects,3)
                for(i in 0 .. 3) {rects[i].x=float(30+i*90);rects[i].y=float(40+i*30);rects[i].w=60.0;rects[i].h=80.0}
                if(!SDL_SetRenderDrawColor(renderer,60u,180u,230u,255u) || !SDL_RenderFillRectsArray(renderer,rects)) {return err(sdl_error("57_software_renderer"),type<SdlUnit>)}
                rendered=SDL_FlushRenderer(renderer) && SDL_UpdateWindowSurface(window)
                if(!rendered) {return err(sdl_error("57_software_renderer"),type<SdlUnit>)}
                if(rendered && !smoke) {SDL_Delay(1200u)}

                return sdl_ok()
            }
            if (is_err(created)) {rendered=false; return err(unwrap_err(created),type<SdlUnit>) }

            return sdl_ok()
        }
        if (is_err(opened)) {rendered=false; return err(unwrap_err(opened),type<SdlUnit>) }

        return sdl_ok()
    }
    if(!is_ok(initialized) || !rendered) {print("Software rendering failed: {is_err(initialized) ? unwrap_err(initialized).message : SDL_GetErrorCopy()}\n");return 1}
    return 0
}
