options gen2
require dassdl3/sdl3_scope
require daslib/defer
require dassdl3/sdl3_surface_pixels_boost
require dassdl3/sdl3_renderer_operations_boost
def render_example(renderer : SDL_Renderer?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var rendered=false
    return sdl_scope() {
        let source : SDL_Surface? = with_surface(4,4,SDL_PixelFormat.PIXELFORMAT_RGBA32) |> sdl_use
        for(y in 0 .. 4) {for(x in 0 .. 4) {if(!SDL_WriteSurfacePixel(source,x,y,uint(x*80),uint(y*80),180u,255u)) {return err(sdl_error("66_surface_pixels"),type<SdlUnit>)}}}
        let dest : SDL_Surface? = with_surface(32,24,SDL_PixelFormat.PIXELFORMAT_RGBA32) |> sdl_use
        let sr = SDL_Rect(w=4,h=4)
        let dr = SDL_Rect(w=32,h=24)
        if(!SDL_ClearSurface(dest,0.0,0.0,0.0,1.0) || !SDL_BlitSurfaceTiledWithScaleRefs(source,sr,2.0,SDL_ScaleMode.SCALEMODE_NEAREST,dest,dr)) {return err(sdl_error("66_surface_pixels"),type<SdlUnit>)}
        let texture=SDL_CreateTextureFromSurface(renderer,dest)
        if(texture==null) {return err(sdl_error("66_surface_pixels"),type<SdlUnit>)}
        {
            defer(){SDL_DestroyTexture(texture)}
            if(!SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST)) {return err(sdl_error("66_surface_pixels"),type<SdlUnit>)}
            draw_texture(renderer,texture) |> sdl_try
            rendered=SDL_RenderPresent(renderer)
            if(!rendered) {return err(sdl_error("66_surface_pixels"),type<SdlUnit>)}
            if(rendered && !smoke) {SDL_Delay(1200u)}
        }

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let initialized=sdl_scope() {
        with_sdl() |> sdl_use
        return with_window_renderer("SDL Surface and Pixels",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?; renderer : SDL_Renderer?) {
            return render_example(renderer, smoke)
        }
    }
    if(is_err(initialized)) {print("Surface/Pixels failed: {unwrap_err(initialized).message}\n");return 1}
    return 0
}
