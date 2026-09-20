options gen2
require dassdl3/sdl3_window_io_boost
[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        let screensaver=SDL_ScreenSaverEnabled()
        verify(SDL_DisableScreenSaver() && !SDL_ScreenSaverEnabled())
        verify(SDL_EnableScreenSaver() && SDL_ScreenSaverEnabled())
        if(!screensaver) {verify(SDL_DisableScreenSaver())}
        let owned=with_window("window IO",32,24,SDL_WINDOW_HIDDEN|SDL_WINDOW_NOT_FOCUSABLE) $(window : SDL_Window?) {
            var mode : SDL_DisplayMode
            verify(SDL_GetDesktopDisplayModeCopy(SDL_GetDisplayForWindow(window),mode))
            verify(SDL_SetWindowFullscreenModeRef(window,mode))
            var selected : SDL_DisplayMode
            verify(SDL_GetWindowFullscreenModeCopy(window,selected) && selected.w==mode.w)
            unsafe {
                verify(SDL_SetWindowFullscreenMode(window,addr(mode)))
                verify(SDL_GetWindowFullscreenMode(window)!=null)
            }
            // Hidden window: exercise requests without changing desktop resolution.
            verify(SDL_SetWindowFullscreen(window,true))
            verify((SDL_GetWindowFlags(window)&SDL_WINDOW_FULLSCREEN)!=0ul)
            verify(SDL_SetWindowFullscreen(window,false) && SDL_SyncWindow(window))
            verify(SDL_SetWindowDesktopFullscreenMode(window))
            verify(!SDL_GetWindowFullscreenModeCopy(window,selected) && selected.w==0)
            var profile : array<uint8>
            let copied=is_ok(window_icc_profile(window,profile))
            unsafe {
                var size=0ul
                let raw=SDL_GetWindowICCProfile(window,addr(size))
                verify((raw!=null)==copied)
                if(raw!=null) {
                    verify(uint64(length(profile))==size && size>0ul)
                    let bytes=reinterpret<uint8?>(raw)
                    for(i in 0 .. length(profile)) {verify(bytes[i]==profile[i])}
                    SDL_free(raw)
                }
                else {verify(length(profile)==0)}
            }
            print("ICC profile available: {copied}\n")
            verify(!SDL_WindowHasSurface(window))
            let surface=SDL_GetWindowSurface(window)
            verify(surface!=null && SDL_WindowHasSurface(window))
            var size : int2
            verify(is_ok(surface_size(surface,size)) && size.x==32 && size.y==24)
            let red=SDL_MapSurfaceRGBA(surface,uint(210),uint(30),uint(40),uint(255))
            verify(SDL_FillSurfaceAll(surface,red))
            var rect : SDL_Rect
            rect.x=2;rect.y=3;rect.w=4;rect.h=5
            let blue=SDL_MapSurfaceRGBA(surface,uint(10),uint(20),uint(230),uint(255))
            unsafe {verify(SDL_FillSurfaceRect(surface,addr(rect),blue))}
            var pixels : array<uint8>;resize(pixels,32*24*4)
            verify(is_ok(copy_surface_rgba8(surface,pixels,32*4)))
            verify(pixels[0]==uint8(210) && pixels[1]==uint8(30))
            let offset=(3*32+2)*4
            verify(pixels[offset]==uint8(10) && pixels[offset+2]==uint8(230))
            let vsync_ok=SDL_SetWindowSurfaceVSync(window,SDL_WINDOW_SURFACE_VSYNC_DISABLED)
            var vsync=-99
            let vsync_query=is_ok(window_surface_vsync(window,vsync))
            unsafe {var raw_vsync=-99;verify(SDL_GetWindowSurfaceVSync(window,addr(raw_vsync))==vsync_query);if(vsync_query){verify(raw_vsync==vsync)}}
            if(vsync_ok && vsync_query) {verify(vsync==0)}
            print("Surface VSync set/query: {vsync_ok}/{vsync_query}\n")
            verify(SDL_UpdateWindowSurface(window))
            unsafe {verify(SDL_UpdateWindowSurfaceRects(window,addr(rect),1))}
            var rects : array<SDL_Rect>;push(rects,rect)
            verify(is_ok(update_window_rects(window,rects)))
            verify(SDL_SetWindowSize(window,40,30) && SDL_SyncWindow(window))
            // Never touch the old borrowed surface after resize.
            let resized=SDL_GetWindowSurface(window)
            verify(resized!=null && is_ok(surface_size(resized,size)) && size.x==40 && size.y==30)
            verify(SDL_DestroyWindowSurface(window) && !SDL_WindowHasSurface(window))
            verify(!SDL_UpdateWindowSurface(window))
            verify(SDL_GetWindowSurface(window)!=null)
            verify(SDL_SetWindowKeyboardGrab(window,true))
            verify(!SDL_GetWindowKeyboardGrab(window)) // hidden window has no focus
            verify(SDL_SetWindowKeyboardGrab(window,false))
            verify(SDL_SetWindowMouseGrab(window,true))
            verify(!SDL_GetWindowMouseGrab(window))
            verify(SDL_GetGrabbedWindow()==null)
            verify(SDL_SetWindowMouseGrab(window,false))
            unsafe {verify(SDL_SetWindowMouseRect(window,addr(rect)));verify(SDL_GetWindowMouseRect(window)!=null)}
            var saved : SDL_Rect
            verify(SDL_GetWindowMouseRectCopy(window,saved) && saved.x==2 && saved.w==4)
            verify(SDL_ClearWindowMouseRect(window))
            verify(!SDL_GetWindowMouseRectCopy(window,saved) && saved.w==0)
            verify(SDL_SetWindowMouseRectRef(window,rect) && SDL_ClearWindowMouseRect(window))
            verify(SDL_FlashWindow(window,SDL_FlashOperation.FLASH_CANCEL))
            // System menu positive path is interactive; automated test checks rejection.
            verify(!SDL_ShowWindowSystemMenu(null,0,0))
            let icon=SDL_CreateSurface(8,8,SDL_PixelFormat.PIXELFORMAT_RGBA32)
            verify(icon!=null)
            verify(SDL_FillSurfaceAll(icon,SDL_MapSurfaceRGBA(icon,uint(10),uint(40),uint(200),uint(255))))
            verify(SDL_SetWindowIcon(window,icon))
            verify(!SDL_SetWindowShape(window,icon)) // TRANSPARENT required
            SDL_DestroySurface(icon)
            var invalid : array<uint8>;push(invalid,uint8(7))
            verify(!is_ok(window_icc_profile(null,invalid)) && length(invalid)==0)

            return sdl_ok()
        } |> is_ok
        verify(owned)
        let transparent=with_window("shape",16,16,SDL_WINDOW_HIDDEN|SDL_WINDOW_TRANSPARENT) $(window : SDL_Window?) {
            let shaped=with_surface(16,16,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(shape : SDL_Surface?) {
                verify(SDL_FillSurfaceAll(shape,SDL_MapSurfaceRGBA(shape,uint(0),uint(0),uint(0),uint(255))))
                verify(SDL_SetWindowShape(window,shape))
                // Pinned SDL 3.2.18 contradicts documented NULL-removal behavior.
                verify(!SDL_SetWindowShape(window,null))
                return sdl_ok()
            } |> is_ok
            verify(shaped)

            return sdl_ok()
        } |> is_ok
        verify(transparent)
        var called=false
        let bad=with_surface(-1,1,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(unused : SDL_Surface?) {called=true
            return sdl_ok()
        } |> is_ok
        verify(!bad && !called)

        return sdl_ok()
    } |> is_ok
    verify(initialized)
    return 0
}
