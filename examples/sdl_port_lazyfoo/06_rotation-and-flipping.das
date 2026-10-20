options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/06-rotation-and-flipping/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("06 rotation and flipping",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let texture : SDL_Texture? = renderer |> with_image_texture(asset("sprites-alpha.png")) |> sdl_use
        var angle=0.0; var flip=SDL_FlipMode.FLIP_NONE
        lesson_loop(window,renderer,smoke, $(event) {
            match(event) {
                if(SdlEvent(key_down=$v(key))) {
                    if(key.keycode==SDLK_LEFT){angle-=15.0}
                    if(key.keycode==SDLK_RIGHT){angle+=15.0}
                    if(key.keycode==SDLK_SPACE){flip=flip==SDL_FlipMode.FLIP_NONE ? SDL_FlipMode.FLIP_HORIZONTAL : SDL_FlipMode.FLIP_NONE}
                    if(key.keycode==SDLK_V){flip=SDL_FlipMode.FLIP_VERTICAL}
                }
                if(_) {}
            }
            return sdl_ok()
        }) $(frame,dt) {
            sdl_status(SDL_RenderTextureRotatedRefs(renderer,texture,SDL_FRect(w=32.0,h=32.0),
                SDL_FRect(x=220.0,y=140.0,w=200.0,h=200.0),double(angle),SDL_FPoint(x=100.0,y=100.0),flip),"SDL_RenderTextureRotated") |> sdl_try
            return sdl_ok()
        } |> sdl_try

        return sdl_ok()
    }
    return report(result)
}
