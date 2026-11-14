options gen2
require sdl3

// Read one byte from the app's own bundled resource and use it as the blue channel.
[export]
def app_blue() : int {
    let io = SDL_IOFromFile("{SDL_GetBasePath()}assets/color.txt", "rb")
    if (io == null) { return -1 }
    var blue : uint
    let read = SDL_ReadU8Ref(io, blue)
    let closed = SDL_CloseIO(io)
    return read && closed ? int(blue) : -1
}
