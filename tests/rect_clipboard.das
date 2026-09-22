options gen2
require dassdl3/sdl3_rect_clipboard_boost

def rectangles {
    var a,b,out : SDL_Rect;a.x=0;a.y=0;a.w=10;a.h=10;b.x=5;b.y=5;b.w=10;b.h=10
    var p = SDL_Point(x = 9, y = 9)
    var fa,fb,fo : SDL_FRect;var fp : SDL_FPoint
    unsafe {
        SDL_RectToFRect(addr(a),addr(fa));verify(fa.w==10.0)
        verify(SDL_PointInRect(addr(p),addr(a)) && !SDL_RectEmpty(addr(a)) && SDL_RectsEqual(addr(a),addr(a)))
        p.x=10;verify(!SDL_PointInRect(addr(p),addr(a)))
        verify(SDL_HasRectIntersection(addr(a),addr(b)) && SDL_GetRectIntersection(addr(a),addr(b),addr(out)))
        verify(out.x==5 && out.y==5 && out.w==5 && out.h==5)
        verify(SDL_GetRectUnion(addr(a),addr(b),addr(out)) && out.w==15 && out.h==15)
        var x1=-5;var y1=5;var x2=20;var y2=5
        verify(SDL_GetRectAndLineIntersection(addr(a),addr(x1),addr(y1),addr(x2),addr(y2)) && x1==0 && x2==9 && y1==5 && y2==5)
        var points : array<SDL_Point>;resize(points,3);points[0].x=2;points[0].y=3;points[1].x=8;points[1].y=7;points[2].x=20;points[2].y=20
        verify(SDL_GetRectEnclosingPoints(addr(points[0]),3,addr(a),addr(out)) && out.x==2 && out.y==3 && out.w==7 && out.h==5)
        verify(SDL_GetRectEnclosingPointsArray(points,a,out) && out.w==7)
        verify(SDL_GetRectEnclosingPointsAll(points,out) && out.w==19 && out.h==18)
        fb.x=5.0;fb.y=5.0;fb.w=10.0;fb.h=10.0;fp.x=10.0;fp.y=10.0
        verify(SDL_PointInRectFloat(addr(fp),addr(fa)) && !SDL_RectEmptyFloat(addr(fa)))
        verify(SDL_RectsEqualFloat(addr(fa),addr(fa)) && SDL_RectsEqualEpsilon(addr(fa),addr(fa),0.001))
        verify(SDL_HasRectIntersectionFloat(addr(fa),addr(fb)) && SDL_GetRectIntersectionFloat(addr(fa),addr(fb),addr(fo)) && fo.w==5.0)
        verify(SDL_GetRectUnionFloat(addr(fa),addr(fb),addr(fo)) && fo.w==15.0)
        var fx1=-5.0;var fy1=5.0;var fx2=20.0;var fy2=5.0
        verify(SDL_GetRectAndLineIntersectionFloat(addr(fa),addr(fx1),addr(fy1),addr(fx2),addr(fy2)) && fx1==0.0 && fx2==10.0)
        var fpoints : array<SDL_FPoint>;resize(fpoints,3);fpoints[0].x=2.0;fpoints[0].y=3.0;fpoints[1].x=8.0;fpoints[1].y=7.0;fpoints[2].x=20.0;fpoints[2].y=20.0
        verify(SDL_GetRectEnclosingPointsFloat(addr(fpoints[0]),3,addr(fa),addr(fo)) && fo.w==6.0 && fo.h==4.0)
        verify(SDL_GetRectEnclosingPointsFloatArray(fpoints,fa,fo) && fo.w==6.0)
        verify(SDL_GetRectEnclosingPointsFloatAll(fpoints,fo) && fo.w==18.0)
        verify(SDL_GetRectAndLineIntersectionRefs(a,x1,y1,x2,y2))
        verify(SDL_GetRectAndLineIntersectionFloatRefs(fa,fx1,fy1,fx2,fy2))
        resize(points,0);verify(!SDL_GetRectEnclosingPointsAll(points,out))
    }
    SDL_RectToFRectRef(a,fo);verify(fo.w==10.0)
    verify(SDL_PointInRectFloatRefs(fp,fa) && !SDL_RectEmptyFloatRef(fa) && SDL_RectsEqualFloatRefs(fa,fa) && SDL_RectsEqualEpsilonRefs(fa,fa,0.01))
    verify(SDL_HasRectIntersectionFloatRefs(fa,fb) && SDL_GetRectIntersectionFloatRefs(fa,fb,fo) && fo.w==5.0)
    verify(SDL_GetRectUnionFloatRefs(fa,fb,fo) && fo.w==15.0)
    p.x=9;verify(SDL_PointInRectRefs(p,a) && !SDL_RectEmptyRef(a) && SDL_RectsEqualRefs(a,a))
    verify(SDL_HasRectIntersectionRefs(a,b) && SDL_GetRectIntersectionRefs(a,b,out) && out.w==5)
    verify(SDL_GetRectUnionRefs(a,b,out) && out.w==15)
    b.x=10;verify(!SDL_HasRectIntersectionRefs(a,b))
    a.w=0;verify(SDL_RectEmptyRef(a));fa.w=-1.0;verify(SDL_RectEmptyFloatRef(fa))
}
[export]
def main(smoke : bool) : int {
    rectangles()
    let initialized=with_sdl() {
        verify(SDL_SetClipboardText("SDL UTF-8: привет"))
        verify(SDL_HasClipboardText() && unwrap_or(clipboard_text(), "")=="SDL UTF-8: привет")
        unsafe {let text=SDL_GetClipboardText();verify(text=="SDL UTF-8: привет");SDL_free(reinterpret<void?>(text))}
        verify(SDL_SetPrimarySelectionText("selection") && SDL_HasPrimarySelectionText() && unwrap_or(primary_selection_text(), "")=="selection")
        unsafe {let text=SDL_GetPrimarySelectionText();verify(text=="selection");SDL_free(reinterpret<void?>(text))}
        var bytes : array<uint8>;resize(bytes,3);bytes[0]=uint8(1);bytes[1]=uint8(0);bytes[2]=uint8(255)
        verify(is_ok(set_clipboard_data("application/x-dassdl3-test",bytes)));bytes[0]=uint8(99)
        verify(SDL_HasClipboardData("application/x-dassdl3-test"))
        var copied : array<uint8>;verify(is_ok(clipboard_data("application/x-dassdl3-test",copied)) && length(copied)==3 && copied[0]==uint8(1) && copied[2]==uint8(255))
        unsafe {
            var size : uint64;let raw=SDL_GetClipboardData("application/x-dassdl3-test",addr(size));verify(raw!=null && size==3ul);SDL_free(raw)
            var count : uint64;let names=SDL_GetClipboardMimeTypes(addr(count));verify(names!=null && count==1ul && names[0]=="application/x-dassdl3-test");SDL_free(names)
        }
        var names : array<string>;verify(is_ok(clipboard_mime_types(names)) && length(names)==1 && names[0]=="application/x-dassdl3-test")
        verify(SDL_SetClipboardText("replacement") && unwrap_or(clipboard_text(), "")=="replacement")
        verify(copied[0]==uint8(1) && names[0]=="application/x-dassdl3-test")
        verify(SDL_ClearClipboardData() && !SDL_HasClipboardData("application/x-dassdl3-test"))
        verify(SDL_SetClipboardData(null,null,null,null,0ul))
        verify(!is_ok(set_clipboard_data("",bytes)))

        return sdl_ok()
    } |> is_ok
    verify(initialized)
    print("Rect and Clipboard: native/ref geometry, UTF-8 and copied binary ownership passed\n")
    return 0
}
