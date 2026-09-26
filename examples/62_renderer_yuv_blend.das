options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_renderer_yuv_blend_boost
def render_example(renderer : SDL_Renderer?; smoke : bool) : SdlStatus {
    var rendered=false
    return sdl_scope() {
        let texture : SDL_Texture? = with_texture(renderer,SDL_PixelFormat.PIXELFORMAT_IYUV,SDL_TextureAccess.TEXTUREACCESS_STATIC,32,32) |> sdl_use
        var y,u,v : array<uint8>;resize(y,1024);resize(u,256);resize(v,256)
        for(i in 0 .. 1024) {y[i]=uint8(((i%32)/8+i/256)%2==0 ? 81 : 180)}
        for(i in 0 .. 256) {u[i]=uint8(90);v[i]=uint8(240)}
        update_yuv_texture(texture,y,32,u,16,v,16) |> sdl_try
        if(!SDL_SetRenderDrawColorFloat(renderer,0.08,0.1,0.14,1.0) || !SDL_RenderClear(renderer)) {return err(sdl_error("62_renderer_yuv_blend"),type<SdlUnit>)}
        var dst = SDL_FRect(x = 60.0, y = 20.0, w = 200.0, h = 200.0)
        draw_texture(renderer,texture,dst) |> sdl_try
        rendered=SDL_RenderPresent(renderer)
        if(!rendered) {return err(sdl_error("62_renderer_yuv_blend"),type<SdlUnit>)}
        if(rendered && !smoke) {SDL_Delay(1200u)}

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let initialized=sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("Planar YUV texture",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = with_renderer(window) |> sdl_use
        return render_example(renderer, smoke)
    }
    if(is_err(initialized)) {print("YUV example failed: {unwrap_err(initialized).message}\n");return 1}
    return 0
}
