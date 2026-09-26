options gen2
require dassdl3/sdl3_boost
require dassdl3/sdl3_scope
require dassdl3/sdl3_pixels_boost
require math
var window : SDL_Window?
var renderer : SDL_Renderer?
var frames = 0
var started : uint64
var texture : SDL_Texture?
def report(result : $Result<SdlUnit; SdlError>) : int {
    if (is_err(result)) { let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return -1 }
    return 0
}
def initialize() : $Result<SdlUnit; SdlError> {
    sdl_init() |> sdl_try
    window = create_window("dasSDL3 Web: render target", 640, 480) |> sdl_try
    renderer = create_renderer(window) |> sdl_try
    sdl_status(SDL_SetRenderLogicalPresentation(renderer, 640, 480, SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_LETTERBOX), "SDL_SetRenderLogicalPresentation") |> sdl_try
    texture = SDL_CreateRGBA8Texture(renderer, 128, 128, true)
    if (texture == null) {return err(sdl_error("SDL_CreateRGBA8Texture"), type<SdlUnit>)}
    started = SDL_GetTicks()
    print("Renderer: {SDL_GetRendererName(renderer)}\n")
    return sdl_ok()
}
def draw_frame() : $Result<SdlUnit; SdlError> {
    sdl_scope() {
        renderer |> with_render_target(texture) |> sdl_use
        renderer |> clear(uint4(20u, 40u, 80u, 255u)) |> sdl_try
        renderer |> set_color(uint4(70u, 200u, 160u, 255u)) |> sdl_try
        renderer |> fill_rect(SDL_MakeFRect(16.0 + float(frames % 32), 32.0, 48.0, 64.0)) |> sdl_try
        return sdl_ok()
    } |> sdl_try
    renderer |> clear() |> sdl_try
    renderer |> draw_texture(texture, SDL_MakeFRect(160.0, 80.0, 320.0, 320.0)) |> sdl_try
    renderer |> present() |> sdl_try
    frames++
    if (frames == 60) {print("Rendered 60 frames.\n")}
    return sdl_ok()
}
[export]
def app_init() : int {return report(initialize())}
[export]
def app_frame() : int {return report(draw_frame())}
[export]
def app_event(event : SDL_Event) : int {
    if (should_close(event, window)) {return 1}

    return 0
}
[export]
def app_quit {
    destroy_texture(texture); texture = null
    destroy_renderer(renderer); renderer = null
    destroy_window(window); window = null
    SDL_Quit()
    print("Session released after {frames} frames.\n")
}
