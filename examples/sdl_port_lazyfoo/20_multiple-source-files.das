options gen2
require ./common/demo_support.das
require ./common/dot_motion.das
// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/20-multiple-source-files/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("20 multiple source files",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        var dot=Dot()
        lesson_loop(window,renderer,smoke, $(event) {
            dot_event(dot,event)
            return sdl_ok()
        }) $(frame,dt) {
            // dot_motion.das contains state, event handling, motion and rendering.
            move_dot(dot,dt,640.0,480.0)
            draw_dot(renderer,dot) |> sdl_try
            return sdl_ok()
        } |> sdl_try
        if(smoke){verify(dot.position.x>300.0)}
        return sdl_ok()
    }
    return report(result)
}
