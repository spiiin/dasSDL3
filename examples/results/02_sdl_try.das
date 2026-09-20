options gen2
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_try

// Same application as 01_results; Result checks expand to ordinary early returns.
def render_loop(renderer : SDL_Renderer?; texture : SDL_Texture?; smoke : bool; var frames : int&) {
    let size = texture_size(texture) |> sdl_try
    print("Texture: {size.x} x {size.y}\n")
    var event = SDL_MakeEvent()
    var running = true
    while (running) {
        while (is_some(poll_event(event))) {
            if (should_close(event)) { running = false }
        }
        if (!running) { break }
        renderer |> clear() |> sdl_try
        renderer |> draw_texture(texture) |> sdl_try
        renderer |> present() |> sdl_try
        frames++
        if (smoke && frames >= 3) { break }
        SDL_Delay(16u)
    }
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    var frames = 0
    let result = with_sdl(SDL_INIT_VIDEO) {
        let flags = smoke ? SDL_WINDOW_HIDDEN : SDL_WINDOW_RESIZABLE
        return with_window("SDL sdl_try - Escape to exit", 640, 480, flags) $(window : SDL_Window?) {
            return window |> with_renderer() $(renderer : SDL_Renderer?) {
                return renderer |> with_texture("{SDL_GetBasePath()}assets/checker.bmp") $(texture : SDL_Texture?) {
                    return render_loop(renderer, texture, smoke, frames)
                }
            }
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    let driver = hint_string("SDL_RENDER_DRIVER") |> unwrap_or("automatic")
    print("Rendered {frames} frames; resources released. Driver hint: {driver}\n")
    return 0
}
