options gen2
require dassdl3/sdl3_image_boost
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_scope
require dassdl3/sdl3_pixels_boost
require dassdl3/sdl3_iostream_boost
require daslib/defer
require math

def check_png(surface : SDL_Surface?) {
    let size = surface_size(surface) |> sdl_try
    verify(size == int2(32, 32))
    var bytes : array<uint8>
    resize(bytes, 4096)
    copy_surface_rgba8(surface, bytes, 128) |> sdl_try
    for (y in 0 .. 32) {
        for (x in 0 .. 32) {
            let expected = x < 16 ? uint4(220u, 40u, 70u, 255u) : uint4(30u, 190u, 240u, 96u)
            let i = (y * 32 + x) * 4
            verify(uint4(uint(bytes[i]), uint(bytes[i + 1]), uint(bytes[i + 2]), uint(bytes[i + 3])) == expected)
        }
    }
    return sdl_ok()
}

def check_jpg(surface : SDL_Surface?) {
    let size = surface_size(surface) |> sdl_try
    verify(size == int2(32, 32))
    var bytes : array<uint8>
    resize(bytes, 4096)
    copy_surface_rgba8(surface, bytes, 128) |> sdl_try
    let i = (8 * 32 + 8) * 4
    verify(abs(int(bytes[i]) - 220) <= 8 && abs(int(bytes[i + 1]) - 40) <= 8 && abs(int(bytes[i + 2]) - 70) <= 8)
    verify(bytes[i + 3] == uint8(255))// JPEG has no alpha.
    return sdl_ok()
}

def test_images(renderer : SDL_Renderer?; assets : string) {
    var called = false
    let missing = with_image("{assets}missing.png") $(surface : SDL_Surface?) {
        called = true
        return sdl_ok()
    }
    verify(is_err(missing) && !called)
    let saved_error = unwrap_err(missing)
    SDL_ClearError()
    verify(saved_error.operation == "IMG_Load" && saved_error.message != "")
    verify(is_err(load_image("{assets}invalid.bin")))
    SDL_SetErrorMessage("stale error")
    with_image("{assets}alpha.png") $(surface : SDL_Surface?) { return check_png(surface) } |> sdl_try

    // Borrowed IO remains usable after sniffing, success and failure.
    with_io_file("{assets}alpha.png", "rb") $(io : SDL_IOStream?) {
        let before = SDL_TellIO(io)
        verify(IMG_isPNG(io) && !IMG_isJPG(io) && SDL_TellIO(io) == before)
        with_image(io) $(surface : SDL_Surface?) { return check_png(surface) } |> sdl_try
        verify(SDL_SeekIO(io, 0l, SDL_IOWhence.IO_SEEK_SET) == 0l)
        var typed <- load_image(io, "PNG") |> sdl_try
        { defer() { SDL_DestroySurface(typed) }; check_png(typed) |> sdl_try }
        return sdl_ok()
    } |> sdl_try
    with_io_file("{assets}invalid.bin", "rb") $(io : SDL_IOStream?) {
        verify(is_err(load_image(io)))
        verify(SDL_TellIO(io) >= 0l)
        return sdl_ok()
    } |> sdl_try

    with_image("{assets}alpha.png") $(surface : SDL_Surface?) {
        let png = "{SDL_GetBasePath()}image-{SDL_GetTicksNS()}.png"
        let jpg = "{SDL_GetBasePath()}image-{SDL_GetTicksNS()}.jpg"
        defer() { SDL_RemovePath(png); SDL_RemovePath(jpg) }
        surface |> save_image_png(png) |> sdl_try
        surface |> save_image_jpg(jpg, 95) |> sdl_try
        with_image(png) $(loaded : SDL_Surface?) { return check_png(loaded) } |> sdl_try
        with_image(jpg) $(loaded : SDL_Surface?) { return check_jpg(loaded) } |> sdl_try
        with_io_dynamic() $(io : SDL_IOStream?) {
            surface |> save_image_png(io) |> sdl_try
            verify(SDL_SeekIO(io, 0l, SDL_IOWhence.IO_SEEK_SET) == 0l)
            with_image(io) $(loaded : SDL_Surface?) { return check_png(loaded) } |> sdl_try
            return sdl_ok()
        } |> sdl_try
        with_io_dynamic() $(io : SDL_IOStream?) {
            surface |> save_image_jpg(io, 95) |> sdl_try
            verify(SDL_SeekIO(io, 0l, SDL_IOWhence.IO_SEEK_SET) == 0l)
            with_image(io) $(loaded : SDL_Surface?) { return check_jpg(loaded) } |> sdl_try
            return sdl_ok()
        } |> sdl_try
        return sdl_ok()
    } |> sdl_try

    renderer |> with_image_texture("{assets}alpha.png") $(texture : SDL_Texture?) {
        verify(texture_size(texture) |> unwrap == float2(32.0, 32.0))
        renderer |> clear(uint4(0u, 0u, 0u, 255u)) |> sdl_try
        renderer |> draw_texture(texture, SDL_FRect(w = 32.0, h = 32.0)) |> sdl_try
        return renderer |> with_read_pixels() $(surface : SDL_Surface?) {
            var bytes : array<uint8>
            resize(bytes, 64 * 64 * 4)
            copy_surface_rgba8(surface, bytes, 64 * 4) |> sdl_try
            let opaque = (8 * 64 + 8) * 4
            let alpha = (8 * 64 + 24) * 4
            verify(bytes[opaque] == uint8(220))
            verify(abs(int(bytes[alpha]) - 11) <= 1 && abs(int(bytes[alpha + 1]) - 71) <= 1)
            return sdl_ok()
        }
    } |> sdl_try
    with_io_file("{assets}alpha.png", "rb") $(io : SDL_IOStream?) {
        return renderer |> with_image_texture(io) $(texture : SDL_Texture?) {
            verify(texture_size(texture) |> unwrap == float2(32.0, 32.0))
            return sdl_ok()
        }
    } |> sdl_try

    with_image_animation("{assets}two_frames.gif") $(animation : IMG_Animation?) {
        verify(image_animation_delay(animation, 0) |> unwrap == 50)
        verify(image_animation_delay(animation, 1) |> unwrap == 90)
        verify(is_err(image_animation_frame(animation, -1)) && is_err(image_animation_frame(animation, 2)))
        for (i in 0 .. 2) {
            var frame <- image_animation_frame(animation, i) |> sdl_try
            var bytes : array<uint8>
            resize(bytes, 4)
            copy_surface_rgba8(frame, bytes, 4) |> sdl_try
            verify(bytes[i] == uint8(255) && bytes[1 - i] == uint8(0))
        }
        return sdl_ok()
    } |> sdl_try
    with_io_file("{assets}two_frames.gif", "rb") $(io : SDL_IOStream?) {
        return with_image_animation(io) $(animation : IMG_Animation?) {
            verify(image_animation_delay(animation, 1) |> unwrap == 90)
            return sdl_ok()
        }
    } |> sdl_try
    let early = with_image("{assets}alpha.png") $(surface : SDL_Surface?) {
        return err(SdlError(operation = "body", message = "keep"), type<SdlUnit>)
    }
    verify(is_err(early) && unwrap_err(early).operation == "body")
    verify(is_err(image_animation_delay(null, 0)))
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    verify(IMG_Version() == 3002004)
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("SDL_image tests", 64, 64, SDL_WINDOW_HIDDEN) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        return test_images(renderer, "{SDL_GetBasePath()}assets/libraries/")
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("SDL_image: PNG pixels/alpha, JPEG, IO, GIF frames, errors and scopes passed.\n")
    return 0
}
