options gen2
require dassdl3/sdl3_window_io_boost
[export]
def main(smoke : bool) : int {
    var painted=false
    let initialized=with_sdl() {
        let owned=with_window("Window surface",320,240,SDL_WINDOW_HIDDEN) $(window) {
            let surface=SDL_GetWindowSurface(window)
            if(surface==null){return}
            let color=SDL_MapSurfaceRGBA(surface,uint(30),uint(100),uint(180),uint(255))
            if(!SDL_FillSurfaceAll(surface,color)){return}
            var rect : SDL_Rect
            rect.x=40;rect.y=40;rect.w=100;rect.h=80
            let accent=SDL_MapSurfaceRGBA(surface,uint(240),uint(180),uint(20),uint(255))
            if(!SDL_FillSurfaceRectRef(surface,rect,accent)){return}
            painted=SDL_UpdateWindowSurface(window)
            if(painted){print("Painted borrowed window surface; window owns its cleanup\n")}
        }
        if(!owned || !painted){print("{SDL_GetError()}\n")}
    }
    return initialized && painted ? 0 : 1
}
