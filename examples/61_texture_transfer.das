options gen2
require dassdl3/sdl3_texture_transfer_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let opened=with_window("Texture surface lock",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?) {
            let created=with_renderer(window) $(renderer : SDL_Renderer?) {
                let scoped=with_texture(renderer,SDL_PixelFormat.PIXELFORMAT_RGBA32,SDL_TextureAccess.TEXTUREACCESS_STREAMING,32,32) $(texture : SDL_Texture?) {
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
                if (is_err(scoped)) {rendered=false; return err(unwrap_err(scoped),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(created)) {rendered=false; return err(unwrap_err(created),type<SdlUnit>) }

            return sdl_ok()
        }
        if (is_err(opened)) {rendered=false; return err(unwrap_err(opened),type<SdlUnit>) }

        return sdl_ok()
    }
    if(!is_ok(initialized) || !rendered) {print("Texture transfer failed: {is_err(initialized) ? unwrap_err(initialized).message : SDL_GetErrorCopy()}\n");return 1}
    return 0
}
