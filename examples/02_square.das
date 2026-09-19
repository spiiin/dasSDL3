options gen2
require dassdl3/sdl3_boost
require math

[export]
def main(smoke : bool) : int {
    var frames = 0
    with_sdl() {
        let flags = smoke ? SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIDDEN : SDL_WINDOW_RESIZABLE
        with_window("dasSDL3 boost - Escape to exit", 800, 600, flags) $(window) {
            window |> with_renderer() $(renderer) {
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
                    renderer |> clear()
                    renderer |> set_color(uint4(70u, 200u, 160u, 255u))
                    renderer |> fill_rect(square)
                    renderer |> present()
                    frames++
                    if (smoke && frames >= 60) { break }
                    SDL_Delay(16u)
                }
            }
        }
    }
    print("Rendered {frames} frames; SDL resources released.\n")
    return 0
}
