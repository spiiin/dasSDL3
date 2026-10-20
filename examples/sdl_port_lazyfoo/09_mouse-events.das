options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/09-mouse-events/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("09 mouse events",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        var hover=false; var down=false; var clicks=0
        lesson_loop(window,renderer,smoke, $(event) {
            match(event) {
                if(SdlEvent(mouse_motion=$v(mouse))) { hover=mouse.position.x>=80.0 && mouse.position.x<280.0 && mouse.position.y>=100.0 && mouse.position.y<200.0 }
                if(SdlEvent(mouse_button_down=$v(mouse))) { if(mouse.button==1u8 && hover){down=true;clicks++} }
                if(SdlEvent(mouse_button_up=$v(mouse))) { if(mouse.button==1u8){down=false} }
                if(_) {}
            }
            return sdl_ok()
        }) $(frame,dt) {
            let color=down ? uint4(255u,170u,60u,255u) : (hover ? uint4(80u,220u,140u,255u) : uint4(70u,110u,180u,255u))
            renderer |> box(80.0,100.0,200.0,100.0,color) |> sdl_try
            return sdl_ok()
        } |> sdl_try
        if(smoke){verify(hover && !down && clicks==1)}
        return sdl_ok()
    }
    return report(result)
}
