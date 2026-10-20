options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/04-color-keying/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("04 color keying",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let surface : SDL_Surface? = with_image(asset("sprites.png")) |> sdl_use
        let key=SDL_MapSurfaceRGB(surface,255u,0u,255u)
        sdl_status(SDL_SetSurfaceColorKey(surface,true,key),"SDL_SetSurfaceColorKey") |> sdl_try
        let texture : SDL_Texture? = renderer |> with_keyed_texture(surface) |> sdl_use
        lesson_loop(window,renderer,smoke, $(event) {

            return sdl_ok()
        }) $(frame,dt) {
            renderer |> box(40.0,140.0,560.0,180.0,uint4(40u,130u,100u,255u)) |> sdl_try
            renderer |> draw_texture(texture,SDL_FRect(x=64.0,y=150.0,w=512.0,h=128.0)) |> sdl_try
            return sdl_ok()
        } |> sdl_try

        return sdl_ok()
    }
    return report(result)
}
