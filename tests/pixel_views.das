options gen2
require dassdl3/sdl3_pixel_views
require dassdl3/sdl3_scope

[export]
def main(smoke : bool) : int {
    let result=sdl_scope() {
        with_sdl() |> sdl_use
        let surface : SDL_Surface? = with_surface(4,4,SDL_PixelFormat.PIXELFORMAT_RGBA32) |> sdl_use
        with_surface_pixels_rgba8(surface) $(pixels) {
            set_pixel(pixels,0,0,uint4(1u,2u,3u,255u)) |> sdl_try
            return sdl_ok()
        } |> sdl_try
        let renderer : SDL_Renderer? = with_software_renderer(surface) |> sdl_use
        let texture : SDL_Texture? = with_streaming_texture(renderer,4,4) |> sdl_use
        let rect=SDL_Rect(w=4,h=4)
        with_texture_pixels_rgba8(texture,rect) $(pixels) {
            verify(pixels.width==4 && pixels.height==4 && pixels.pitch>=16)
            for(y in 0 .. pixels.height) {
                with_row(pixels,y) $(var row : array<uint>#) {
                    verify(length(row)==4)
                    for(x in 0 .. length(row)) { row[x]=rgba8(uint(x),uint(y),180u,255u) }
                    return sdl_ok()
                } |> sdl_try
            }
            set_pixel(pixels,1,2,uint4(20u,40u,60u,255u)) |> sdl_try
            verify(is_err(set_pixel(pixels,4,0,uint4(0u))))
            verify(is_err(set_pixel(pixels,0,0,uint4(256u))))
            var called=false
            let invalid=with_row(pixels,-1) $(var row : array<uint>#) { called=true;return sdl_ok() }
            verify(is_err(invalid) && !called)
            with_pixels(pixels) $(var bytes : array<uint8>#) {
                verify(bytes[0]==uint8(0) && bytes[2]==uint8(180) && bytes[3]==uint8(255))
                verify(bytes[2*pixels.pitch+4]==uint8(20))
                return sdl_ok()
            } |> sdl_try
            return sdl_ok()
        } |> sdl_try
        draw_texture(renderer,texture) |> sdl_try
        verify(SDL_FlushRenderer(renderer))
        var image : array<uint8>;resize(image,64)
        copy_surface_rgba8(surface,image,16) |> sdl_try
        verify(image[36]==uint8(20) && image[37]==uint8(40) && image[38]==uint8(60))
        // A narrow subrectangle keeps the full texture pitch, not width*4.
        with_texture_pixels_rgba8(texture,SDL_Rect(x=1,y=1,w=2,h=2)) $(pixels) {
            verify(pixels.width==2 && pixels.height==2 && pixels.pitch>=8)
            for(y in 0 .. 2) {
                with_row(pixels,y) $(var row : array<uint>#) {
                    for(x in 0 .. 2) { row[x]=rgba8(90u,uint(y),uint(x),255u) }
                    return sdl_ok()
                } |> sdl_try
            }
            with_pixels(pixels) $(var bytes : array<uint8>#) {
                verify(length(bytes)==pixels.pitch+8 && bytes[pixels.pitch+1]==uint8(1))
                return sdl_ok()
            } |> sdl_try
            return sdl_ok()
        } |> sdl_try
        draw_texture(renderer,texture) |> sdl_try
        verify(SDL_FlushRenderer(renderer))
        copy_surface_rgba8(surface,image,16) |> sdl_try
        verify(image[20]==uint8(90) && image[41]==uint8(1) && image[42]==uint8(1))
        // The body error survives unlock; a second lock proves early-return cleanup.
        let failure=with_texture_pixels_rgba8(texture,rect) $(pixels) {
            return err(SdlError(operation="body",message="kept"),type<SdlUnit>)
        }
        verify(is_err(failure) && unwrap_err(failure).operation=="body")
        with_texture_pixels_rgba8(texture,rect) $(pixels) { return sdl_ok() } |> sdl_try
        return sdl_ok()
    }
    if(is_err(result)) { print("{unwrap_err(result).message}\n");return 1 }
    print("Pixel views: row/byte access, bounds, packing and unlock PASS\n")
    return 0
}
