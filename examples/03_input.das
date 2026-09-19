options gen2
require dassdl3/sdl3_boost
require math

[export]
def main(smoke : bool) : int {
    var frames = 0
    print("Mouse: move square; left click: color; wheel: size; arrows: move.\n")
    print("Type UTF-8 text: window title; Backspace: clear; Escape: quit.\n")
    with_sdl() {
        let flags = smoke ? SDL_WINDOW_HIDDEN : 0ul
        with_window("dasSDL3 input", 800, 600, flags) $(window) {
            window |> with_renderer() $(renderer) {
                with_text_input(window) {
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
                        while (poll_event(event)) {
                            if (should_close(event, window)) { running = false }
                            if (input_window_id(event) != SDL_GetWindowID(window)) { continue }
                            if (mouse_motion_event(event, motion)) {
                                position = float2(motion.x, motion.y)
                            }
                            if (mouse_button_event(event, button)) {
                                if (button.down && uint(button.button) == SDL_BUTTON_LEFT) { alternate = !alternate }
                            }
                            if (mouse_wheel_event(event, wheel)) {
                                size = clamp(size + wheel_delta(wheel).y * 8.0, 16.0, 240.0)
                            }
                            if (key_event(event, key)) {
                                if (key.down && key.key == SDLK_BACKSPACE) { typed = "" }
                            }
                            if (text_input_event(event, incoming)) {
                                typed := "{typed}{incoming}"
                                composition = ""
                            }
                            if (text_editing_event(event, incoming, selection_start, selection_length)) {
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
                        window |> set_title("dasSDL3 | {typed} [{composition}] | mouse/arrows, click, wheel; Esc exits")
                        renderer |> clear()
                        renderer |> set_color(alternate ? uint4(245u, 190u, 60u, 255u) : uint4(70u, 200u, 160u, 255u))
                        renderer |> fill_rect(SDL_MakeFRect(position.x - size / 2.0, position.y - size / 2.0, size, size))
                        renderer |> present()
                        frames++
                        if (smoke && frames >= 60) { break }
                        SDL_Delay(16u)
                    }
                }
            }
        }
    }
    print("Input example: {frames} frames; text input stopped.\n")
    return 0
}
