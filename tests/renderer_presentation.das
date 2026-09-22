options gen2
require math
require dassdl3/sdl3_renderer_presentation_boost

def presentation(renderer : SDL_Renderer?; mode : SDL_RendererLogicalPresentation; x,y,w,h : float) {
    verify(SDL_SetRenderLogicalPresentation(renderer,10,10,mode))
    var got : SDL_FRect
    verify(SDL_GetRenderLogicalPresentationRectRef(renderer,got))
    verify(abs(got.x-x)<0.001 && abs(got.y-y)<0.001 && abs(got.w-w)<0.001 && abs(got.h-h)<0.001)
    var lw,lh : int;var selected=SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_DISABLED
    verify(is_ok(render_logical_presentation(renderer,lw,lh,selected)) && lw==10 && lh==10 && selected==mode)
}
[export]
def main(smoke : bool) : int {
    var saved_name : string
    let initialized=with_sdl() {
        let count=SDL_GetNumRenderDrivers()
        verify(count>0)
        for(i in 0 .. count) {verify(unwrap_or(render_driver(i), "")!="" && unwrap_or(render_driver(i), "")==SDL_GetRenderDriver(i))}
        verify(unwrap_or(render_driver(-1), "")=="" && SDL_GetRenderDriver(count)=="")
        let allocated=with_surface(32,24,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface : SDL_Surface?) {
            let created=with_software_renderer(surface) $(renderer : SDL_Renderer?) {
                saved_name=unwrap_or(renderer_name(renderer), "")
                verify(saved_name=="software" && saved_name==SDL_GetRendererName(renderer))
                let props=SDL_GetRendererProperties(renderer)
                verify(props!=0u && SDL_GetRendererProperties(renderer)==props)
                verify(SDL_SetNumberProperty(props,"dasSDL3.presentation.test",73l))
                verify(SDL_GetNumberProperty(props,"dasSDL3.presentation.test",0l)==73l)
                verify(SDL_ClearProperty(props,"dasSDL3.presentation.test")) // renderer owns group
                var safe : SDL_Rect
                unsafe {verify(SDL_GetRenderSafeArea(renderer,addr(safe)) && safe.w==32 && safe.h==24)}
                verify(SDL_GetRenderSafeAreaRef(renderer,safe) && safe.w==32)
                presentation(renderer,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_STRETCH,0.0,0.0,32.0,24.0)
                presentation(renderer,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_LETTERBOX,4.0,0.0,24.0,24.0)
                presentation(renderer,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_OVERSCAN,0.0,-4.0,32.0,32.0)
                presentation(renderer,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_INTEGER_SCALE,6.0,2.0,20.0,20.0)
                var lw,lh : int;var mode=SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_DISABLED
                var rect : SDL_FRect
                unsafe {
                    verify(SDL_GetRenderLogicalPresentation(renderer,addr(lw),addr(lh),addr(mode)))
                    verify(lw==10 && lh==10 && mode==SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_INTEGER_SCALE)
                    verify(SDL_GetRenderLogicalPresentationRect(renderer,addr(rect)) && rect.x==6.0 && rect.y==2.0)
                }
                verify(SDL_SetRenderDrawColor(renderer,0u,0u,0u,255u) && SDL_RenderClear(renderer))
                verify(SDL_SetRenderDrawColor(renderer,200u,30u,10u,255u) && SDL_RenderPoint(renderer,2.0,3.0))
                verify(SDL_FlushRenderer(renderer))
                var bytes : array<uint8>;resize(bytes,32*24*4)
                verify(is_ok(copy_surface_rgba8(surface,bytes,32*4)))
                for(y in 0 .. 24) {for(x in 0 .. 32) {
                    let inside=x>=10 && x<12 && y>=8 && y<10
                    let i=(y*32+x)*4
                    verify(bytes[i]==uint8(inside ? 200 : 0) && bytes[i+1]==uint8(inside ? 30 : 0) && bytes[i+2]==uint8(inside ? 10 : 0))
                }}
                verify(SDL_SetRenderLogicalPresentation(renderer,0,0,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_DISABLED))
                verify(SDL_GetRenderLogicalPresentationRectRef(renderer,rect) && rect.w==32.0 && rect.h==24.0)

                return sdl_ok()
            } |> is_ok
            verify(created)

            return sdl_ok()
        } |> is_ok
        verify(allocated)
        let opened=with_window("logical coordinates",64,48,SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            let created=with_renderer(window) $(renderer : SDL_Renderer?) {
                verify(SDL_SetRenderLogicalPresentation(renderer,20,20,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_LETTERBOX))
                var ww,wh : int;verify(is_ok(window_size(window,ww,wh)))
                var x=-99.0;var y=-99.0
                unsafe {verify(SDL_RenderCoordinatesFromWindow(renderer,float(ww)/2.0,float(wh)/2.0,addr(x),addr(y)))}
                verify(abs(x-10.0)<0.001 && abs(y-10.0)<0.001)
                unsafe {verify(SDL_RenderCoordinatesToWindow(renderer,10.0,10.0,addr(x),addr(y)))}
                verify(abs(x-float(ww)/2.0)<0.001 && abs(y-float(wh)/2.0)<0.001)
                verify(SDL_SetRenderScale(renderer,2.0,2.0))
                var viewport = SDL_Rect(x = 1, y = 2, w = 8, h = 8)
                verify(SDL_SetRenderViewportRef(renderer,viewport))
                var wx,wy : float
                verify(is_ok(render_to_window(renderer,2.0,3.0,wx,wy)))
                verify(is_ok(render_from_window(renderer,wx,wy,x,y)) && abs(x-2.0)<0.001 && abs(y-3.0)<0.001)
                var dst : SDL_FRect;var pw,ph : int
                verify(SDL_GetRenderLogicalPresentationRectRef(renderer,dst) && is_ok(render_output_size(renderer,pw,ph)))
                verify(abs(wx-(dst.x+6.0*dst.w/20.0)*float(ww)/float(pw))<0.001)
                verify(abs(wy-(dst.y+10.0*dst.h/20.0)*float(wh)/float(ph))<0.001)
                let texture=with_target_texture(renderer,8,8) $(target : SDL_Texture?) {
                    let selected=with_render_target(renderer,target) {
                        verify(SDL_SetRenderLogicalPresentation(renderer,4,4,SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_STRETCH))
                        // Coordinate conversions use the main window view, not the active target.
                        verify(is_ok(render_from_window(renderer,wx,wy,x,y)) && abs(x-2.0)<0.001 && abs(y-3.0)<0.001)

                        return sdl_ok()
                    } |> is_ok
                    verify(selected)

                    return sdl_ok()
                } |> is_ok
                verify(texture)
                var lw,lh : int;var mode=SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_DISABLED
                verify(is_ok(render_logical_presentation(renderer,lw,lh,mode)) && lw==20 && lh==20 && mode==SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_LETTERBOX)

                return sdl_ok()
            } |> is_ok
            verify(created)

            return sdl_ok()
        } |> is_ok
        verify(opened)

        return sdl_ok()
    } |> is_ok
    verify(initialized && saved_name=="software")
    var w=7;var h=7;var mode=SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_STRETCH
    verify(!is_ok(render_logical_presentation(null,w,h,mode)) && w==0 && h==0 && mode==SDL_RendererLogicalPresentation.LOGICAL_PRESENTATION_DISABLED)
    var x=7.0;var y=9.0
    verify(!is_ok(render_from_window(null,0.0,0.0,x,y)) && x==7.0 && y==9.0)
    verify(!is_ok(render_to_window(null,0.0,0.0,x,y)) && x==7.0 && y==9.0)
    verify(unwrap_or(renderer_name(null), "")=="" && SDL_GetRendererProperties(null)==0u)
    print("renderer presentation: modes, pixels, names and coordinates passed\n")
    return 0
}
