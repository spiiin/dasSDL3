options gen2
options gc
options persistent_heap
require dassdl3/sdl3_imgui_widgets
require dassdl3/sdl3_boost
require dassdl3/sdl3_try
require imgui/imgui_theme_daslang

var sdl_window : SDL_Window?
var renderer : SDL_Renderer?
var context : ImGuiContext?
var backend_ready = false
var running = true
var failed = false

def report(result : SdlStatus) {
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        failed = true
        running = false
    }
}

def initialize_resources() : SdlStatus {
    sdl_init() |> sdl_try
    sdl_window = create_window("SDL3 + dasImgui v2", 800, 600, SDL_WINDOW_RESIZABLE) |> sdl_try
    renderer = create_renderer(sdl_window) |> sdl_try
    context = CreateContext()
    if (context == null) { return err(SdlError(operation = "CreateContext", message = "No ImGui context"), type<SdlUnit>) }
    sdl_status(ImGui_SDL3_Init(sdl_window, renderer), "ImGui_SDL3_Init") |> sdl_try
    backend_ready = true
    DisableIniPersistence()
    apply_daslang_theme()
    return sdl_ok()
}

[export]
def init() { report(initialize_resources()) }

def draw_frame() : SdlStatus {
    imgui_widgets_new_frame()
    SetNextWindowPos(ImVec2(20.0, 20.0), ImGuiCond.FirstUseEver, ImVec2(0.0, 0.0))
    SetNextWindowSize(ImVec2(520.0, 320.0), ImGuiCond.FirstUseEver)
    window(MAIN, (text = "SDL widgets", closable = false, flags = ImGuiWindowFlags.None)) {
        text("Upstream v2 widgets on SDLRenderer3")
        button(INCREMENT, (text = "Increment"))
        text("Clicks: {INCREMENT.click_count}")
        slider_float(SPEED, (text = "Speed", init = 0.5, bounds = (0.0, 1.0)))
        checkbox(ENABLED, (text = "Enabled", init = true))
        text("State and widget paths are available to upstream telemetry.")
        text("Escape exits when keyboard input is not captured.")
    }
    renderer |> clear() |> sdl_try
    imgui_widgets_render(renderer)
    renderer |> present() |> sdl_try
    return sdl_ok()
}

[export]
def update() : bool {
    if (!running) { return false }
    var event = SDL_MakeEvent()
    while (is_some(poll_event(event))) {
        imgui_widgets_process_event(event)
        if (SDL_EventIsQuit(event) || (SDL_EventIsEscape(event) && !ImGui_SDL3_WantCaptureKeyboard())) { running = false }
    }
    if (!running) { return false }
    report(draw_frame())
    SDL_Delay(16u)
    return running
}

[export]
def shutdown() {
    if (backend_ready) {
        ImGui_ImplSDLRenderer3_Shutdown()
        ImGui_ImplSDL3_Shutdown()
        backend_ready = false
    }
    if (context != null) { DestroyContext(context); context = null }
    if (renderer != null) { destroy_renderer(renderer); renderer = null }
    if (sdl_window != null) { destroy_window(sdl_window); sdl_window = null }
    SDL_Quit()
    print("SDL widgets released.\n")
}

[export]
def exit_code() : int { return failed ? 1 : 0 }
