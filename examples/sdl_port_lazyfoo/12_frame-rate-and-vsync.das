options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/12-frame-rate-and-vsync/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("12 frame rate and vsync",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        with_ttf() |> sdl_use
        let font : TTF_Font? = with_font("{SDL_GetBasePath()}assets/libraries/JetBrainsMono-Regular.ttf",22.0) |> sdl_use
        let engine : TTF_TextEngine? = renderer |> with_renderer_text_engine() |> sdl_use
        let text : TTF_Text? = engine |> with_text(font,"") |> sdl_use
        var vsync=false; var capped=true; let start=SDL_GetTicksNS()
        lesson_loop(window,renderer,smoke, $(event) {
            match(event) {
                if(SdlEvent(key_down=$v(key))) {
                    if(key.keycode==SDLK_V){vsync=!vsync;sdl_status(SDL_SetRenderVSync(renderer,vsync ? 1 : 0),"SDL_SetRenderVSync") |> sdl_try}
                    if(key.keycode==SDLK_SPACE){capped=!capped}
                }
                if(_) {}
            }
            return sdl_ok()
        }) $(frame,dt) {
            let begin=SDL_GetTicksNS()
            let fps=smoke ? 60.0lf : double(frame+1)*1.0e9lf/double(max(1ul,begin-start))
            text |> set_text("Average FPS: {fps}
V: VSync ({vsync}); Space: cap ({capped})") |> sdl_try
            text |> draw_text(30.0,180.0) |> sdl_try
            if(capped && !smoke){let spent=SDL_GetTicksNS()-begin;if(spent<16666667ul){SDL_DelayNS(16666667ul-spent)}}
            return sdl_ok()
        } |> sdl_try

        return sdl_ok()
    }
    return report(result)
}
