options gen2
require daslib/defer
module sdl3_gl_egl shared public
require dassdl3/sdl3_result public

def public gl_attribute(attribute : SDL_GLAttr) {
    var value=0
    if(!SDL_GL_GetAttributeRef(attribute,value)) {return err(sdl_error("SDL_GL_GetAttribute"),type<int>)}
    return ok(value,type<SdlError>)
}
def public gl_swap_interval() {
    var value=0
    if(!SDL_GL_GetSwapIntervalRef(value)) {return err(sdl_error("SDL_GL_GetSwapInterval"),type<int>)}
    return ok(value,type<SdlError>)
}
def public set_gl_attribute(attribute : SDL_GLAttr; value : int) {return sdl_status(SDL_GL_SetAttribute(attribute,value),"SDL_GL_SetAttribute")}
def public set_gl_swap_interval(value : int) {return sdl_status(SDL_GL_SetSwapInterval(value),"SDL_GL_SetSwapInterval")}
def public swap_gl_window(window : SDL_Window?) {return sdl_status(SDL_GL_SwapWindow(window),"SDL_GL_SwapWindow")}
def public make_gl_current(window : SDL_Window?; context : SDL_GLContextState?) {return sdl_status(SDL_GL_MakeCurrent(window,context),"SDL_GL_MakeCurrent")}
def public create_gl_context(window : SDL_Window?) {
    var context=SDL_GL_CreateContext(window)
    if(context==null) {return err(sdl_error("SDL_GL_CreateContext"),type<SDL_GLContextState?>)}
    return <- move_ok(context,type<SdlError>)
}
// Consume on success only. Raw pointer aliases are not invalidated.
def public destroy_gl_context(var context : SDL_GLContextState?&) {
    if(!SDL_GL_DestroyContext(context)) {return err(sdl_error("SDL_GL_DestroyContext"),type<SdlUnit>)}
    context=null
    return sdl_ok()
}
// No implicit restoration: like SDL creation, the new context becomes current.
// The callback must not destroy the borrowed context or its window.
def public with_gl_context(window : SDL_Window?; body : block<(context : SDL_GLContextState?) : $Result<auto(T); SdlError>>) {
    let context=SDL_GL_CreateContext(window)
    if(context==null) {return err(sdl_error("SDL_GL_CreateContext"),type<T>)}
    var result : $Result<T; SdlError>
    {
        defer() {
            let closed=SDL_GL_DestroyContext(context)
            if(!closed && is_ok(result)) {result <- err(sdl_error("SDL_GL_DestroyContext"),type<T>)}
        }
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) {result=body(context)}
        else {result <- body(context)}
    }
    return <- result
}
// Both saved and selected window/context pairs must outlive the callback.
def public with_gl_current(window : SDL_Window?; context : SDL_GLContextState?; body : block<() : $Result<auto(T); SdlError>>) {
    let previous_window=SDL_GL_GetCurrentWindow()
    let previous_context=SDL_GL_GetCurrentContext()
    if(!SDL_GL_MakeCurrent(window,context)) {return err(sdl_error("SDL_GL_MakeCurrent"),type<T>)}
    var result : $Result<T; SdlError>
    {
        defer() {
            let restored=SDL_GL_MakeCurrent(previous_window,previous_context)
            if(!restored && is_ok(result)) {result <- err(sdl_error("SDL_GL_MakeCurrent restore"),type<T>)}
        }
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) {result=body()}
        else {result <- body()}
    }
    return <- result
}
// Keep this scope outside GL windows and contexts. Empty means SDL's default library.
def public with_gl_library(path : string; body : block<() : $Result<auto(T); SdlError>>) {
    let loaded=empty(path) ? SDL_GL_LoadLibraryDefault() : SDL_GL_LoadLibrary(path)
    if(!loaded) {return err(sdl_error("SDL_GL_LoadLibrary"),type<T>)}
    {
        defer() {SDL_GL_UnloadLibrary()}
        return <- body()
    }
}
