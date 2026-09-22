options gen2
module sdl3_imgui shared public
require imgui public
require imgui_sdl3 public
require dassdl3/sdl3_init_boost public
require daslib/defer

// The body borrows the current context. Do not switch/destroy it or its SDL owners.
// Backend shutdown precedes context destruction; the caller's context is restored.
def public with_imgui(window : SDL_Window?; renderer : SDL_Renderer?;
                     blk : block<() : $Result<auto(TT); SdlError>>) {
    var previous = GetCurrentContext()
    var context = CreateContext()
    if (context == null) {
        return err(SdlError(operation="CreateContext",message="Could not create ImGui context"),type<TT>)
    }
    var result : $Result<TT; SdlError>
    {
        defer() { DestroyContext(context); SetCurrentContext(previous) }
        SetCurrentContext(context)
        if (!ImGui_SDL3_Init(window,renderer)) { return err(sdl_error("ImGui_SDL3_Init"),type<TT>) }
        {
            defer() { ImGui_ImplSDLRenderer3_Shutdown(); ImGui_ImplSDL3_Shutdown() }
            static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { result = blk() }
            else { result <- blk() }
        }
    }
    return <- result
}
