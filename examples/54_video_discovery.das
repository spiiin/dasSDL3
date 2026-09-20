options gen2
require dassdl3/sdl3_video_boost
[export]
def main(smoke : bool) : int {
    var ok=false
    let initialized=with_sdl() {
        var ids : array<uint>
        var operation_result_1 <- displays(ids)
        if (is_err(operation_result_1)) {print("{unwrap_err(operation_result_1).message}\n");return err(unwrap_err(operation_result_1),type<SdlUnit>)}
        for(id in ids) {
            var mode : SDL_DisplayMode
            if(SDL_GetDesktopDisplayModeCopy(id,mode)) {
                let name=unwrap_or(display_name(id), "")
                print("{name}: {mode.w} x {mode.h}, {mode.refresh_rate} Hz\n")
            }
        }
        ok=with_window("Video discovery",320,240,SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            var w=0;var h=0
            if(is_ok(window_size_pixels(window,w,h))) {print("Window pixel size: {w} x {h}\n")}

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    return is_ok(initialized) && ok ? 0 : 1
}
