options gen2
require dassdl3/sdl3_init_boost
[export]
def main(smoke : bool) : int {
    if(!SDL_SetAppMetadata("Hints and Init","1.0","org.dassdl3.hints")) { return 1 }
    var events_ok=false
    let initialized=with_sdl(0u) {
        events_ok=with_sdl_subsystems(SDL_INIT_EVENTS) {
            let name=app_metadata_string("SDL.app.metadata.name")
            print("{name}: events initialized\n")
        }
        if(!events_ok) { print("{SDL_GetError()}\n") }
    }
    return initialized && events_ok ? 0 : 1
}
