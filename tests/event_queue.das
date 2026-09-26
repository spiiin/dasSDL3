options gen2
require dassdl3/sdl3_event_queue
require dassdl3/sdl3_scope

def check_user(event : SdlEvent; event_type : uint; code : int) {
    verify(event is user)
    let user = event as user
    verify(user.event_type == event_type && user.code == code)
}

def test_queue(window : SDL_Window?) {
    verify(should_close(SdlEvent(quit = QuitEvent())))
    verify(should_close(SdlEvent(key_down = KeyEvent(keycode = SDLK_ESCAPE))))
    verify(!should_close(SdlEvent(key_up = KeyEvent(keycode = SDLK_ESCAPE))))
    verify(should_close(SdlEvent(window = WindowEvent(window_id = SDL_GetWindowID(window), event_type = SDL_EVENT_WINDOW_CLOSE_REQUESTED)), window))
    SDL_PumpEvents()
    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST)
    let first = register_events(3) |> sdl_try
    var iter_raw = SDL_MakeUserEvent(first, 0u, 17)
    verify(SDL_PushEventRef(iter_raw)); verify(SDL_PushEventRef(iter_raw))
    var iter_count = 0
    for (event in poll_events()) {
        check_user(event, first, 17)
        iter_count++
        break
    }
    verify(iter_count == 1 && SDL_HasEvent(first))
    for (event in poll_events()) { check_user(event, first, 17); iter_count++ }
    verify(iter_count == 2 && !SDL_HasEvent(first))
    SDL_SetErrorText("stale iterator error")
    for (event in poll_events()) { verify(false) }
    let raw_first = SDL_RegisterEvents(2)
    verify(raw_first >= first + 3u)
    SDL_SetErrorText("stale register error")
    verify(SDL_RegisterEvents(0) == 0u)
    let bad_registration = register_events(0)
    verify(is_err(bad_registration) && unwrap_err(bad_registration).message == "Invalid user event count")
    verify(is_err(register_events(-1)) && is_err(register_events(2147483647)))

    var input : array<SDL_Event>
    resize(input, 3)
    for (i in 0 .. 3) { input[i] = SDL_MakeUserEvent(first + uint(i), SDL_GetWindowID(window), 100 + i) }
    unsafe { verify(SDL_PeepEvents(addr(input[0]), 3, SDL_EventAction.ADDEVENT, 0u, 0u) == 3) }
    verify(SDL_HasEvent(first) && SDL_HasEvents(first, first + 2u))
    verify(unwrap(count_events(first, first + 2u)) == 3)
    unsafe { verify(SDL_PeepEvents(null, 0, SDL_EventAction.PEEKEVENT, first, first + 2u) == 3) }
    var peeked <- peek_events(2, first, first + 2u) |> sdl_try
    verify(length(peeked) == 2)
    check_user(peeked[0], first, 100); check_user(peeked[1], first + 1u, 101)
    verify(unwrap(count_events(first, first + 2u)) == 3)
    var taken <- take_events(1, first + 1u, first + 1u) |> sdl_try
    verify(length(taken) == 1); check_user(taken[0], first + 1u, 101)
    verify(!SDL_HasEvent(first + 1u) && SDL_HasEvent(first) && SDL_HasEvent(first + 2u))
    var raw = SDL_MakeEvent()
    unsafe {
        verify(SDL_PeepEvents(addr(raw), 1, SDL_EventAction.GETEVENT, first, first) == 1)
        verify(SDL_GetWindowFromEvent(addr(raw)) == window)
    }
    var associated_window <- event_window(raw)
    verify(is_some(associated_window) && move_unwrap(associated_window) == window)
    verify(is_none(event_window(SDL_MakeEvent())))
    check_user(decode_event(raw), first, 100)
    SDL_FlushEvent(first + 2u)
    verify(!SDL_HasEvents(first, first + 2u))

    SDL_SetEventEnabled(first, true)
    verify(SDL_EventEnabled(first))
    verify(SDL_PushEventRef(input[0]))
    SDL_SetEventEnabled(first, false)
    verify(!SDL_EventEnabled(first) && !SDL_HasEvent(first))
    // Peep ADD bypasses producer-side enabled checks as well as callbacks.
    verify(unwrap(peep_events(input, SDL_EventAction.ADDEVENT)) == 3)
    verify(SDL_HasEvent(first))
    SDL_FlushEvents(first, first + 2u)
    SDL_SetEventEnabled(first, true)

    // Empty destination must not accidentally become SDL's NULL count query.
    verify(SDL_PushEventRef(input[0]))
    var empty_events : array<SDL_Event>
    verify(unwrap(peep_events(empty_events, SDL_EventAction.GETEVENT)) == 0)
    var zero <- take_events(0) |> sdl_try
    verify(empty(zero) && SDL_HasEvent(first))
    verify(is_err(take_events(-1)))
    var output : array<SDL_Event>; resize(output, 4)
    verify(unwrap(peep_events(output, SDL_EventAction.GETEVENT, first, first + 2u)) == 1)
    verify(output[0].event_type == first && output[1].event_type == 0u)
    verify(unwrap(peep_events(output, SDL_EventAction.PEEKEVENT, first, first + 2u)) == 0)
    verify(output[0].event_type == 0u)

    // Queued-event waits are deterministic and do not depend on external input.
    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST)
    verify(SDL_PushEventRef(input[0]))
    unsafe { verify(SDL_WaitEvent(addr(raw))) }
    check_user(decode_event(raw), first, 100)
    verify(SDL_PushEventRef(input[1]))
    var waited <- wait_event() |> sdl_try
    check_user(waited, first + 1u, 101)
    verify(SDL_PushEventRef(input[2]))
    wait_event(raw) |> sdl_try
    verify(raw.event_type == first + 2u)
    verify(SDL_PushEventRef(input[0]))
    unsafe { verify(SDL_WaitEventTimeout(addr(raw), 10)) }
    verify(SDL_PushEventRef(input[1]))
    var timed <- wait_event_timeout(10) |> sdl_try
    verify(is_some(timed)); check_user(unwrap(timed), first + 1u, 101)
    verify(SDL_PushEventRef(input[2]))
    let borrowed = wait_event_timeout(raw, 10) |> sdl_try
    verify(is_some(borrowed) && raw.event_type == first + 2u)
    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST)
    SDL_SetErrorText("stale timeout error")
    var timeout <- wait_event_timeout(1) |> sdl_try
    verify(is_none(timeout))
    let immediate = wait_event_timeout(raw, 0) |> sdl_try
    verify(is_none(immediate) && raw.event_type == 0u)

    // Pinned SDL queue capacity: partial ADD is a count, not a failed Result.
    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST)
    var filling : array<SDL_Event>; resize(filling, 65534)
    for (event in filling) { event = input[0] }
    verify(unwrap(peep_events(filling, SDL_EventAction.ADDEVENT)) == 65534)
    let partial = peep_events(input, SDL_EventAction.ADDEVENT)
    verify(is_ok(partial) && unwrap(partial) == 1)
    verify(unwrap(peep_events(input, SDL_EventAction.ADDEVENT)) == 0)
    verify(unwrap(count_events(first, first + 2u)) == 65535)
    SDL_FlushEvents(first, first + 2u)
    return sdl_ok()
}

