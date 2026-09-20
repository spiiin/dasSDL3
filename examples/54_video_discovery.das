options gen2
require dassdl3/sdl3_video_boost
[export]
def main(smoke : bool) : int {
    var ok=false
    let initialized=with_sdl() {
        var ids : array<uint>
        if(!displays(ids)) {print("{SDL_GetError()}\n");return}
        for(id in ids) {
            var mode : SDL_DisplayMode
            if(SDL_GetDesktopDisplayModeCopy(id,mode)) {
                let name=display_name(id)
                print("{name}: {mode.w} x {mode.h}, {mode.refresh_rate} Hz\n")
            }
        }
        ok=with_window("Video discovery",320,240,SDL_WINDOW_HIDDEN) $(window) {
            var w=0;var h=0
            if(window_size_pixels(window,w,h)) {print("Window pixel size: {w} x {h}\n")}
        }
    }
    return initialized && ok ? 0 : 1
}
