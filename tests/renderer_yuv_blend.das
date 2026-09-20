options gen2
require math
require dassdl3/sdl3_renderer_yuv_blend_boost

def expect_rgb(renderer : SDL_Renderer?; surface : SDL_Surface?; texture : SDL_Texture?; r,g,b : int) {
    verify(SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST))
    verify(SDL_SetRenderDrawColor(renderer,0u,0u,0u,255u) && SDL_RenderClear(renderer))
    verify(is_ok(draw_texture(renderer,texture)) && SDL_FlushRenderer(renderer))
    var bytes : array<uint8>;resize(bytes,5*3*4)
    verify(is_ok(copy_surface_rgba8(surface,bytes,20)))
    for(i in 0 .. 15) {verify(abs(int(bytes[i*4])-r)<=4 && abs(int(bytes[i*4+1])-g)<=4 && abs(int(bytes[i*4+2])-b)<=4)}
}
def planes(renderer : SDL_Renderer?; surface : SDL_Surface?; format : SDL_PixelFormat; nv,vu : bool) {
    let created=with_texture(renderer,format,SDL_TextureAccess.TEXTUREACCESS_STATIC,5,3) $(texture : SDL_Texture?) {
        var y,u,v,uv : array<uint8>;resize(y,19);resize(u,7);resize(v,7);resize(uv,14)
        for(i in 0 .. length(y)) {y[i]=uint8(0)}
        for(i in 0 .. length(u)) {u[i]=uint8(128);v[i]=uint8(128)}
        for(i in 0 .. length(uv)) {uv[i]=uint8(128)}
        unsafe {
            if(nv) {verify(SDL_UpdateNVTexture(texture,null,addr(y[0]),7,addr(uv[0]),8))}
            else {verify(SDL_UpdateYUVTexture(texture,null,addr(y[0]),7,addr(u[0]),4,addr(v[0]),4))}
        }
        expect_rgb(renderer,surface,texture,0,0,0)
        for(i in 0 .. length(y)) {y[i]=uint8(255)}
        if(nv) {verify(is_ok(update_nv_texture(texture,y,7,uv,8)))}
        else {verify(is_ok(update_yuv_texture(texture,y,7,u,4,v,4)))}
        expect_rgb(renderer,surface,texture,255,255,255)
        // JPEG/full-range red, exercises U/V ordering rather than gray only.
        for(i in 0 .. length(y)) {y[i]=uint8(76)}
        for(i in 0 .. length(u)) {u[i]=uint8(85);v[i]=uint8(255)}
        for(row in 0 .. 2) {for(col in 0 .. 3) {let i=row*8+col*2;uv[i]=uint8(vu ? 255 : 85);uv[i+1]=uint8(vu ? 85 : 255)}}
        if(nv) {
            verify(is_ok(update_nv_texture(texture,y,7,uv,8)))
            verify(!is_ok(update_yuv_texture(texture,y,7,u,4,v,4)))
            verify(!is_ok(update_nv_texture(texture,y,4,uv,8)) && !is_ok(update_nv_texture(texture,y,2147483647,uv,8)))
            resize(uv,13);verify(!is_ok(update_nv_texture(texture,y,7,uv,8)))
        }
        else {
            verify(is_ok(update_yuv_texture(texture,y,7,u,4,v,4)))
            verify(!is_ok(update_nv_texture(texture,y,7,uv,8)))
            verify(!is_ok(update_yuv_texture(texture,y,7,u,2,v,4)))
            resize(v,6);verify(!is_ok(update_yuv_texture(texture,y,7,u,4,v,4)))
        }
        expect_rgb(renderer,surface,texture,255,0,0)

        return sdl_ok()
    } |> is_ok
    verify(created)
}
[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        let allocated=with_surface(5,3,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface : SDL_Surface?) {
            let created=with_software_renderer(surface) $(renderer : SDL_Renderer?) {
                planes(renderer,surface,SDL_PixelFormat.PIXELFORMAT_IYUV,false,false)
                planes(renderer,surface,SDL_PixelFormat.PIXELFORMAT_YV12,false,false)
                planes(renderer,surface,SDL_PixelFormat.PIXELFORMAT_NV12,true,false)
                planes(renderer,surface,SDL_PixelFormat.PIXELFORMAT_NV21,true,true)
                verify(SDL_SetRenderDrawColorFloat(renderer,1.0,0.5,0.25,0.5))
                var r,g,b,a,scale : float
                unsafe {verify(SDL_GetRenderDrawColorFloat(renderer,addr(r),addr(g),addr(b),addr(a)))}
                verify(r==1.0 && g==0.5 && b==0.25 && a==0.5)
                verify(is_ok(render_draw_color(renderer,r,g,b,a)) && g==0.5 && a==0.5)
                unsafe {
                    var nr,ng,nb,na : uint8
                    verify(SDL_GetRenderDrawColor(renderer,addr(nr),addr(ng),addr(nb),addr(na)))
                    verify(nr==uint8(255) && ng==uint8(127) && nb==uint8(63) && na==uint8(127))
                }
                var nr,ng,nb,na : uint
                verify(is_ok(render_draw_color_bytes(renderer,nr,ng,nb,na)) && nr==255u && ng==127u && nb==63u && na==127u)
                verify(SDL_SetRenderColorScale(renderer,2.0))
                unsafe {verify(SDL_GetRenderColorScale(renderer,addr(scale)) && scale==2.0)}
                verify(is_ok(render_color_scale(renderer,scale)) && scale==2.0)
                verify(SDL_SetRenderColorScale(renderer,1.0))
                let alpha=SDL_ComposeCustomBlendMode(SDL_BlendFactor.BLENDFACTOR_SRC_ALPHA,SDL_BlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,SDL_BlendOperation.BLENDOPERATION_ADD,SDL_BlendFactor.BLENDFACTOR_ONE,SDL_BlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,SDL_BlendOperation.BLENDOPERATION_ADD)
                verify(alpha==SDL_BLENDMODE_BLEND && SDL_SetRenderDrawBlendMode(renderer,alpha))
                var blend=SDL_BLENDMODE_INVALID
                unsafe {verify(SDL_GetRenderDrawBlendMode(renderer,addr(blend)) && blend==alpha)}
                verify(is_ok(render_draw_blend_mode(renderer,blend)) && blend==alpha)
                verify(SDL_SetRenderDrawColor(renderer,0u,0u,0u,255u) && SDL_RenderClear(renderer))
                verify(SDL_SetRenderDrawColorFloat(renderer,1.0,0.5,0.25,0.5) && SDL_RenderPoint(renderer,0.0,0.0) && SDL_FlushRenderer(renderer))
                var bytes : array<uint8>;resize(bytes,60);verify(is_ok(copy_surface_rgba8(surface,bytes,20)))
                verify(abs(int(bytes[0])-127)<=2 && abs(int(bytes[1])-63)<=2 && abs(int(bytes[2])-31)<=2)
                for(i in 1 .. 15) {verify(bytes[i*4]==uint8(0) && bytes[i*4+1]==uint8(0) && bytes[i*4+2]==uint8(0))}
                let custom=SDL_ComposeCustomBlendMode(SDL_BlendFactor.BLENDFACTOR_DST_COLOR,SDL_BlendFactor.BLENDFACTOR_SRC_COLOR,SDL_BlendOperation.BLENDOPERATION_ADD,SDL_BlendFactor.BLENDFACTOR_ONE,SDL_BlendFactor.BLENDFACTOR_ZERO,SDL_BlendOperation.BLENDOPERATION_ADD)
                verify(custom!=SDL_BLENDMODE_INVALID && !SDL_SetRenderDrawBlendMode(renderer,custom)) // software has no custom blend support
                verify(is_ok(render_draw_blend_mode(renderer,blend)) && blend==alpha)

                return sdl_ok()
            } |> is_ok
            verify(created)

            return sdl_ok()
        } |> is_ok
        verify(allocated)

        return sdl_ok()
    } |> is_ok
    verify(initialized)
    var r=9.0;var g=9.0;var b=9.0;var a=9.0;var scale=9.0;var mode=0u
    verify(!is_ok(render_draw_color(null,r,g,b,a)) && r==0.0 && a==0.0)
    verify(!is_ok(render_color_scale(null,scale)) && scale==1.0)
    verify(!is_ok(render_draw_blend_mode(null,mode)) && mode==SDL_BLENDMODE_INVALID)
    print("renderer YUV/blend: four formats, padded odd planes, color and blend passed\n")
    return 0
}
