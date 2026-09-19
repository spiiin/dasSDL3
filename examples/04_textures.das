options gen2
require dassdl3/sdl3_boost
require math

// Adapted from SDL release-3.2.18 examples/renderer/06-textures/textures.c
// (public domain). Uses our own BMP and explicit scoped ownership instead of callbacks.
[export]
def main(smoke : bool) : int {
    var frames = 0
    with_sdl() {
        let flags = smoke ? SDL_WINDOW_HIDDEN : 0ul
        with_window("dasSDL3 textures - Escape to exit", 640, 480, flags) $(window) {
            window |> with_renderer() $(renderer) {
                renderer |> with_texture("{SDL_GetBasePath()}assets/checker.bmp") $(texture) {
                    let size = texture_size(texture)
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
                        renderer |> clear()
                        // Moving original, scaled copy, and a cropped quadrant.
                        renderer |> draw_texture(texture, SDL_MakeFRect(30.0 + 20.0 * sin(phase), 30.0, size.x, size.y))
                        renderer |> draw_texture(texture, SDL_MakeFRect(220.0, 150.0, size.x * scale, size.y * scale))
                        let crop = SDL_MakeFRect(0.0, 0.0, size.x / 2.0, size.y / 2.0)
                        renderer |> draw_texture(texture, crop, SDL_MakeFRect(480.0, 330.0, 128.0, 128.0))
                        renderer |> present()
                        frames++
                        if (smoke && frames >= 60) { break }
                        SDL_Delay(16u)
                    }
                }
            }
        }
    }
    print("Textures: rendered {frames} frames; resources released.\n")
    return 0
}
