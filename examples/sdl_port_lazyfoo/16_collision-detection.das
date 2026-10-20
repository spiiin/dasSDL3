options gen2
require ./common/demo_support.das
require ./common/collision.das
// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/16-collision-detection/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("16 collision detection",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        var dot=Dot(position=float2(270,220));let wall=SDL_FRect(x=320.0,y=160.0,w=70.0,h=180.0)
        lesson_loop(window,renderer,smoke, $(event) {
            dot_event(dot,event)
            return sdl_ok()
        }) $(frame,dt) {
            move_colliding(dot,wall,dt)
            renderer |> box(wall.x,wall.y,wall.w,wall.h,uint4(210u,90u,100u,255u)) |> sdl_try
            draw_dot(renderer,dot) |> sdl_try
            return sdl_ok()
        } |> sdl_try
        if(smoke){verify(!overlaps(SDL_FRect(x=dot.position.x,y=dot.position.y,w=32.0,h=32.0),wall))}
        return sdl_ok()
    }
    return report(result)
}
