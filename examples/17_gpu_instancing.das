options gen2
require dassdl3/sdl3_gpu_instancing_boost

[export]
def main(smoke : bool) : int {
    var available = false
    var frames = 0
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL,true,"") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let shaders = "{SDL_GetBasePath()}assets/shaders/instances"
            // Split vertices preserve sharp normals and UV seams at cube edges.
            var positions <- array<float4>(
                float4(1.0,-1.0,-1.0,1.0),float4(1.0,1.0,-1.0,1.0),float4(1.0,1.0,1.0,1.0),float4(1.0,-1.0,1.0,1.0),
                float4(-1.0,-1.0,1.0,1.0),float4(-1.0,1.0,1.0,1.0),float4(-1.0,1.0,-1.0,1.0),float4(-1.0,-1.0,-1.0,1.0),
                float4(-1.0,1.0,-1.0,1.0),float4(-1.0,1.0,1.0,1.0),float4(1.0,1.0,1.0,1.0),float4(1.0,1.0,-1.0,1.0),
                float4(-1.0,-1.0,1.0,1.0),float4(-1.0,-1.0,-1.0,1.0),float4(1.0,-1.0,-1.0,1.0),float4(1.0,-1.0,1.0,1.0),
                float4(-1.0,-1.0,1.0,1.0),float4(1.0,-1.0,1.0,1.0),float4(1.0,1.0,1.0,1.0),float4(-1.0,1.0,1.0,1.0),
                float4(1.0,-1.0,-1.0,1.0),float4(-1.0,-1.0,-1.0,1.0),float4(-1.0,1.0,-1.0,1.0),float4(1.0,1.0,-1.0,1.0))
            var normals <- array<float4>(
                float4(1.0,0.0,0.0,0.0),float4(1.0,0.0,0.0,0.0),float4(1.0,0.0,0.0,0.0),float4(1.0,0.0,0.0,0.0),
                float4(-1.0,0.0,0.0,0.0),float4(-1.0,0.0,0.0,0.0),float4(-1.0,0.0,0.0,0.0),float4(-1.0,0.0,0.0,0.0),
                float4(0.0,1.0,0.0,0.0),float4(0.0,1.0,0.0,0.0),float4(0.0,1.0,0.0,0.0),float4(0.0,1.0,0.0,0.0),
                float4(0.0,-1.0,0.0,0.0),float4(0.0,-1.0,0.0,0.0),float4(0.0,-1.0,0.0,0.0),float4(0.0,-1.0,0.0,0.0),
                float4(0.0,0.0,1.0,0.0),float4(0.0,0.0,1.0,0.0),float4(0.0,0.0,1.0,0.0),float4(0.0,0.0,1.0,0.0),
                float4(0.0,0.0,-1.0,0.0),float4(0.0,0.0,-1.0,0.0),float4(0.0,0.0,-1.0,0.0),float4(0.0,0.0,-1.0,0.0))
            var uv <- array<float2>(
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0),
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0),
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0),
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0),
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0),
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0))
            var indices <- array<uint>(
                0u,1u,2u,0u,
                2u,3u,4u,5u,
                6u,4u,6u,7u,
                8u,9u,10u,8u,
                10u,11u,12u,13u,
                14u,12u,14u,15u,
                16u,17u,18u,16u,
                18u,19u,20u,21u,
                22u,20u,22u,23u)
            var pixels : array<uint8>
            for (y in 0 .. 8) {
                for (x in 0 .. 8) {
                    let bright = ((x / 2 + y / 2) % 2) == 0
                    push(pixels,uint8(bright ? 240 : 40))
                    push(pixels,uint8(bright ? 180 : 80))
                    push(pixels,uint8(bright ? 70 : 180))
                    push(pixels,uint8(255))
                }
            }
            var instances : GpuInstanceList
            for (z in 0 .. 8) {
                for (x in 0 .. 8) {
                    let angle = float(x + z) * 0.3
                    var model : float4x4
                    identity(model)
                    model[0] = float4(cos(angle)*0.4,0.0,-sin(angle)*0.4,0.0)
                    model[1] = float4(0.0,0.3 + float(x % 3)*0.1,0.0,0.0)
                    model[2] = float4(sin(angle)*0.4,0.0,cos(angle)*0.4,0.0)
                    model[3] = float4(float(x)-3.5,0.0,float(z)-3.5,1.0)
                    instances |> gpu_instance_add(model)
                }
            }
            with_window("SDL GPU 64 instances / one draw - Escape to exit",800,600,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_instanced_mesh(window,positions,normals,uv,indices,pixels,8u,8u,"{shaders}.vert.{extension}","{shaders}.frag.{extension}",format,instances) $(mesh) {
                        clear(instances.model_columns)
                        clear(positions)
                        clear(normals)
                        clear(uv)
                        clear(pixels)
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
                            let camera = gpu_camera(float3(sin(angle)*9.0,7.0,cos(angle)*9.0),float3(0.0),float3(0.0,1.0,0.0),1.0,gpu_window_aspect(window),0.1,100.0)
                            if (device |> gpu_draw_instanced_mesh(window,mesh,camera,float3(0.4,0.8,1.0),0.2)) { frames++ }
                            if (smoke && frames == 60) { break }
                            attempts++
                            if (smoke && attempts >= 300) { panic("GPU instances: no drawable") }
                            SDL_Delay(16u)
                        }
                    }
                }
            }
            print("GPU instances: {SDL_GetGPUDeviceDriver(device)}, {frames} frames, 64 instances / indexed draw; depth/resources released.\n")
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
    }
    if (!available) { return smoke ? 77 : 1 }
    if (smoke && frames != 60) { panic("GPU instances smoke interrupted") }
    return 0
}
