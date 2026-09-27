options gen2
options gc
options persistent_heap
require dassdl3/sdl3_boost
require dassdl3/sdl3_try
require math

// Resources survive update calls. The host owns the frame loop and GC boundary.
var window : SDL_Window?
var renderer : SDL_Renderer?
var failed = false
var running = true
var active = false
var frames = 0
var started : uint64

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
    window = create_window("dasSDL3 lifecycle - Escape to exit", 640, 480) |> sdl_try
    renderer = create_renderer(window) |> sdl_try
    started = SDL_GetTicks()
    return sdl_ok()
}

[export]
def init() {
    active = true
    failed = false
    running = true
    frames = 0
    report(initialize_resources())
}

def draw_frame() : SdlStatus {
    let time = float(SDL_GetTicks() - started) / 1000.0
    renderer |> clear() |> sdl_try
    renderer |> set_color(uint4(70u, 200u, 160u, 255u)) |> sdl_try
    renderer |> fill_rect(SDL_MakeFRect(280.0 + 180.0 * sin(time), 200.0, 80.0, 80.0)) |> sdl_try
    renderer |> present() |> sdl_try
    return sdl_ok()
}

// Web SDL callbacks consume events before polling. Desktop uses the loop below.
[export]
def app_event(event : SDL_Event) : int {
    if (should_close(event)) { running = false }
    return 0
}

[export]
def update() : bool {
    if (!running) { return false }
    var event = SDL_MakeEvent()
    while (is_some(poll_event(event))) {
        if (should_close(event)) { running = false }
    }
    if (!running) { return false }
    report(draw_frame())
    if (failed) { return false }
    frames++
    if (frames == 60) { print("Rendered 60 frames.\n") }
    return true
}

[export]
def shutdown() {
    if (!active) { return }
    if (renderer != null) { destroy_renderer(renderer); renderer = null }
    if (window != null) { destroy_window(window); window = null }
    SDL_Quit()
    active = false
    print("Lifecycle released after {frames} frames.\n")
}

// Optional SDL host extension; bool update alone cannot distinguish failure/quit.
[export]
def exit_code() : int { return failed ? 1 : 0 }
