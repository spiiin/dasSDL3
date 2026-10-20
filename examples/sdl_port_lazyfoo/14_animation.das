options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/14-animation/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("14 animation",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let texture : SDL_Texture? = renderer |> with_image_texture(asset("sprites-alpha.png")) |> sdl_use
        var time=0.0
        lesson_loop(window,renderer,smoke, $(event) {

            return sdl_ok()
        }) $(frame,dt) {
            time+=dt
            let index=int(time*8.0)%4
            renderer |> draw_texture(texture,SDL_FRect(x=float(index*32),w=32.0,h=32.0),SDL_FRect(x=240.0,y=160.0,w=160.0,h=160.0)) |> sdl_try
            return sdl_ok()
        } |> sdl_try

        return sdl_ok()
    }
    return report(result)
}
