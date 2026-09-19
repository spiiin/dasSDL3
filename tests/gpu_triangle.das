options gen2
require dassdl3/sdl3_gpu_boost
require daslib/rtti
require daslib/strings_boost

[export]
def main(smoke : bool) : int {
    verify(smoke)
    var available = false
    var orphan = 0ul
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL, true, "") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let base = "{SDL_GetBasePath()}assets/shaders/triangle"
            let vertex = "{base}.vert.{extension}"
            let fragment = "{base}.frag.{extension}"
            print("GPU triangle contracts: {SDL_GetGPUDeviceDriver(device)}, {extension}\n")
            if (!SDLTestGPUTrianglePixels(device, vertex, fragment, format)) { panic("{SDL_GetError()}") }
            verify(SDLTestGPUPipelines() == 0 && SDLTestGPUShaders() == 0)
            with_window("GPU triangle contracts", 160, 120, SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    verify(SDL_CreateGPUVertexIDPipeline(device, window, "missing.vert", fragment, format) == 0ul)
                    verify(SDL_CreateGPUVertexIDPipeline(device, window, vertex, "missing.frag", format) == 0ul)
                    // Valid text file, but not a compiled shader (rejected before SDL shader creation).
                    verify(SDL_CreateGPUVertexIDPipeline(device, window, "{base}.vert.hlsl", fragment, format) == 0ul)
                    verify(SDL_CreateGPUVertexIDPipeline(device, window, vertex, fragment, 0u) == 0ul)
                    verify(SDL_CreateGPUVertexIDPipeline(device, window, vertex, fragment, SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL) == 0ul)
                    verify(SDLTestGPUPipelineFailure(device, window, vertex, fragment, format))
                    verify(SDLTestGPUPipelines() == 0 && SDLTestGPUShaders() == 0)
                    var stale = 0ul
                    device |> with_gpu_vertex_id_pipeline(window, vertex, fragment, format) $(pipeline) {
                        stale = pipeline
                        verify(SDLTestGPUPipelines() == 1 && SDLTestGPUShaders() == 0)
                        verify(gpu_draw_triangle(device, window, pipeline))
                        verify(SDLTestGPUForeignPipeline(device, pipeline))
                        verify(SDLTestGPUDevices() == 1)
                        verify(gpu_draw_triangle(device, window, pipeline))
                        return
                    }
                    var w, h : uint
                    verify(SDL_DrawGPUVertexIDTriangle(device, window, stale, w, h) == -1)
                    verify(w == 0u && h == 0u)
                    verify(!SDL_ReleaseGPUVertexIDPipeline(device, stale))
                    var caught = false
                    try {
                        device |> with_gpu_vertex_id_pipeline(window, vertex, fragment, format) $(pipeline) {
                            verify(pipeline != stale)
                            verify(gpu_draw_triangle(device, window, pipeline))
                            panic("triangle-panic")
                        }
                    } recover {
                        caught = true
                        verify(rtrim(this_context().last_exception) == "triangle-panic")
                    }
                    verify(caught && SDLTestGPUPipelines() == 0 && SDLTestGPUShaders() == 0)
                    // Device shutdown must invalidate even a manually-created, unreleased ID.
                    orphan = SDL_CreateGPUVertexIDPipeline(device, window, vertex, fragment, format)
                    verify(orphan != 0ul && orphan != stale)
                    verify(SDL_DrawGPUVertexIDTriangle(null, window, orphan, w, h) == -1)
                    verify(SDLTestGPUPipelines() == 1)
                }
            }
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
        verify(SDLTestGPUPipelines() == 0 && SDLTestGPUShaders() == 0)
        verify(SDLTestGPUDevices() == 0 && SDLTestGPUClaims() == 0)
        if (available) {
            var w, h : uint
            // Invalid ID is rejected without dereferencing a device or window.
            verify(SDL_DrawGPUVertexIDTriangle(null, null, orphan, w, h) == -1)
        }
    }
    if (!available) { return 77 }
    print("Triangle: CPU pixel reference, partial failure, early return, panic, stale/foreign IDs and device cleanup passed.\n")
    return 0
}
