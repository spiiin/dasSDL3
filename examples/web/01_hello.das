options gen2
require dassdl3/sdl3_boost
[export]
def app_init() : int { print("Hello from daScript + SDL3 WebAssembly!\n"); return 0 }
[export]
def app_frame() : int { return 1 }
[export]
def app_event(event : SDL_Event) : int { return 0 }
[export]
def app_quit { print("Session released.\n") }
