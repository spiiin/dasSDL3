options gen2
require dassdl3/sdl3_imgui_widgets
require dassdl3/sdl3_scope
require dassdl3/sdl3_pixels_boost
require live/live_commands
require strings

def draw_widgets() {
    SetNextWindowPos(ImVec2(10.0, 10.0), ImGuiCond.Always, ImVec2(0.0, 0.0))
    SetNextWindowSize(ImVec2(300.0, 210.0), ImGuiCond.Always)
    window(TEST, (text = "SDL widget test", closable = false, flags = ImGuiWindowFlags.None)) {
        button(CLICK.PUBLIC, (text = "Click via synth"))
        slider_float(VALUE.PUBLIC, (text = "Value", init = 0.5, bounds = (0.0, 1.0)))
        checkbox(TOGGLE.PUBLIC, (text = "Toggle", init = true))
        text("SDLRenderer3 + upstream v2")
    }
}

def run_test(renderer : SDL_Renderer?) : SdlStatus {
    DisableIniPersistence()
    set_user_control_enabled(false)
    let blocked_key = SDL_MakeKeyEvent(SDL_EVENT_KEY_DOWN, 97u)
    verify(!imgui_widgets_process_event(blocked_key))
    for (frame in 0 .. 8) {
        if (frame == 2) {
            let (found, rect) = widget_rect("TEST/CLICK")
            verify(found)
            synth_mouse_move((rect.x + rect.z) * 0.5, (rect.y + rect.w) * 0.5)
        }
        if (frame == 3) { synth_mouse_button(0, 1) }
        if (frame == 4) { synth_mouse_button(0, 0) }
        imgui_widgets_new_frame()
        draw_widgets()
        renderer |> clear() |> sdl_try
        imgui_widgets_render(renderer)
        if (frame == 6) {
            renderer |> with_read_pixels() $(surface : SDL_Surface?) {
                let size = surface_size(surface) |> sdl_try
                var bytes : array<uint8>
                resize(bytes, size.x * size.y * 4)
                copy_surface_rgba8(surface, bytes, size.x * 4) |> sdl_try
                var lit = 0
                for (pixel in range(length(bytes) / 4)) {
                    let i = pixel * 4
                    if (uint(bytes[i]) > 150u && uint(bytes[i + 1]) > 150u && uint(bytes[i + 2]) > 150u) { lit++ }
                }
                verify(lit > 150)
                print("Widgets: {lit} bright pixels\n")
                return sdl_ok()
            } |> sdl_try
        }
        renderer |> present() |> sdl_try
    }
    verify(CLICK.click_count == 1)
    let snapshot = live_dispatch_command("\{\"name\":\"imgui_snapshot\"\}")
    verify(find(snapshot, "TEST/CLICK") >= 0 && find(snapshot, "TEST/VALUE") >= 0)
    verify(find(snapshot, "click_count") >= 0)
    let changed = live_dispatch_command("\{\"name\":\"imgui_force_set\",\"args\":\{\"target\":\"TEST/VALUE\",\"value\":0.75\}\}")
    imgui_widgets_new_frame()
    draw_widgets()
    renderer |> clear() |> sdl_try
    imgui_widgets_render(renderer)
    verify(VALUE.value == 0.75)
    renderer |> present() |> sdl_try
    // Exercise the upstream yielding click coroutine, including resume after
    // the scoped GetIO reference (a pinned C++ emitter issue on Apple Clang).
    let clicked = live_dispatch_command("\{\"name\":\"imgui_click\",\"args\":\{\"target\":\"TEST/CLICK\"\}\}")
    verify(find(clicked, "error") < 0)
    for (frame in 0 .. 24) {
        imgui_widgets_new_frame()
        draw_widgets()
        renderer |> clear() |> sdl_try
        imgui_widgets_render(renderer)
        renderer |> present() |> sdl_try
    }
    verify(CLICK.click_count == 2 && synth_coroutines_active() == 0)
    set_user_control_enabled(true)
    print("Widgets: synth click, snapshot and force_set PASS\n")
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("SDL widgets test", 320, 240, SDL_WINDOW_HIDDEN) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        with_imgui(window, renderer) |> sdl_use
        return run_test(renderer)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    verify(GetCurrentContext() == null)
    return 0
}
