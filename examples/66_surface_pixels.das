options gen2
require daslib/defer
require dassdl3/sdl3_surface_pixels_boost
require dassdl3/sdl3_renderer_operations_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let window_ok=with_window_renderer("SDL Surface and Pixels",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window,renderer) {
            let src_ok=with_surface(4,4,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(source) {
                for(y in 0 .. 4) {for(x in 0 .. 4) {if(!SDL_WriteSurfacePixel(source,x,y,uint(x*80),uint(y*80),180u,255u)) {return}}}
                let dst_ok=with_surface(32,24,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(dest) {
                    var sr,dr : SDL_Rect;sr.w=4;sr.h=4;dr.w=32;dr.h=24
                    if(!SDL_ClearSurface(dest,0.0,0.0,0.0,1.0) || !SDL_BlitSurfaceTiledWithScaleRefs(source,sr,2.0,SDL_ScaleMode.SCALEMODE_NEAREST,dest,dr)) {return}
                    let texture=SDL_CreateTextureFromSurface(renderer,dest)
                    if(texture==null) {return}
                    {
                        defer(){SDL_DestroyTexture(texture)}
                        if(!SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST) || !draw_texture(renderer,texture)) {return}
                        rendered=SDL_RenderPresent(renderer)
                        if(rendered && !smoke) {SDL_Delay(1200u)}
                    }
                }
                if(!dst_ok) {rendered=false}
            }
            if(!src_ok) {rendered=false}
        }
        if(!window_ok) {rendered=false}
    }
    if(!initialized || !rendered) {print("Surface/Pixels failed: {SDL_GetError()}\n");return 1}
    return 0
}
