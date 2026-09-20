options gen2
require dassdl3/sdl3_boost
require math

var example_failed = false

[export]
def main(smoke : bool) : int {
    var frames = 0
    let scope_ok_0 = with_sdl() {
        let flags = smoke ? SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIDDEN : SDL_WINDOW_RESIZABLE
        let scope_ok_1 = with_window("dasSDL3 boost - Escape to exit", 800, 600, flags) $(window) {
            let scope_ok_2 = window |> with_renderer() $(renderer) {
                var event = SDL_MakeEvent()
                let start = SDL_GetTicks()
                var running = true
                while (running) {
                    while (poll_event(event)) {
                        if (should_close(event)) { running = false }
                    }
                    if (!running) { break }
                    let t = float(SDL_GetTicks() - start) / 1000.0
                    let square = SDL_MakeFRect(360.0 + 200.0 * sin(t), 260.0, 80.0, 80.0)
                    if (!(renderer |> clear())) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    if (!(renderer |> set_color(uint4(70u, 200u, 160u, 255u)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    if (!(renderer |> fill_rect(square))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    if (!(renderer |> present())) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    frames++
                    if (smoke && frames >= 60) { break }
                    SDL_Delay(16u)
                }
            }
            if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
        if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    print("Rendered {frames} frames; SDL resources released.\n")
    return example_failed ? 1 : 0
}
