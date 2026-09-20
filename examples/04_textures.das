options gen2
require dassdl3/sdl3_boost
require math

// Adapted from SDL release-3.2.18 examples/renderer/06-textures/textures.c
// (public domain). Uses our own BMP and explicit scoped ownership instead of callbacks.
var example_failed = false

[export]
def main(smoke : bool) : int {
    var frames = 0
    let scope_ok_0 = with_sdl() {
        let flags = smoke ? SDL_WINDOW_HIDDEN : 0ul
        let scope_ok_1 = with_window("dasSDL3 textures - Escape to exit", 640, 480, flags) $(window) {
            let scope_ok_2 = window |> with_renderer() $(renderer) {
                let scope_ok_3 = renderer |> with_texture("{SDL_GetBasePath()}assets/checker.bmp") $(texture) {
                    var query_result_1 : float2
                    if (!texture_size(texture,query_result_1)) { example_failed = true; print("SDL query: {SDL_GetError()}\n"); return }
                    let size = query_result_1
                    var event = SDL_MakeEvent()
                    var running = true
                    let start = SDL_GetTicks()
                    while (running) {
                        while (poll_event(event)) {
                            if (should_close(event)) { running = false }
                        }
                        if (!running) { break }
                        let phase = float(SDL_GetTicks() - start) / 1000.0
                        let scale = 1.5 + 0.5 * sin(phase)
                        if (!(renderer |> clear())) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        // Moving original, scaled copy, and a cropped quadrant.
                        if (!(renderer |> draw_texture(texture, SDL_MakeFRect(30.0 + 20.0 * sin(phase), 30.0, size.x, size.y)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(renderer |> draw_texture(texture, SDL_MakeFRect(220.0, 150.0, size.x * scale, size.y * scale)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        let crop = SDL_MakeFRect(0.0, 0.0, size.x / 2.0, size.y / 2.0)
                        if (!(renderer |> draw_texture(texture, crop, SDL_MakeFRect(480.0, 330.0, 128.0, 128.0)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(renderer |> present())) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        frames++
                        if (smoke && frames >= 60) { break }
                        SDL_Delay(16u)
                    }
                }
                if (!scope_ok_3) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
        if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    print("Textures: rendered {frames} frames; resources released.\n")
    return example_failed ? 1 : 0
}
