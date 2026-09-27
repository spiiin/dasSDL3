options gen2
require dassdl3/sdl3_boost
var mode = 0
var window : SDL_Window?
[export]
def configure(value : int) { mode = value }
[export]
def init() {
    if (mode == 1) { panic("init probe") }
    if (mode == 5 || mode == 6) {
        verify(SDL_Init(SDL_INIT_VIDEO))
        window = SDL_CreateWindow("Event fault probe", 64, 64, 0ul)
        verify(window != null)
        if (mode == 6) {
            let result = create_renderer(window, "unavailable-test-driver")
            verify(is_err(result))
            let error = unwrap_err(result)
            print("{error.operation}: {error.message}\n")
        }
    }
}
[export]
def update() : bool { if (mode == 2) { panic("update probe") }; return mode == 5 }
[export]
def app_event(event : SDL_Event) : int { if (mode == 5) { panic("event probe") }; return 0 }
[export]
def shutdown() {
    if (window != null) { SDL_DestroyWindow(window); window = null }
    SDL_Quit()
    print("CLEANED\n")
    if (mode == 3) { panic("shutdown probe") }
}
[export]
def exit_code() : int { return mode == 4 || mode == 6 ? 5 : 0 }
