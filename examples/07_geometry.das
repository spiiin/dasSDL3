options gen2
require dassdl3/sdl3_geometry_boost
require math

// Adapted scenario: SDL 3.2.18 examples/renderer/10-geometry/geometry.c (public domain).
// Own checker BMP, PollEvent loop and resource scopes; all arrays belong to script.
[export]
def main(smoke : bool) : int {
    var frames = 0
    with_sdl() {
        with_window("Geometry: vertices + indices - Escape to exit", 640, 480,
                    smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window) {
            window |> with_renderer() $(renderer) {
                renderer |> with_texture("{SDL_GetBasePath()}assets/checker.bmp") $(texture) {
                    var triangle, quad : array<SDL_Vertex>
                    triangle |> resize(3)
                    quad |> resize(4)
                    let white = float4(1.0)
                    quad[0] = vertex(float2(420.0, 170.0), white, float2(0.0, 0.0))
                    quad[1] = vertex(float2(600.0, 170.0), white, float2(1.0, 0.0))
                    quad[2] = vertex(float2(420.0, 350.0), white, float2(0.0, 1.0))
                    quad[3] = vertex(float2(600.0, 350.0), white, float2(1.0, 1.0))
                    let indices <- array<int>(0, 1, 2, 2, 1, 3)
                    var event = SDL_MakeEvent()
                    var running = true
                    while (running) {
                        while (poll_event(event)) {
                            if (should_close(event, window)) { running = false }
                        }
                        if (!running) { break }
                        let size = 110.0 + 30.0 * sin(float(frames) / 30.0)
                        triangle[0] = vertex(float2(210.0, 240.0 - size), float4(1.0, 0.0, 0.0, 1.0))
                        triangle[1] = vertex(float2(210.0 + size, 240.0 + size), float4(0.0, 1.0, 0.0, 1.0))
                        triangle[2] = vertex(float2(210.0 - size, 240.0 + size), float4(0.0, 0.0, 1.0, 1.0))
                        renderer |> clear()
                        renderer |> draw_geometry(triangle)
                        renderer |> draw_geometry(quad, indices, texture)
                        renderer |> present()
                        frames++
                        if (smoke && frames >= 60) { break }
                        SDL_Delay(16u)
                    }
                }
            }
        }
    }
    print("Geometry: {frames} frames; colored triangle and indexed textured quad.\n")
    return 0
}
