options gen2
require dassdl3/sdl3_boost
require math

def input_loop(window : SDL_Window?; renderer : SDL_Renderer?; smoke : bool; var frames : int&) : $Result<SdlUnit; SdlError> {
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
        var set_title_result <- window |> set_title("dasSDL3 | {typed} [{composition}] | mouse/arrows, click, wheel; Esc exits")
        if (is_err(set_title_result)) { return err(unwrap_err(set_title_result),type<SdlUnit>) }
        var clear_result <- renderer |> clear()
        if (is_err(clear_result)) { return err(unwrap_err(clear_result),type<SdlUnit>) }
        var set_color_result <- renderer |> set_color(alternate ? uint4(245u, 190u, 60u, 255u) : uint4(70u, 200u, 160u, 255u))
        if (is_err(set_color_result)) { return err(unwrap_err(set_color_result),type<SdlUnit>) }
        var fill_rect_result <- renderer |> fill_rect(SDL_MakeFRect(position.x - size / 2.0, position.y - size / 2.0, size, size))
        if (is_err(fill_rect_result)) { return err(unwrap_err(fill_rect_result),type<SdlUnit>) }
        var present_result <- renderer |> present()
        if (is_err(present_result)) { return err(unwrap_err(present_result),type<SdlUnit>) }
        frames++
        if (smoke && frames >= 60) { break }
        SDL_Delay(16u)
    }

    return sdl_ok()
}

def run_input(window : SDL_Window?; renderer : SDL_Renderer?; smoke : bool; var frames : int&) : $Result<SdlUnit; SdlError> {
    return with_text_input(window) {
        return input_loop(window, renderer, smoke, frames)
    }
}

[export]
def main(smoke : bool) : int {
    var frames = 0
    print("Mouse: move square; left click: color; wheel: size; arrows: move.\n")
    print("Type UTF-8 text: window title; Backspace: clear; Escape: quit.\n")
    let result = with_sdl() {
        let flags = smoke ? SDL_WINDOW_HIDDEN : 0ul
        return with_window("dasSDL3 input", 800, 600, flags) $(window : SDL_Window?) {
            return window |> with_renderer() $(renderer : SDL_Renderer?) {
                return run_input(window, renderer, smoke, frames)
            }
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Input example: {frames} frames; text input stopped.\n")
    return 0
}
