options gen2
require dassdl3/sdl3_rect_clipboard_boost

[export]
def clipboard_exchange() : int {
    let text = clipboard_text()
    if (is_err(text)) {
        print("SDL clipboard read: {unwrap_err(text).message}\n")
        return 0
    }
    if (unwrap(text) != "café") {
        print("SDL clipboard did not contain the expected test text.\n")
        return 0
    }
    if (!SDL_SetClipboardText("SDL: café")) {
        print("SDL_SetClipboardText: {SDL_GetError()}\n")
        return -1
    }
    return 1
}
