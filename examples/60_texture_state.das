options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_texture_state_boost
def render_example(renderer : SDL_Renderer?; smoke : bool) : SdlStatus {
    var rendered = false
    return sdl_scope() {
        let texture : SDL_Texture? = with_texture(renderer, SDL_PixelFormat.PIXELFORMAT_RGBA32, SDL_TextureAccess.TEXTUREACCESS_STREAMING, 2, 2) |> sdl_use
        var bytes : array<uint8>; resize(bytes, 16)
        for (i in 0 .. 4) {
            let value = uint8(i == 0 || i == 3 ? 255 : 100)
            bytes[i * 4] = value; bytes[i * 4 + 1] = value; bytes[i * 4 + 2] = value; bytes[i * 4 + 3] = uint8(255)
        }
        upload_rgba8(texture, bytes, 8) |> sdl_try
        if (!SDL_SetTextureScaleMode(texture, SDL_ScaleMode.SCALEMODE_NEAREST)) {return err(sdl_error("60_texture_state"), type<SdlUnit>)}
        if (!SDL_SetTextureColorModFloat(texture, 0.3, 0.8, 1.0) || !SDL_SetTextureAlphaModFloat(texture, 0.8)) {return err(sdl_error("60_texture_state"), type<SdlUnit>)}
        if (!SDL_SetRenderDrawColor(renderer, 20u, 25u, 35u, 255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("60_texture_state"), type<SdlUnit>)}
        var rect = SDL_FRect(x = 60.0, y = 20.0, w = 200.0, h = 200.0)
        draw_texture(renderer, texture, rect) |> sdl_try
        rendered = SDL_RenderPresent(renderer)
        if (!rendered) {return err(sdl_error("60_texture_state"), type<SdlUnit>)}
        if (rendered && !smoke) {SDL_Delay(1200u)}

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let initialized = sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("Texture modulation", 320, 240, smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = with_renderer(window) |> sdl_use
        return render_example(renderer, smoke)
    }
    if (is_err(initialized)) {print("Texture example failed: {unwrap_err(initialized).message}\n"); return 1}
    return 0
}
