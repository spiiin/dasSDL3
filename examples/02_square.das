options gen2
require dassdl3/sdl3_boost
require math

var example_failed = false

[export]
def main(smoke : bool) : int {
    var frames = 0
    let scope_ok_0 = with_sdl() {
        let flags = smoke ? SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIDDEN : SDL_WINDOW_RESIZABLE
        let scope_ok_1 = with_window("dasSDL3 boost - Escape to exit", 800, 600, flags) $(window : SDL_Window?) {
            let scope_ok_2 = window |> with_renderer() $(renderer : SDL_Renderer?) {
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
                    var operation_result_1 <- renderer |> clear()
                    if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                    var operation_result_2 <- renderer |> set_color(uint4(70u, 200u, 160u, 255u))
                    if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                    var operation_result_3 <- renderer |> fill_rect(square)
                    if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
                    var operation_result_4 <- renderer |> present()
                    if (is_err(operation_result_4)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_4).message}\n"); return err(unwrap_err(operation_result_4),type<SdlUnit>) }
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
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    print("Rendered {frames} frames; SDL resources released.\n")
    return example_failed ? 1 : 0
}
