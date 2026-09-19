options gen2
require sdl3

[export]
def main(smoke : bool) : int {
    verify(smoke)
    verify(SDL_GetVersion() == 3002018)
    unsafe {
        var rect = SDL_MakeFRect(1.0, 2.0, 30.0, 40.0)
        verify(rect.x == 1.0 && rect.y == 2.0 && rect.w == 30.0 && rect.h == 40.0)
        rect.x = 7.0
        verify(rect.x == 7.0)
        var event = SDL_MakeEvent()
        verify(event.event_type == 0u && !SDL_EventIsQuit(event) && !SDL_EventIsEscape(event))
        event = SDL_MakeKeyEvent(SDL_EVENT_KEY_DOWN, SDLK_ESCAPE)
        verify(SDL_EventIsEscape(event))
        event = SDL_MakeKeyEvent(SDL_EVENT_KEY_UP, SDLK_ESCAPE)
        verify(!SDL_EventIsEscape(event))
        event = SDL_MakeEvent()
        event.event_type = SDL_EVENT_QUIT
        verify(SDL_EventIsQuit(event) && !SDL_EventIsEscape(event))
        verify(SDL_Init(SDL_INIT_VIDEO))
        verify(SDL_PushEvent(addr(event)))
        var received = SDL_MakeEvent()
        var found = false
        while (SDL_PollEvent(addr(received))) {
            if (SDL_EventIsQuit(received)) { found = true }
        }
        SDL_Quit()
        verify(found)
    }
    print("SDL3 version, struct fields, event union adapters and event queue: OK\n")
    return 0
}
