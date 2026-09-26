options gen2
require math
require dassdl3/sdl3_texture_state_boost

def check_image(renderer : SDL_Renderer?; surface : SDL_Surface?; texture : SDL_Texture?; r, g, b : int) {
    verify(SDL_SetRenderDrawColor(renderer, 0u, 0u, 0u, 255u) && SDL_RenderClear(renderer))
    verify(is_ok(draw_texture(renderer, texture)) && SDL_FlushRenderer(renderer))
    var bytes : array<uint8>; resize(bytes, 16 * 16 * 4)
    verify(is_ok(copy_surface_rgba8(surface, bytes, 16 * 4)))
    for (i in 0 .. 256) {
        verify(abs(int(bytes[i * 4]) - r) <= 2 && abs(int(bytes[i * 4 + 1]) - g) <= 2 && abs(int(bytes[i * 4 + 2]) - b) <= 2)
    }
}
[export]
def main(smoke : bool) : int {
    let initialized = with_sdl() {
        let allocated = with_surface(16, 16, SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface : SDL_Surface?) {
            let created = with_software_renderer(surface) $(renderer : SDL_Renderer?) {
                let streamed = with_texture(renderer, SDL_PixelFormat.PIXELFORMAT_RGBA32, SDL_TextureAccess.TEXTUREACCESS_STREAMING, 1, 1) $(texture : SDL_Texture?) {
                    verify(SDL_GetRendererFromTexture(texture) == renderer)
                    let props = SDL_GetTextureProperties(texture)
                    verify(props != 0u && SDL_GetNumberProperty(props, "SDL.texture.width", 0l) == 1l)
                    verify(SDL_GetNumberProperty(props, "SDL.texture.access", -1l) == int64(SDL_TextureAccess.TEXTUREACCESS_STREAMING))
                    var bytes : array<uint8>; resize(bytes, 4)
                    for (i in 0 .. 4) {bytes[i] = uint8(255)}
                    verify(is_ok(upload_rgba8(texture, bytes, 4)))
                    verify(SDL_SetTextureColorModFloat(texture, 1.0, 0.5, 0.25))
                    verify(SDL_SetTextureAlphaModFloat(texture, 1.0))
                    var r, g, b, a : float; var mode = SDL_ScaleMode.SCALEMODE_INVALID
                    unsafe {
                        verify(SDL_GetTextureColorModFloat(texture, addr(r), addr(g), addr(b)) && r == 1.0 && g == 0.5 && b == 0.25)
                        verify(SDL_GetTextureAlphaModFloat(texture, addr(a)) && a == 1.0)
                    }
                    verify(is_ok(texture_color_mod(texture, r, g, b)) && r == 1.0 && g == 0.5 && b == 0.25)
                    verify(SDL_SetTextureScaleMode(texture, SDL_ScaleMode.SCALEMODE_NEAREST))
                    unsafe {verify(SDL_GetTextureScaleMode(texture, addr(mode)) && mode == SDL_ScaleMode.SCALEMODE_NEAREST)}
                    check_image(renderer, surface, texture, 255, 127, 63)
                    verify(SDL_SetTextureAlphaModFloat(texture, 0.5) && is_ok(texture_alpha_mod(texture, a)) && a == 0.5)
                    check_image(renderer, surface, texture, 127, 63, 31)
                    verify(SDL_SetTextureScaleMode(texture, SDL_ScaleMode.SCALEMODE_LINEAR))
                    verify(is_ok(texture_scale_mode(texture, mode)) && mode == SDL_ScaleMode.SCALEMODE_LINEAR)
                    check_image(renderer, surface, texture, 127, 63, 31)
                    verify(!SDL_SetTextureScaleMode(texture, SDL_ScaleMode.SCALEMODE_INVALID))

                    return sdl_ok()
                } |> is_ok
                verify(streamed)
                // All creation access modes, without reading uninitialized texture content.
                let static_texture = SDL_CreateTexture(renderer, SDL_PixelFormat.PIXELFORMAT_RGBA32, SDL_TextureAccess.TEXTUREACCESS_STATIC, 3, 2)
                verify(static_texture != null && SDL_GetRendererFromTexture(static_texture) == renderer)
                SDL_DestroyTexture(static_texture)
                let target = with_texture(renderer, SDL_PixelFormat.PIXELFORMAT_RGBA32, SDL_TextureAccess.TEXTUREACCESS_TARGET, 4, 5) $(texture : SDL_Texture?) {
                    let selected = with_render_target(renderer, texture) {
                        var w, h : int
                        verify(is_ok(current_render_output_size(renderer, w, h)) && w == 4 && h == 5)

                        return sdl_ok()
                    } |> is_ok
                    verify(selected)

                    return sdl_ok()
                } |> is_ok
                verify(target)
                let properties = with_properties() $(props : uint) {
                    verify(SDL_SetNumberProperty(props, "SDL.texture.create.format", int64(SDL_PixelFormat.PIXELFORMAT_RGBA32)))
                    verify(SDL_SetNumberProperty(props, "SDL.texture.create.access", int64(SDL_TextureAccess.TEXTUREACCESS_STREAMING)))
                    verify(SDL_SetNumberProperty(props, "SDL.texture.create.width", 2l) && SDL_SetNumberProperty(props, "SDL.texture.create.height", 3l))
                    let raw = SDL_CreateTextureWithProperties(renderer, props)
                    verify(raw != null)
                    var size : float2; verify(is_ok(texture_size(raw, size)) && size == float2(2.0, 3.0))
                    SDL_DestroyTexture(raw)
                    let scoped = with_texture_properties(renderer, props) $(texture : SDL_Texture?) {
                        verify(SDL_GetTextureProperties(texture) != props)
                        verify(is_ok(texture_size(texture, size)) && size == float2(2.0, 3.0))
                        return sdl_ok()
                    } |> is_ok
                    verify(scoped && SDL_GetNumberProperty(props, "SDL.texture.create.width", 0l) == 2l)

                    return sdl_ok()
                } |> is_ok
                verify(properties)
                var called = false
                verify(!with_texture(renderer, SDL_PixelFormat.PIXELFORMAT_RGBA32, SDL_TextureAccess.TEXTUREACCESS_STATIC, 0, 2) $(texture : SDL_Texture?) {called = true
                    return sdl_ok()
                } |> is_ok)
                verify(!called)
                verify(!with_texture_properties(null, 0u) $(texture : SDL_Texture?) {called = true
                    return sdl_ok()
                } |> is_ok)
                verify(!called)

                return sdl_ok()
            } |> is_ok
            verify(created)

            return sdl_ok()
        } |> is_ok
        verify(allocated)

        return sdl_ok()
    } |> is_ok
    verify(initialized)
    var r = 9.0; var g = 9.0; var b = 9.0; var a = 9.0; var mode = SDL_ScaleMode.SCALEMODE_INVALID
    verify(!is_ok(texture_color_mod(null, r, g, b)) && r == 1.0 && g == 1.0 && b == 1.0)
    verify(!is_ok(texture_alpha_mod(null, a)) && a == 1.0)
    verify(!is_ok(texture_scale_mode(null, mode)) && mode == SDL_ScaleMode.SCALEMODE_INVALID)
    verify(SDL_GetRendererFromTexture(null) == null && SDL_GetTextureProperties(null) == 0u)
    print("texture state: creation, modulation pixels and ownership passed\n")
    return 0
}
