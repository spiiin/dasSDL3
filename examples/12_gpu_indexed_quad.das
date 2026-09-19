options gen2
require dassdl3/sdl3_gpu_mesh_boost

[export]
def main(smoke : bool) : int {
    var available = false
    var frames = 0
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL, true, "") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let shaders = "{SDL_GetBasePath()}assets/shaders/mesh"
            print("GPU indexed quad: {SDL_GetGPUDeviceDriver(device)}, {extension}\n")
            var vertices <- array<float4>(
                float4(-0.75, 0.75, 0.0, 0.0), float4(0.75, 0.75, 1.0, 0.0), float4(0.75, -0.75, 1.0, 1.0),
                float4(-0.75, -0.75, 0.0, 1.0))
            // Red/green top row, blue/yellow bottom row. Nearest sampling makes orientation visible.
            var indices <- array<uint>(0u,1u,2u,0u,2u,3u)
            var pixels <- array<uint8>(uint8(255), uint8(0), uint8(0), uint8(255), uint8(0), uint8(255), uint8(0), uint8(255), uint8(0), uint8(0), uint8(255), uint8(255), uint8(255), uint8(255), uint8(0), uint8(255))
            with_window("SDL GPU IndexedQuad - Escape to exit", 640, 480, SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_indexed_textured_mesh(window, vertices, indices, pixels, 2u, 2u,
                            "{shaders}.vert.{extension}", "{shaders}.frag.{extension}", format) $(mesh) {
                        // Upload is copied: source storage can immediately be changed or freed.
                        clear(indices)
                        clear(vertices)
                        clear(pixels)
                        var event = SDL_MakeEvent()
                        var attempts = 0
                        var running = true
                        while (running) {
                            while (poll_event(event)) {
                                if (should_close(event, window)) { running = false }
                            }
                            if (!running) { break }
                            if (device |> gpu_draw_textured_mesh(window, mesh)) { frames++ }
                            if (smoke && frames == 60) { break }
                            attempts++
                            if (smoke && attempts >= 300) { panic("GPU quad: no drawable after 300 attempts") }
                            SDL_Delay(16u)
                        }
                    }
                }
            }
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
    }
    if (!available) { return smoke ? 77 : 1 }
    if (smoke && frames != 60) { panic("GPU indexed quad smoke interrupted") }
    print("GPU indexed quad: {frames} frames; resources released.\n")
    return 0
}
