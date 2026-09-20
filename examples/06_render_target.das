options gen2
require dassdl3/sdl3_pixels_boost

// Project example: offscreen render -> owned readback -> display the target.

def render_target_example(window : SDL_Window?; renderer : SDL_Renderer?; target : SDL_Texture?; smoke : bool; var frames : int&) : $Result<SdlUnit; SdlError> {
    let render_target_result = renderer |> with_render_target(target) {
        return paint_target(renderer)
    }
    if (is_err(render_target_result)) { return render_target_result }
    var event = SDL_MakeEvent()
    var running = true
    while (running) {
        while (is_some(poll_event(event))) {
            if (should_close(event, window)) { running = false }
        }
        if (!running) { break }
        var clear_result_2 <- renderer |> clear()
        if (is_err(clear_result_2)) { return clear_result_2 }
        var draw_texture_result <- renderer |> draw_texture(target, SDL_MakeFRect(192.0, 112.0, 256.0, 256.0))
        if (is_err(draw_texture_result)) { return draw_texture_result }
        var present_result <- renderer |> present()
        if (is_err(present_result)) { return present_result }
        frames++
        if (smoke && frames >= 60) { break }
        SDL_Delay(16u)
    }

    return sdl_ok()
}

def verify_readback(surface : SDL_Surface?) : $Result<SdlUnit; SdlError> {
    let surface_size_result = surface_size(surface)
    if (is_err(surface_size_result)) { return err(unwrap_err(surface_size_result),type<SdlUnit>) }
    let size = unwrap(surface_size_result)
    var bytes : array<uint8>
    bytes |> resize(unwrap_or(rgba8_buffer_size(size.x, size.y, size.x * 4), -1))
    var copy_surface_rgba8_result <- surface |> copy_surface_rgba8(bytes, size.x * 4)
    if (is_err(copy_surface_rgba8_result)) { return copy_surface_rgba8_result }
    verify(bytes[0] == uint8(20) && bytes[1] == uint8(40) && bytes[2] == uint8(80))
    print("Readback: {size.x} x {size.y}, RGBA copy verified.\n")

    return sdl_ok()
}

def paint_target(renderer : SDL_Renderer?) : $Result<SdlUnit; SdlError> {
    var clear_result <- renderer |> clear(uint4(20u, 40u, 80u, 255u))
    if (is_err(clear_result)) { return clear_result }
    var set_color_result <- renderer |> set_color(uint4(255u, 160u, 20u, 255u))
    if (is_err(set_color_result)) { return set_color_result }
    var fill_rect_result <- renderer |> fill_rect(SDL_MakeFRect(32.0, 32.0, 64.0, 64.0))
    if (is_err(fill_rect_result)) { return fill_rect_result }
    // Readback is expensive: do it once, not on every frame.
    return renderer |> with_read_pixels() $(surface : SDL_Surface?) {
        return verify_readback(surface)
    }
}

[export]
def main(smoke : bool) : int {
    var frames = 0
    let result = with_sdl() {
        return with_window("Render target + readback - Escape to exit", 640, 480,
                    smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?) {
            return window |> with_renderer() $(renderer : SDL_Renderer?) {
                return renderer |> with_target_texture(128, 128) $(target : SDL_Texture?) {
                    return render_target_example(window, renderer, target, smoke, frames)
                }
            }
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Render target: {frames} frames; previous target restored, resources released.\n")
    return 0
}
