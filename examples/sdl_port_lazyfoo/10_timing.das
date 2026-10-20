options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/10-timing/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("10 timing",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        with_ttf() |> sdl_use
        let font : TTF_Font? = with_font("{SDL_GetBasePath()}assets/libraries/JetBrainsMono-Regular.ttf",22.0) |> sdl_use
        let engine : TTF_TextEngine? = renderer |> with_renderer_text_engine() |> sdl_use
        let text : TTF_Text? = engine |> with_text(font,"") |> sdl_use
        var start=SDL_GetTicks(); var stopped=false; var elapsed=0ul
        lesson_loop(window,renderer,smoke, $(event) {
            match(event) {
                if(SdlEvent(key_down=$v(key))) { if(key.keycode==SDLK_SPACE){stopped=!stopped;if(!stopped){start=SDL_GetTicks()}} }
                if(_) {}
            }
            return sdl_ok()
        }) $(frame,dt) {
            if(!stopped){elapsed=SDL_GetTicks()-start}
            text |> set_text("Elapsed: {elapsed} ms
Space: stop/restart") |> sdl_try
            text |> draw_text(60.0,180.0) |> sdl_try
            return sdl_ok()
        } |> sdl_try

        return sdl_ok()
    }
    return report(result)
}
