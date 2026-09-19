options gen2
require dassdl3/sdl3_gpu_batches_boost

def animate_batches(var instances : GpuBatchList; first, second : uint64; time : float) {
    gpu_batch_clear(instances)
    for (z in 0 .. 8) {
        for (x in 0 .. 8) {
            let angle = float(x + z) * 0.3 + time * (0.6 + float(x % 3)*0.2)
            var model : float4x4
            identity(model)
            model[0] = float4(cos(angle)*0.4,0.0,-sin(angle)*0.4,0.0)
            model[1] = float4(0.0,0.35 + 0.12*sin(time*1.7 + float(x + z)),0.0,0.0)
            model[2] = float4(sin(angle)*0.4,0.0,cos(angle)*0.4,0.0)
            model[3] = float4(float(x)-3.5,0.5*sin(time*2.0 + float(x + z)*0.4),float(z)-3.5,1.0)
            instances |> gpu_batch_add(((x+z)%2 == 0) ? first : second,model,float4(0.55+0.45*sin(time+float(x)*0.5),0.55+0.45*sin(time*0.7+float(z)*0.5),0.55+0.45*cos(time+float(x+z)*0.4),1.0))
        }
    }
}

[export]
def main(smoke : bool) : int {
    var available = false
    var frames = 0
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL,true,"") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let shaders = "{SDL_GetBasePath()}assets/shaders/colored_instances"
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
            var instances : GpuColoredInstanceList
            var unit : float4x4
            identity(unit)
            instances |> gpu_colored_instance_add(unit)
            var alternate : array<uint8>
            alternate := pixels
            for (i in 0 .. 64) { swap(alternate[i*4],alternate[i*4+2]) }
            with_window("SDL GPU 64 objects / two material batches - Escape to exit",800,600,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_colored_instanced_mesh(window,positions,normals,uv,indices,pixels,8u,8u,"{shaders}.vert.{extension}","{shaders}.frag.{extension}",format,instances) $(first) {
                        device |> with_gpu_colored_instanced_mesh(window,positions,normals,uv,indices,alternate,8u,8u,"{shaders}.vert.{extension}","{shaders}.frag.{extension}",format,instances) $(second) {
                            device |> with_gpu_batch_scene(window) $(scene) {
                                var list : GpuBatchList
                                clear(alternate)
                                clear(instances.model_columns)
                                clear(instances.colors)
                                clear(positions)
                                clear(normals)
                                clear(uv)
                                clear(pixels)
                                clear(indices)
                                var event = SDL_MakeEvent()
                                var running = true
                                let started = SDL_GetTicks()
                                var attempts = 0
                                while (running) {
                                    while (poll_event(event)) {
                                        if (should_close(event,window)) { running = false }
                                    }
                                    if (!running) { break }
                                    let time = smoke ? float(frames)/60.0 : float(SDL_GetTicks()-started)*0.001
                                    animate_batches(list,first,second,time)
                                    let angle = time * 0.25
                                    let camera = gpu_camera(float3(sin(angle)*9.0,7.0,cos(angle)*9.0),float3(0.0),float3(0.0,1.0,0.0),1.0,gpu_window_aspect(window),0.1,100.0)
                                    if (device |> gpu_draw_batches(window,scene,list,camera,float3(0.4,0.8,1.0),0.2)) { frames++ }
                                    gpu_batch_clear(list)
                                    if (smoke && frames == 60) { break }
                                    attempts++
                                    if (smoke && attempts >= 300) { panic("GPU material batches: no drawable") }
                                    SDL_Delay(16u)
                                }
                            }
                        }
                    }
                }
            }
            print("GPU material batches: {SDL_GetGPUDeviceDriver(device)}, {frames} frames, 64 objects / 2 indexed draws; depth/resources released.\n")
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
    }
    if (!available) { return smoke ? 77 : 1 }
    if (smoke && frames != 60) { panic("GPU instances smoke interrupted") }
    return 0
}
