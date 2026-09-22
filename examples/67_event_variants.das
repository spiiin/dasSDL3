options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_events
require daslib/match

def event_loop(window : SDL_Window?; smoke : bool) {
    var running = true
    var frames = 0
    while (running) {
        for (event in poll_events()) {
            if(should_close(event,window)) { running=false; break }
            match (event) {
                if (SdlEvent(quit=_)) { running = false }
                if (SdlEvent(key_down=$v(key))) {
                    print("Key pressed: {key.scancode}, repeat: {key.repeat}\n")
                    if (key.keycode == SDLK_ESCAPE && key.window_id == SDL_GetWindowID(window)) { running = false }
                }
                if (SdlEvent(mouse_motion=$v(mouse))) { print("Mouse: {mouse.position}, delta: {mouse.delta}\n") }
                if (SdlEvent(text_input=$v(input))) { print("Text entered: {input.text}\n") }
                if (SdlEvent(text_editing=$v(edit))) { print("Composition: {edit.text} ({edit.start}, {edit.length})\n") }
                if (SdlEvent(text_editing_candidates=$v(ime))) {
                    print("IME candidates: {length(ime.candidates)}, selected: {ime.selected_candidate}\n")
                    for(candidate in ime.candidates) {print("  {candidate}\n")}
                }
                if (SdlEvent(clipboard_update=$v(clipboard))) {
                    print("Clipboard owner: {clipboard.owner}\n")
                    for(mime in clipboard.mime_types) {print("  MIME: {mime}\n")}
                }
                if (SdlEvent(window=$v(value))) {
                    if (value.event_type == SDL_EVENT_WINDOW_CLOSE_REQUESTED && value.window_id == SDL_GetWindowID(window)) { running = false }
                }
                if (_) { } // Other events are intentionally ignored by this application.
            }
        }
        frames++
        if (smoke && frames >= 3) { break }
        SDL_Delay(16u)
    }
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    print("Move the mouse, press keys or enter text. Escape closes the window.\n")
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("dasSDL3 event variants",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        with_text_input(window) |> sdl_use
        return event_loop(window,smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
