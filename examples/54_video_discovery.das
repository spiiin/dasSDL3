options gen2
require dassdl3/sdl3_video_boost
[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        var ids : array<uint>
        var displays_result <- displays(ids)
        if (is_err(displays_result)) {return displays_result}
        for(id in ids) {
            var mode : SDL_DisplayMode
            if(SDL_GetDesktopDisplayModeCopy(id,mode)) {
                let name=unwrap_or(display_name(id), "")
                print("{name}: {mode.w} x {mode.h}, {mode.refresh_rate} Hz\n")
            }
        }
        return with_window("Video discovery",320,240,SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            var w=0;var h=0
            if(is_ok(window_size_pixels(window,w,h))) {print("Window pixel size: {w} x {h}\n")}

            return sdl_ok()
        }
    }
    if(is_err(initialized)) {
        let error=unwrap_err(initialized)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
