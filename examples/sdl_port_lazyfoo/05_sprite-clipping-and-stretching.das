options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/05-sprite-clipping-and-stretching/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("05 sprite clipping and stretching",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let texture : SDL_Texture? = renderer |> with_image_texture(asset("sprites-alpha.png")) |> sdl_use
        var index=0
        lesson_loop(window,renderer,smoke, $(event) {
            match(event) {
                if(SdlEvent(key_down=$v(key))) { if(key.keycode==SDLK_SPACE){index=(index+1)%4} }
                if(_) {}
            }
            return sdl_ok()
        }) $(frame,dt) {
            let clip=SDL_FRect(x=float(index*32),w=32.0,h=32.0)
            renderer |> draw_texture(texture,clip,SDL_FRect(x=100.0,y=180.0,w=64.0,h=64.0)) |> sdl_try
            renderer |> draw_texture(texture,clip,SDL_FRect(x=300.0,y=100.0,w=220.0,h=280.0)) |> sdl_try
            return sdl_ok()
        } |> sdl_try

        return sdl_ok()
    }
    return report(result)
}
