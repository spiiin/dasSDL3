options gen2
module dot_motion shared public
require ./demo_support.das public
struct Dot {
    position : float2 = float2(300,220)
    velocity : float2
    left, right, up, down : bool
}
def public dot_event(var dot : Dot; event : SdlEvent) {
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
def public move_dot(var dot : Dot; dt : float; width,height : float) {
    dot.position.x=clamp(dot.position.x+dot.velocity.x*dt,0.0,width-32.0)
    dot.position.y=clamp(dot.position.y+dot.velocity.y*dt,0.0,height-32.0)
}
def public draw_dot(renderer : SDL_Renderer?; dot : Dot) {
    return renderer |> box(dot.position.x,dot.position.y,32.0,32.0,uint4(255u,190u,55u,255u))
}
