options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_pixels_boost

// Scenario adapted from SDL release-3.2.18 examples/renderer/07-streaming-textures
// (public domain). Own RGBA staging array replaces the borrowed locked surface.

def render_streaming(window : SDL_Window?; renderer : SDL_Renderer?; texture : SDL_Texture?; smoke : bool; var frames : int&) : SdlStatus {
    var pixels : array<uint8>
    let byte_count = rgba8_buffer_size(150, 150, 600) |> sdl_try
    pixels |> resize(byte_count)
    var event = SDL_MakeEvent()
    var running = true
    while (running) {
        while (is_some(poll_event(event))) {
            if (should_close(event, window)) { running = false }
        }
        if (!running) { break }
        let band = (frames * 2) % 135
        for (pixel in 0 .. 22500) {
            let y = pixel / 150
            let i = pixel * 4
            pixels[i] = uint8(0)
            pixels[i+1] = uint8(y >= band && y < band + 15 ? 255 : 0)
            pixels[i+2] = uint8(0)
            pixels[i+3] = uint8(255)
        }
        texture |> upload_rgba8(pixels, 600) |> sdl_try
        renderer |> clear(uint4(66u, 66u, 66u, 255u)) |> sdl_try
        renderer |> draw_texture(texture, SDL_MakeFRect(245.0, 165.0, 150.0, 150.0)) |> sdl_try
        renderer |> present() |> sdl_try
        frames++
        if (smoke && frames >= 60) { break }
        SDL_Delay(16u)
    }

    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    var frames = 0
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("Streaming RGBA - Escape to exit",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let texture : SDL_Texture? = renderer |> with_streaming_texture(150, 150) |> sdl_use
        return render_streaming(window, renderer, texture, smoke, frames)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Streaming texture: {frames} frames; staging array and texture released.\n")
    return 0
}
