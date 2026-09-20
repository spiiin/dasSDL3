options gen2
require dassdl3/sdl3_pixels_boost

// Project example: offscreen render -> owned readback -> display the target.
var example_failed = false

[export]
def main(smoke : bool) : int {
    var frames = 0
    let scope_ok_0 = with_sdl() {
        with_window("Render target + readback - Escape to exit", 640, 480,
                    smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?) {
            let scope_ok_1 = window |> with_renderer() $(renderer : SDL_Renderer?) {
                let scope_ok_2 = renderer |> with_target_texture(128, 128) $(target : SDL_Texture?) {
                    let scope_ok_3 = renderer |> with_render_target(target) {
                        var operation_result_1 <- renderer |> clear(uint4(20u, 40u, 80u, 255u))
                        if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                        var operation_result_2 <- renderer |> set_color(uint4(255u, 160u, 20u, 255u))
                        if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                        var operation_result_3 <- renderer |> fill_rect(SDL_MakeFRect(32.0, 32.0, 64.0, 64.0))
                        if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
                        // Readback is expensive: do it once, not on every frame.
                        let scope_ok_4 = renderer |> with_read_pixels() $(surface : SDL_Surface?) {
                            var query_result_1 : int2
                            var operation_result_4 <- surface_size(surface,query_result_1)
                            if (is_err(operation_result_4)) { example_failed = true; print("SDL query: {unwrap_err(operation_result_4).message}\n"); return err(unwrap_err(operation_result_4),type<SdlUnit>) }
                            let size = query_result_1
                            var bytes : array<uint8>
                            bytes |> resize(unwrap_or(rgba8_buffer_size(size.x, size.y, size.x * 4), -1))
                            var operation_result_5 <- surface |> copy_surface_rgba8(bytes, size.x * 4)
                            if (is_err(operation_result_5)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_5).message}\n"); return err(unwrap_err(operation_result_5),type<SdlUnit>) }
                            verify(bytes[0] == uint8(20) && bytes[1] == uint8(40) && bytes[2] == uint8(80))
                            print("Readback: {size.x} x {size.y}, RGBA copy verified.\n")

                            return sdl_ok()
                        }
                        if (is_err(scope_ok_4)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_4).message}\n") ; return err(unwrap_err(scope_ok_4),type<SdlUnit>) }

                        return sdl_ok()
                    }
                    if (is_err(scope_ok_3)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_3).message}\n") ; return err(unwrap_err(scope_ok_3),type<SdlUnit>) }
                    var event = SDL_MakeEvent()
                    var running = true
                    while (running) {
                        while (is_some(poll_event(event))) {
                            if (should_close(event, window)) { running = false }
                        }
                        if (!running) { break }
                        var operation_result_6 <- renderer |> clear()
                        if (is_err(operation_result_6)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_6).message}\n"); return err(unwrap_err(operation_result_6),type<SdlUnit>) }
                        var operation_result_7 <- renderer |> draw_texture(target, SDL_MakeFRect(192.0, 112.0, 256.0, 256.0))
                        if (is_err(operation_result_7)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_7).message}\n"); return err(unwrap_err(operation_result_7),type<SdlUnit>) }
                        var operation_result_8 <- renderer |> present()
                        if (is_err(operation_result_8)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_8).message}\n"); return err(unwrap_err(operation_result_8),type<SdlUnit>) }
                        frames++
                        if (smoke && frames >= 60) { break }
                        SDL_Delay(16u)
                    }

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    print("Render target: {frames} frames; previous target restored, resources released.\n")
    return example_failed ? 1 : 0
}
