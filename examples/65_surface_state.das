options gen2
require daslib/defer
require dassdl3/sdl3_surface_state_boost
require dassdl3/sdl3_renderer_operations_boost
def render_example(renderer : SDL_Renderer?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var rendered=false
    return with_surface(8,8,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface : SDL_Surface?) {
        let key=SDL_MapSurfaceRGBA(surface,255u,0u,255u,255u)
        if(!SDL_FillSurfaceAll(surface,key)) {return err(sdl_error("65_surface_state"),type<SdlUnit>)}
        var rect : SDL_Rect;rect.x=2;rect.y=2;rect.w=4;rect.h=4
        if(!unwrap_or(set_surface_clip(surface,rect), false) || !SDL_FillSurfaceAll(surface,SDL_MapSurfaceRGBA(surface,255u,255u,255u,255u)) || !unwrap_or(reset_surface_clip(surface), false)) {return err(sdl_error("65_surface_state"),type<SdlUnit>)}
        if(!SDL_SetSurfaceColorKey(surface,true,key) || !SDL_SetSurfaceColorMod(surface,255u,160u,40u) || !SDL_SetSurfaceAlphaMod(surface,200u) || !SDL_SetSurfaceBlendMode(surface,SDL_BLENDMODE_BLEND)) {return err(sdl_error("65_surface_state"),type<SdlUnit>)}
        let texture=SDL_CreateTextureFromSurface(renderer,surface)
        if(texture==null) {return err(sdl_error("65_surface_state"),type<SdlUnit>)}
        {
            defer(){SDL_DestroyTexture(texture)}
            if(!SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST)) {return err(sdl_error("65_surface_state"),type<SdlUnit>)}
            if(!SDL_SetRenderDrawColor(renderer,25u,35u,55u,255u) || !SDL_RenderClear(renderer) || !is_ok(draw_texture(renderer,texture))) {return err(sdl_error("65_surface_state"),type<SdlUnit>)}
            rendered=SDL_RenderPresent(renderer)
            if(!rendered) {return err(sdl_error("65_surface_state"),type<SdlUnit>)}
            if(rendered && !smoke) {SDL_Delay(1200u)}
        }

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        return with_window_renderer("Surface color key and modulation",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?; renderer : SDL_Renderer?) {
            return render_example(renderer, smoke)
        }
    }
    if(is_err(initialized)) {print("Surface state failed: {unwrap_err(initialized).message}\n");return 1}
    return 0
}
