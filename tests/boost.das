options gen2
require dassdl3/sdl3_boost
require daslib/rtti
require daslib/strings_boost

var cleanup_order = 0
var window_id = 0u

// Observe the actual SDL state after each scope, before SDL_Quit can mask leaks.
def exercise_window(window : SDL_Window?; mode : int) {
    var failed = false
    var error = ""
    try {
        if (mode == 3) { create_renderer(window, "dasSDL3-nonexistent-driver") }
        window |> with_renderer() $(renderer) {
            renderer |> clear()
            let rect = SDL_MakeFRect(1.0, 2.0, 10.0, 12.0)
            renderer |> fill_rect(rect)
            renderer |> present()
            if (mode == 1) { return }
            if (mode == 2) { panic("intentional cleanup test") }
            if (mode == 4) { renderer |> set_color(uint4(256u, 0u, 0u, 255u)) }
        }
    } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    verify(SDL_GetRenderer(window) == null, "renderer must be destroyed first")
    verify(SDL_GetWindowFromID(window_id) != null, "window destroyed before renderer")
    if (mode != 3) { cleanup_order = cleanup_order * 10 + 1 }
    if (failed) { panic(error) }
}

def exercise(mode : int) {
    with_sdl() {
        var failed = false
        var error = ""
        try {
            with_window("boost lifetime test", 64, 64, SDL_WINDOW_HIDDEN) $(window) {
                window_id = SDL_GetWindowID(window)
                verify(window_id != 0u)
                exercise_window(window, mode)
            }
        } recover {
            failed = true
            error := rtrim(this_context().last_exception)
        }
        verify(SDL_GetWindowFromID(window_id) == null, "window survived cleanup")
        verify(SDL_WasInit(SDL_INIT_VIDEO) != 0u, "SDL quit before window cleanup")
        cleanup_order = cleanup_order * 10 + 2
        if (failed) { panic(error) }
    }
}

[export]
def main(smoke : bool) : int {
    verify(smoke)
    for (mode in range(5)) {
        cleanup_order = 0
        window_id = 0u
        var caught = false
        var error = ""
        try { exercise(mode) } recover {
            caught = true
            error := rtrim(this_context().last_exception)
        }
        verify(caught == (mode >= 2), "unexpected failure/success")
        verify(cleanup_order == (mode == 3 ? 2 : 12), "incorrect cleanup order")
        verify(SDL_WasInit(SDL_INIT_VIDEO) == 0u, "SDL still initialized")
        verify(SDL_GetWindowFromID(window_id) == null, "window leaked")
        if (mode == 2) { verify(error == "intentional cleanup test", "panic message lost") }
    }
    with_sdl() {
        var event = SDL_MakeKeyEvent(SDL_EVENT_KEY_DOWN, SDLK_ESCAPE)
        verify(should_close(event))
        push_event(event)
        var received = SDL_MakeEvent()
        var found = false
        while (poll_event(received)) {
            if (should_close(received)) { found = true }
        }
        verify(found, "boost event queue failed")
    }
    print("Boost: normal/early return, panic, partial init, color validation and events: OK\n")
    return 0
}
