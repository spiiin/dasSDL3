options gen2
require daslib/defer
require dassdl3/sdl3_gl_egl
require dassdl3/sdl3_boost
require dassdl3/sdl3_scope

def exercise(window : SDL_Window?) : $Result<SdlUnit; SdlError> {
    var first=window |> create_gl_context() |> sdl_try
    var second : SDL_GLContextState? = null
    var result : $Result<SdlUnit; SdlError>
    {
        defer() {
            if(second!=null) {SDL_GL_DestroyContext(second)}
            if(first!=null) {SDL_GL_DestroyContext(first)}
        }
        result=sdl_scope() {
            verify(SDL_GL_GetCurrentContext()==first && SDL_GL_GetCurrentWindow()==window)
            let major=gl_attribute(SDL_GLAttr.GL_CONTEXT_MAJOR_VERSION) |> sdl_try
            verify(major>=2)
            verify(SDLTestGLPixel(SDL_GL_GetProcAddress("glClearColor"),SDL_GL_GetProcAddress("glClear"),SDL_GL_GetProcAddress("glReadPixels")))
            // Driver support varies. Query still distinguishes value from failure.
            let interval=set_gl_swap_interval(0)
            if(is_ok(interval)) {let actual=gl_swap_interval() |> sdl_try; verify(actual==0)}
            window |> swap_gl_window() |> sdl_try
            second=window |> create_gl_context() |> sdl_try
            let body_error=with_gl_current(window,first) {
                verify(SDL_GL_GetCurrentContext()==first)
                return err(SdlError(operation="body",message="preserve me"),type<int>)
            }
            verify(is_err(body_error) && unwrap_err(body_error).message=="preserve me")
            verify(SDL_GL_GetCurrentContext()==second)
            var moved <- with_gl_current(window,first) {
                var values <- array<int>(4,9)
                return <- move_ok(values,type<SdlError>)
            }
            verify(is_ok(moved))
            var values <- move_unwrap(moved)
            verify(values[1]==9 && SDL_GL_GetCurrentContext()==second)
            destroy_gl_context(second) |> sdl_try
            verify(second==null && SDL_GL_GetCurrentContext()==null)
            make_gl_current(window,first) |> sdl_try
            destroy_gl_context(first) |> sdl_try
            verify(first==null && SDL_GL_GetCurrentContext()==null)
            let early=with_gl_context(window) $(context) {
                verify(context==SDL_GL_GetCurrentContext())
                return err(SdlError(operation="early",message="kept"),type<SdlUnit>)
            }
            verify(is_err(early) && unwrap_err(early).message=="kept")
            verify(SDL_GL_GetCurrentContext()==null)
            return sdl_ok()
        }
    }
    return <- result
}
[export]
def main(smoke : bool) : int {
    let result=sdl_scope() {
        with_sdl() |> sdl_use
        SDL_GL_ResetAttributes()
        set_gl_attribute(SDL_GLAttr.GL_CONTEXT_MAJOR_VERSION,2) |> sdl_try
        set_gl_attribute(SDL_GLAttr.GL_CONTEXT_MINOR_VERSION,1) |> sdl_try
        with_gl_library("") |> sdl_use
        let window : SDL_Window? = with_window("GL binding test",64,64,SDL_WINDOW_OPENGL | SDL_WINDOW_HIDDEN) |> sdl_use
        return exercise(window)
    }
    if(is_err(result)) {let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    print("GL: real contexts, pixel readback, switching and deferred cleanup passed.\n")
    return 0
}
