options gen2
require dassdl3/sdl3_pixels_boost

// Scenario adapted from SDL release-3.2.18 examples/renderer/07-streaming-textures
// (public domain). Own RGBA staging array replaces the borrowed locked surface.
var example_failed = false

[export]
def main(smoke : bool) : int {
    var frames = 0
    let scope_ok_0 = with_sdl() {
        with_window("Streaming RGBA - Escape to exit", 640, 480,
                    smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window) {
            let scope_ok_1 = window |> with_renderer() $(renderer) {
                let scope_ok_2 = renderer |> with_streaming_texture(150, 150) $(texture) {
                    var pixels : array<uint8>
                    pixels |> resize(rgba8_buffer_size(150, 150, 600))
                    var event = SDL_MakeEvent()
                    var running = true
                    while (running) {
                        while (poll_event(event)) {
                            if (should_close(event, window)) { running = false }
                        }
                        if (!running) { break }
                        let band = (frames * 2) % 135
                        for (pixel in 0 .. 22500) {
                            let y = pixel / 150
                            let i = pixel * 4
                            pixels[i] = uint8(0)
                            pixels[i+1] = uint8(y >= band && y < band + 15 ? 255 : 0)
                            pixels[i+2] = uint8(0)
                            pixels[i+3] = uint8(255)
                        }
                        if (!(texture |> upload_rgba8(pixels, 600))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(renderer |> clear(uint4(66u, 66u, 66u, 255u)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(renderer |> draw_texture(texture, SDL_MakeFRect(245.0, 165.0, 150.0, 150.0)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
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
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    print("Streaming texture: {frames} frames; staging array and texture released.\n")
    return example_failed ? 1 : 0
}
