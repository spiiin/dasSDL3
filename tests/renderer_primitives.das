options gen2
require dassdl3/sdl3_renderer_primitives_boost

def reset_image(renderer : SDL_Renderer?) {
    verify(SDL_SetRenderDrawColor(renderer,0u,0u,0u,255u) && SDL_RenderClear(renderer))
    verify(SDL_SetRenderDrawColor(renderer,230u,40u,20u,255u))
}
def check_pixel(renderer : SDL_Renderer?; surface : SDL_Surface?; x,y : int) {
    verify(SDL_FlushRenderer(renderer))
    var bytes : array<uint8>;resize(bytes,16*16*4)
    verify(is_ok(copy_surface_rgba8(surface,bytes,16*4)))
    let i=(y*16+x)*4
    verify(bytes[i]==uint8(230) && bytes[i+1]==uint8(40) && bytes[i+2]==uint8(20))
    verify(bytes[0]==uint8(0))
}
[export]
def main(smoke : bool) : int {
    var called=false
    verify(!with_software_renderer(null) $(renderer : SDL_Renderer?) {called=true
        return sdl_ok()
    } |> is_ok)
    verify(!called)
    let initialized=with_sdl() {
        let allocated=with_surface(16,16,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface : SDL_Surface?) {
            let scoped=with_software_renderer(surface) $(renderer : SDL_Renderer?) {
                verify(SDL_GetRenderWindow(renderer)==null)
                var points : array<SDL_FPoint>;resize(points,2)
                points[0].x=2.0;points[0].y=2.0;points[1].x=6.0;points[1].y=2.0
                var rects : array<SDL_FRect>;resize(rects,1)
                rects[0].x=2.0;rects[0].y=2.0;rects[0].w=5.0;rects[0].h=5.0
                reset_image(renderer);verify(SDL_RenderPoint(renderer,2.0,2.0));check_pixel(renderer,surface,2,2)
                reset_image(renderer);verify(SDL_RenderLine(renderer,2.0,2.0,6.0,2.0));check_pixel(renderer,surface,4,2)
                reset_image(renderer);verify(SDL_RenderRectRef(renderer,rects[0]));check_pixel(renderer,surface,2,4)
                reset_image(renderer)
                unsafe {verify(SDL_RenderPoints(renderer,addr(points[0]),length(points)))}
                check_pixel(renderer,surface,6,2)
                reset_image(renderer);verify(SDL_RenderPointsArray(renderer,points));check_pixel(renderer,surface,6,2)
                reset_image(renderer)
                unsafe {verify(SDL_RenderLines(renderer,addr(points[0]),length(points)))}
                check_pixel(renderer,surface,4,2)
                reset_image(renderer);verify(SDL_RenderLinesArray(renderer,points));check_pixel(renderer,surface,4,2)
                reset_image(renderer)
                unsafe {verify(SDL_RenderRects(renderer,addr(rects[0]),length(rects)))}
                check_pixel(renderer,surface,2,4)
                reset_image(renderer);verify(SDL_RenderRectsArray(renderer,rects));check_pixel(renderer,surface,2,4)
                reset_image(renderer)
                unsafe {verify(SDL_RenderFillRects(renderer,addr(rects[0]),length(rects)))}
                check_pixel(renderer,surface,4,4)
                reset_image(renderer);verify(SDL_RenderFillRectsArray(renderer,rects));check_pixel(renderer,surface,4,4)
                reset_image(renderer)
                unsafe {verify(SDL_RenderRect(renderer,addr(rects[0])))}
                check_pixel(renderer,surface,2,4)
                // Empty arrays retain SDL's no-op result, without indexing their storage.
                var empty_points : array<SDL_FPoint>;var empty_rects : array<SDL_FRect>
                verify(SDL_RenderPointsArray(renderer,empty_points) && SDL_RenderLinesArray(renderer,empty_points))
                verify(SDL_RenderRectsArray(renderer,empty_rects) && SDL_RenderFillRectsArray(renderer,empty_rects))

                return sdl_ok()
            } |> is_ok
            verify(scoped)
            // Renderer destruction leaves its caller-owned surface alive; early return too.
            verify(with_software_renderer(surface) $(renderer : SDL_Renderer?) {return sdl_ok()} |> is_ok)
            verify(SDL_FillSurfaceAll(surface,SDL_MapSurfaceRGBA(surface,1u,2u,3u,255u)))

            return sdl_ok()
        } |> is_ok
        verify(allocated)
        verify(with_window("renderer association",16,16,SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            verify(with_renderer(window) $(renderer : SDL_Renderer?) {verify(SDL_GetRenderWindow(renderer)==window)
                return sdl_ok()
            } |> is_ok)

            return sdl_ok()
        } |> is_ok)

        return sdl_ok()
    } |> is_ok
    verify(initialized)
    verify(!SDL_RenderPoint(null,0.0,0.0))
    print("renderer primitives: pixels and ownership passed\n")
    return 0
}
