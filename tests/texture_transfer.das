options gen2
require math
require dassdl3/sdl3_texture_transfer_boost

def snapshot(renderer : SDL_Renderer?; surface : SDL_Surface?; texture : SDL_Texture?; var bytes : array<uint8>) {
    verify(SDL_SetRenderDrawColor(renderer, 0u, 0u, 0u, 255u) && SDL_RenderClear(renderer))
    verify(is_ok(draw_texture(renderer, texture)) && SDL_FlushRenderer(renderer))
    resize(bytes, 4 * 4 * 4); verify(is_ok(copy_surface_rgba8(surface, bytes, 16)))
}
[export]
def main(smoke : bool) : int {
    let initialized = with_sdl() {
        let allocated = with_surface(4, 4, SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface : SDL_Surface?) {
            let created = with_software_renderer(surface) $(renderer : SDL_Renderer?) {
                let scoped = with_texture(renderer, SDL_PixelFormat.PIXELFORMAT_RGBA32, SDL_TextureAccess.TEXTUREACCESS_STATIC, 4, 4) $(texture : SDL_Texture?) {
                    var full = SDL_Rect(w = 4, h = 4)
                    var source : array<uint8>; resize(source, 64)
                    for (i in 0 .. 64) {source[i] = uint8(255)}
                    unsafe {verify(SDL_UpdateTexture(texture, null, addr(source[0]), 16))}
                    verify(SDL_SetTextureColorMod(texture, 200u, 100u, 50u) && SDL_SetTextureAlphaMod(texture, 128u))
                    var r, g, b, a : uint; var blend = SDL_BLENDMODE_INVALID
                    unsafe {
                        var nr, ng, nb, na : uint8
                        verify(SDL_GetTextureColorMod(texture, addr(nr), addr(ng), addr(nb)))
                        verify(SDL_GetTextureAlphaMod(texture, addr(na)))
                        verify(nr == uint8(200) && ng == uint8(100) && nb == uint8(50) && na == uint8(128))
                    }
                    verify(is_ok(texture_color_mod_bytes(texture, r, g, b)) && r == uint(200) && g == uint(100) && b == uint(50))
                    verify(is_ok(texture_alpha_mod_byte(texture, a)) && a == uint(128))
                    verify(SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND))
                    unsafe {verify(SDL_GetTextureBlendMode(texture, addr(blend)) && blend == SDL_BLENDMODE_BLEND)}
                    var image : array<uint8>; snapshot(renderer, surface, texture, image)
                    for (i in 0 .. 16) {verify(abs(int(image[i * 4]) - 100) <= 2 && abs(int(image[i * 4 + 1]) - 50) <= 2 && abs(int(image[i * 4 + 2]) - 25) <= 2)}
                    verify(SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_NONE) && is_ok(texture_blend_mode(texture, blend)) && blend == SDL_BLENDMODE_NONE)
                    snapshot(renderer, surface, texture, image)
                    for (i in 0 .. 16) {verify(image[i * 4] == uint8(200) && image[i * 4 + 1] == uint8(100) && image[i * 4 + 2] == uint8(50))}
                    verify(!SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_INVALID))
                    verify(SDL_SetTextureColorMod(texture, 255u, 255u, 255u) && SDL_SetTextureAlphaMod(texture, 255u))
                    verify(is_ok(update_texture_rgba8(texture, full, source, 16)))
                    var rect = SDL_Rect(x = 1, y = 1, w = 2, h = 2)
                    // Padded first row, no required trailing padding in the final row.
                    var patch : array<uint8>; resize(patch, 20)
                    for (y in 0 .. 2) {for (x in 0 .. 2) {let i = y * 12 + x * 4; patch[i] = uint8(20); patch[i + 1] = uint8(40); patch[i + 2] = uint8(60); patch[i + 3] = uint8(255)}}
                    verify(is_ok(update_texture_rgba8(texture, rect, patch, 12)))
                    snapshot(renderer, surface, texture, image)
                    for (y in 0 .. 4) {for (x in 0 .. 4) {
                        let inside = x >= 1 && x < 3 && y >= 1 && y < 3; let i = (y * 4 + x) * 4
                        verify(image[i] == uint8(inside ? 20 : 255) && image[i + 1] == uint8(inside ? 40 : 255) && image[i + 2] == uint8(inside ? 60 : 255))
                    }}
                    verify(is_err(update_texture_rgba8(texture, rect, patch, 7)))
                    verify(!is_ok(update_texture_rgba8(texture, rect, patch, 2147483647)))
                    resize(patch, 19); verify(!is_ok(update_texture_rgba8(texture, rect, patch, 12)))
                    rect.x = 2147483647; verify(!is_ok(update_texture_rgba8(texture, rect, source, 16)))
                    var called = false
                    verify(!with_texture_surface(texture, full) $(locked : SDL_Surface?) {called = true
                        return sdl_ok()
                    } |> is_ok); verify(!called)

                    return sdl_ok()
                } |> is_ok
                verify(scoped)
                let streamed = with_texture(renderer, SDL_PixelFormat.PIXELFORMAT_RGBA32, SDL_TextureAccess.TEXTUREACCESS_STREAMING, 4, 4) $(texture : SDL_Texture?) {
                    var full = SDL_Rect(w = 4, h = 4)
                    unsafe {
                        var pixels : void?; var pitch : int
                        verify(SDL_LockTexture(texture, null, addr(pixels), addr(pitch)) && pixels != null && pitch >= 16)
                        var bytes = reinterpret<uint8?>(pixels)
                        for (y in 0 .. 4) {for (x in 0 .. 4) {let i = y * pitch + x * 4; bytes[i] = uint8(30); bytes[i + 1] = uint8(60); bytes[i + 2] = uint8(90); bytes[i + 3] = uint8(255)}}
                        SDL_UnlockTexture(texture)
                    }
                    var image : array<uint8>; snapshot(renderer, surface, texture, image)
                    for (i in 0 .. 16) {verify(image[i * 4] == uint8(30) && image[i * 4 + 2] == uint8(90))}
                    unsafe {
                        var locked : SDL_Surface?
                        verify(SDL_LockTextureToSurface(texture, addr(full), addr(locked)))
                        verify(SDL_FillSurfaceAll(locked, SDL_MapSurfaceRGBA(locked, 70u, 80u, 90u, 255u)))
                        SDL_UnlockTexture(texture)
                    }
                    snapshot(renderer, surface, texture, image)
                    for (i in 0 .. 16) {verify(image[i * 4] == uint8(70) && image[i * 4 + 1] == uint8(80))}
                    let locked = with_texture_surface(texture, full) $(mapped : SDL_Surface?) {
                        verify(SDL_FillSurfaceAll(mapped, SDL_MapSurfaceRGBA(mapped, 10u, 20u, 30u, 255u)))
                        return sdl_ok()
                    } |> is_ok
                    verify(locked)
                    snapshot(renderer, surface, texture, image)
                    for (i in 0 .. 16) {verify(image[i * 4] == uint8(10) && image[i * 4 + 1] == uint8(20))}
                    var invalid = full; invalid.w = 0; var called = false
                    verify(!with_texture_surface(texture, invalid) $(mapped : SDL_Surface?) {called = true
                        return sdl_ok()
                    } |> is_ok); verify(!called)
                    var region = SDL_Rect(x = 1, y = 1, w = 2, h = 2)
                    let partial = with_texture_surface(texture, region) $(mapped : SDL_Surface?) {
                        var size : int2; verify(is_ok(surface_size(mapped, size)) && size == int2(2, 2))
                        verify(SDL_FillSurfaceAll(mapped, SDL_MapSurfaceRGBA(mapped, 90u, 80u, 70u, 255u)))

                        return sdl_ok()
                    } |> is_ok
                    verify(partial)
                    snapshot(renderer, surface, texture, image)
                    for (y in 0 .. 4) {for (x in 0 .. 4) {
                        let inside = x >= 1 && x < 3 && y >= 1 && y < 3; let i = (y * 4 + x) * 4
                        verify(image[i] == uint8(inside ? 90 : 10) && image[i + 1] == uint8(inside ? 80 : 20))
                    }}
                    // Exercise another successful lock after early return and region updates.
                    let again = with_texture_surface(texture, full) $(mapped : SDL_Surface?) {verify(SDL_FillSurfaceAll(mapped, SDL_MapSurfaceRGBA(mapped, 1u, 2u, 3u, 255u)))
                        return sdl_ok()
                    } |> is_ok
                    verify(again)

                    return sdl_ok()
                } |> is_ok
                verify(streamed)

                return sdl_ok()
            } |> is_ok
            verify(created)

            return sdl_ok()
        } |> is_ok
        verify(allocated)

        return sdl_ok()
    } |> is_ok
    verify(initialized)
    var r, g, b, a : uint; var blend = 0u
    verify(!is_ok(texture_color_mod_bytes(null, r, g, b)) && r == uint(255) && g == uint(255) && b == uint(255))
    verify(!is_ok(texture_alpha_mod_byte(null, a)) && a == uint(255))
    verify(!is_ok(texture_blend_mode(null, blend)) && blend == SDL_BLENDMODE_INVALID)
    print("texture transfer: bytes, blending, updates and locks passed\n")
    return 0
}
