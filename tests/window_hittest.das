options gen2
require dassdl3/sdl3_rect_clipboard_boost
[export]
def main(smoke : bool) : int {
    SDLTestCallbacksReset()
    let initialized=with_sdl() {
        let window=SDL_CreateWindow("hit test",160,100,SDL_WINDOW_HIDDEN | SDL_WINDOW_BORDERLESS);verify(window!=null)
        verify(SDL_SetWindowHitTest(window,SDLTestHitCallback(),null))
        verify(SDLTestWindowHit(window,20,20)==2l && SDLTestWindowHit(window,5,20)==10l && SDLTestHitCount()>=2)
        verify(SDL_SetWindowHitTest(window,null,null))
        var calls=0
        let scoped=with_window_hit_test(window,$(win,x,y) : SDL_HitTestResult {
            verify(win==window);calls++
            return x<10 ? SDL_HitTestResult.HITTEST_RESIZE_LEFT : SDL_HitTestResult.HITTEST_DRAGGABLE
        }) {
            verify(SDLTestWindowHit(window,20,20)==2l && SDLTestWindowHit(window,5,20)==10l)
            var entered=false
            let nested=with_window_hit_test(window,$(win,x,y) : SDL_HitTestResult {return SDL_HitTestResult.HITTEST_NORMAL}) {entered=true
                return sdl_ok()
            } |> is_ok
            verify(!nested)
            verify(!entered);return sdl_ok()
        } |> is_ok
        verify(scoped && calls>=2)
        let previous=calls;SDLTestWindowHit(window,20,20);verify(calls==previous)
        let destroyed=with_window_hit_test(window,$(win,x,y) : SDL_HitTestResult {return SDL_HitTestResult.HITTEST_NORMAL}) {SDL_DestroyWindow(window)
            return sdl_ok()
        } |> is_ok
        verify(destroyed)
        var entered=false
        let invalid=with_window_hit_test(null,$(win,x,y) : SDL_HitTestResult {return SDL_HitTestResult.HITTEST_NORMAL}) {entered=true
            return sdl_ok()
        } |> is_ok
        verify(!invalid)
        verify(!entered)

        return sdl_ok()
    } |> is_ok
    verify(initialized)
    print("Window hit test: native and script callbacks, unregister, nesting and window destruction passed\n")
    return 0
}
