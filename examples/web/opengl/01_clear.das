options gen2
require dassdl3/sdl3_boost
require dassdl3/sdl3_try
require opengl
require math
var window : SDL_Window?
var context : SDL_GLContextState?
var frames=0
var started : uint64


def report(result : $Result<SdlUnit; SdlError>) : int {
    if(is_err(result)) {let error=unwrap_err(result);print("{error.operation}: {error.message}\n");return -1}
    return 0
}

def initialize() : $Result<SdlUnit; SdlError> {
    sdl_init() |> sdl_try
    SDL_GL_ResetAttributes()
    sdl_status(SDL_GL_SetAttribute(SDL_GLAttr.GL_CONTEXT_PROFILE_MASK,SDL_GL_CONTEXT_PROFILE_ES),"SDL_GL_SetAttribute") |> sdl_try
    sdl_status(SDL_GL_SetAttribute(SDL_GLAttr.GL_CONTEXT_MAJOR_VERSION,3),"SDL_GL_SetAttribute") |> sdl_try
    sdl_status(SDL_GL_SetAttribute(SDL_GLAttr.GL_CONTEXT_MINOR_VERSION,0),"SDL_GL_SetAttribute") |> sdl_try
    window=create_window("dasSDL3 WebGL 2",640,480,SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE) |> sdl_try
    context=SDL_GL_CreateContext(window)
    if(context==null) {return err(sdl_error("SDL_GL_CreateContext"),type<SdlUnit>)}
    sdl_status(SDL_GL_MakeCurrent(window,context),"SDL_GL_MakeCurrent") |> sdl_try
    print("OpenGL ES 3.0 / WebGL 2 via daScript dasOpenGL.\n")

    started=SDL_GetTicks()
    return sdl_ok()
}
def draw_frame() : $Result<SdlUnit; SdlError> {
    var width,height : int
    sdl_status(SDL_GetWindowSizeInPixelsRef(window,width,height),"SDL_GetWindowSizeInPixels") |> sdl_try
    glViewport(0,0,width,height)
    glClearColor(70.0/255.0,200.0/255.0,160.0/255.0,1.0)
    glClear(GL_COLOR_BUFFER_BIT)
    let error=glGetError()
    if(error!=uint(GL_NO_ERROR)) {return err(SdlError(operation="OpenGL frame",message="GL error {error}"),type<SdlUnit>)}
    sdl_status(SDL_GL_SwapWindow(window),"SDL_GL_SwapWindow") |> sdl_try
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

    if(context!=null) {
        if(!SDL_GL_DestroyContext(context)) {let error=sdl_error("SDL_GL_DestroyContext");print("{error.operation}: {error.message}\n")}
        context=null
    }
    destroy_window(window);window=null
    SDL_Quit()
    print("Session released after {frames} frames.\n")
}
