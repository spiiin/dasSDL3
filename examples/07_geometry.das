options gen2
require dassdl3/sdl3_geometry_boost
require math

// Adapted scenario: SDL 3.2.18 examples/renderer/10-geometry/geometry.c (public domain).
// Own checker BMP, PollEvent loop and resource scopes; all arrays belong to script.
var example_failed = false

[export]
def main(smoke : bool) : int {
    var frames = 0
    let scope_ok_0 = with_sdl() {
        with_window("Geometry: vertices + indices - Escape to exit", 640, 480,
                    smoke ? SDL_WINDOW_HIDDEN : 0ul) $(window : SDL_Window?) {
            let scope_ok_1 = window |> with_renderer() $(renderer : SDL_Renderer?) {
                let scope_ok_2 = renderer |> with_texture("{SDL_GetBasePath()}assets/checker.bmp") $(texture : SDL_Texture?) {
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
                        while (is_some(poll_event(event))) {
                            if (should_close(event, window)) { running = false }
                        }
                        if (!running) { break }
                        let size = 110.0 + 30.0 * sin(float(frames) / 30.0)
                        triangle[0] = vertex(float2(210.0, 240.0 - size), float4(1.0, 0.0, 0.0, 1.0))
                        triangle[1] = vertex(float2(210.0 + size, 240.0 + size), float4(0.0, 1.0, 0.0, 1.0))
                        triangle[2] = vertex(float2(210.0 - size, 240.0 + size), float4(0.0, 0.0, 1.0, 1.0))
                        var operation_result_1 <- renderer |> clear()
                        if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                        var operation_result_2 <- renderer |> draw_geometry(triangle)
                        if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                        var operation_result_3 <- renderer |> draw_geometry(quad, indices, texture)
                        if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
                        var operation_result_4 <- renderer |> present()
                        if (is_err(operation_result_4)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_4).message}\n"); return err(unwrap_err(operation_result_4),type<SdlUnit>) }
                        frames++
                        if (smoke && frames >= 60) { break }
                        SDL_Delay(16u)
                    }

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    print("Geometry: {frames} frames; colored triangle and indexed textured quad.\n")
    return example_failed ? 1 : 0
}
