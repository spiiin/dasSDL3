options gen2
require sdl3
require sdl3_ttf

// Native fixture checks the close callback before and after each script call.
[export]
def open_font(io : SDL_IOStream?; closeio : bool) : TTF_Font? {
    return TTF_OpenFontIO(io, closeio, 24.0)
}

[export]
def dispose_font(font : TTF_Font?) : bool {
    var size : int2
    let measured = TTF_GetStringSizeRef(font, "Retained IO", size)
    TTF_CloseFont(font)
    return measured && size.x > 0 && size.y > 0
}
