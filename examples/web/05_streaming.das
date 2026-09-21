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
var pixels : array<uint8>
def report(result : $Result<SdlUnit; SdlError>) : int {
    if(is_err(result)) { let error=unwrap_err(result); print("{error.operation}: {error.message}\n"); return -1 }
    return 0
}
def initialize() : $Result<SdlUnit; SdlError> {
    sdl_init() |> sdl_try
    window = create_window("dasSDL3 Web: streaming",640,480) |> sdl_try
    renderer = create_renderer(window) |> sdl_try
    sdl_status(SDL_SetRenderLogicalPresentation(renderer,640,480,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_LETTERBOX),"SDL_SetRenderLogicalPresentation") |> sdl_try
    texture = SDL_CreateRGBA8Texture(renderer,128,128,false)
    if(texture==null) {return err(sdl_error("SDL_CreateRGBA8Texture"),type<SdlUnit>)}
    let count=rgba8_buffer_size(128,128,512) |> sdl_try
    pixels |> resize(count)
    started=SDL_GetTicks()
    print("Renderer: {SDL_GetRendererName(renderer)}\n")
    return sdl_ok()
}
def draw_frame() : $Result<SdlUnit; SdlError> {
    let band=(frames*2)%112
    for(y in 0..128) {
        for(x in 0..128) {
            let i=(y*128+x)*4
            let lit=y>=band && y<band+16
            pixels[i]=uint8(lit ? 70 : 18)
            pixels[i+1]=uint8(lit ? 200 : 24)
            pixels[i+2]=uint8(lit ? 160 : 38)
            pixels[i+3]=uint8(255)
        }
    }
    texture |> upload_rgba8(pixels,512) |> sdl_try
    renderer |> clear() |> sdl_try
    renderer |> draw_texture(texture,SDL_MakeFRect(160.0,80.0,320.0,320.0)) |> sdl_try
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
    destroy_texture(texture);texture=null
    destroy_renderer(renderer);renderer=null
    destroy_window(window);window=null
    SDL_Quit()
    print("Session released after {frames} frames.\n")
}
