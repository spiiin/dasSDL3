options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_renderer_operations_boost
def render_example(renderer : SDL_Renderer?; smoke : bool) : SdlStatus {
    var rendered = false
    return sdl_scope() {
        let texture : SDL_Texture? = with_texture(renderer, SDL_PixelFormat.PIXELFORMAT_RGBA32, SDL_TextureAccess.TEXTUREACCESS_STREAMING, 4, 4) |> sdl_use
        var bytes : array<uint8>; resize(bytes, 64)
        for (y in 0 .. 4) {for (x in 0 .. 4) {let i = (y * 4 + x) * 4; bytes[i] = uint8(x < 2 ? 230 : 40); bytes[i + 1] = uint8(100); bytes[i + 2] = uint8(x < 2 ? 40 : 230); bytes[i + 3] = uint8(255)}}
        upload_rgba8(texture, bytes, 16) |> sdl_try
        if (!SDL_SetTextureScaleMode(texture, SDL_ScaleMode.SCALEMODE_NEAREST)) {return err(sdl_error("63_renderer_operations"), type<SdlUnit>)}
        if (!SDL_SetRenderDrawColor(renderer, 20u, 25u, 35u, 255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("63_renderer_operations"), type<SdlUnit>)}
        let src = SDL_FRect(w = 4.0, h = 4.0)
        let dst = SDL_FRect(x = 100.0, y = 60.0, w = 120.0, h = 120.0)
        var center = SDL_FPoint(x = 60.0, y = 60.0)
        if (!SDL_RenderTextureRotatedRefs(renderer, texture, src, dst, double(30), center, SDL_FlipMode.FLIP_NONE)) {return err(sdl_error("63_renderer_operations"), type<SdlUnit>)}
        if (!SDL_SetRenderDrawColor(renderer, 255u, 255u, 255u, 255u) || !SDL_RenderDebugText(renderer, 8.0, 8.0, "SDL rotated texture")) {return err(sdl_error("63_renderer_operations"), type<SdlUnit>)}
        rendered = SDL_RenderPresent(renderer)
        if (!rendered) {return err(sdl_error("63_renderer_operations"), type<SdlUnit>)}
        if (rendered && !smoke) {SDL_Delay(1200u)}

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let initialized = sdl_scope() {
        with_sdl() |> sdl_use
        return with_window_renderer("Rotated texture", 320, 240, smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?; renderer : SDL_Renderer?) {
            return render_example(renderer, smoke)
        }
    }
    if (is_err(initialized)) {print("Renderer operations failed: {unwrap_err(initialized).message}\n"); return 1}
    return 0
}
