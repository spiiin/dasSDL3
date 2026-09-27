options gen2
options gc
options persistent_heap
require ./frame_recovery.das
require dassdl3/sdl3_imgui_widgets
require dassdl3/sdl3_boost
require dassdl3/sdl3_try
require sdl3_live_demo
require imgui/imgui_theme_daslang
require imgui/imgui_live_core
require daslib/json_boost
require live/live_commands
require ./loopback_http.das
require live/live_watch_boost
require live/live_vars
require live_host

// Resource ownership is in this example's native host.cpp, outside reloadable code.
// The production boost layer does not acquire a new global ownership model.
var @live edits = 33
var @live ticks = 0
var failed = false
var frame_started = false

[live_command(description = "SDL example state and native acquisition count")]
def demo_state(input : JsonValue?) : JsonValue? {
    return JV((edits = edits, ticks = ticks, acquisitions = demo_acquisitions(), revision = 1, clicks = INCREMENT.click_count, speed = SPEED.value))
}

[live_command(description = "Change state used to verify preservation across reload")]
def demo_increment(input : JsonValue?) : JsonValue? {
    edits++
    return JV(edits)
}

[export]
def init() {
    if (!demo_open()) {
        print("SDL live init: {SDL_GetError()}\n")
        failed = true
        request_exit()
        return
    }
    apply_daslang_theme()
}

def frame() : SdlStatus {
    let renderer = demo_renderer()
    imgui_widgets_new_frame()
    frame_started = true
    SetNextWindowPos(ImVec2(20.0, 20.0), ImGuiCond.FirstUseEver, ImVec2(0.0, 0.0))
    SetNextWindowSize(ImVec2(520.0, 320.0), ImGuiCond.FirstUseEver)
    window(MAIN, (text = "SDL live widgets", closable = false, flags = ImGuiWindowFlags.None)) {
        text("Save this script to reload automatically; Reload also works.")
        button(INCREMENT.PUBLIC, (text = "Increment"))
        slider_float(SPEED.PUBLIC, (text = "Speed", init = 0.5, bounds = (0.0, 1.0)))
        button(RELOAD, (text = "Reload script"))
        if (RELOAD.clicked) { request_reload(false) }
        text("Clicks: {INCREMENT.click_count}, edits: {edits}")
    }
    renderer |> clear() |> sdl_try
    imgui_widgets_render(renderer)
    frame_started = false
    renderer |> present() |> sdl_try
    return sdl_ok()
}

[export]
def update() {
    if (failed) { request_exit(); return }
    var event = SDL_MakeEvent()
    while (is_some(poll_event(event))) {
        imgui_widgets_process_event(event)
        if (SDL_EventIsQuit(event) || (SDL_EventIsEscape(event) && !ImGui_SDL3_WantCaptureKeyboard())) { request_exit() }
    }
    let result = frame()
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        failed = true
        request_exit()
    }
    ticks++
    SDL_Delay(16u)
}

[export]
def shutdown() {
    if (frame_started) {
        discard_interrupted_frame()
        frame_started = false
    }
    if (!is_reload()) { demo_close() }
}
