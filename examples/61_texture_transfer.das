options gen2
require dassdl3/sdl3_texture_transfer_boost
def render_example(renderer : SDL_Renderer?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var rendered=false
    return with_texture(renderer,SDL_PixelFormat.PIXELFORMAT_RGBA32,SDL_TextureAccess.TEXTUREACCESS_STREAMING,32,32) $(texture : SDL_Texture?) {
        var full : SDL_Rect;full.w=32;full.h=32
        var filled=false
        let locked=with_texture_surface(texture,full) $(surface : SDL_Surface?) {
            if(!SDL_FillSurfaceAll(surface,SDL_MapSurfaceRGBA(surface,240u,240u,240u,255u))) {return err(sdl_error("61_texture_transfer"),type<SdlUnit>)}
            var inset : SDL_Rect;inset.x=8;inset.y=8;inset.w=16;inset.h=16
            filled=SDL_FillSurfaceRectRef(surface,inset,SDL_MapSurfaceRGBA(surface,40u,100u,220u,255u))
            if(!filled) {return err(sdl_error("SDL_FillSurfaceRect"),type<SdlUnit>)}

            return sdl_ok()
        }
        if(is_err(locked)) {return err(unwrap_err(locked),type<SdlUnit>)}
        if(!SDL_SetTextureBlendMode(texture,SDL_BLENDMODE_BLEND) || !SDL_SetTextureAlphaMod(texture,200u)) {return err(sdl_error("61_texture_transfer"),type<SdlUnit>)}
        if(!SDL_SetTextureColorMod(texture,180u,255u,255u) || !SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST)) {return err(sdl_error("61_texture_transfer"),type<SdlUnit>)}
        if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return err(sdl_error("61_texture_transfer"),type<SdlUnit>)}
        var dst : SDL_FRect;dst.x=60.0;dst.y=20.0;dst.w=200.0;dst.h=200.0
        rendered=is_ok(draw_texture(renderer,texture,dst)) && SDL_RenderPresent(renderer)
        if(!rendered) {return err(sdl_error("61_texture_transfer"),type<SdlUnit>)}
        if(rendered && !smoke) {SDL_Delay(1200u)}

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        return with_window("Texture surface lock",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?) {
            return with_renderer(window) $(renderer : SDL_Renderer?) {
                return render_example(renderer, smoke)
            }
        }
    }
    if(is_err(initialized)) {print("Texture transfer failed: {unwrap_err(initialized).message}\n");return 1}
    return 0
}
