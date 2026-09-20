options gen2
module sdl3_video_boost shared public
require dassdl3/sdl3_boost public

def public displays(var output : array<uint>) : bool {return SDL_GetDisplaysCopy(output)}
def public windows(var output : array<SDL_Window?>) : bool {return SDL_GetWindowsCopy(output)}
def public display_modes(display : uint; var output : array<SDL_DisplayMode>) : bool {
    return SDL_GetFullscreenDisplayModesCopy(display,output)
}
def public display_name(display : uint) : string {return SDL_GetDisplayNameCopy(display)}
def public window_title(window : SDL_Window?) : string {return SDL_GetWindowTitleCopy(window)}
def public window_size(window : SDL_Window?; var w, h : int&) : bool {return SDL_GetWindowSizeRef(window,w,h)}
def public window_size_pixels(window : SDL_Window?; var w, h : int&) : bool {return SDL_GetWindowSizeInPixelsRef(window,w,h)}
def public window_position(window : SDL_Window?; var x, y : int&) : bool {return SDL_GetWindowPositionRef(window,x,y)}
