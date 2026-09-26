options gen2
require dassdl3/sdl3_boost
require dassdl3/sdl3_remaining_34_boost
require dassdl3/sdl3_scope

// SDL taskbar progress plus an ordinary Renderer progress bar.
def run(smoke : bool) : SdlStatus {
    return sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("SDL progress - Escape to exit", 640, 160, 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        window |> set_window_progress_state(SDL_ProgressState.PROGRESS_STATE_NORMAL) |> sdl_try
        var event = SDL_MakeEvent(); var running = true; var frame = 0
        let total = smoke ? 4 : 240
        while (running && frame < total) {
            while (is_some(poll_event(event))) {
                if (should_close(event)) { print("{event_description(event)}\n"); running = false }
            }
            let progress = float(frame + 1) / float(total)
            window |> set_window_progress_value(progress) |> sdl_try
            renderer |> clear() |> sdl_try
            renderer |> set_color(uint4(40u, 180u, 100u, 255u)) |> sdl_try
            renderer |> fill_rect(SDL_FRect(x = 20.0, y = 60.0, w = 600.0 * progress, h = 40.0)) |> sdl_try
            renderer |> present() |> sdl_try
            frame++
            SDL_Delay(16u)
        }
        window |> set_window_progress_state(SDL_ProgressState.PROGRESS_STATE_NONE) |> sdl_try
        return sdl_ok()
    }
}
[export]
def main(smoke : bool) : int {
    let result = run(smoke)
    if (is_err(result)){let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1}
    print("Window progress finished; resources released.\n")
    return 0
}
