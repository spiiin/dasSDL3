options gen2
require dassdl3/sdl3_boost
require math

// Adapted from SDL release-3.2.18 examples/renderer/06-textures/textures.c
// (public domain). Uses our own BMP and explicit scoped ownership instead of callbacks.

def render_textures(renderer : SDL_Renderer?; texture : SDL_Texture?; smoke : bool; var frames : int&) : $Result<SdlUnit; SdlError> {
    return texture_size(texture) |> and_then() $(size : float2) {
        var event = SDL_MakeEvent()
        var running = true
        let start = SDL_GetTicks()
        while (running) {
            while (is_some(poll_event(event))) {
                if (should_close(event)) { running = false }
            }
            if (!running) { break }
            let phase = float(SDL_GetTicks() - start) / 1000.0
            let scale = 1.5 + 0.5 * sin(phase)
            var cleared <- renderer |> clear()
            if (is_err(cleared)) { return <- cleared }
            // Moving original, scaled copy, and a cropped quadrant.
            var original <- renderer |> draw_texture(texture, SDL_MakeFRect(30.0 + 20.0 * sin(phase), 30.0, size.x, size.y))
            if (is_err(original)) { return <- original }
            var scaled <- renderer |> draw_texture(texture, SDL_MakeFRect(220.0, 150.0, size.x * scale, size.y * scale))
            if (is_err(scaled)) { return <- scaled }
            let crop = SDL_MakeFRect(0.0, 0.0, size.x / 2.0, size.y / 2.0)
            var cropped <- renderer |> draw_texture(texture, crop, SDL_MakeFRect(480.0, 330.0, 128.0, 128.0))
            if (is_err(cropped)) { return <- cropped }
            var presented <- renderer |> present()
            if (is_err(presented)) { return <- presented }
            frames++
            if (smoke && frames >= 60) { break }
            SDL_Delay(16u)
        }

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    var frames = 0
    let result = with_sdl() {
        let flags = smoke ? SDL_WINDOW_HIDDEN : 0ul
        return with_window("dasSDL3 textures - Escape to exit", 640, 480, flags) $(window : SDL_Window?) {
            return window |> with_renderer() $(renderer : SDL_Renderer?) {
                return renderer |> with_texture("{SDL_GetBasePath()}assets/checker.bmp") $(texture : SDL_Texture?) {
                    return render_textures(renderer, texture, smoke, frames)
                }
            }
        }
    }
    if (is_err(result)) {
        let error=unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Textures: rendered {frames} frames; resources released.\n")
    return 0
}
