options gen2
require dassdl3/sdl3_renderer_final_boost

def clear_black(renderer : SDL_Renderer?) {
    verify(SDL_SetRenderDrawColor(renderer,0u,0u,0u,255u) && SDL_RenderClear(renderer))
}
[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        let allocated=with_surface(16,16,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface) {
            let created=with_software_renderer(surface) $(renderer) {
                var xy,uv : array<SDL_FPoint>;resize(xy,3)
                xy[0].x=1.0;xy[0].y=1.0;xy[1].x=14.0;xy[1].y=1.0;xy[2].x=1.0;xy[2].y=14.0
                var colors : array<SDL_FColor>;resize(colors,3)
                for (c in colors) {c.r=1.0;c.a=1.0}
                var indices : array<int>;resize(indices,3);indices[0]=0;indices[1]=1;indices[2]=2
                var narrow : array<uint8>;resize(narrow,3);narrow[1]=uint8(1);narrow[2]=uint8(2)
                var wide : array<uint16>;resize(wide,3);wide[1]=uint16(1);wide[2]=uint16(2)
                var expected,actual : array<uint8>;resize(expected,1024);resize(actual,1024)
                clear_black(renderer)
                verify(render_geometry_raw(renderer,null,xy,colors,uv,indices) && SDL_FlushRenderer(renderer))
                verify(copy_surface_rgba8(surface,expected,64))
                verify(expected[(2*16+2)*4]==uint8(255) && expected[(14*16+14)*4]==uint8(0))
                for(mode in 0 .. 4) {
                    clear_black(renderer)
                    unsafe {
                        if(mode==0) {verify(SDL_RenderGeometryRaw(renderer,null,addr(xy[0].x),8,addr(colors[0]),16,null,8,3,addr(narrow[0]),3,1))}
                        elif(mode==1) {verify(SDL_RenderGeometryRaw(renderer,null,addr(xy[0].x),8,addr(colors[0]),16,null,8,3,addr(wide[0]),3,2))}
                        elif(mode==2) {verify(SDL_RenderGeometryRaw(renderer,null,addr(xy[0].x),8,addr(colors[0]),16,null,8,3,addr(indices[0]),3,4))}
                        else {verify(render_geometry_raw(renderer,null,xy,colors,uv))}
                    }
                    verify(SDL_FlushRenderer(renderer) && copy_surface_rgba8(surface,actual,64))
                    for(i in 0 .. 1024) {verify(expected[i]==actual[i])}
                }
                indices[0]=-1;verify(!render_geometry_raw(renderer,null,xy,colors,uv,indices))
                resize(indices,0);clear_black(renderer);verify(render_geometry_raw(renderer,null,xy,colors,uv,indices))
                verify(SDL_FlushRenderer(renderer) && copy_surface_rgba8(surface,actual,64))
                verify(actual[(2*16+2)*4]==uint8(0))
                resize(colors,2);verify(!render_geometry_raw(renderer,null,xy,colors,uv))
                verify(SDL_GetRenderMetalLayer(renderer)==null && SDL_GetRenderMetalCommandEncoder(renderer)==null)
                verify(!SDL_AddVulkanRenderSemaphores(renderer,0u,0l,0l))
                clear_black(renderer);verify(SDL_SetRenderDrawColor(renderer,255u,255u,255u,255u))
                verify(SDL_RenderDebugText(renderer,0.0,0.0,"%s%n") && SDL_FlushRenderer(renderer) && copy_surface_rgba8(surface,expected,64))
                clear_black(renderer);verify(SDL_SetRenderDrawColor(renderer,255u,255u,255u,255u))
                verify(SDL_RenderDebugTextFormatText(renderer,0.0,0.0,"%s%n") && SDL_FlushRenderer(renderer) && copy_surface_rgba8(surface,actual,64))
                for(i in 0 .. 1024) {verify(expected[i]==actual[i])}
            }
            verify(created)
        }
        verify(allocated)
        let window_ok=with_window_renderer("event conversion",64,48,SDL_WINDOW_HIDDEN) $(window,renderer) {
            verify(SDL_SetRenderScale(renderer,2.0,2.0))
            var event : SDL_Event
            var motion : SDL_MouseMotionEvent;motion.windowID=SDL_GetWindowID(window);motion.x=20.0;motion.y=12.0;motion.xrel=4.0;motion.yrel=6.0
            SDL_WriteMouseMotionEvent(motion,event)
            unsafe {verify(SDL_ConvertEventToRenderCoordinates(renderer,addr(event)))}
            verify(SDL_ReadMouseMotionEvent(event,motion))
            verify(motion.x==10.0 && motion.y==6.0 && motion.xrel==2.0 && motion.yrel==3.0)
            var button : SDL_MouseButtonEvent;button.windowID=SDL_GetWindowID(window);button.x=20.0;button.y=12.0;button.down=true
            SDL_WriteMouseButtonEvent(button,event);verify(convert_event_to_render(renderer,event) && SDL_ReadMouseButtonEvent(event,button))
            verify(button.x==10.0 && button.y==6.0 && button.down)
            var wheel : SDL_MouseWheelEvent;wheel.windowID=SDL_GetWindowID(window);wheel.mouse_x=20.0;wheel.mouse_y=12.0;wheel.x=3.0;wheel.y=4.0
            SDL_WriteMouseWheelEvent(wheel,event);verify(convert_event_to_render(renderer,event) && SDL_ReadMouseWheelEvent(event,wheel))
            verify(wheel.mouse_x==10.0 && wheel.mouse_y==6.0 && wheel.x==3.0 && wheel.y==4.0)
            verify(!convert_event_to_render(null,event))
        }
        verify(window_ok)
    }
    verify(initialized)
    print("renderer final API: geometry pixels, events, literal text and unsupported interop passed\n")
    return 0
}
