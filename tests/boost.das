options gen2
require dassdl3/sdl3_boost
require daslib/defer

var cleanup_order = 0
var window_id = 0u

def exercise(mode : int) {
    let initialized = with_sdl() {
        let opened = with_window("deferred SDL cleanup",64,64,SDL_WINDOW_HIDDEN) $(window) {
            window_id = SDL_GetWindowID(window)
            if (mode == 3) {
                verify(create_renderer(window,"dasSDL3-nonexistent-driver") == null)
                verify(SDL_GetError() != "")
                return
            }
            let rendered = window |> with_renderer() $(renderer) {
                verify(renderer |> clear())
                verify(renderer |> fill_rect(SDL_MakeFRect(1.0,2.0,10.0,12.0)))
                verify(renderer |> present())
                if (mode == 1) { return }
                if (mode == 2) {
                    verify(!set_title(null,"invalid window"))
                    verify(SDL_GetError() != "")
                    return
                }
                if (mode == 4) {
                    verify(!(renderer |> set_color(uint4(256u,0u,0u,255u))))
                    verify(SDL_GetError() != "")
                }
            }
            verify(rendered)
            verify(SDL_GetRenderer(window) == null)
            verify(SDL_GetWindowFromID(window_id) == window)
            cleanup_order = cleanup_order * 10 + 1
        }
        verify(opened && SDL_GetWindowFromID(window_id) == null)
        verify(SDL_WasInit(SDL_INIT_VIDEO) != 0u)
        cleanup_order = cleanup_order * 10 + 2
    }
    verify(initialized)
}

// Direct SDL ownership needs no with_* helper or exception bridge.
def direct_ownership() : bool {
    if (!sdl_init()) { return false }
    {
        defer() { SDL_Quit() }
        let window = create_window("direct defer",64,64,SDL_WINDOW_HIDDEN)
        if (window == null) { return false }
        {
            defer() { destroy_window(window) }
            window_id = SDL_GetWindowID(window)
            let renderer = create_renderer(window)
            if (renderer == null) { return false }
            {
                defer() { destroy_renderer(renderer) }
                return set_title(null,"expected failure")
            }
        }
    }
}

[export]
def main(smoke : bool) : int {
    verify(smoke)
    for (mode in range(5)) {
        cleanup_order = 0
        exercise(mode)
        verify(cleanup_order == (mode == 3 ? 2 : 12))
        verify(SDL_WasInit(SDL_INIT_VIDEO) == 0u)
        verify(SDL_GetWindowFromID(window_id) == null)
    }
    verify(!direct_ownership())
    verify(SDL_WasInit(SDL_INIT_VIDEO) == 0u)
    verify(SDL_GetWindowFromID(window_id) == null)
    var invoked = false
    let loaded = with_bmp("dasSDL3-missing-file.bmp") $(surface) { invoked = true }
    verify(!loaded && !invoked && SDL_GetError() != "")
    let initialized = with_sdl() {
        var event = SDL_MakeKeyEvent(SDL_EVENT_KEY_DOWN,SDLK_ESCAPE)
        verify(push_event(event))
        var received = SDL_MakeEvent()
        var found = false
        while (poll_event(received)) {
            if (should_close(received)) { found = true }
        }
        verify(found)
    }
    verify(initialized)
    print("Boost: SDL error results, deferred cleanup, early return and partial init OK\n")
    return 0
}
