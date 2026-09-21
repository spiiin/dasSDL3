options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_pixels_boost

// Project example: offscreen render -> owned readback -> display the target.

def render_target_example(window : SDL_Window?; renderer : SDL_Renderer?; target : SDL_Texture?; smoke : bool; var frames : int&) : $Result<SdlUnit; SdlError> {
    sdl_scope() {
        renderer |> with_render_target(target) |> sdl_use
        return paint_target(renderer)
    } |> sdl_try
    var event = SDL_MakeEvent()
    var running = true
    while (running) {
        while (is_some(poll_event(event))) {
            if (should_close(event, window)) { running = false }
        }
        if (!running) { break }
        renderer |> clear() |> sdl_try
        renderer |> draw_texture(target, SDL_MakeFRect(192.0, 112.0, 256.0, 256.0)) |> sdl_try
        renderer |> present() |> sdl_try
        frames++
        if (smoke && frames >= 60) { break }
        SDL_Delay(16u)
    }

    return sdl_ok()
}

def verify_readback(surface : SDL_Surface?) : $Result<SdlUnit; SdlError> {
    let size = surface_size(surface) |> sdl_try
    var bytes : array<uint8>
    let byte_count = rgba8_buffer_size(size.x, size.y, size.x * 4) |> sdl_try
    bytes |> resize(byte_count)
    surface |> copy_surface_rgba8(bytes, size.x * 4) |> sdl_try
    verify(bytes[0] == uint8(20) && bytes[1] == uint8(40) && bytes[2] == uint8(80))
    print("Readback: {size.x} x {size.y}, RGBA copy verified.\n")

    return sdl_ok()
}

def paint_target(renderer : SDL_Renderer?) : $Result<SdlUnit; SdlError> {
    renderer |> clear(uint4(20u, 40u, 80u, 255u)) |> sdl_try
    renderer |> set_color(uint4(255u, 160u, 20u, 255u)) |> sdl_try
    renderer |> fill_rect(SDL_MakeFRect(32.0, 32.0, 64.0, 64.0)) |> sdl_try
    // Readback is expensive: do it once, not on every frame.
    return sdl_scope() {
        let surface : SDL_Surface? = renderer |> with_read_pixels() |> sdl_use
        return verify_readback(surface)
    }
}

[export]
def main(smoke : bool) : int {
    var frames = 0
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("Render target + readback - Escape to exit",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let target : SDL_Texture? = renderer |> with_target_texture(128, 128) |> sdl_use
        return render_target_example(window, renderer, target, smoke, frames)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Render target: {frames} frames; previous target restored, resources released.\n")
    return 0
}
