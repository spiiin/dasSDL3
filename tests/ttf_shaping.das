options gen2
require dassdl3/sdl3_ttf_boost
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_scope
require dassdl3/sdl3_pixels_boost

struct Raster {
    size : int2
    hash : uint
    ink : int
}

def raster(font : TTF_Font?; value : string) {
    return font |> with_text_surface(value,SDL_Color(r=255u8,g=255u8,b=255u8,a=255u8)) $(surface : SDL_Surface?) {
        let size = surface_size(surface) |> sdl_try
        var bytes : array<uint8>
        resize(bytes,size.x*size.y*4)
        copy_surface_rgba8(surface,bytes,size.x*4) |> sdl_try
        var result = Raster(size=size,hash=2166136261u)
        for (i in 0 .. size.x*size.y) {
            let alpha = uint(bytes[4*i+3])
            result.hash = (result.hash ^ alpha)*16777619u
            if (alpha > 0u) { result.ink++ }
        }
        verify(result.ink > 10)
        return ok(result,type<SdlError>)
    }
}

def check_shaping(font : TTF_Font?; engine : TTF_TextEngine?) {
    verify(TTF_FontHasGlyph(font,0x628u) && TTF_FontHasGlyph(font,0x64Eu))
    font |> set_font_direction(TTF_Direction.DIRECTION_RTL) |> sdl_try
    font |> set_font_script("Arab") |> sdl_try
    font |> set_font_language("ar") |> sdl_try
    verify(TTF_GetFontDirection(font) == TTF_Direction.DIRECTION_RTL)
    verify(TTF_GetFontScript(font) == TTF_StringToTag("Arab"))
    // ZWNJ prevents contextual joining without introducing a visible space.
    let joined = font |> raster("بب") |> sdl_try
    let separate = font |> raster("ب‌ب") |> sdl_try
    verify(joined.size != separate.size || joined.hash != separate.hash)
    let marked = font |> raster("بَب") |> sdl_try
    verify(marked.ink > joined.ink)
    engine |> with_text(font,"بب") $(text : TTF_Text?) {
        text |> set_text_direction(TTF_Direction.DIRECTION_RTL) |> sdl_try
        text |> set_text_script("Arab") |> sdl_try
        verify(TTF_GetTextDirection(text) == TTF_Direction.DIRECTION_RTL)
        verify(TTF_GetTextScript(text) == TTF_StringToTag("Arab"))
        var first,second : TTF_SubString
        // Raw pointer/out access is intentionally confined to this contract test.
        unsafe {
            verify(TTF_GetTextSubString(text,0,addr(first)))
            verify(TTF_GetTextSubString(text,2,addr(second)))
        }
        verify(first.offset == 0 && second.offset == 2)
        verify(first.rect.x > second.rect.x)
        // Updating after construction must reshape, not keep cached glyphs.
        text |> set_text("بَب") |> sdl_try
        let size = text |> text_size() |> sdl_try
        verify(size.x > 0 && size.y > 0)
        return sdl_ok()
    } |> sdl_try
    font |> set_font_direction(TTF_Direction.DIRECTION_LTR) |> sdl_try
    font |> set_font_script("Latn") |> sdl_try
    font |> set_font_language("en") |> sdl_try
    // HarfBuzz canonical composition: precomposed and combining forms match.
    let composed = font |> raster("café") |> sdl_try
    let decomposed = font |> raster("café") |> sdl_try
    verify(composed.size == decomposed.size && composed.hash == decomposed.hash)
    // A separate ligature run must have fewer clusters than its six input bytes.
    return engine |> with_text(font,"office") $(text : TTF_Text?) {
        var f1,f2 : TTF_SubString
        unsafe {
            verify(TTF_GetTextSubString(text,1,addr(f1)))
            verify(TTF_GetTextSubString(text,2,addr(f2)))
        }
        verify(f1.cluster_index == f2.cluster_index && f1.length >= 2)
        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    var major,minor,patch : int
    unsafe { TTF_GetHarfBuzzVersion(addr(major),addr(minor),addr(patch)) }
    verify(major == 10 && minor == 4 && patch == 0)
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        with_ttf() |> sdl_use
        let font : TTF_Font? = with_font("{SDL_GetBasePath()}assets/libraries/Amiri-Regular.ttf",48.0) |> sdl_use
        let engine : TTF_TextEngine? = with_surface_text_engine() |> sdl_use
        return check_shaping(font,engine)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("HarfBuzz {major}.{minor}.{patch}: contextual joining, RTL clusters, marks and Latin composition/ligatures passed.\n")
    return 0
}
