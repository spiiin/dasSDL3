options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/07-color-modulation-and-alpha-blending/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("07 color modulation and alpha blending",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let texture : SDL_Texture? = renderer |> with_image_texture(asset("sprites-alpha.png")) |> sdl_use
        var alpha=200u; var red=255u
        lesson_loop(window,renderer,smoke, $(event) {
            match(event) {
                if(SdlEvent(key_down=$v(key))) {
                    if(key.keycode==SDLK_SPACE){alpha=alpha==200u ? 80u : 200u}
                    if(key.keycode==SDLK_R){red=red==255u ? 80u : 255u}
                }
                if(_) {}
            }
            return sdl_ok()
        }) $(frame,dt) {
            sdl_status(SDL_SetTextureBlendMode(texture,SDL_BLENDMODE_BLEND),"SDL_SetTextureBlendMode") |> sdl_try
            sdl_status(SDL_SetTextureColorMod(texture,red,150u,210u),"SDL_SetTextureColorMod") |> sdl_try
            sdl_status(SDL_SetTextureAlphaMod(texture,alpha),"SDL_SetTextureAlphaMod") |> sdl_try
            renderer |> box(80.0,150.0,480.0,170.0,uint4(230u,230u,210u,255u)) |> sdl_try
            renderer |> draw_texture(texture,SDL_FRect(x=64.0,y=170.0,w=512.0,h=128.0)) |> sdl_try
            return sdl_ok()
        } |> sdl_try

        return sdl_ok()
    }
    return report(result)
}
