options gen2
require dassdl3/sdl3_video_boost
[export]
def main(smoke : bool) : int {
    verify(SDL_GetNumVideoDrivers()>0)
    verify(SDL_GetVideoDriver(0)==SDL_GetVideoDriverCopy(0))
    var drivers=SDL_GetVideoDriverCopy(0)
    verify(length(drivers)>0)
    let initialized=with_sdl() {
        verify(SDL_GetCurrentVideoDriver()==SDL_GetCurrentVideoDriverCopy())
        let theme=SDL_GetSystemTheme()
        verify(int(theme)>=0 && int(theme)<=2)
        var ids : array<uint>
        verify(is_ok(displays(ids)) && length(ids)>0)
        let primary=SDL_GetPrimaryDisplay()
        var found=false
        for(id in ids) {if(id==primary){found=true}}
        verify(found)
        verify(SDL_GetDisplayProperties(primary)!=0u)
        let name=unwrap_or(display_name(primary), "")
        verify(name==SDL_GetDisplayName(primary) && length(name)>0)
        let natural=SDL_GetNaturalDisplayOrientation(primary)
        let current=SDL_GetCurrentDisplayOrientation(primary)
        verify(int(natural)>=0 && int(natural)<=4 && int(current)>=0 && int(current)<=4)
        verify(SDL_GetDisplayContentScale(primary)>0.0)
        var bounds : SDL_Rect
        var usable : SDL_Rect
        verify(SDL_GetDisplayBoundsRef(primary,bounds) && bounds.w>0 && bounds.h>0)
        verify(SDL_GetDisplayUsableBoundsRef(primary,usable) && usable.w>0 && usable.h>0)
        var point : SDL_Point
        point.x=bounds.x+bounds.w/2;point.y=bounds.y+bounds.h/2
        verify(SDL_GetDisplayForPointRef(point)==primary && SDL_GetDisplayForRectRef(bounds)==primary)
        var modes : array<SDL_DisplayMode>
        verify(is_ok(display_modes(primary,modes)) && length(modes)>0)
        verify(modes[0].displayID==primary && modes[0].w>0)
        var desktop : SDL_DisplayMode
        var active : SDL_DisplayMode
        var closest : SDL_DisplayMode
        verify(SDL_GetDesktopDisplayModeCopy(primary,desktop))
        verify(SDL_GetCurrentDisplayModeCopy(primary,active))
        verify(desktop.w>0 && active.h>0)
        verify(SDL_GetClosestFullscreenDisplayModeRef(primary,1,1,0.0,true,closest))
        verify(closest.w>0 && closest.displayID==primary)
        unsafe {
            var count=0
            let raw_ids=SDL_GetDisplays(addr(count))
            verify(raw_ids!=null && count==length(ids))
            SDL_free(raw_ids)
            let raw_modes=SDL_GetFullscreenDisplayModes(primary,addr(count))
            verify(raw_modes!=null && count==length(modes))
            SDL_free(raw_modes)
            verify(SDL_GetDesktopDisplayMode(primary)!=null && SDL_GetCurrentDisplayMode(primary)!=null)
            verify(SDL_GetClosestFullscreenDisplayMode(primary,1,1,0.0,true,addr(closest)))
            verify(SDL_GetDisplayBounds(primary,addr(bounds)))
            verify(SDL_GetDisplayUsableBounds(primary,addr(usable)))
            verify(SDL_GetDisplayForPoint(addr(point))==primary && SDL_GetDisplayForRect(addr(bounds))==primary)
        }
        var listed : array<SDL_Window?>
        verify(is_ok(windows(listed)) && length(listed)==0)
        let opened=with_window("Окно",320,240,SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            verify(SDL_GetDisplayForWindow(window)!=0u)
            verify(SDL_GetWindowPixelDensity(window)>0.0 && SDL_GetWindowDisplayScale(window)>0.0)
            verify(SDL_GetWindowPixelFormat(window)!=SDL_PixelFormat.PIXELFORMAT_UNKNOWN)
            verify(SDL_GetWindowParent(window)==null && SDL_GetWindowProperties(window)!=0u)
            verify((SDL_GetWindowFlags(window) & SDL_WINDOW_HIDDEN)!=0ul)
            let title=unwrap_or(window_title(window), "")
            verify(SDL_GetWindowTitle(window)==title && title=="Окно")
            verify(SDL_SetWindowTitle(window,"changed") && title=="Окно")
            verify(is_ok(windows(listed)) && length(listed)==1 && listed[0]==window)
            var w=0;var h=0;var x=0;var y=0
            verify(is_ok(window_size(window,w,h)) && w==320 && h==240)
            verify(is_ok(window_size_pixels(window,w,h)) && w>0 && h>0)
            verify(is_ok(window_position(window,x,y)))
            unsafe {
                var count=0
                let raw_windows=SDL_GetWindows(addr(count))
                verify(raw_windows!=null && count==1)
                SDL_free(raw_windows)
                verify(SDL_GetWindowPosition(window,addr(x),addr(y)))
                verify(SDL_GetWindowSize(window,addr(w),addr(h)) && w==320 && h==240)
                verify(SDL_GetWindowSizeInPixels(window,addr(w),addr(h)) && w>0 && h>0)
            }

            return sdl_ok()
        } |> is_ok
        verify(opened)
        verify(is_ok(windows(listed)) && length(listed)==0)
        verify(!SDL_GetDisplayBoundsRef(0u,bounds))
        verify(!is_ok(display_modes(0u,modes)) && length(modes)==0)
        verify(!SDL_GetCurrentDisplayModeCopy(0u,active) && active.w==0)
        var w=0;var h=0
        verify(!is_ok(window_size(null,w,h)))

        return sdl_ok()
    } |> is_ok
    verify(initialized)
    verify(drivers==SDL_GetVideoDriverCopy(0))
    return 0
}
