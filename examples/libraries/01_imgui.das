options gen2
require dassdl3/sdl3_imgui
require dassdl3/sdl3_scope
require dassdl3/sdl3_pixels_boost

def check_pixels(renderer : SDL_Renderer?) {
    return renderer |> with_read_pixels() $(surface : SDL_Surface?) {
        let size = surface_size(surface) |> sdl_try
        var bytes : array<uint8>
        resize(bytes,size.x * size.y * 4)
        copy_surface_rgba8(surface,bytes,size.x * 4) |> sdl_try
        var lit = 0
        // Text and widgets must produce bright pixels over the dark clear color.
        for (y in 20 .. 260) {
            for (x in 20 .. 460) {
                let offset = (y * size.x + x) * 4
                if (uint(bytes[offset]) > 120u && uint(bytes[offset+1]) > 120u && uint(bytes[offset+2]) > 120u) { lit++ }
            }
        }
        if (lit < 200) {
            return err(SdlError(operation="ImGui pixels",message="Expected visible text and widgets"),type<SdlUnit>)
        }
        print("ImGui: {lit} bright pixels verified.\n")
        return sdl_ok()
    }
}

def run_gui(renderer : SDL_Renderer?; smoke : bool) {
    DisableIniPersistence()
    StyleColorsDark()
    var clicks = 0
    var frames = 0
    var show_demo = false
    var running = true
    var event = SDL_MakeEvent()
    while (running) {
        while (is_some(poll_event(event))) {
            // Always forward events, even if ImGui captures application input.
            ImGui_SDL3_ProcessEvent(event)
            if (SDL_EventIsEscape(event) && !ImGui_SDL3_WantCaptureKeyboard()) { running = false }
            if (SDL_EventIsQuit(event)) { running = false }
        }
        if (!running) { break }
        ImGui_ImplSDLRenderer3_NewFrame()
        ImGui_ImplSDL3_NewFrame()
        NewFrame()
        SetNextWindowPos(ImVec2(20.0,20.0),ImGuiCond.FirstUseEver,ImVec2(0.0,0.0))
        SetNextWindowSize(ImVec2(440.0,240.0),ImGuiCond.FirstUseEver)
        if (Begin("daScript ImGui + SDL3")) {
            Text("Widgets: existing daScript ImGui module")
            Text("Platform and rendering: SDL3 + SDLRenderer3")
            Separator()
            if (Button("Click me")) { clicks++ }
            SameLine()
            Text("Clicks: {clicks}")
            if (Button("Toggle Dear ImGui demo")) { show_demo = !show_demo }
            Text("Resize the SDL window; drag this panel.")
            Text("Escape exits when keyboard input is not captured.")
        }
        End()
        if (show_demo) { ShowDemoWindow() }
        Render()
        sdl_status(SDL_SetRenderDrawColor(renderer,12u,18u,28u,255u),"SDL_SetRenderDrawColor") |> sdl_try
        renderer |> clear() |> sdl_try
        ImGui_SDL3_Render(renderer)
        if (smoke && frames == 2) { check_pixels(renderer) |> sdl_try }
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
        let flags = smoke ? SDL_WINDOW_HIDDEN : SDL_WINDOW_RESIZABLE
        let window : SDL_Window? = with_window("SDL3 + daScript ImGui",960,640,flags) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        with_imgui(window,renderer) |> sdl_use
        return run_gui(renderer,smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("ImGui backends, context and SDL resources released.\n")
    return 0
}
