options gen2
require math
require daslib/defer
require dassdl3/sdl3_surface_state_boost
require dassdl3/sdl3_renderer_primitives_boost

def check_texture(source : SDL_Surface?; renderer : SDL_Renderer?; output : SDL_Surface?; keyed : bool; expected : int3) {
    let texture = SDL_CreateTextureFromSurface(renderer, source); verify(texture != null)
    {
        defer(){SDL_DestroyTexture(texture)}
        verify(SDL_SetTextureScaleMode(texture, SDL_ScaleMode.SCALEMODE_NEAREST))
        verify(SDL_SetRenderDrawColor(renderer, 0u, 0u, 0u, 255u) && SDL_RenderClear(renderer))
        verify(is_ok(draw_texture(renderer, texture)) && SDL_FlushRenderer(renderer))
        var bytes : array<uint8>; resize(bytes, 32)
        verify(is_ok(copy_surface_rgba8(output, bytes, 16)))
        for (y in 0 .. 2) {for (x in 0 .. 4) {
            let i = (y * 4 + x) * 4
            let rgb = x < 2 ? (keyed ? int3(0) : int3(expected.x, 0, expected.z)) : expected
            verify(abs(int(bytes[i]) - rgb.x) <= 2 && abs(int(bytes[i + 1]) - rgb.y) <= 2 && abs(int(bytes[i + 2]) - rgb.z) <= 2)
        }}
    }
}
[export]
def main(smoke : bool) : int {
    let initialized = with_sdl() {
        let allocated = with_surface(2, 1, SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface : SDL_Surface?) {
            let props = SDL_GetSurfaceProperties(surface); verify(props != 0u && props == SDL_GetSurfaceProperties(surface))
            verify(SDL_SetNumberProperty(props, "test.surface", 73l) && SDL_GetNumberProperty(SDL_GetSurfaceProperties(surface), "test.surface", 0l) == 73l)
            verify(SDL_GetSurfaceColorspace(surface) == SDL_Colorspace.COLORSPACE_SRGB)
            verify(SDL_FillSurfaceAll(surface, SDL_MapSurfaceRGBA(surface, 255u, 255u, 255u, 255u)))
            var rect = SDL_Rect(w = 1, h = 1)
            let key = SDL_MapSurfaceRGBA(surface, 255u, 0u, 255u, 255u)
            unsafe {verify(SDL_FillSurfaceRect(surface, addr(rect), key))}
            var before, after : array<uint8>; resize(before, 8); resize(after, 8)
            verify(is_ok(copy_surface_rgba8(surface, before, 8)))
            verify(SDL_SetSurfaceColorspace(surface, SDL_Colorspace.COLORSPACE_SRGB_LINEAR) && SDL_GetSurfaceColorspace(surface) == SDL_Colorspace.COLORSPACE_SRGB_LINEAR)
            verify(SDL_SetSurfaceColorspace(surface, SDL_Colorspace.COLORSPACE_SRGB))
            verify(!SDL_SurfaceHasRLE(surface) && SDL_SetSurfaceRLE(surface, true) && SDL_SurfaceHasRLE(surface))
            verify(SDL_SetSurfaceRLE(surface, false) && !SDL_SurfaceHasRLE(surface))
            var got = 9u
            verify(!SDL_SurfaceHasColorKey(surface) && !unwrap_or(surface_color_key(surface, got), false) && got == 0u)
            verify(SDL_SetSurfaceColorKey(surface, true, key) && SDL_SurfaceHasColorKey(surface))
            unsafe {verify(SDL_GetSurfaceColorKey(surface, addr(got)) && got == key)}
            verify(unwrap_or(surface_color_key(surface, got), false) && got == key)
            verify(SDL_SetSurfaceColorMod(surface, 128u, 64u, 32u) && SDL_SetSurfaceAlphaMod(surface, 255u))
            verify(SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_BLEND))
            var r, g, b, a : uint; var mode : uint
            verify(is_ok(surface_color_mod(surface, r, g, b)) && r == 128u && g == 64u && b == 32u)
            verify(is_ok(surface_alpha_mod(surface, a)) && a == 255u && is_ok(surface_blend_mode(surface, mode)) && mode == SDL_BLENDMODE_BLEND)
            var nr, ng, nb, na : uint8
            unsafe {
                verify(SDL_GetSurfaceColorMod(surface, addr(nr), addr(ng), addr(nb)) && nr == uint8(128) && ng == uint8(64) && nb == uint8(32))
                verify(SDL_GetSurfaceAlphaMod(surface, addr(na)) && na == uint8(255))
                verify(SDL_GetSurfaceBlendMode(surface, addr(mode)) && mode == SDL_BLENDMODE_BLEND)
            }
            let out_ok = with_surface(4, 2, SDL_PixelFormat.PIXELFORMAT_RGBA32) $(output : SDL_Surface?) {
                verify(SDL_GetSurfaceProperties(output) != props)
                let renderer_ok = with_software_renderer(output) $(renderer : SDL_Renderer?) {
                    check_texture(surface, renderer, output, true, int3(128, 64, 32))
                    verify(SDL_SetSurfaceAlphaMod(surface, 128u))
                    check_texture(surface, renderer, output, true, int3(64, 32, 16))
                    verify(SDL_SetSurfaceColorKey(surface, false, 0u) && !SDL_SurfaceHasColorKey(surface))
                    verify(SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_NONE))
                    check_texture(surface, renderer, output, false, int3(128, 64, 32))

                    return sdl_ok()
                } |> is_ok
                verify(renderer_ok)

                return sdl_ok()
            } |> is_ok
            verify(out_ok)
            verify(SDL_SetSurfaceColorMod(surface, 255u, 255u, 255u) && SDL_SetSurfaceAlphaMod(surface, 255u))
            verify(is_ok(copy_surface_rgba8(surface, after, 8)))
            for (i in 0 .. 8) {verify(before[i] == after[i])}
            verify(!SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_INVALID))

            return sdl_ok()
        } |> is_ok
        verify(allocated)
        let clip_ok = with_surface(4, 3, SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface : SDL_Surface?) {
            verify(SDL_FillSurfaceAll(surface, SDL_MapSurfaceRGBA(surface, 0u, 0u, 0u, 255u)))
            var clip, got : SDL_Rect; clip.x = -1; clip.y = 1; clip.w = 3; clip.h = 4
            unsafe {verify(SDL_SetSurfaceClipRect(surface, addr(clip)) && SDL_GetSurfaceClipRect(surface, addr(got)))}
            verify(got.x == 0 && got.y == 1 && got.w == 2 && got.h == 2)
            verify(is_ok(surface_clip(surface, got)) && got.w == 2)
            verify(SDL_FillSurfaceAll(surface, SDL_MapSurfaceRGBA(surface, 255u, 0u, 0u, 255u)))
            var bytes : array<uint8>; resize(bytes, 48); verify(is_ok(copy_surface_rgba8(surface, bytes, 16)))
            for (y in 0 .. 3) {for (x in 0 .. 4) {verify(bytes[(y * 4 + x) * 4] == uint8(x < 2 && y >= 1 ? 255 : 0))}}
            clip.x = 20; clip.y = 20; clip.w = 1; clip.h = 1
            SDL_ClearError(); verify(!unwrap_or(set_surface_clip(surface, clip), false) && SDL_GetError() == "")
            verify(is_ok(surface_clip(surface, got)) && (got.w <= 0 || got.h <= 0))
            verify(unwrap_or(reset_surface_clip(surface), false) && is_ok(surface_clip(surface, got)) && got.x == 0 && got.y == 0 && got.w == 4 && got.h == 3)
            clip.x = 1; clip.y = 1; verify(unwrap_or(set_surface_clip(surface, clip), false))
            unsafe {verify(SDL_SetSurfaceClipRect(surface, null))}
            verify(is_ok(surface_clip(surface, got)) && got.w == 4 && got.h == 3)

            return sdl_ok()
        } |> is_ok
        verify(clip_ok)

        return sdl_ok()
    } |> is_ok
    verify(initialized)
    var r, g, b, a, key, mode : uint; var rect : SDL_Rect
    verify(SDL_GetSurfaceProperties(null) == 0u && SDL_GetSurfaceColorspace(null) == SDL_Colorspace.COLORSPACE_UNKNOWN)
    verify(!SDL_SetSurfaceColorspace(null, SDL_Colorspace.COLORSPACE_SRGB) && !SDL_SetSurfaceRLE(null, true) && !SDL_SurfaceHasRLE(null))
    verify(!SDL_SetSurfaceColorKey(null, true, 0u) && !SDL_SurfaceHasColorKey(null) && !unwrap_or(surface_color_key(null, key), false) && key == 0u)
    verify(!SDL_SetSurfaceColorMod(null, 0u, 0u, 0u) && !is_ok(surface_color_mod(null, r, g, b)) && r == 255u && g == 255u && b == 255u)
    verify(!SDL_SetSurfaceAlphaMod(null, 0u) && !is_ok(surface_alpha_mod(null, a)) && a == 255u)
    verify(!SDL_SetSurfaceBlendMode(null, SDL_BLENDMODE_NONE) && !is_ok(surface_blend_mode(null, mode)) && mode == SDL_BLENDMODE_INVALID)
    verify(!unwrap_or(set_surface_clip(null, rect), false) && !is_ok(surface_clip(null, rect)) && rect.w == 0 && !unwrap_or(reset_surface_clip(null), false))
    print("surface state: raw/ref state, modulation pixels, clip pixels and errors passed\n")
    return 0
}
