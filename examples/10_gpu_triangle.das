options gen2
require dassdl3/sdl3_gpu_boost

[export]
def main(smoke : bool) : int {
    var available = false
    var frames = 0
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL, true, "") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let shaders = "{SDL_GetBasePath()}assets/shaders/triangle"
            print("GPU triangle: {SDL_GetGPUDeviceDriver(device)}, {extension}\n")
            with_window("SDL GPU BasicTriangle - Escape to exit", 640, 480, SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_vertex_id_pipeline(window, "{shaders}.vert.{extension}", "{shaders}.frag.{extension}", format) $(pipeline) {
                        var event = SDL_MakeEvent()
                        var running = true
                        var attempts = 0
                        while (running) {
                            while (poll_event(event)) {
                                if (should_close(event, window)) { running = false }
                            }
                            if (!running) { break }
                            if (gpu_draw_triangle(device, window, pipeline)) { frames++ }
                            attempts++
                            if (smoke && frames == 60) { break }
                            if (smoke && attempts >= 300) { panic("GPU triangle: no drawable after 300 attempts") }
                            SDL_Delay(16u)
                        }
                    }
                }
            }
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
    }
    if (!available) { return smoke ? 77 : 1 }
    if (smoke && frames != 60) { panic("GPU triangle smoke interrupted") }
    print("GPU triangle: {frames} frames; pipeline and device released.\n")
    return 0
}
