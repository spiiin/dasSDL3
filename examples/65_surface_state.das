options gen2
require daslib/defer
require dassdl3/sdl3_surface_state_boost
require dassdl3/sdl3_renderer_operations_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let created=with_window_renderer("Surface color key and modulation",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window,renderer) {
            let allocated=with_surface(8,8,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface) {
                let key=SDL_MapSurfaceRGBA(surface,255u,0u,255u,255u)
                if(!SDL_FillSurfaceAll(surface,key)) {return}
                var rect : SDL_Rect;rect.x=2;rect.y=2;rect.w=4;rect.h=4
                if(!set_surface_clip(surface,rect) || !SDL_FillSurfaceAll(surface,SDL_MapSurfaceRGBA(surface,255u,255u,255u,255u)) || !reset_surface_clip(surface)) {return}
                if(!SDL_SetSurfaceColorKey(surface,true,key) || !SDL_SetSurfaceColorMod(surface,255u,160u,40u) || !SDL_SetSurfaceAlphaMod(surface,200u) || !SDL_SetSurfaceBlendMode(surface,SDL_BLENDMODE_BLEND)) {return}
                let texture=SDL_CreateTextureFromSurface(renderer,surface)
                if(texture==null) {return}
                {
                    defer(){SDL_DestroyTexture(texture)}
                    if(!SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST)) {return}
                    if(!SDL_SetRenderDrawColor(renderer,25u,35u,55u,255u) || !SDL_RenderClear(renderer) || !draw_texture(renderer,texture)) {return}
                    rendered=SDL_RenderPresent(renderer)
                    if(rendered && !smoke) {SDL_Delay(1200u)}
                }
            }
            if(!allocated) {rendered=false}
        }
        if(!created) {rendered=false}
    }
    if(!initialized || !rendered) {print("Surface state failed: {SDL_GetError()}\n");return 1}
    return 0
}
