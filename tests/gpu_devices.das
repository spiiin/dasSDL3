options gen2
require dassdl3/sdl3_gpu_boost
require daslib/rtti
require daslib/strings_boost

def draw(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : uint64) {
    for (i in 0 .. 120) {
        SDL_PumpEvents()
        if (gpu_draw_triangle(device, window, pipeline)) { return }
        SDL_Delay(10u)
    }
    panic("multi-device: no drawable")
}

[export]
def main(smoke : bool) : int {
    verify(smoke)
    var available = false
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL, true, "") $(first) {
            let spirv = (SDL_GetGPUShaderFormats(first) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let ext = spirv ? "spv" : "dxil"
            let base = "{SDL_GetBasePath()}assets/shaders/triangle"
            let vertex = "{base}.vert.{ext}"
            let fragment = "{base}.frag.{ext}"
            print("Multi-device backend: {SDL_GetGPUDeviceDriver(first)}, debug=true\n")
            with_window("device A", 160, 120, 0ul) $(window_a) {
                first |> with_gpu_window(window_a) {
                    first |> with_gpu_vertex_id_pipeline(window_a, vertex, fragment, format) $(pipeline_a) {
                        for (cycle in 0 .. 3) {
                            draw(first, window_a, pipeline_a)
                            var caught = false
                            var old_b = 0ul
                            try {
                                verify(try_with_gpu_device(format, true, "") $(second) {
                                    verify(SDLTestGPUDevices() == 2)
                                    with_window("device B", 160, 120, 0ul) $(window_b) {
                                        second |> with_gpu_window(window_b) {
                                            second |> with_gpu_vertex_id_pipeline(window_b, vertex, fragment, format) $(pipeline_b) {
                                                old_b = pipeline_b
                                                var w, h : uint
                                                verify(SDL_DrawGPUVertexIDTriangle(second, window_a, pipeline_a, w, h) == -1)
                                                verify(!SDL_ReleaseGPUVertexIDPipeline(second, pipeline_a))
                                                verify(!SDL_ClaimGPUWindowScoped(second, window_a))
                                                verify(SDLTestGPUPipelines() == 2 && SDLTestGPUClaims() == 2)
                                                draw(first, window_a, pipeline_a)
                                                draw(second, window_b, pipeline_b)
                                                if (cycle == 1) { panic("device-b-panic") }
                                                return
                                            }
                                        }
                                    }
                                })
                            } recover {
                                var error = ""
                                error := rtrim(this_context().last_exception)
                                if (error != "device-b-panic") { panic(error) }
                                caught = true
                            }
                            verify(caught == (cycle == 1))
                            verify(SDLTestGPUDevices() == 1 && SDLTestGPUPipelines() == 1 && SDLTestGPUClaims() == 1)
                            var w, h : uint
                            verify(SDL_DrawGPUVertexIDTriangle(first, window_a, old_b, w, h) == -1)
                            draw(first, window_a, pipeline_a)
                        }
                    }
                }
            }
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
        verify(SDLTestGPUDevices() == 0 && SDLTestGPUPipelines() == 0 && SDLTestGPUClaims() == 0)
    }
    if (!available) { return 77 }
    print("Two real devices: alternating draws, foreign handles, normal/panic teardown and survivor draw PASS.\n")
    return 0
}
