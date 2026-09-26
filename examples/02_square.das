options gen2
require dassdl3/sdl3_window_boost
require dassdl3/sdl3_scope
require dassdl3/sdl3_boost
require math

def render_loop(renderer : SDL_Renderer?; smoke : bool; var frames : int&) : SdlStatus {
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
        renderer |> clear() |> sdl_try
        renderer |> set_color(uint4(70u, 200u, 160u, 255u)) |> sdl_try
        renderer |> fill_rect(square) |> sdl_try
        renderer |> present() |> sdl_try
        frames++
        if (smoke && frames >= 60) { break }
        SDL_Delay(16u)
    }

    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    var frames = 0
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        var settings = window_options("dasSDL3 boost - Escape to exit", int2(800, 600))
        settings |> window_flags(SDL_WINDOW_HIDDEN, smoke)
        let window : SDL_Window? = with_window(settings) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        return render_loop(renderer, smoke, frames)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Rendered {frames} frames; SDL resources released.\n")
    return 0
}
