options gen2
require dassdl3/sdl3_gpu_3d_boost

[export]
def main(smoke : bool) : int {
    var available = false
    var frames = 0
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL,true,"") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let shaders = "{SDL_GetBasePath()}assets/shaders/scene3d"
            var positions <- array<float4>(
                float4(-1.0,-1.0,-1.0,1.0),float4(1.0,-1.0,-1.0,1.0),float4(1.0,1.0,-1.0,1.0),float4(-1.0,1.0,-1.0,1.0),
                float4(-1.0,-1.0,1.0,1.0),float4(1.0,-1.0,1.0,1.0),float4(1.0,1.0,1.0,1.0),float4(-1.0,1.0,1.0,1.0))
            var colors <- array<float4>(
                float4(0.1,0.1,0.2,1.0),float4(1.0,0.1,0.2,1.0),float4(1.0,1.0,0.2,1.0),float4(0.1,1.0,0.2,1.0),
                float4(0.1,0.1,1.0,1.0),float4(1.0,0.1,1.0,1.0),float4(1.0,1.0,1.0,1.0),float4(0.1,1.0,1.0,1.0))
            var indices <- array<uint>(0u,2u,1u,0u,3u,2u,4u,5u,6u,4u,6u,7u,
                0u,1u,5u,0u,5u,4u,3u,7u,6u,3u,6u,2u,0u,4u,7u,0u,7u,3u,1u,2u,6u,1u,6u,5u)
            with_window("SDL GPU 3D cube - Escape to exit",800,600,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_3d_mesh(window,positions,colors,indices,"{shaders}.vert.{extension}","{shaders}.frag.{extension}",format) $(mesh) {
                        clear(positions)
                        clear(colors)
                        clear(indices)
                        var event = SDL_MakeEvent()
                        var running = true
                        var attempts = 0
                        while (running) {
                            while (poll_event(event)) {
                                if (should_close(event,window)) { running = false }
                            }
                            if (!running) { break }
                            let angle = float(frames) * 0.02
                            var model : float4x4
                            identity(model)
                            model[0] = float4(cos(angle),0.0,-sin(angle),0.0)
                            model[2] = float4(sin(angle),0.0,cos(angle),0.0)
                            let camera = gpu_camera(float3(3.0,2.0,5.0),float3(0.0),float3(0.0,1.0,0.0),1.0,gpu_window_aspect(window),0.1,100.0)
                            if (device |> gpu_draw_3d_mesh(window,mesh,camera * model)) { frames++ }
                            if (smoke && frames == 60) { break }
                            attempts++
                            if (smoke && attempts >= 300) { panic("GPU cube: no drawable") }
                            SDL_Delay(16u)
                        }
                    }
                }
            }
            print("GPU cube: {SDL_GetGPUDeviceDriver(device)}, {frames} frames; depth/resources released.\n")
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
    }
    if (!available) { return smoke ? 77 : 1 }
    if (smoke && frames != 60) { panic("GPU cube smoke interrupted") }
    return 0
}
