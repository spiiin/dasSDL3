options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_window_io_boost
[export]
def main(smoke : bool) : int {
    var painted=false
    let initialized=sdl_scope() {
        with_sdl() |> sdl_use
        let owned=sdl_scope() {
            let window : SDL_Window? = with_window("Window surface",320,240,SDL_WINDOW_HIDDEN) |> sdl_use
            let surface=SDL_GetWindowSurface(window)
            if(surface==null){return err(sdl_error("56_window_surface"),type<SdlUnit>)}
            let color=SDL_MapSurfaceRGBA(surface,uint(30),uint(100),uint(180),uint(255))
            if(!SDL_FillSurfaceAll(surface,color)){return err(sdl_error("56_window_surface"),type<SdlUnit>)}
            var rect : SDL_Rect
            rect.x=40;rect.y=40;rect.w=100;rect.h=80
            let accent=SDL_MapSurfaceRGBA(surface,uint(240),uint(180),uint(20),uint(255))
            if(!SDL_FillSurfaceRectRef(surface,rect,accent)){return err(sdl_error("56_window_surface"),type<SdlUnit>)}
            painted=SDL_UpdateWindowSurface(window)
            if(!painted) {return err(sdl_error("SDL_UpdateWindowSurface"),type<SdlUnit>)}
            if(painted){print("Painted borrowed window surface; window owns its cleanup\n")}

            return sdl_ok()
        }
        return owned
    }
    if(is_err(initialized)) {print("{unwrap_err(initialized).message}\n");return 1}
    return painted ? 0 : 1
}
