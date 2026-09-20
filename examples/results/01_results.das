options gen2
require dassdl3/sdl3_init_boost

[export]
def main(smoke : bool) : int {
    var frames = 0
    let result = with_sdl(SDL_INIT_VIDEO) {
        let flags = smoke ? SDL_WINDOW_HIDDEN : SDL_WINDOW_RESIZABLE
        return with_window("SDL Result/Option - Escape to exit", 640, 480, flags) $(window : SDL_Window?) {
            return window |> with_renderer() $(renderer : SDL_Renderer?) {
                return renderer |> with_texture("{SDL_GetBasePath()}assets/checker.bmp") $(texture : SDL_Texture?) {
                    return texture_size(texture) |> and_then() $(size : float2) {
                        print("Texture: {size.x} x {size.y}\n")
                        var event = SDL_MakeEvent()
                        var running = true
                        while (running) {
                            while (is_some(poll_event(event))) {
                                if (should_close(event)) { running = false }
                            }
                            if (!running) { break }
                            var cleared = renderer |> clear()
                            if (is_err(cleared)) { return <- cleared }
                            var drawn = renderer |> draw_texture(texture)
                            if (is_err(drawn)) { return <- drawn }
                            var presented = renderer |> present()
                            if (is_err(presented)) { return <- presented }
                            frames++
                            if (smoke && frames >= 3) { break }
                            SDL_Delay(16u)
                        }
                        return sdl_ok()
                    }
                }
            }
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    let driver = hint_string("SDL_RENDER_DRIVER") |> unwrap_or("automatic")
    print("Rendered {frames} frames; resources released. Driver hint: {driver}\n")
    return 0
}
