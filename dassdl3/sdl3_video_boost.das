options gen2
module sdl3_video_boost shared public
require dassdl3/sdl3_boost public

def public displays(var output : array<uint>) {return sdl_status(SDL_GetDisplaysCopy(output), "displays")}
def public windows(var output : array<SDL_Window?>) {return sdl_status(SDL_GetWindowsCopy(output), "windows")}
def public display_modes(display : uint; var output : array<SDL_DisplayMode>) {
    return sdl_status(SDL_GetFullscreenDisplayModesCopy(display,output), "display_modes")
}
def public display_name(display : uint) {
    var value : string
    if (!SDL_GetDisplayNameValue(display,value)) {return err(sdl_error("display_name"),type<string>)}
    return ok(value,type<SdlError>)
}
def public window_title(window : SDL_Window?) {
    var value : string
    if (!SDL_GetWindowTitleValue(window,value)) {return err(sdl_error("window_title"),type<string>)}
    return ok(value,type<SdlError>)
}
def public window_size(window : SDL_Window?; var w, h : int&) {return sdl_status(SDL_GetWindowSizeRef(window,w,h), "window_size")}
def public window_size_pixels(window : SDL_Window?; var w, h : int&) {return sdl_status(SDL_GetWindowSizeInPixelsRef(window,w,h), "window_size_pixels")}
def public window_position(window : SDL_Window?; var x, y : int&) {return sdl_status(SDL_GetWindowPositionRef(window,x,y), "window_position")}

def public displays() {
    var output : array<uint>
    let status = displays(output)
    if (is_err(status)) { return err(unwrap_err(status),type<array<uint>>) }
    var value <- output
    return <- move_ok(value,type<SdlError>)
}

def public windows() {
    var output : array<SDL_Window?>
    let status = windows(output)
    if (is_err(status)) { return err(unwrap_err(status),type<array<SDL_Window?>>) }
    var value <- output
    return <- move_ok(value,type<SdlError>)
}

def public display_modes(display : uint) {
    var output : array<SDL_DisplayMode>
    let status = display_modes(display,output)
    if (is_err(status)) { return err(unwrap_err(status),type<array<SDL_DisplayMode>>) }
    var value <- output
    return <- move_ok(value,type<SdlError>)
}

def public window_size(window : SDL_Window?) {
    var w : int
    var h : int
    let status = window_size(window,w,h)
    if (is_err(status)) { return err(unwrap_err(status),type<int2>) }
    var value = int2(w,h)
    return <- move_ok(value,type<SdlError>)
}

def public window_size_pixels(window : SDL_Window?) {
    var w : int
    var h : int
    let status = window_size_pixels(window,w,h)
    if (is_err(status)) { return err(unwrap_err(status),type<int2>) }
    var value = int2(w,h)
    return <- move_ok(value,type<SdlError>)
}

def public window_position(window : SDL_Window?) {
    var x : int
    var y : int
    let status = window_position(window,x,y)
    if (is_err(status)) { return err(unwrap_err(status),type<int2>) }
    var value = int2(x,y)
    return <- move_ok(value,type<SdlError>)
}
