options gen2
// Opt-in interactive Windows input/driver diagnostic; Escape closes the window.
require dassdl3/sdl3_scope
require dassdl3/sdl3_events
require dassdl3/sdl3_keyboard_mouse_boost
require dassdl3/sdl3_renderer_presentation_boost
require daslib/match

[export]
def main(smoke : bool) : int {
    let result=sdl_scope(){
        with_sdl(SDL_INIT_VIDEO | SDL_INIT_AUDIO) |> sdl_use
        let window : SDL_Window? = with_window("SDL desktop input probe",640,480,0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let renderer_driver=renderer_name(renderer) |> sdl_try
        print("VIDEO={SDL_GetCurrentVideoDriverCopy()} AUDIO={SDL_GetCurrentAudioDriverCopy()} RENDERER={renderer_driver}\n")
        with_text_input(window) |> sdl_use
        var running=true
        while(running){
            for(event in poll_events()){
                if(should_close(event,window)){running=false}
                match(event){
                    if(SdlEvent(key_down=$v(key))){
                        print("KEY {key_name(key.keycode)} code={key.keycode} scan={key.scancode} right={SDLK_RIGHT} left={SDLK_LEFT}\n")
                    }
                    if(SdlEvent(text_input=$v(text))){print("TEXT {text.text}\n")}
                    if(_){}
                }
            }
            renderer |> clear(uint4(40u,60u,90u,255u)) |> sdl_try
            renderer |> present() |> sdl_try
            SDL_Delay(8u)
        }
        return sdl_ok()
    }
    if(is_err(result)){let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    return 0
}
