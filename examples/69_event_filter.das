options gen2
require dassdl3/sdl3_event_queue
require dassdl3/sdl3_scope

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let first = register_events(1) |> sdl_try
        for (code in 0 .. 6) {
            var event = SDL_MakeUserEvent(first,0u,code)
            if (!push_event(event)) { return err(sdl_error("SDL_PushEvent"),type<SdlUnit>) }
        }
        // This block visits only the current queue; it is not retained.
        filter_events() $(var event : SDL_Event) {
            var decoded <- decode_event(event)
            if (decoded is user) { return (decoded as user).code % 2 == 0 }
            return true
        } |> sdl_try
        let events <- take_events(16,first,first) |> sdl_try
        verify(length(events) == 3)
        for (event in events) { print("Kept user event {(event as user).code}\n") }
        return sdl_ok()
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
