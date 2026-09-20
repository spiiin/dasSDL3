options gen2
require dassdl3/sdl3_window_boost
require dassdl3/sdl3_properties_boost
[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        let properties=with_properties() $(props) {
            verify(SDL_SetStringProperty(props,"SDL.window.create.title","Properties window"))
            verify(SDL_SetNumberProperty(props,"SDL.window.create.width",320l))
            verify(SDL_SetNumberProperty(props,"SDL.window.create.height",240l))
            verify(SDL_SetBooleanProperty(props,"SDL.window.create.hidden",true))
            verify(SDL_SetBooleanProperty(props,"SDL.window.create.focusable",false))
            let raw=SDL_CreateWindowWithProperties(props)
            verify(raw!=null && window_title(raw)=="Properties window")
            verify(SDL_SetStringProperty(props,"SDL.window.create.title","Updated properties"))
            verify(window_title(raw)=="Properties window")
            SDL_DestroyWindow(raw)
            var owner_id=0u
            var child_id=0u
            let owned=with_window_properties(props) $(window) {
                owner_id=SDL_GetWindowID(window)
                verify(SDL_SetWindowPosition(window,SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED))
                verify(SDL_SetWindowSize(window,360,260) && SDL_SyncWindow(window))
                var w=0;var h=0
                verify(window_size(window,w,h) && w==360 && h==260)
                verify(!SDL_SetWindowSize(window,0,260))
                verify(SDL_SetWindowMinimumSize(window,100,80))
                verify(window_minimum_size(window,w,h) && w==100 && h==80)
                verify(SDL_SetWindowMaximumSize(window,800,600))
                verify(window_maximum_size(window,w,h) && w==800 && h==600)
                verify(SDL_SetWindowAspectRatio(window,1.0,2.0))
                var low=0.0;var high=0.0
                verify(window_aspect_ratio(window,low,high) && low==1.0 && high==2.0)
                verify(SDL_SetWindowAspectRatio(window,0.0,0.0))
                var rect : SDL_Rect
                verify(SDL_GetWindowSafeAreaRef(window,rect) && rect.w>0 && rect.h>0)
                var top=0;var left=0;var bottom=0;var right=0
                verify(SDL_GetWindowBordersSizeRef(window,top,left,bottom,right))
                unsafe {
                    verify(SDL_GetWindowMinimumSize(window,addr(w),addr(h)) && w==100)
                    verify(SDL_GetWindowMaximumSize(window,addr(w),addr(h)) && w==800)
                    verify(SDL_GetWindowAspectRatio(window,addr(low),addr(high)) && low==0.0 && high==0.0)
                    verify(SDL_GetWindowSafeArea(window,addr(rect)))
                    verify(SDL_GetWindowBordersSize(window,addr(top),addr(left),addr(bottom),addr(right)))
                }
                verify(SDL_SetWindowBordered(window,false))
                verify((SDL_GetWindowFlags(window)&SDL_WINDOW_BORDERLESS)!=0ul)
                verify(SDL_SetWindowBordered(window,true))
                verify(SDL_SetWindowResizable(window,true))
                verify((SDL_GetWindowFlags(window)&SDL_WINDOW_RESIZABLE)!=0ul)
                verify(SDL_SetWindowAlwaysOnTop(window,true))
                verify((SDL_GetWindowFlags(window)&SDL_WINDOW_ALWAYS_ON_TOP)!=0ul)
                verify(SDL_SetWindowAlwaysOnTop(window,false))
                verify(SDL_SetWindowOpacity(window,0.75) && SDL_GetWindowOpacity(window)==0.75)
                verify(SDL_SetWindowOpacity(window,1.0))
                verify(SDL_SetWindowFocusable(window,false))
                verify((SDL_GetWindowFlags(window)&SDL_WINDOW_NOT_FOCUSABLE)!=0ul)
                // Hidden-window state requests do not steal focus or maximize the desktop.
                verify(SDL_RaiseWindow(window))
                verify(SDL_MaximizeWindow(window))
                verify(SDL_MinimizeWindow(window))
                verify(SDL_RestoreWindow(window))
                verify(SDL_ShowWindow(window))
                verify((SDL_GetWindowFlags(window)&SDL_WINDOW_HIDDEN)==0ul)
                verify(SDL_HideWindow(window) && SDL_SyncWindow(window))
                let popup=with_popup_window(window,10,10,80,40,SDL_WINDOW_TOOLTIP|SDL_WINDOW_HIDDEN) $(child) {
                    child_id=SDL_GetWindowID(child)
                    verify(SDL_GetWindowParent(child)==window)
                    verify(!SDL_SetWindowParent(child,null))
                    verify(!SDL_SetWindowModal(child,true))
                    return
                }
                verify(popup && SDL_GetWindowFromID(child_id)==null)
                let child=SDL_CreateWindow("child",80,60,SDL_WINDOW_HIDDEN)
                verify(child!=null)
                verify(SDL_SetWindowParent(child,window) && SDL_GetWindowParent(child)==window)
                verify(SDL_SetWindowModal(child,true))
                verify(!SDL_SetWindowParent(child,null))
                verify(SDL_SetWindowModal(child,false))
                verify(SDL_SetWindowParent(child,null) && SDL_GetWindowParent(child)==null)
                SDL_DestroyWindow(child)
                return
            }
            verify(owned && SDL_GetWindowFromID(owner_id)==null)
            verify(SDL_SetBooleanProperty(props,"SDL.window.create.modal",true))
            var called=false
            let bad=with_window_properties(props) $(unused) {called=true}
            verify(!bad && !called)
        }
        verify(properties)
        var called=false
        let bad_popup=with_popup_window(null,0,0,10,10,SDL_WINDOW_TOOLTIP) $(unused) {called=true}
        verify(!bad_popup && !called)
        // Raw cascading ownership: destroy only the parent, then query by IDs.
        let parent=SDL_CreateWindow("cascade",120,80,SDL_WINDOW_HIDDEN)
        verify(parent!=null)
        let popup=SDL_CreatePopupWindow(parent,0,0,40,20,SDL_WINDOW_TOOLTIP|SDL_WINDOW_HIDDEN)
        verify(popup!=null)
        let id=SDL_GetWindowID(popup)
        let regular=SDL_CreateWindow("regular child",60,40,SDL_WINDOW_HIDDEN)
        verify(regular!=null && SDL_SetWindowParent(regular,parent))
        let regular_id=SDL_GetWindowID(regular)
        SDL_DestroyWindow(parent)
        verify(SDL_GetWindowFromID(id)==null && SDL_GetWindowFromID(regular_id)==null)
        verify(!SDL_SetWindowPosition(null,0,0) && !SDL_SetWindowFocusable(null,false))
        var all : array<SDL_Window?>
        verify(windows(all) && length(all)==0)
    }
    verify(initialized)
    return 0
}
