options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/01-hello-sdl3/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("01 hello sdl3",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use

        lesson_loop(window,renderer,smoke, $(event) {

            return sdl_ok()
        }) $(frame,dt) {
            renderer |> box(160.0,140.0,320.0,200.0,uint4(60u,190u,240u,255u)) |> sdl_try
            return sdl_ok()
        } |> sdl_try

        return sdl_ok()
    }
    return report(result)
}
