options gen2
require ./common/demo_support.das

// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/03-key-presses-and-key-states/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("03 key presses and key states",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        var pressed = SDLK_UP
        lesson_loop(window,renderer,smoke, $(event) {
            match (event) {
                if (SdlEvent(key_down=$v(key))) { pressed=key.keycode }
                if (_) {}
            }
            return sdl_ok()
        }) $(frame,dt) {
            let keys <- keyboard_state()
            var x=300.0; var y=220.0
            if (keys[int(SDL_Scancode.SCANCODE_LEFT)] || pressed==SDLK_LEFT) { x-=100.0 }
            if (keys[int(SDL_Scancode.SCANCODE_RIGHT)] || pressed==SDLK_RIGHT) { x+=100.0 }
            if (keys[int(SDL_Scancode.SCANCODE_UP)] || pressed==SDLK_UP) { y-=100.0 }
            if (keys[int(SDL_Scancode.SCANCODE_DOWN)] || pressed==SDLK_DOWN) { y+=100.0 }
            renderer |> box(x,y,40.0,40.0,uint4(70u,220u,160u,255u)) |> sdl_try
            return sdl_ok()
        } |> sdl_try

        return sdl_ok()
    }
    return report(result)
}
