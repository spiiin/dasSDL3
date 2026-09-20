options gen2
require dassdl3/sdl3_renderer_state_boost

def black(renderer : SDL_Renderer?) {
    verify(SDL_SetRenderDrawColor(renderer,0u,0u,0u,255u) && SDL_RenderClear(renderer))
    verify(SDL_SetRenderDrawColor(renderer,200u,30u,10u,255u))
}
def image_is_rect(renderer : SDL_Renderer?; surface : SDL_Surface?; x,y,w,h : int) {
    verify(SDL_FlushRenderer(renderer))
    var bytes : array<uint8>;resize(bytes,32*32*4)
    verify(copy_surface_rgba8(surface,bytes,32*4))
    for(py in 0 .. 32) {for(px in 0 .. 32) {
        let inside=px>=x && px<x+w && py>=y && py<y+h
        let i=(py*32+px)*4
        verify(bytes[i]==uint8(inside ? 200 : 0))
        verify(bytes[i+1]==uint8(inside ? 30 : 0) && bytes[i+2]==uint8(inside ? 10 : 0))
    }}
}
[export]
def main(smoke : bool) : int {
    let scope1=with_sdl() {
        let scope2=with_surface(32,32,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface) {
            let scope3=with_software_renderer(surface) $(renderer) {
                var w=-1;var h=-1;var sx=-1.0;var sy=-1.0
                verify(render_output_size(renderer,w,h) && w==32 && h==32)
                verify(current_render_output_size(renderer,w,h) && w==32 && h==32)
                verify(render_scale(renderer,sx,sy) && sx==1.0 && sy==1.0)
                verify(!SDL_RenderViewportSet(renderer) && !SDL_RenderClipEnabled(renderer))
                var viewport : SDL_Rect
                viewport.x=4;viewport.y=6;viewport.w=16;viewport.h=16
                var clip : SDL_Rect
                clip.x=2;clip.y=3;clip.w=4;clip.h=3
                var got : SDL_Rect
                unsafe {
                    verify(SDL_GetRenderOutputSize(renderer,addr(w),addr(h)) && w==32 && h==32)
                    verify(SDL_GetCurrentRenderOutputSize(renderer,addr(w),addr(h)) && w==32 && h==32)
                    verify(SDL_GetRenderScale(renderer,addr(sx),addr(sy)) && sx==1.0 && sy==1.0)
                    verify(SDL_SetRenderViewport(renderer,addr(viewport)))
                    verify(SDL_GetRenderViewport(renderer,addr(got)) && got.x==4 && got.y==6 && got.w==16)
                    verify(SDL_SetRenderClipRect(renderer,addr(clip)))
                    verify(SDL_GetRenderClipRect(renderer,addr(got)) && got.x==2 && got.y==3 && got.h==3)
                }
                verify(SDL_RenderViewportSet(renderer) && SDL_RenderClipEnabled(renderer))
                black(renderer)
                unsafe {verify(SDL_RenderFillRect(renderer,null))}
                image_is_rect(renderer,surface,6,9,4,3)
                // Reset pointer-valued state using safe NULL adapters.
                verify(SDL_ResetRenderViewport(renderer) && SDL_DisableRenderClip(renderer))
                verify(!SDL_RenderViewportSet(renderer) && !SDL_RenderClipEnabled(renderer))
                verify(SDL_GetRenderViewportRef(renderer,got) && got.w==32 && got.h==32)
                verify(SDL_GetRenderClipRectRef(renderer,got) && got.w==0 && got.h==0)
                black(renderer)
                verify(SDL_SetRenderScale(renderer,2.0,2.0))
                verify(render_scale(renderer,sx,sy) && sx==2.0 && sy==2.0)
                verify(SDL_GetRenderViewportRef(renderer,got) && got.w==16 && got.h==16)
                verify(SDL_RenderPoint(renderer,2.0,3.0))
                image_is_rect(renderer,surface,4,6,2,2)
                verify(SDL_SetRenderScale(renderer,1.0,1.0))
                verify(SDL_SetRenderViewportRef(renderer,viewport) && SDL_SetRenderClipRectRef(renderer,clip))
                // SDL stores viewport/clip/scale separately for each render target.
                let scope4=with_target_texture(renderer,8,10) $(target) {
                    let scope5=with_render_target(renderer,target) {
                        verify(render_output_size(renderer,w,h))
                        print("software output while target selected: {w}x{h}\n")
                        verify(w==8 && h==10) // pinned software backend reports active surface
                        verify(current_render_output_size(renderer,w,h) && w==8 && h==10)
                        verify(!SDL_RenderViewportSet(renderer) && !SDL_RenderClipEnabled(renderer))
                        verify(render_scale(renderer,sx,sy) && sx==1.0 && sy==1.0)
                        verify(SDL_SetRenderScale(renderer,2.0,2.0))
                        verify(SDL_SetRenderClipRectRef(renderer,clip))
                    }
                    verify(scope5)
                    verify(SDL_GetRenderViewportRef(renderer,got) && got.x==4 && got.y==6)
                    verify(SDL_GetRenderClipRectRef(renderer,got) && got.w==4 && SDL_RenderClipEnabled(renderer))
                    verify(render_scale(renderer,sx,sy) && sx==1.0 && sy==1.0)
                    let scope6=with_render_target(renderer,target) {
                        verify(render_scale(renderer,sx,sy) && sx==2.0 && sy==2.0)
                        verify(SDL_RenderClipEnabled(renderer))
                    }
                    verify(scope6)
                }
                verify(scope4)
                viewport.w=-1
                verify(!SDL_SetRenderViewportRef(renderer,viewport))
                verify(SDL_GetRenderViewportRef(renderer,got) && got.w==16)
                // SDL's negative clip dimensions disable clipping; no invented validation.
                clip.w=-1
                verify(SDL_SetRenderClipRectRef(renderer,clip) && !SDL_RenderClipEnabled(renderer))
            }
            verify(scope3)
        }
        verify(scope2)
        let window_ok=with_window("renderer output queries",32,32,SDL_WINDOW_HIDDEN) $(window) {
            let renderer_ok=with_renderer(window) $(renderer) {
                var base_w,base_h,w,h : int
                verify(render_output_size(renderer,base_w,base_h) && base_w>8 && base_h>10)
                let texture_ok=with_target_texture(renderer,8,10) $(target) {
                    let selected=with_render_target(renderer,target) {
                        verify(render_output_size(renderer,w,h) && w==base_w && h==base_h)
                        verify(current_render_output_size(renderer,w,h) && w==8 && h==10)
                    }
                    verify(selected)
                }
                verify(texture_ok)
                verify(current_render_output_size(renderer,w,h) && w==base_w && h==base_h)
            }
            verify(renderer_ok)
        }
        verify(window_ok)
    }
    verify(scope1)
    var w=9;var h=9;var sx=9.0;var sy=9.0;var rect : SDL_Rect
    verify(!render_output_size(null,w,h) && w==0 && h==0)
    verify(!current_render_output_size(null,w,h) && w==0 && h==0)
    verify(!render_scale(null,sx,sy) && sx==1.0 && sy==1.0)
    verify(!SDL_GetRenderViewportRef(null,rect) && !SDL_GetRenderClipRectRef(null,rect))
    verify(!SDL_SetRenderViewportRef(null,rect) && !SDL_SetRenderClipRectRef(null,rect))
    verify(!SDL_SetRenderScale(null,1.0,1.0))
    print("renderer state: output, pixels and target-local state passed\n")
    return 0
}
