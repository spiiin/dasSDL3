options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_geometry_boost
require math

// Adapted scenario: SDL 3.2.18 examples/renderer/10-geometry/geometry.c (public domain).
// Own checker BMP, PollEvent loop and resource scopes; all arrays belong to script.

def render_geometry(window : SDL_Window?; renderer : SDL_Renderer?; texture : SDL_Texture?; smoke : bool; var frames : int&) : SdlStatus {
    var triangle : array<SDL_Vertex>
    triangle |> resize(3)
    let white = float4(1.0)
    var quad <- array(
        vertex(float2(420.0, 170.0), white, float2(0.0, 0.0)),
        vertex(float2(600.0, 170.0), white, float2(1.0, 0.0)),
        vertex(float2(420.0, 350.0), white, float2(0.0, 1.0)),
        vertex(float2(600.0, 350.0), white, float2(1.0, 1.0))
    )
    let indices <- array<int>(0, 1, 2, 2, 1, 3)
    var event = SDL_MakeEvent()
    var running = true
    while (running) {
        while (is_some(poll_event(event))) {
            if (should_close(event, window)) { running = false }
        }
        if (!running) { break }
        let size = 110.0 + 30.0 * sin(float(frames) / 30.0)
        triangle[0] = vertex(float2(210.0, 240.0 - size), float4(1.0, 0.0, 0.0, 1.0))
        triangle[1] = vertex(float2(210.0 + size, 240.0 + size), float4(0.0, 1.0, 0.0, 1.0))
        triangle[2] = vertex(float2(210.0 - size, 240.0 + size), float4(0.0, 0.0, 1.0, 1.0))
        renderer |> clear() |> sdl_try
        renderer |> draw_geometry(triangle) |> sdl_try
        renderer |> draw_geometry(quad, indices, texture) |> sdl_try
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
        let window : SDL_Window? = with_window("Geometry: vertices + indices - Escape to exit", 640, 480, smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        let texture : SDL_Texture? = renderer |> with_texture("{SDL_GetBasePath()}assets/checker.bmp") |> sdl_use
        return render_geometry(window, renderer, texture, smoke, frames)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Geometry: {frames} frames; colored triangle and indexed textured quad.\n")
    return 0
}
