options gen2
require dassdl3/sdl3_boost
require math

def render_loop(renderer : SDL_Renderer?; smoke : bool; var frames : int&) : $Result<SdlUnit; SdlError> {
    var event = SDL_MakeEvent()
    let start = SDL_GetTicks()
    var running = true
    while (running) {
        while (is_some(poll_event(event))) {
            if (should_close(event)) { running = false }
        }
        if (!running) { break }
        let t = float(SDL_GetTicks() - start) / 1000.0
        let square = SDL_MakeFRect(360.0 + 200.0 * sin(t), 260.0, 80.0, 80.0)
        var clear_result <- renderer |> clear()
        if (is_err(clear_result)) { return clear_result }
        var set_color_result <- renderer |> set_color(uint4(70u, 200u, 160u, 255u))
        if (is_err(set_color_result)) { return set_color_result }
        var fill_rect_result <- renderer |> fill_rect(square)
        if (is_err(fill_rect_result)) { return fill_rect_result }
        var present_result <- renderer |> present()
        if (is_err(present_result)) { return present_result }
        frames++
        if (smoke && frames >= 60) { break }
        SDL_Delay(16u)
    }

    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    var frames = 0
    let result = with_sdl() {
        let flags = smoke ? SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIDDEN : SDL_WINDOW_RESIZABLE
        return with_window("dasSDL3 boost - Escape to exit", 800, 600, flags) $(window : SDL_Window?) {
            return window |> with_renderer() $(renderer : SDL_Renderer?) {
                return render_loop(renderer, smoke, frames)
            }
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Rendered {frames} frames; SDL resources released.\n")
    return 0
}
