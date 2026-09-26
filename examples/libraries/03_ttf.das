options gen2
require dassdl3/sdl3_ttf_boost
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_scope

def show_text(renderer : SDL_Renderer?; title, body : TTF_Text?; smoke : bool) {
    title |> set_text_color(uint4(90u, 210u, 255u, 255u)) |> sdl_try
    body |> set_text_color(uint4(240u, 240u, 240u, 255u)) |> sdl_try
    var running = true
    var frames = 0
    var event = SDL_MakeEvent()
    while (running) {
        while (is_some(poll_event(event))) {
            if (should_close(event)) { running = false }
        }
        if (!running) { break }
        renderer |> clear(uint4(25u, 30u, 40u, 255u)) |> sdl_try
        title |> draw_text(30.0, 40.0) |> sdl_try
        body |> draw_text(30.0, 110.0) |> sdl_try
        renderer |> present() |> sdl_try
        frames++
        if (smoke && frames == 3) { break }
        SDL_Delay(16u)
    }
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        with_ttf() |> sdl_use
        let flags = smoke ? SDL_WINDOW_HIDDEN : SDL_WINDOW_RESIZABLE
        let window : SDL_Window? = with_window("SDL_ttf - Escape to exit", 720, 320, flags) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let font : TTF_Font? = with_font("{SDL_GetBasePath()}assets/libraries/JetBrainsMono-Regular.ttf", 24.0) |> sdl_use
        let engine : TTF_TextEngine? = renderer |> with_renderer_text_engine() |> sdl_use
        let title : TTF_Text? = engine |> with_text(font, "SDL_ttf + daScript") |> sdl_use
        let body : TTF_Text? = engine |> with_text(font, "UTF-8: café, naïve\nFont, TextEngine and Text use scoped cleanup.") |> sdl_use
        let size = body |> text_size() |> sdl_try
        print("SDL_ttf {TTF_Version()}: text size {size.x} x {size.y}\n")
        return show_text(renderer, title, body, smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Text, engine and font released; SDL_ttf shut down.\n")
    return 0
}
