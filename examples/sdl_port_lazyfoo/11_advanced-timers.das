options gen2
require ./common/demo_support.das
require ./common/lesson_timer.das
// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/11-advanced-timers/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("11 advanced timers",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        with_ttf() |> sdl_use
        let font : TTF_Font? = with_font("{SDL_GetBasePath()}assets/libraries/JetBrainsMono-Regular.ttf",22.0) |> sdl_use
        let engine : TTF_TextEngine? = renderer |> with_renderer_text_engine() |> sdl_use
        let text : TTF_Text? = engine |> with_text(font,"") |> sdl_use
        var timer=LessonTimer(); var clock=100ul
        lesson_loop(window,renderer,smoke, $(event) {
            let now=smoke ? clock : SDL_GetTicksNS()
            match(event) {
                if(SdlEvent(key_down=$v(key))) {
                    if(key.keycode==SDLK_SPACE){if(timer.started){timer=LessonTimer()}else{timer_start(timer,now)}}
                    if(key.keycode==SDLK_P){if(timer.paused){timer_resume(timer,now)}else{timer_pause(timer,now)}}
                }
                if(_) {}
            }
            return sdl_ok()
        }) $(frame,dt) {
            if(!smoke){clock=SDL_GetTicksNS()}else{clock+=16666667ul}
            let seconds=double(timer_ticks(timer,clock))*1.0e-9lf
            text |> set_text("Timer: {seconds} s
Space: start/stop; P: pause/resume") |> sdl_try
            text |> draw_text(40.0,170.0) |> sdl_try
            return sdl_ok()
        } |> sdl_try
        if(smoke){verify(timer.started && !timer.paused)}
        return sdl_ok()
    }
    return report(result)
}
