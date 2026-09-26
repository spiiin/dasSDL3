options gen2
require dassdl3/sdl3_image_boost
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_scope

def draw_images(renderer : SDL_Renderer?; png, svg : SDL_Texture?; smoke : bool) {
    let size = texture_size(png) |> sdl_try
    print("SDL_image {IMG_Version()}: PNG {size.x} x {size.y}; SVG loaded.\n")
    var running = true
    var frames = 0
    var event = SDL_MakeEvent()
    while (running) {
        while (is_some(poll_event(event))) {
            if (should_close(event)) { running = false }
        }
        if (!running) { break }
        renderer |> clear(uint4(40u, 50u, 65u, 255u)) |> sdl_try
        // Right half of the PNG is translucent; SVG is rasterized by SDL_image.
        renderer |> draw_texture(png, SDL_FRect(x = 40.0, y = 70.0, w = 256.0, h = 256.0)) |> sdl_try
        renderer |> draw_texture(svg, SDL_FRect(x = 344.0, y = 70.0, w = 256.0, h = 256.0)) |> sdl_try
        renderer |> present() |> sdl_try
        frames++
        if (smoke && frames == 3) { break }
        SDL_Delay(16u)
    }
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let assets = "{SDL_GetBasePath()}assets/libraries/"
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let flags = smoke ? SDL_WINDOW_HIDDEN : SDL_WINDOW_RESIZABLE
        let window : SDL_Window? = with_window("SDL_image: PNG alpha and SVG - Escape to exit", 640, 400, flags) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let png : SDL_Texture? = renderer |> with_image_texture("{assets}alpha.png") |> sdl_use
        let svg : SDL_Texture? = renderer |> with_image_texture("{assets}sample.svg") |> sdl_use
        return draw_images(renderer, png, svg, smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("SDL_image textures and SDL resources released.\n")
    return 0
}
