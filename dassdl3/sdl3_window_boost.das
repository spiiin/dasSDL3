options gen2
require daslib/defer
module sdl3_window_boost shared public
require dassdl3/sdl3_video_boost public

// Keep any parent alive until this scope exits. The block must not destroy the
// window or an ancestor: SDL recursively destroys children with their parent.
def public with_window_properties(props : uint; blk : block<(window : SDL_Window?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let window=SDL_CreateWindowWithProperties(props)
    if(window==null) {return err(sdl_error("with_window_properties"), type<TT>)}
    {defer() {SDL_DestroyWindow(window)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(window) } else { scope_result <- blk(window) }}

    return <- scope_result
}
def public with_popup_window(parent : SDL_Window?; x,y,w,h : int; flags : uint64;
        blk : block<(window : SDL_Window?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let window=SDL_CreatePopupWindow(parent,x,y,w,h,flags)
    if(window==null) {return err(sdl_error("with_popup_window"), type<TT>)}
    {defer() {SDL_DestroyWindow(window)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(window) } else { scope_result <- blk(window) }}

    return <- scope_result
}
def public window_minimum_size(window : SDL_Window?; var w,h : int&) {
    return sdl_status(SDL_GetWindowMinimumSizeRef(window,w,h), "window_minimum_size")
}
def public window_maximum_size(window : SDL_Window?; var w,h : int&) {
    return sdl_status(SDL_GetWindowMaximumSizeRef(window,w,h), "window_maximum_size")
}
def public window_aspect_ratio(window : SDL_Window?; var low,high : float&) {
    return sdl_status(SDL_GetWindowAspectRatioRef(window,low,high), "window_aspect_ratio")
}

def public window_minimum_size(window : SDL_Window?) {
    var w : int
    var h : int
    let status = window_minimum_size(window,w,h)
    if (is_err(status)) { return err(unwrap_err(status),type<int2>) }
    var value = int2(w,h)
    return <- move_ok(value,type<SdlError>)
}

def public window_maximum_size(window : SDL_Window?) {
    var w : int
    var h : int
    let status = window_maximum_size(window,w,h)
    if (is_err(status)) { return err(unwrap_err(status),type<int2>) }
    var value = int2(w,h)
    return <- move_ok(value,type<SdlError>)
}

def public window_aspect_ratio(window : SDL_Window?) {
    var low : float
    var high : float
    let status = window_aspect_ratio(window,low,high)
    if (is_err(status)) { return err(unwrap_err(status),type<float2>) }
    var value = float2(low,high)
    return <- move_ok(value,type<SdlError>)
}
