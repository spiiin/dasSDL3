options gen2
require dassdl3/sdl3_renderer_yuv_blend_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let opened=with_window("Planar YUV texture",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?) {
            let created=with_renderer(window) $(renderer : SDL_Renderer?) {
                let scoped=with_texture(renderer,SDL_PixelFormat.PIXELFORMAT_IYUV,SDL_TextureAccess.TEXTUREACCESS_STATIC,32,32) $(texture : SDL_Texture?) {
                    var y,u,v : array<uint8>;resize(y,1024);resize(u,256);resize(v,256)
                    for(i in 0 .. 1024) {y[i]=uint8(((i%32)/8+i/256)%2==0 ? 81 : 180)}
                    for(i in 0 .. 256) {u[i]=uint8(90);v[i]=uint8(240)}
                    var operation_result_1 <- update_yuv_texture(texture,y,32,u,16,v,16)
                    if (is_err(operation_result_1)) {return err(unwrap_err(operation_result_1),type<SdlUnit>)}
                    if(!SDL_SetRenderDrawColorFloat(renderer,0.08,0.1,0.14,1.0) || !SDL_RenderClear(renderer)) {return err(sdl_error("62_renderer_yuv_blend"),type<SdlUnit>)}
                    var dst : SDL_FRect;dst.x=60.0;dst.y=20.0;dst.w=200.0;dst.h=200.0
                    rendered=is_ok(draw_texture(renderer,texture,dst)) && SDL_RenderPresent(renderer)
                    if(!rendered) {return err(sdl_error("62_renderer_yuv_blend"),type<SdlUnit>)}
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
    if(!is_ok(initialized) || !rendered) {print("YUV example failed: {is_err(initialized) ? unwrap_err(initialized).message : SDL_GetErrorCopy()}\n");return 1}
    return 0
}
