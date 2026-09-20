options gen2
require dassdl3/sdl3_pixels_boost

// Project example: offscreen render -> owned readback -> display the target.
var example_failed = false

[export]
def main(smoke : bool) : int {
    var frames = 0
    let scope_ok_0 = with_sdl() {
        with_window("Render target + readback - Escape to exit", 640, 480,
                    smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window) {
            let scope_ok_1 = window |> with_renderer() $(renderer) {
                let scope_ok_2 = renderer |> with_target_texture(128, 128) $(target) {
                    let scope_ok_3 = renderer |> with_render_target(target) {
                        if (!(renderer |> clear(uint4(20u, 40u, 80u, 255u)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(renderer |> set_color(uint4(255u, 160u, 20u, 255u)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(renderer |> fill_rect(SDL_MakeFRect(32.0, 32.0, 64.0, 64.0)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        // Readback is expensive: do it once, not on every frame.
                        let scope_ok_4 = renderer |> with_read_pixels() $(surface) {
                            var query_result_1 : int2
                            if (!surface_size(surface,query_result_1)) { example_failed = true; print("SDL query: {SDL_GetError()}\n"); return }
                            let size = query_result_1
                            var bytes : array<uint8>
                            bytes |> resize(rgba8_buffer_size(size.x, size.y, size.x * 4))
                            if (!(surface |> copy_surface_rgba8(bytes, size.x * 4))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                            verify(bytes[0] == uint8(20) && bytes[1] == uint8(40) && bytes[2] == uint8(80))
                            print("Readback: {size.x} x {size.y}, RGBA copy verified.\n")
                        }
                        if (!scope_ok_4) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
                    }
                    if (!scope_ok_3) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
                    var event = SDL_MakeEvent()
                    var running = true
                    while (running) {
                        while (poll_event(event)) {
                            if (should_close(event, window)) { running = false }
                        }
                        if (!running) { break }
                        if (!(renderer |> clear())) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(renderer |> draw_texture(target, SDL_MakeFRect(192.0, 112.0, 256.0, 256.0)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
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
    print("Render target: {frames} frames; previous target restored, resources released.\n")
    return example_failed ? 1 : 0
}
