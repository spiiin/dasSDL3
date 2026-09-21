options gen2
require dassdl3/sdl3_boost
require dassdl3/sdl3_scope
require dassdl3/sdl3_audio_boost
require math
var window : SDL_Window?
var renderer : SDL_Renderer?
var frames = 0
var started : uint64
var stream : SDL_AudioStream?
var samples : array<uint8>
def report(result : $Result<SdlUnit; SdlError>) : int {
    if(is_err(result)) { let error=unwrap_err(result); print("{error.operation}: {error.message}\n"); return -1 }
    return 0
}
def initialize() : $Result<SdlUnit; SdlError> {
    sdl_init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) |> sdl_try
    window = create_window("dasSDL3 Web: audio",640,480) |> sdl_try
    renderer = create_renderer(window) |> sdl_try
    sdl_status(SDL_SetRenderLogicalPresentation(renderer,640,480,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_LETTERBOX),"SDL_SetRenderLogicalPresentation") |> sdl_try
    // Signed 16-bit little-endian mono PCM; 0.25 seconds at 48 kHz.
    stream = open_playback(audio_spec(uint(SDL_AudioFormat.AUDIO_S16LE),1,48000)) |> sdl_try
    samples |> resize(24000)
    for(i in 0..12000) {
        let sample=int(1800.0*sin(float(i)*6.28318530718*440.0/48000.0))
        samples[i*2]=uint8(sample & 255)
        samples[i*2+1]=uint8((sample & 65535) / 256)
    }
    stream |> put_audio(samples) |> sdl_try
    stream |> resume_audio() |> sdl_try
    print("Audio started: quiet 440 Hz tone. Stop releases the playback stream.\n")
    started=SDL_GetTicks()
    print("Renderer: {SDL_GetRendererName(renderer)}\n")
    return sdl_ok()
}
def draw_frame() : $Result<SdlUnit; SdlError> {
    let queued=stream |> queued_audio() |> sdl_try
    if(queued<24000) {stream |> put_audio(samples) |> sdl_try}
    renderer |> clear() |> sdl_try
    renderer |> set_color(uint4(70u,200u,160u,255u)) |> sdl_try
    renderer |> fill_rect(SDL_MakeFRect(80.0,180.0,float(queued)/100.0+10.0,120.0)) |> sdl_try
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
    destroy_audio_stream(stream);stream=null
    destroy_renderer(renderer);renderer=null
    destroy_window(window);window=null
    SDL_Quit()
    print("Session released after {frames} frames.\n")
}
