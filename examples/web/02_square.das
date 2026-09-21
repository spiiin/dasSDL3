options gen2
require dassdl3/sdl3_boost
require dassdl3/sdl3_scope
require math
var window : SDL_Window?
var renderer : SDL_Renderer?
var frames = 0
var started : uint64

def report(result : $Result<SdlUnit; SdlError>) : int {
    if(is_err(result)) { let error=unwrap_err(result); print("{error.operation}: {error.message}\n"); return -1 }
    return 0
}
def initialize() : $Result<SdlUnit; SdlError> {
    sdl_init() |> sdl_try
    window = create_window("dasSDL3 Web: square",640,480) |> sdl_try
    renderer = create_renderer(window) |> sdl_try
    sdl_status(SDL_SetRenderLogicalPresentation(renderer,640,480,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_LETTERBOX),"SDL_SetRenderLogicalPresentation") |> sdl_try
    
    started=SDL_GetTicks()
    print("Renderer: {SDL_GetRendererName(renderer)}\n")
    return sdl_ok()
}
def draw_frame() : $Result<SdlUnit; SdlError> {
    renderer |> set_color(uint4(18u,24u,38u,255u)) |> sdl_try
    renderer |> clear() |> sdl_try
    let time=float(SDL_GetTicks()-started)/1000.0
    renderer |> set_color(uint4(70u,200u,160u,255u)) |> sdl_try
    renderer |> fill_rect(SDL_MakeFRect(280.0+180.0*sin(time),200.0,80.0,80.0)) |> sdl_try
    renderer |> present() |> sdl_try
    frames++
    if(frames==60) {print("Rendered 60 frames.\n")}
    return sdl_ok()
}
[export]
def app_init() : int {return report(initialize())}
[export]
def app_frame() : int {return report(draw_frame())}
[export]
def app_event(event : SDL_Event) : int {
    if(should_close(event,window)) {return 1}
    
    return 0
}
[export]
def app_quit {
    
    destroy_renderer(renderer);renderer=null
    destroy_window(window);window=null
    SDL_Quit()
    print("Session released after {frames} frames.\n")
}
