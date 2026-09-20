options gen2
require dassdl3/sdl3_renderer_yuv_blend_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let opened=with_window("Planar YUV texture",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window) {
            let created=with_renderer(window) $(renderer) {
                let scoped=with_texture(renderer,SDL_PixelFormat.PIXELFORMAT_IYUV,SDL_TextureAccess.TEXTUREACCESS_STATIC,32,32) $(texture) {
                    var y,u,v : array<uint8>;resize(y,1024);resize(u,256);resize(v,256)
                    for(i in 0 .. 1024) {y[i]=uint8(((i%32)/8+i/256)%2==0 ? 81 : 180)}
                    for(i in 0 .. 256) {u[i]=uint8(90);v[i]=uint8(240)}
                    if(!update_yuv_texture(texture,y,32,u,16,v,16)) {return}
                    if(!SDL_SetRenderDrawColorFloat(renderer,0.08,0.1,0.14,1.0) || !SDL_RenderClear(renderer)) {return}
                    var dst : SDL_FRect;dst.x=60.0;dst.y=20.0;dst.w=200.0;dst.h=200.0
                    rendered=draw_texture(renderer,texture,dst) && SDL_RenderPresent(renderer)
                    if(rendered && !smoke) {SDL_Delay(1200u)}
                }
                if(!scoped) {rendered=false}
            }
            if(!created) {rendered=false}
        }
        if(!opened) {rendered=false}
    }
    if(!initialized || !rendered) {print("YUV example failed: {SDL_GetError()}\n");return 1}
    return 0
}
