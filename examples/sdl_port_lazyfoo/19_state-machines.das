options gen2
require ./common/demo_support.das
require ./common/dot_motion.das
// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/19-state-machines/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("19 state machines",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        with_ttf() |> sdl_use
        let font : TTF_Font? = with_font("{SDL_GetBasePath()}assets/libraries/JetBrainsMono-Regular.ttf",22.0) |> sdl_use
        let engine : TTF_TextEngine? = renderer |> with_renderer_text_engine() |> sdl_use
        let text : TTF_Text? = engine |> with_text(font,"") |> sdl_use
        var state=0;var transitions=0;var dot=Dot()
        lesson_loop(window,renderer,smoke, $(event) {
            let previous_state=state
            match(event) {
                if(SdlEvent(key_down=$v(key))) {
                    if(key.keycode==SDLK_RETURN || key.keycode==SDLK_SPACE){state=(state+1)%3;transitions++}
                    if(key.keycode==SDLK_P && state>0){state=state==1 ? 2 : 1;transitions++}
                    if(key.keycode==SDLK_M){state=0;transitions++}
                }
                if(_) {}
            }
            if(state!=previous_state){
                dot.left=false;dot.right=false;dot.up=false;dot.down=false
                dot.velocity=float2(0.0)
            }
            if(state==1){dot_event(dot,event)}
            return sdl_ok()
        }) $(frame,dt) {
            if(state==1){move_dot(dot,dt,640.0,480.0);draw_dot(renderer,dot) |> sdl_try}
            text |> set_text(state==0 ? "MENU: Enter to play" : (state==1 ? "PLAY: arrows move; P pauses; M menu" : "PAUSED: P resumes; M menu")) |> sdl_try
            text |> draw_text(25.0,70.0) |> sdl_try
            return sdl_ok()
        } |> sdl_try
        if(smoke){verify(transitions==4 && state==2)}
        return sdl_ok()
    }
    return report(result)
}
