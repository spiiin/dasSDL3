options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_video_boost
[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        var ids : array<uint>
        displays(ids) |> sdl_try
        for(id in ids) {
            var mode : SDL_DisplayMode
            if(SDL_GetDesktopDisplayModeCopy(id,mode)) {
                let name=display_name(id) |> sdl_try
                print("{name}: {mode.w} x {mode.h}, {mode.refresh_rate} Hz\n")
            }
        }
        return with_window("Video discovery",320,240,SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            var w=0;var h=0
            window_size_pixels(window,w,h) |> sdl_try
            print("Window pixel size: {w} x {h}\n")

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
