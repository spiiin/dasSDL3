options gen2
require dassdl3/sdl3_gpu_resources_boost

def fill_visible(var list : GpuBatchList; first, second : uint64; time : float;
frustum : GpuFrustum; culling : bool) : int {
    gpu_batch_clear(list)
    var visible = 0
    // 48 * 48 = 2304 objects; local cube [-1,1]^3 is enclosed by radius sqrt(3).
    for (z in 0 .. 48) {
        for (x in 0 .. 48) {
            let angle = float(x+z)*0.3 + time*0.6
            var model : float4x4
            identity(model)
            model[0] = float4(cos(angle)*0.4,0.0,-sin(angle)*0.4,0.0)
            model[1] = float4(0.0,0.35+0.12*sin(time+float(x+z)),0.0,0.0)
            model[2] = float4(sin(angle)*0.4,0.0,cos(angle)*0.4,0.0)
            model[3] = float4(float(x)-23.5,0.0,float(z)-23.5,1.0)
            let seen = gpu_sphere_visible(frustum,model,float4(0.0,0.0,0.0,1.732051))
            if (seen) { visible++ }
            if (!culling || seen) {
                list |> gpu_batch_add(((x+z)%2 == 0) ? first : second,model)
            }
        }
    }
    return visible
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
            var alternate : array<uint8>
            alternate := pixels
            for (i in 0 .. 64) { swap(alternate[i*4],alternate[i*4+2]) }
            with_window("SDL GPU shared geometry - C: toggle, Space: pause, Escape: exit",800,600,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_geometry(positions,normals,uv,indices) $(geometry) {
                        device |> with_gpu_material(window,pixels,8u,8u,"{shaders}.vert.{extension}","{shaders}.frag.{extension}",format) $(warm) {
                            device |> with_gpu_material(window,alternate,8u,8u,"{shaders}.vert.{extension}","{shaders}.frag.{extension}",format) $(cool) {
                                device |> with_gpu_shared_mesh(geometry,warm) $(first) {
                                    device |> with_gpu_shared_mesh(geometry,cool) $(second) {
                                        device |> with_gpu_batch_scene(window) $(scene) {
                                            var list : GpuBatchList
                                            clear(alternate)
                                            clear(positions)
                                            clear(normals)
                                            clear(uv)
                                            clear(pixels)
                                            clear(indices)
                                            var event = SDL_MakeEvent()
                                            var culling = true
                                            var paused = false
                                            var time = 0.0
                                            var visible = 0
                                            var running = true
                                            var previous = SDL_GetTicks()
                                            var attempts = 0
                                            while (running) {
                                                while (poll_event(event)) {
                                                    if (should_close(event,window)) { running = false }
                                                    var key : SDL_KeyboardEvent
                                                    if (key_event(event,key) && key.down && !key.repeat && input_window_id(event) == SDL_GetWindowID(window)) {
                                                        if (key.key == 99u) { culling = !culling }
                                                        if (key.key == 32u) { paused = !paused }
                                                    }
                                                }
                                                if (!running) { break }
                                                let now = SDL_GetTicks()
                                                if (!paused) { time += smoke ? 1.0/60.0 : min(float(now-previous)*0.001,0.1) }
                                                previous = now
                                                if (smoke) { culling = frames < 30 }
                                                let angle = time*0.25
                                                let camera = gpu_camera(float3(sin(angle)*12.0,7.0,cos(angle)*12.0),float3(0.0),float3(0.0,1.0,0.0),1.0,gpu_window_aspect(window),0.1,35.0)
                                                let frustum = gpu_frustum(camera)
                                                visible = fill_visible(list,first,second,time,frustum,culling)
                                                var first_visible = false
                                                var second_visible = false
                                                for (mesh in list.meshes) {
                                                    if (mesh == first) { first_visible = true }
                                                    if (mesh == second) { second_visible = true }
                                                }
                                                let draws = (first_visible ? 1 : 0)+(second_visible ? 1 : 0)
                                                let mode = culling ? "ON" : "OFF"
                                                window |> set_title("1 geometry / 2 materials | Culling {mode} | total 2304 | visible {visible} | submitted {length(list.meshes)} | draws {draws} | C: toggle | Space: pause | Esc")
                                                if (smoke) {
                                                    verify(visible > 0 && visible < 2304)
                                                    verify(length(list.meshes) == (culling ? visible : 2304))
                                                }
                                                if (device |> gpu_draw_batches(window,scene,list,camera,float3(0.4,0.8,1.0),0.2)) { frames++ }
                                                gpu_batch_clear(list)
                                                if (smoke && frames == 60) { break }
                                                attempts++
                                                if (smoke && attempts >= 300) { panic("GPU shared geometry: no drawable") }
                                                SDL_Delay(16u)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            print("GPU shared geometry: {SDL_GetGPUDeviceDriver(device)}, {frames} frames, 1 geometry / 2 materials / 2304 objects; depth/resources released.\n")
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
    }
    if (!available) { return smoke ? 77 : 1 }
    if (smoke && frames != 60) { panic("GPU culling smoke interrupted") }
    return 0
}
