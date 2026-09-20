options gen2
require daslib/defer
require dassdl3/sdl3_surface_pixels_boost
require dassdl3/sdl3_renderer_operations_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let window_ok=with_window_renderer("SDL Surface and Pixels",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?; renderer : SDL_Renderer?) {
            let src_ok=with_surface(4,4,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(source : SDL_Surface?) {
                for(y in 0 .. 4) {for(x in 0 .. 4) {if(!SDL_WriteSurfacePixel(source,x,y,uint(x*80),uint(y*80),180u,255u)) {return err(sdl_error("66_surface_pixels"),type<SdlUnit>)}}}
                let dst_ok=with_surface(32,24,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(dest : SDL_Surface?) {
                    var sr,dr : SDL_Rect;sr.w=4;sr.h=4;dr.w=32;dr.h=24
                    if(!SDL_ClearSurface(dest,0.0,0.0,0.0,1.0) || !SDL_BlitSurfaceTiledWithScaleRefs(source,sr,2.0,SDL_ScaleMode.SCALEMODE_NEAREST,dest,dr)) {return err(sdl_error("66_surface_pixels"),type<SdlUnit>)}
                    let texture=SDL_CreateTextureFromSurface(renderer,dest)
                    if(texture==null) {return err(sdl_error("66_surface_pixels"),type<SdlUnit>)}
                    {
                        defer(){SDL_DestroyTexture(texture)}
                        if(!SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST) || !is_ok(draw_texture(renderer,texture))) {return err(sdl_error("66_surface_pixels"),type<SdlUnit>)}
                        rendered=SDL_RenderPresent(renderer)
                        if(!rendered) {return err(sdl_error("66_surface_pixels"),type<SdlUnit>)}
                        if(rendered && !smoke) {SDL_Delay(1200u)}
                    }

                    return sdl_ok()
                }
                if (is_err(dst_ok)) {rendered=false; return err(unwrap_err(dst_ok),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(src_ok)) {rendered=false; return err(unwrap_err(src_ok),type<SdlUnit>) }

            return sdl_ok()
        }
        if (is_err(window_ok)) {rendered=false; return err(unwrap_err(window_ok),type<SdlUnit>) }

        return sdl_ok()
    }
    if(!is_ok(initialized) || !rendered) {print("Surface/Pixels failed: {is_err(initialized) ? unwrap_err(initialized).message : SDL_GetErrorCopy()}\n");return 1}
    return 0
}
