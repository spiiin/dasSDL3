options gen2
require dassdl3/sdl3_event_queue
require dassdl3/sdl3_scope
require daslib/match

def run(window : SDL_Window?; smoke : bool) {
    let custom_type = register_events(1) |> sdl_try
    var initial = SDL_MakeUserEvent(custom_type, SDL_GetWindowID(window), 42)
    if (!push_event(initial)) {
        return err(SdlError(operation = "push_event", message = "Initial event was not accepted"), type<SdlUnit>)
    }
    var preview <- peek_events(8, custom_type, custom_type) |> sdl_try
    print("Queued custom events: {length(preview)} (peek does not remove them)\n")
    var running = true
    var waits = 0
    while (running) {
        var next <- wait_event_timeout(100) |> sdl_try
        if (is_none(next)) { print("No event before timeout\n") }
        else {
            let event <- move_unwrap(next)
            match (event) {
                if (SdlEvent(quit = _)) { running = false }
                if (SdlEvent(window = $v(value))) {
                    if (value.event_type == SDL_EVENT_WINDOW_CLOSE_REQUESTED) { running = false }
                }
                if (SdlEvent(key_down = $v(key))) {
                    if (key.scancode == SDL_SCANCODE_ESCAPE) { running = false }
                }
                if (SdlEvent(user = $v(value))) { print("User event: type={value.event_type}, code={value.code}\n") }
                if (SdlEvent(drop_file = $v(drop))) { print("Dropped file: {drop.data}\n") }
                if (_) { }
            }
        }
        waits++
        if (smoke && waits >= 3) { break }
    }
    return sdl_ok()
}
[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("SDL event queue - Escape to exit", 640, 480, smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        return run(window, smoke)
    }
    if (is_err(result)) { let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1 }
    return 0
}
