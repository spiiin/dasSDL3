options gen2
require daslib/defer
module sdl3_window_boost shared public
require dassdl3/sdl3_video_boost public

// Keep any parent alive until this scope exits. The block must not destroy the
// window or an ancestor: SDL recursively destroys children with their parent.
def public with_window_properties(props : uint; blk : block<(window : SDL_Window?) : void>) : bool {
    let window=SDL_CreateWindowWithProperties(props)
    if(window==null) {return false}
    {defer() {SDL_DestroyWindow(window)};blk(window);return true}
}
def public with_popup_window(parent : SDL_Window?; x,y,w,h : int; flags : uint64;
        blk : block<(window : SDL_Window?) : void>) : bool {
    let window=SDL_CreatePopupWindow(parent,x,y,w,h,flags)
    if(window==null) {return false}
    {defer() {SDL_DestroyWindow(window)};blk(window);return true}
}
def public window_minimum_size(window : SDL_Window?; var w,h : int&) : bool {
    return SDL_GetWindowMinimumSizeRef(window,w,h)
}
def public window_maximum_size(window : SDL_Window?; var w,h : int&) : bool {
    return SDL_GetWindowMaximumSizeRef(window,w,h)
}
def public window_aspect_ratio(window : SDL_Window?; var low,high : float&) : bool {
    return SDL_GetWindowAspectRatioRef(window,low,high)
}
