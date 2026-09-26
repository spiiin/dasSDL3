options gen2
require dassdl3/sdl3_rect_clipboard_boost
[export]
def main(smoke : bool) : int {
    SDLTestCallbacksReset()
    let initialized = with_sdl() {
        var types : array<string>; push(types, "application/x-callback-test")
        unsafe {
            verify(SDL_SetClipboardData(SDLTestClipboardProvider(), SDLTestClipboardCleaner(), null, addr(types[0]), 1ul))
            var count : uint64; let raw = SDL_GetClipboardData(types[0], addr(count)); verify(raw != null && count == 3ul); SDL_free(raw)
            verify(SDLTestClipboardRequestCount() > 0 && SDLTestClipboardCleanupCount() == 0)
            verify(SDL_SetClipboardData(SDLTestClipboardProvider(), SDLTestClipboardCleaner(), null, addr(types[0]), 1ul))
            verify(SDLTestClipboardCleanupCount() == 1)
            verify(SDL_ClearClipboardData() && SDLTestClipboardCleanupCount() == 2)
            verify(SDL_ClearClipboardData() && SDLTestClipboardCleanupCount() == 2)
            verify(!SDL_SetClipboardData(SDLTestClipboardProvider(), SDLTestClipboardCleaner(), null, null, 0ul) && SDLTestClipboardCleanupCount() == 2)
            verify(SDL_SetClipboardData(SDLTestClipboardProvider(), SDLTestClipboardCleaner(), null, addr(types[0]), 1ul))
        }

        return sdl_ok()
    } |> is_ok
    verify(initialized && SDLTestClipboardCleanupCount() == 3)
    print("Clipboard native callbacks: request/replacement/clear/quit exactly-once cleanup passed\n")
    return 0
}
