options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/02-textures-and-extension-libraries/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("02 textures and extension libraries",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let texture : SDL_Texture? = renderer |> with_image_texture(asset("sprites-alpha.png")) |> sdl_use
        lesson_loop(window,renderer,smoke, $(event) {

            return sdl_ok()
        }) $(frame,dt) {
            let size = texture |> texture_size() |> sdl_try
            renderer |> draw_texture(texture,SDL_FRect(x=64.0,y=150.0,w=size.x*4.0,h=size.y*4.0)) |> sdl_try
            return sdl_ok()
        } |> sdl_try

        return sdl_ok()
    }
    return report(result)
}
