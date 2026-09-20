options gen2
require dassdl3/sdl3_renderer_operations_boost

def pixel(bytes : array<uint8>; x,y : int) : uint3 {
    let i=(y*16+x)*4;return uint3(uint(bytes[i]),uint(bytes[i+1]),uint(bytes[i+2]))
}
def draw_case(renderer : SDL_Renderer?; texture : SDL_Texture?; op : int; raw : bool) {
    verify(SDL_SetRenderDrawColor(renderer,0u,0u,0u,255u) && SDL_RenderClear(renderer))
    var src : SDL_FRect;src.w=4.0;src.h=4.0
    var dst : SDL_FRect;dst.x=4.0;dst.y=4.0;dst.w=8.0;dst.h=8.0
    var center : SDL_FPoint;center.x=4.0;center.y=4.0
    var origin,right,down : SDL_FPoint
    origin.x=4.0;origin.y=4.0;right.x=12.0;right.y=4.0;down.x=6.0;down.y=12.0
    if(op==2) {dst.x=0.0;dst.y=0.0;dst.w=12.0;dst.h=8.0}
    if(op==3) {dst.x=2.0;dst.y=2.0;dst.w=12.0;dst.h=12.0}
    if(raw) {
        unsafe {
            if(op==0) {verify(SDL_RenderTextureRotated(renderer,texture,addr(src),addr(dst),double(180),addr(center),SDL_FlipMode.FLIP_NONE))}
            elif(op==1) {verify(SDL_RenderTextureAffine(renderer,texture,addr(src),addr(origin),addr(right),addr(down)))}
            elif(op==2) {verify(SDL_RenderTextureTiled(renderer,texture,addr(src),1.0,addr(dst)))}
            else {verify(SDL_RenderTexture9Grid(renderer,texture,addr(src),1.0,1.0,1.0,1.0,1.0,addr(dst)))}
        }
    }
    else {
        if(op==0) {verify(SDL_RenderTextureRotatedRefs(renderer,texture,src,dst,double(180),center,SDL_FlipMode.FLIP_NONE))}
        elif(op==1) {verify(SDL_RenderTextureAffineRefs(renderer,texture,src,origin,right,down))}
        elif(op==2) {verify(SDL_RenderTextureTiledRefs(renderer,texture,src,1.0,dst))}
        else {verify(SDL_RenderTexture9GridRefs(renderer,texture,src,1.0,1.0,1.0,1.0,1.0,dst))}
    }
    verify(SDL_FlushRenderer(renderer))
}
def drawing(renderer : SDL_Renderer?; surface : SDL_Surface?) {
    let scoped=with_texture(renderer,SDL_PixelFormat.PIXELFORMAT_RGBA32,SDL_TextureAccess.TEXTUREACCESS_STREAMING,4,4) $(texture) {
        var source : array<uint8>;resize(source,64)
        for(y in 0 .. 4) {for(x in 0 .. 4) {let i=(y*4+x)*4;source[i]=uint8(x<2 ? 255 : 0);source[i+2]=uint8(x<2 ? 0 : 255);source[i+3]=uint8(255)}}
        verify(upload_rgba8(texture,source,16) && SDL_SetTextureScaleMode(texture,SDL_ScaleMode.SCALEMODE_NEAREST))
        var raw_image,adapted : array<uint8>;resize(raw_image,1024);resize(adapted,1024)
        for(op in 0 .. 4) {
            draw_case(renderer,texture,op,true);verify(copy_surface_rgba8(surface,raw_image,64))
            draw_case(renderer,texture,op,false);verify(copy_surface_rgba8(surface,adapted,64))
            for(i in 0 .. 1024) {verify(raw_image[i]==adapted[i])}
            verify(pixel(adapted,15,15)==uint3(0u))
            if(op==0) {verify(pixel(adapted,5,5)==uint3(0u,0u,255u) && pixel(adapted,10,5)==uint3(255u,0u,0u))}
            elif(op==1) {verify(pixel(adapted,6,6)==uint3(255u,0u,0u) && pixel(adapted,10,6)==uint3(0u,0u,255u) && pixel(adapted,4,11)==uint3(0u))}
            elif(op==2) {
                for(y in 0 .. 16) {for(x in 0 .. 16) {
                    let inside=x<12 && y<8
                    let expected=inside ? (x%4<2 ? uint3(255u,0u,0u) : uint3(0u,0u,255u)) : uint3(0u)
                    verify(pixel(adapted,x,y)==expected)
                }}
            }
            else {verify(pixel(adapted,2,2)==uint3(255u,0u,0u) && pixel(adapted,13,13)==uint3(0u,0u,255u) && pixel(adapted,1,2)==uint3(0u))}
        }
    }
    verify(scoped)
    verify(SDL_SetRenderDrawColor(renderer,30u,60u,90u,255u) && SDL_RenderClear(renderer))
    var rect : SDL_Rect;rect.x=4;rect.y=4;rect.w=8;rect.h=8
    unsafe {
        let owned=SDL_RenderReadPixels(renderer,addr(rect));verify(owned!=null)
        var size : int2;verify(surface_size(owned,size) && size==int2(8,8))
        var bytes : array<uint8>;resize(bytes,256);verify(copy_surface_rgba8(owned,bytes,32))
        for(i in 0 .. 64) {verify(bytes[i*4]==uint8(30) && bytes[i*4+1]==uint8(60) && bytes[i*4+2]==uint8(90))}
        SDL_DestroySurface(owned)
    }
    rect.x=12;rect.y=12
    let readback=with_read_pixels(renderer,rect) $(owned) {
        var size : int2;verify(surface_size(owned,size) && size==int2(4,4))
        return
    }
    verify(readback)
    verify(SDL_SetRenderDrawColor(renderer,0u,0u,0u,255u) && SDL_RenderClear(renderer))
    verify(SDL_SetRenderDrawColor(renderer,255u,255u,255u,255u) && SDL_RenderDebugText(renderer,0.0,0.0,"A%"))
    verify(SDL_FlushRenderer(renderer))
    var bytes : array<uint8>;resize(bytes,1024);verify(copy_surface_rgba8(surface,bytes,64))
    var lit=0
    for(i in 0 .. 256) {if(bytes[i*4]!=uint8(0)) {lit++}}
    verify(lit>0 && lit<128) // literal debug text produced glyph pixels, not a format string
}
[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        unsafe {
            var window : SDL_Window?;var renderer : SDL_Renderer?
            verify(SDL_CreateWindowAndRenderer("raw pair",16,16,SDL_WINDOW_HIDDEN,addr(window),addr(renderer)))
            verify(window!=null && SDL_GetRenderWindow(renderer)==window)
            SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window)
        }
        var id=0u
        let pair=with_window_renderer("scoped pair",16,16,SDL_WINDOW_HIDDEN) $(window,renderer) {
            id=SDL_GetWindowID(window)
            let changed=SDL_SetRenderVSync(renderer,SDL_RENDERER_VSYNC_DISABLED)
            var vsync=-9;var raw=-9
            let queried=render_vsync(renderer,vsync)
            unsafe {verify(SDL_GetRenderVSync(renderer,addr(raw))==queried)}
            if(changed && queried) {verify(raw==0 && vsync==0)}
            print("Renderer VSync disable/query: {changed}/{queried}\n")
            return
        }
        verify(pair && id!=0u && SDL_GetWindowFromID(id)==null)
        let allocated=with_surface(16,16,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface) {
            let props_ok=with_properties() $(props) {
                verify(SDL_SetStringProperty(props,"SDL.renderer.create.name","software"))
                unsafe {verify(SDL_SetPointerProperty(props,"SDL.renderer.create.surface",reinterpret<void?>(surface)))}
                let renderer=SDL_CreateRendererWithProperties(props);verify(renderer!=null)
                drawing(renderer,surface)
                SDL_DestroyRenderer(renderer)
                let scoped=with_renderer_properties(props) $(next) {verify(SDL_GetRenderWindow(next)==null);return}
                verify(scoped && SDL_FillSurfaceAll(surface,SDL_MapSurfaceRGBA(surface,1u,2u,3u,255u)))
            }
            verify(props_ok)
        }
        verify(allocated)
        var called=false
        verify(!with_renderer_properties(0u) $(renderer) {called=true});verify(!called)
        var rect : SDL_Rect;rect.w=1;rect.h=1
        verify(!with_read_pixels(null,rect) $(surface) {called=true});verify(!called)
    }
    verify(initialized)
    print("renderer operations: draw pixels, readback and ownership passed\n")
    return 0
}
