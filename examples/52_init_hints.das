options gen2
require dassdl3/sdl3_init_boost
[export]
def main(smoke : bool) : int {
    if(!SDL_SetAppMetadata("Hints and Init","1.0","org.dassdl3.hints")) { return 1 }
    let initialized=with_sdl(0u) {
        return with_sdl_subsystems(SDL_INIT_EVENTS) {
            let name=unwrap_or(unwrap_or(app_metadata_string("SDL.app.metadata.name"),none(type<string>)), "")
            print("{name}: events initialized\n")

            return sdl_ok()
        }
    }
    if(is_err(initialized)) {print("{unwrap_err(initialized).message}\n");return 1}
    return 0
}
