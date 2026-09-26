options gen2
require dassdl3/sdl3_gl_egl
require dassdl3/sdl3_boost
require dassdl3/sdl3_scope
[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        SDL_GL_ResetAttributes()
        set_gl_attribute(SDL_GLAttr.GL_CONTEXT_MAJOR_VERSION, 2) |> sdl_try
        set_gl_attribute(SDL_GLAttr.GL_CONTEXT_MINOR_VERSION, 1) |> sdl_try
        let window : SDL_Window? = with_window("SDL OpenGL context", 64, 64, SDL_WINDOW_OPENGL | SDL_WINDOW_HIDDEN) |> sdl_use
        let context : SDL_GLContextState? = window |> with_gl_context() |> sdl_use
        let major = gl_attribute(SDL_GLAttr.GL_CONTEXT_MAJOR_VERSION) |> sdl_try
        let minor = gl_attribute(SDL_GLAttr.GL_CONTEXT_MINOR_VERSION) |> sdl_try
        print("OpenGL context: {major}.{minor}; current={context==SDL_GL_GetCurrentContext()}\n")
        // SDL manages the context. Drawing uses the existing daScript OpenGL module;
        // see examples/web/opengl for rendering examples.
        return sdl_ok()
    }
    if (is_err(result)) {let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1}
    return 0
}
