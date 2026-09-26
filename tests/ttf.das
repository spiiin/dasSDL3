options gen2
require dassdl3/sdl3_ttf_boost
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_scope
require dassdl3/sdl3_pixels_boost
require dassdl3/sdl3_window_io_boost
require dassdl3/sdl3_iostream_boost

// Pixel oracle checks real glyph rasterization, not just successful calls.
def check_ink(surface : SDL_Surface?) {
    let size = surface_size(surface) |> sdl_try
    verify(size.x > 0 && size.y > 0)
    var bytes : array<uint8>
    resize(bytes, size.x * size.y * 4)
    copy_surface_rgba8(surface, bytes, size.x * 4) |> sdl_try
    var ink = 0
    var empty = 0
    for (i in 0 .. size.x * size.y) {
        if (bytes[i * 4 + 3] != uint8(0)) { ink++ }
        else { empty++ }
    }
    verify(ink > 10 && empty > 10)
    return sdl_ok()
}

def test_font(renderer : SDL_Renderer?; font : TTF_Font?) {
    verify(TTF_GetFontSize(font) == 24.0)
    verify(TTF_FontHasGlyph(font, 65u) && TTF_FontHasGlyph(font, 233u))
    let metrics = font |> glyph_metrics(65u) |> sdl_try
    verify(metrics.advance > 0 && metrics.bounds.y > metrics.bounds.x)
    let measured = font |> string_size("café") |> sdl_try
    verify(measured.x > 0 && measured.y > 0)
    font |> with_text_surface("café", SDL_Color(r = 255u8, g = 255u8, b = 255u8, a = 255u8)) $(surface : SDL_Surface?) {
        return check_ink(surface)
    } |> sdl_try
    with_surface_text_engine() $(engine : TTF_TextEngine?) {
        return engine |> with_text(font, "café") $(text : TTF_Text?) {
            let initial = text |> text_size() |> sdl_try
            verify(initial == measured)
            text |> set_text("café café") |> sdl_try
            let larger = text |> text_size() |> sdl_try
            verify(larger.x > initial.x)
            verify(TTF_SetTextWrapWidth(text, initial.x + 2))
            let wrapped = text |> text_size() |> sdl_try
            verify(wrapped.y > initial.y)
            verify(TTF_SetTextWrapWidth(text, 0))
            verify(TTF_SetTextPosition(text, 0, 0))
            verify(TTF_AppendTextString(text, "!", 0ul))
            verify(TTF_UpdateText(text))
            verify(TTF_GetTextFont(text) == font && TTF_GetTextEngine(text) == engine)
            text |> set_text("café café") |> sdl_try
            // Allocate a transparent destination with a deliberately generous border.
            return with_surface(larger.x + 20, larger.y + 20, SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface : SDL_Surface?) {
                verify(SDL_ClearSurface(surface, 0.0, 0.0, 0.0, 0.0))
                text |> draw_text(10, 10, surface) |> sdl_try
                return check_ink(surface)
            }
        }
    } |> sdl_try
    return renderer |> with_renderer_text_engine() $(engine : TTF_TextEngine?) {
        return engine |> with_text(font, "Text") $(text : TTF_Text?) {
            text |> set_text_color(uint4(255u, 80u, 30u, 255u)) |> sdl_try
            renderer |> clear(uint4(0u, 0u, 0u, 255u)) |> sdl_try
            text |> draw_text(8.0, 8.0) |> sdl_try
            renderer |> with_read_pixels() $(surface : SDL_Surface?) {
                let size = surface_size(surface) |> sdl_try
                var bytes : array<uint8>
                resize(bytes, size.x * size.y * 4)
                copy_surface_rgba8(surface, bytes, size.x * 4) |> sdl_try
                var colored = 0
                for (i in 0 .. size.x * size.y) {
                    if (uint(bytes[4 * i]) > 30u && uint(bytes[4 * i]) > uint(bytes[4 * i + 1])) { colored++ }
                }
                verify(colored > 10)
                return sdl_ok()
            } |> sdl_try
            return renderer |> present()
        }
    }
}

[export]
def main(smoke : bool) : int {
    let before = TTF_WasInit()
    let assets = "{SDL_GetBasePath()}assets/libraries/"
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        with_ttf() |> sdl_use
        verify(TTF_WasInit() == before + 1)
        var called = false
        let missing = with_font("{assets}missing.ttf", 24.0) $(font : TTF_Font?) {
            called = true
            return sdl_ok()
        }
        verify(is_err(missing) && !called)
        let saved = unwrap_err(missing)
        SDL_ClearError()
        verify(saved.operation == "TTF_OpenFont" && saved.message != "")
        let window : SDL_Window? = with_window("SDL_ttf test", 320, 160, SDL_WINDOW_HIDDEN) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        SDL_SetErrorMessage("stale SDL error")
        with_font("{assets}JetBrainsMono-Regular.ttf", 24.0) $(font : TTF_Font?) {
            with_font("{assets}JetBrainsMono-Regular.ttf", 16.0) $(small : TTF_Font?) {
                let a = small |> string_size("Metrics") |> sdl_try
                let b = font |> string_size("Metrics") |> sdl_try
                verify(a.x < b.x && a.y < b.y)
                return sdl_ok()
            } |> sdl_try
            return test_font(renderer, font)
        } |> sdl_try
        // IO remains open throughout the font lifetime and after CloseFont.
        with_io_file("{assets}JetBrainsMono-Regular.ttf", "rb") $(io : SDL_IOStream?) {
            with_font(io, 24.0) $(font : TTF_Font?) { return test_font(renderer, font) } |> sdl_try
            verify(SDL_SeekIO(io, 0l, SDL_IOWhence.IO_SEEK_SET) == 0l)
            return sdl_ok()
        } |> sdl_try
        return sdl_ok()
    }
    verify(TTF_WasInit() == before)
    // Error propagation still balances initialization and unwinds all scopes.
    let failed = with_ttf() {
        return with_font("{assets}JetBrainsMono-Regular.ttf", 24.0) $(font : TTF_Font?) {
            return err(SdlError(operation = "test", message = "body error"), type<SdlUnit>)
        }
    }
    verify(is_err(failed) && unwrap_err(failed).message == "body error" && TTF_WasInit() == before)
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("SDL_ttf: UTF-8 metrics, surface/renderer pixels, borrowed IO and scope cleanup passed.\n")
    return 0
}
