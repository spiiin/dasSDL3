options gen2
require dassdl3/sdl3_gl_egl
require dassdl3/sdl3_boost
require dassdl3/sdl3_try
[export]
def main(smoke : bool) : int {
    verify(SDL_WasInit(SDL_INIT_VIDEO)==0u)
    verify(SDL_SetHintWithPriority(SDL_HINT_VIDEO_DRIVER,"dummy",SDL_HintPriority.HINT_OVERRIDE))
    verify(SDL_Init(SDL_INIT_VIDEO))
    SDL_GL_ResetAttributes()
    SDL_EGL_SetAttributeCallbacks(null,null,null,null)
    verify(SDL_GL_SetAttribute(SDL_GLAttr.GL_CONTEXT_MAJOR_VERSION,3))
    var value=0
    unsafe {verify(SDL_GL_GetAttribute(SDL_GLAttr.GL_CONTEXT_MAJOR_VERSION,addr(value)))}
    verify(value==3)
    verify(!SDL_GL_LoadLibrary("dasSDL3-no-such-GL-library.dll"))
    verify(!SDL_GL_LoadLibraryDefault())
    verify(SDL_GL_GetProcAddress("glClear")==null)
    verify(SDL_EGL_GetProcAddress("eglGetDisplay")==null)
    verify(!SDL_GL_ExtensionSupported("DASSDL3_missing_extension"))
    verify(SDL_GL_CreateContext(null)==null)
    verify(SDL_GL_GetCurrentWindow()==null && SDL_GL_GetCurrentContext()==null)
    // Already unbound is a successful no-op, even on dummy.
    verify(SDL_GL_MakeCurrent(null,null))
    verify(SDL_EGL_GetCurrentDisplay()==null)
    verify(SDL_EGL_GetCurrentConfig()==null)
    verify(SDL_EGL_GetWindowSurface(null)==null) // no EGL backend, returns before touching window
    verify(!SDL_GL_SetSwapInterval(0))
    unsafe {verify(!SDL_GL_GetSwapInterval(addr(value)))}
    verify(value==0)
    verify(!SDL_GL_SwapWindow(null))
    verify(!SDL_GL_DestroyContext(null))
    verify(is_err(gl_swap_interval()))
    verify(is_err(create_gl_context(null)))
    var entered=false
    let failed=with_gl_context(null) $(context) {entered=true;return sdl_ok()}
    verify(!entered && is_err(failed))
    let library=with_gl_library("") {entered=true;return sdl_ok()}
    verify(!entered && is_err(library))
    SDL_GL_UnloadLibrary()
    SDL_GL_ResetAttributes()
    SDL_Quit()
    print("GL/EGL: all 20 raw calls and unavailable-backend contracts passed.\n")
    return 0
}
