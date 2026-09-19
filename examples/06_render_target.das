options gen2
require dassdl3/sdl3_pixels_boost

// Project example: offscreen render -> owned readback -> display the target.
[export]
def main(smoke : bool) : int {
    var frames = 0
    with_sdl() {
        with_window("Render target + readback - Escape to exit", 640, 480,
                    smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window) {
            window |> with_renderer() $(renderer) {
                renderer |> with_target_texture(128, 128) $(target) {
                    renderer |> with_render_target(target) {
                        renderer |> clear(uint4(20u, 40u, 80u, 255u))
                        renderer |> set_color(uint4(255u, 160u, 20u, 255u))
                        renderer |> fill_rect(SDL_MakeFRect(32.0, 32.0, 64.0, 64.0))
                        // Readback is expensive: do it once, not on every frame.
                        renderer |> with_read_pixels() $(surface) {
                            let size = surface_size(surface)
                            var bytes : array<uint8>
                            bytes |> resize(rgba8_buffer_size(size.x, size.y, size.x * 4))
                            surface |> copy_surface_rgba8(bytes, size.x * 4)
                            verify(bytes[0] == uint8(20) && bytes[1] == uint8(40) && bytes[2] == uint8(80))
                            print("Readback: {size.x} x {size.y}, RGBA copy verified.\n")
                        }
                    }
                    var event = SDL_MakeEvent()
                    var running = true
                    while (running) {
                        while (poll_event(event)) {
                            if (should_close(event, window)) { running = false }
                        }
                        if (!running) { break }
                        renderer |> clear()
                        renderer |> draw_texture(target, SDL_MakeFRect(192.0, 112.0, 256.0, 256.0))
                        renderer |> present()
                        frames++
                        if (smoke && frames >= 60) { break }
                        SDL_Delay(16u)
                    }
                }
            }
        }
    }
    print("Render target: {frames} frames; previous target restored, resources released.\n")
    return 0
}
