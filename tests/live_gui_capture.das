options gen2
module live_gui_capture
require dassdl3/sdl3_pixels_boost
require dassdl3/sdl3_try
require live/live_commands
require daslib/json_boost

var pending = false
var completed = 0

[live_command(description = "Queue test framebuffer capture before the next present")]
def gui_capture(input : JsonValue?) : JsonValue? {
    pending = true
    return JV(completed + 1)
}

[live_command(description = "Read completed test capture number")]
def gui_capture_status(input : JsonValue?) : JsonValue? {
    return JV(completed)
}

def public capture_test_frame(renderer : SDL_Renderer?) : SdlStatus {
    if (!pending) { return sdl_ok() }
    renderer |> with_read_pixels() $(surface : SDL_Surface?) {
        return sdl_status(SDL_SaveBMP(surface, "capture.bmp"), "SDL_SaveBMP")
    } |> sdl_try
    pending = false
    completed++
    return sdl_ok()
}
