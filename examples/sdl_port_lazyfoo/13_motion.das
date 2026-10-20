options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/13-motion/index.php

struct Dot {
    position : float2 = float2(300,220)
    velocity : float2
    left, right, up, down : bool
}
def dot_event(var dot : Dot; event : SdlEvent) {
    match(event) {
        if(SdlEvent(key_down=$v(key))) {
            if(key.keycode==SDLK_LEFT){dot.left=true}
            if(key.keycode==SDLK_RIGHT){dot.right=true}
            if(key.keycode==SDLK_UP){dot.up=true}
            if(key.keycode==SDLK_DOWN){dot.down=true}
        }
        if(SdlEvent(key_up=$v(key))) {
            if(key.keycode==SDLK_LEFT){dot.left=false}
            if(key.keycode==SDLK_RIGHT){dot.right=false}
            if(key.keycode==SDLK_UP){dot.up=false}
            if(key.keycode==SDLK_DOWN){dot.down=false}
        }
        if(SdlEvent(window=$v(win))) {
            if(win.event_type==SDL_EVENT_WINDOW_FOCUS_LOST){dot.left=false;dot.right=false;dot.up=false;dot.down=false}
        }
        if(_) {}
    }
    dot.velocity=float2(float((dot.right ? 1 : 0)-(dot.left ? 1 : 0)),float((dot.down ? 1 : 0)-(dot.up ? 1 : 0)))*180.0
}
def move_dot(var dot : Dot; dt : float; width,height : float) {
    dot.position.x=clamp(dot.position.x+dot.velocity.x*dt,0.0,width-32.0)
    dot.position.y=clamp(dot.position.y+dot.velocity.y*dt,0.0,height-32.0)
}
def draw_dot(renderer : SDL_Renderer?; dot : Dot) {
    return renderer |> box(dot.position.x,dot.position.y,32.0,32.0,uint4(255u,190u,55u,255u))
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("13 motion",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        var dot=Dot()
        lesson_loop(window,renderer,smoke, $(event) {
            dot_event(dot,event)
            return sdl_ok()
        }) $(frame,dt) {
            move_dot(dot,dt,640.0,480.0)
            draw_dot(renderer,dot) |> sdl_try
            return sdl_ok()
        } |> sdl_try
        if(smoke){verify(dot.position.x>300.0 && dot.position.y>220.0)}
        return sdl_ok()
    }
    return report(result)
}