def test_payloads(window : SDL_Window?) {
    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST)
    let types <- array<uint>(SDL_EVENT_DROP_BEGIN, SDL_EVENT_DROP_FILE, SDL_EVENT_DROP_TEXT, SDL_EVENT_DROP_COMPLETE, SDL_EVENT_DROP_POSITION)
    var raw : array<SDL_Event>; resize(raw, 5)
    for (i in 0 .. 5) { raw[i] = SDLTestDropEvent(types[i], SDL_GetWindowID(window)) }
    verify(unwrap(peep_events(raw, SDL_EventAction.ADDEVENT)) == 5)
    var peeked <- peek_events(5, SDL_EVENT_DROP_FILE, SDL_EVENT_DROP_POSITION) |> sdl_try
    var taken <- take_events(5, SDL_EVENT_DROP_FILE, SDL_EVENT_DROP_POSITION) |> sdl_try
    verify(length(peeked) == 5 && length(taken) == 5)
    verify(taken[0] is drop_begin && taken[1] is drop_file && taken[2] is drop_text && taken[3] is drop_complete && taken[4] is drop_position)
    let file = taken[1] as drop_file
    verify(file.timestamp == 0xfedcba9876543210ul && file.window_id == SDL_GetWindowID(window))
    verify(file.position == float2(12.5, -4.5) && file.source == "source application" && file.data == "файл-日本.txt")
    verify((taken[0] as drop_begin).data == "")
    SDLTestMutateDropText()
    SDL_PumpEvents()
    verify((peeked[1] as drop_file).data == "файл-日本.txt" && (taken[2] as drop_text).source == "source application")
    // A wrong union tag must never interpret another member as drop pointers.
    var poisoned = SDLTestInputEvent(SDL_EVENT_MOUSE_MOTION, 0u)
    var window_id : uint; var position : float2; var source, data : string
    verify(!SDL_ReadDropEvent(poisoned, window_id, position, source, data))
    verify(window_id == 0u && source == "" && data == "")
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("queue test", 32, 32, SDL_WINDOW_HIDDEN) |> sdl_use
        test_queue(window) |> sdl_try
        return test_payloads(window)
    }
    if (is_err(result)) { print("{unwrap_err(result).operation}: {unwrap_err(result).message}\n"); return 1 }
    // Shutdown is a deterministic SDL error, distinct from an empty live queue.
    SDL_SetErrorText("stale shutdown error")
    var failed <- wait_event_timeout(0)
    verify(is_err(failed))
    let saved = unwrap_err(failed)
    SDL_SetErrorText("later error")
    verify(saved.operation == "SDL_WaitEventTimeout" && saved.message != "stale shutdown error" && saved.message != "later error")
    verify(is_err(wait_event()) && is_err(count_events()))
    var raw : array<SDL_Event>; resize(raw, 1)
    verify(is_err(peep_events(raw, SDL_EventAction.PEEKEVENT)))
    print("Event queue: raw API, ranges, order, waits, errors and owned payloads PASS\n")
    return 0
}
