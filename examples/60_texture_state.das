options gen2
require dassdl3/sdl3_texture_state_boost
[export]
def main(smoke : bool) : int {
    var rendered=false
    let initialized=with_sdl() {
        let opened=with_window("Texture modulation",320,240,smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window) {
            let created=with_renderer(window) $(renderer) {
                let scoped=with_texture(renderer,SDL_PixelFormat.PIXELFORMAT_RGBA32,SDL_TextureAccess.TEXTUREACCESS_STREAMING,2,2) $(texture) {
                    var bytes : array<uint8>;resize(bytes,16)
                    for(i in 0 .. 4) {
                        let value=uint8(i==0 || i==3 ? 255 : 100)
                        bytes[i*4]=value;bytes[i*4+1]=value;bytes[i*4+2]=value;bytes[i*4+3]=uint8(255)
                    }
                    if(!upload_rgba8(texture,bytes,8) || !SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST)) {return}
                    if(!SDL_SetTextureColorModFloat(texture,0.3,0.8,1.0) || !SDL_SetTextureAlphaModFloat(texture,0.8)) {return}
                    if(!SDL_SetRenderDrawColor(renderer,20u,25u,35u,255u) || !SDL_RenderClear(renderer)) {return}
                    var rect : SDL_FRect;rect.x=60.0;rect.y=20.0;rect.w=200.0;rect.h=200.0
                    rendered=draw_texture(renderer,texture,rect) && SDL_RenderPresent(renderer)
                    if(rendered && !smoke) {SDL_Delay(1200u)}
                }
                if(!scoped) {rendered=false}
            }
            if(!created) {rendered=false}
        }
        if(!opened) {rendered=false}
    }
    if(!initialized || !rendered) {print("Texture example failed: {SDL_GetError()}\n");return 1}
    return 0
}
