options gen2
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_scope

[export]
def main : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("daspkg consumer", 64, 64, SDL_WINDOW_HIDDEN) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        renderer |> clear() |> sdl_try
        renderer |> present() |> sdl_try
        return sdl_ok()
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    verify(SDL_WasInit(0u) == 0u)
    print("daspkg SDL core: rendered; resources released.\n")
    return 0
}
