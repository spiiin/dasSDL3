options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_init_boost
[export]
def main(smoke : bool) : int {
    if (!SDL_SetAppMetadata("Hints and Init", "1.0", "org.dassdl3.hints")) { return 1 }
    let initialized = sdl_scope() {
        with_sdl(0u) |> sdl_use
        with_sdl_subsystems(SDL_INIT_EVENTS) |> sdl_use
        let metadata = app_metadata_string("SDL.app.metadata.name") |> sdl_try
        let name = metadata |> unwrap_or("")
        print("{name}: events initialized\n")

        return sdl_ok()
    }
    if (is_err(initialized)) {print("{unwrap_err(initialized).message}\n"); return 1}
    return 0
}
