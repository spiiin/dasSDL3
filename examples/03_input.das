options gen2
require dassdl3/sdl3_boost
require math

var example_failed = false

[export]
def main(smoke : bool) : int {
    var frames = 0
    print("Mouse: move square; left click: color; wheel: size; arrows: move.\n")
    print("Type UTF-8 text: window title; Backspace: clear; Escape: quit.\n")
    let scope_ok_0 = with_sdl() {
        let flags = smoke ? SDL_WINDOW_HIDDEN : 0ul
        let scope_ok_1 = with_window("dasSDL3 input", 800, 600, flags) $(window : SDL_Window?) {
            let scope_ok_2 = window |> with_renderer() $(renderer : SDL_Renderer?) {
                let scope_ok_3 = with_text_input(window) {
                    var event = SDL_MakeEvent()
                    var key : SDL_KeyboardEvent
                    var motion : SDL_MouseMotionEvent
                    var button : SDL_MouseButtonEvent
                    var wheel : SDL_MouseWheelEvent
                    var typed = ""
                    var incoming = ""
                    var composition = ""
                    var selection_start, selection_length : int
                    var position = float2(400.0, 300.0)
                    var size = 80.0
                    var alternate = false
                    var running = true
                    var previous = SDL_GetTicks()
                    while (running) {
                        while (is_some(poll_event(event))) {
                            if (should_close(event, window)) { running = false }
                            if (input_window_id(event) != SDL_GetWindowID(window)) { continue }
                            if (is_some(mouse_motion_event(event, motion))) {
                                position = float2(motion.x, motion.y)
                            }
                            if (is_some(mouse_button_event(event, button))) {
                                if (button.down && uint(button.button) == SDL_BUTTON_LEFT) { alternate = !alternate }
                            }
                            if (is_some(mouse_wheel_event(event, wheel))) {
                                size = clamp(size + wheel_delta(wheel).y * 8.0, 16.0, 240.0)
                            }
                            if (is_some(key_event(event, key))) {
                                if (key.down && key.key == SDLK_BACKSPACE) { typed = "" }
                            }
                            if (is_some(text_input_event(event, incoming))) {
                                typed := "{typed}{incoming}"
                                composition = ""
                            }
                            if (is_some(text_editing_event(event, incoming, selection_start, selection_length))) {
                                composition := incoming
                            }
                        }
                        if (!running) { break }
                        let now = SDL_GetTicks()
                        let dt = min(float(now - previous) / 1000.0, 0.1)
                        previous = now
                        if (key_down(SDL_SCANCODE_LEFT)) { position.x -= 240.0 * dt }
                        if (key_down(SDL_SCANCODE_RIGHT)) { position.x += 240.0 * dt }
                        if (key_down(SDL_SCANCODE_UP)) { position.y -= 240.0 * dt }
                        if (key_down(SDL_SCANCODE_DOWN)) { position.y += 240.0 * dt }
                        position.x = clamp(position.x, size / 2.0, 800.0 - size / 2.0)
                        position.y = clamp(position.y, size / 2.0, 600.0 - size / 2.0)
                        var operation_result_1 <- window |> set_title("dasSDL3 | {typed} [{composition}] | mouse/arrows, click, wheel; Esc exits")
                        if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                        var operation_result_2 <- renderer |> clear()
                        if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                        var operation_result_3 <- renderer |> set_color(alternate ? uint4(245u, 190u, 60u, 255u) : uint4(70u, 200u, 160u, 255u))
                        if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
                        var operation_result_4 <- renderer |> fill_rect(SDL_MakeFRect(position.x - size / 2.0, position.y - size / 2.0, size, size))
                        if (is_err(operation_result_4)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_4).message}\n"); return err(unwrap_err(operation_result_4),type<SdlUnit>) }
                        var operation_result_5 <- renderer |> present()
                        if (is_err(operation_result_5)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_5).message}\n"); return err(unwrap_err(operation_result_5),type<SdlUnit>) }
                        frames++
                        if (smoke && frames >= 60) { break }
                        SDL_Delay(16u)
                    }

                    return sdl_ok()
                }
                if (is_err(scope_ok_3)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_3).message}\n") ; return err(unwrap_err(scope_ok_3),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

            return sdl_ok()
        }
        if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    print("Input example: {frames} frames; text input stopped.\n")
    return example_failed ? 1 : 0
}
