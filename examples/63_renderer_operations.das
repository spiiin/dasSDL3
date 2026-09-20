options gen2
require dassdl3/sdl3_renderer_operations_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let created=with_window_renderer("Rotated texture",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window,renderer) {
            let scoped=with_texture(renderer,SDL_PixelFormat.PIXELFORMAT_RGBA32,SDL_TextureAccess.TEXTUREACCESS_STREAMING,4,4) $(texture) {
                var bytes : array<uint8>;resize(bytes,64)
                for(y in 0 .. 4) {for(x in 0 .. 4) {let i=(y*4+x)*4;bytes[i]=uint8(x<2 ? 230 : 40);bytes[i+1]=uint8(100);bytes[i+2]=uint8(x<2 ? 40 : 230);bytes[i+3]=uint8(255)}}
                if(!upload_rgba8(texture,bytes,16) || !SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST)) {return}
                if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return}
                var src,dst : SDL_FRect;src.w=4.0;src.h=4.0;dst.x=100.0;dst.y=60.0;dst.w=120.0;dst.h=120.0
                var center : SDL_FPoint;center.x=60.0;center.y=60.0
                if(!SDL_RenderTextureRotatedRefs(renderer,texture,src,dst,double(30),center,SDL_FlipMode.FLIP_NONE)) {return}
                if(!SDL_SetRenderDrawColor(renderer,255u,255u,255u,255u) || !SDL_RenderDebugText(renderer,8.0,8.0,"SDL rotated texture")) {return}
                rendered=SDL_RenderPresent(renderer)
                if(rendered && !smoke) {SDL_Delay(1200u)}
            }
            if(!scoped) {rendered=false}
        }
        if(!created) {rendered=false}
    }
    if(!initialized || !rendered) {print("Renderer operations failed: {SDL_GetError()}\n");return 1}
    return 0
}
