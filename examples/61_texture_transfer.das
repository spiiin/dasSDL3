options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_pixel_views
def render_example(renderer : SDL_Renderer?; smoke : bool) : SdlStatus {
    var rendered=false
    return sdl_scope() {
        let texture : SDL_Texture? = with_texture(renderer,SDL_PixelFormat.PIXELFORMAT_RGBA32,SDL_TextureAccess.TEXTUREACCESS_STREAMING,32,32) |> sdl_use
        var full = SDL_Rect(w = 32, h = 32)
        with_texture_pixels_rgba8(texture,full) $(pixels) {
            for(y in 0 .. pixels.height) {
                pixels |> with_row(y) $(var row : array<uint>#) {
                    for(x in 0 .. length(row)) {
                        row[x]=rgba8(uint(x*8),uint(y*8),180u,255u)
                    }
                    return sdl_ok()
                } |> sdl_try
            }
            return sdl_ok()
        } |> sdl_try
        if(!SDL_SetTextureBlendMode(texture,SDL_BLENDMODE_BLEND) || !SDL_SetTextureAlphaMod(texture,200u)) {return err(sdl_error("61_texture_transfer"),type<SdlUnit>)}
        if(!SDL_SetTextureColorMod(texture,180u,255u,255u) || !SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST)) {return err(sdl_error("61_texture_transfer"),type<SdlUnit>)}
        if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("61_texture_transfer"),type<SdlUnit>)}
        var dst = SDL_FRect(x = 60.0, y = 20.0, w = 200.0, h = 200.0)
        draw_texture(renderer,texture,dst) |> sdl_try
        rendered=SDL_RenderPresent(renderer)
        if(!rendered) {return err(sdl_error("61_texture_transfer"),type<SdlUnit>)}
        if(rendered && !smoke) {SDL_Delay(1200u)}

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let initialized=sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window(WindowOptions(title="Texture pixel view",size=int2(320,240),flags=smoke ? SDL_WINDOW_HIDDEN : 0ul)) |> sdl_use
        let renderer : SDL_Renderer? = with_renderer(window) |> sdl_use
        return render_example(renderer, smoke)
    }
    if(is_err(initialized)) {print("Texture transfer failed: {unwrap_err(initialized).message}\n");return 1}
    return 0
}
