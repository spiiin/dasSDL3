options gen2
require dassdl3/sdl3_keyboard_mouse_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_scope

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let flags = smoke ? SDL_WINDOW_HIDDEN : 0ul
        let window : SDL_Window? = with_window("Keyboard and mouse - Escape to exit", 640, 480, flags) |> sdl_use
        with_text_input(window) |> sdl_use
        let keyboard_ids <- keyboards() |> sdl_try
        let mouse_ids <- mice() |> sdl_try
        print("Keyboards: {length(keyboard_ids)}, mice: {length(mouse_ids)}\n")
        for (id in keyboard_ids) { let name = keyboard_name(id) |> sdl_try; print("Keyboard {id}: {name}\n") }
        for (id in mouse_ids) { let name = mouse_name(id) |> sdl_try; print("Mouse {id}: {name}\n") }
        var frames = 0
        var running = true
        while (running) {
            var event = SDL_MakeEvent()
            while (is_some(poll_event(event))) {
                if (should_close(event)) { running = false }
                var decoded <- decode_event(event)
                if (decoded is text_input) { print("Text: {(decoded as text_input).text}\n") }
            }
            let keys <- keyboard_state()
            if (keys[int(SDL_Scancode.SCANCODE_ESCAPE)]) { running = false }
            let mouse = mouse_state()
            if (frames == 0) { print("Mouse: {mouse.position}; buttons: {mouse.buttons}\n") }
            frames++
            if (smoke && frames >= 3) { break }
            SDL_Delay(16u)
        }
        return sdl_ok()
    }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }
    return 0
}
