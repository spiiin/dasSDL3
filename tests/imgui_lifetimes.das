options gen2
require dassdl3/sdl3_imgui
require dassdl3/sdl3_scope
require daslib/defer

[export]
def main(smoke : bool) : int {
    verify(GetCurrentContext() == null)
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("ImGui lifetime test",320,240,SDL_WINDOW_HIDDEN) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        var called = false
        let failed = with_imgui(window,null) {
            called = true
            return sdl_ok()
        }
        verify(is_err(failed) && !called && GetCurrentContext() == null)
        for (i in 0 .. 3) {
            let body_error = with_imgui(window,renderer) {
                verify(GetCurrentContext() != null)
                // Refuse to overwrite a live backend, without damaging it.
                verify(!ImGui_SDL3_Init(window,renderer))
                return err(SdlError(operation="body",message="preserve this error"),type<SdlUnit>)
            }
            verify(is_err(body_error) && unwrap_err(body_error).operation == "body")
            verify(GetCurrentContext() == null)
        }
        var previous = CreateContext()
        {
            defer() { DestroyContext(previous) }
            with_imgui(window,renderer) {
                verify(GetCurrentContext() != previous)
                return sdl_ok()
            } |> sdl_try
            verify(GetCurrentContext() == previous)
        }
        return sdl_ok()
    }
    verify(is_ok(result) && GetCurrentContext() == null)
    print("ImGui: failed initialization, body error, repeated scopes and context restoration passed.\n")
    return 0
}
