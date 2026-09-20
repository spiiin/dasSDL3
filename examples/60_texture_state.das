options gen2
require dassdl3/sdl3_texture_state_boost
def render_example(renderer : SDL_Renderer?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var rendered=false
    return with_texture(renderer,SDL_PixelFormat.PIXELFORMAT_RGBA32,SDL_TextureAccess.TEXTUREACCESS_STREAMING,2,2) $(texture : SDL_Texture?) {
        var bytes : array<uint8>;resize(bytes,16)
        for(i in 0 .. 4) {
            let value=uint8(i==0 || i==3 ? 255 : 100)
            bytes[i*4]=value;bytes[i*4+1]=value;bytes[i*4+2]=value;bytes[i*4+3]=uint8(255)
        }
        if(!is_ok(upload_rgba8(texture,bytes,8)) || !SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST)) {return err(sdl_error("60_texture_state"),type<SdlUnit>)}
        if(!SDL_SetTextureColorModFloat(texture,0.3,0.8,1.0) || !SDL_SetTextureAlphaModFloat(texture,0.8)) {return err(sdl_error("60_texture_state"),type<SdlUnit>)}
        if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("60_texture_state"),type<SdlUnit>)}
        var rect : SDL_FRect;rect.x=60.0;rect.y=20.0;rect.w=200.0;rect.h=200.0
        rendered=is_ok(draw_texture(renderer,texture,rect)) && SDL_RenderPresent(renderer)
        if(!rendered) {return err(sdl_error("60_texture_state"),type<SdlUnit>)}
        if(rendered && !smoke) {SDL_Delay(1200u)}

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        return with_window("Texture modulation",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?) {
            return with_renderer(window) $(renderer : SDL_Renderer?) {
                return render_example(renderer, smoke)
            }
        }
    }
    if(is_err(initialized)) {print("Texture example failed: {unwrap_err(initialized).message}\n");return 1}
    return 0
}
