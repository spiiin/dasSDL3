options gen2
require ./common/demo_support.das
require ./common/dot_motion.das
// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/18-scrolling/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("18 scrolling",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        var dot=Dot(position=float2(800,450))
        lesson_loop(window,renderer,smoke, $(event) {
            dot_event(dot,event)
            return sdl_ok()
        }) $(frame,dt) {
            move_dot(dot,dt,1600.0,900.0)
            let camera=float2(clamp(dot.position.x-320.0,0.0,960.0),clamp(dot.position.y-240.0,0.0,420.0))
            for(y in 0..10){for(x in 0..16){
                let shade=((x+y)%2)==0 ? 55u : 85u
                renderer |> box(float(x*100)-camera.x,float(y*100)-camera.y,96.0,96.0,uint4(35u,shade,95u,255u)) |> sdl_try
            }}
            renderer |> box(dot.position.x-camera.x,dot.position.y-camera.y,32.0,32.0,uint4(255u,190u,55u,255u)) |> sdl_try
            return sdl_ok()
        } |> sdl_try

        return sdl_ok()
    }
    return report(result)
}
