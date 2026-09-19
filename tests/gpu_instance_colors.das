options gen2
require dassdl3/sdl3_gpu_instance_colors_boost
require dassdl3/sdl3_gpu_scene_boost
require daslib/rtti
require daslib/strings_boost

def check_gpu(ok : bool) {
    if (!ok) { panic("GPU instancing test: {SDL_GetError()}") }
}
def draw(device : SDL_GPUDevice?; window : SDL_Window?; mesh : uint64; camera : float4x4) {
    for (attempt in 0 .. 100) {
        SDL_PumpEvents()
        if (device |> gpu_draw_instanced_mesh(window,mesh,camera,float3(0.0,0.0,1.0))) { return }
        SDL_Delay(10u)
    }
    panic("GPU instancing: no drawable")
}
[export]
def main(smoke : bool) : int {
    var unit : float4x4
    identity(unit)
    var instances : GpuColoredInstanceList
    var model = unit
    model[0] = float4(0.6,0.0,0.0,0.0)
    model[1] = float4(0.0,0.8,0.0,0.0)
    model[3] = float4(-0.3,0.0,0.25,1.0)
    instances |> gpu_colored_instance_add(model)
    model[0] = float4(0.8,0.0,0.2,0.0)
    model[2] = float4(-0.1,0.0,0.4,0.0)
    model[3] = float4(0.25,0.0,0.6,1.0)
    instances |> gpu_colored_instance_add(model)
    model = unit
    model[0] = float4(-0.3,0.0,0.0,0.0)
    model[1] = float4(0.0,0.4,0.0,0.0)
    model[2] = float4(0.0,0.0,-0.8,0.0)
    model[3] = float4(0.0,0.45,0.1,1.0)
    instances |> gpu_colored_instance_add(model)
    check_gpu(SDLTestGPUColorsGuards(instances.model_columns))
    instances.colors[0] = float4(1.0,0.25,0.1,0.5)
    instances.colors[1] = float4(0.15,1.0,0.4,0.25)
    instances.colors[2] = float4(0.2,0.3,1.0,0.0)
    var first : array<float4>
    first := instances.colors
    var second <- array<float4>(float4(0.1,0.4,1.0,1.0),float4(1.0,0.2,0.1,0.75),float4(0.2,1.0,0.3,0.5))
    var available = false
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL,true,"") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let vs = "{SDL_GetBasePath()}assets/shaders/colored_instances.vert.{extension}"
            let fs = "{SDL_GetBasePath()}assets/shaders/colored_instances.frag.{extension}"
            var positions <- array<float4>(float4(-0.8,-0.7,0.0,1.0),float4(0.8,-0.7,0.0,1.0),float4(0.0,0.8,0.0,1.0))
            var normals <- array<float4>(float4(1.0,0.0,1.0,0.0),float4(1.0,0.0,1.0,0.0),float4(1.0,0.0,1.0,0.0))
            var uv <- array<float2>(float2(0.0),float2(0.0),float2(0.0))
            var indices <- array<uint>(0u,1u,2u)
            var texels <- array<uint8>(uint8(160),uint8(210),uint8(96),uint8(192))
            var bad : array<float4>
            verify(SDLTestGPUColorsOffscreen(device,positions,normals,uv,texels,indices,instances.model_columns,bad,vs,fs,format) == 0ul)
            bad := first
            bad[2].w = 1.1
            verify(SDLTestGPUColorsOffscreen(device,positions,normals,uv,texels,indices,instances.model_columns,bad,vs,fs,format) == 0ul)
            verify(SDLTestGPUColorsOffscreen(device,positions,normals,uv,texels,indices,instances.model_columns,first,vs,"missing-shader",format) == 0ul)
            verify(SDLTestGPULitMeshes() == 0)
            let mesh = SDLTestGPUColorsOffscreen(device,positions,normals,uv,texels,indices,instances.model_columns,instances.colors,vs,fs,format)
            verify(mesh != 0ul)
            clear(instances.colors) // GPU keeps creation-time colors.
            check_gpu(SDLTestGPUColorsPixels(device,mesh,instances.model_columns,first))
            verify(!SDL_UpdateGPUInstances(device,mesh,instances.model_columns))
            verify(!SDL_UpdateGPUColoredInstances(device,mesh,instances.model_columns,bad))
            check_gpu(SDLTestGPUColorsPixels(device,mesh,instances.model_columns,first))
            instances.colors := second
            device |> gpu_update_colored_instances(mesh,instances)
            clear(instances.colors)
            check_gpu(SDLTestGPUColorsPixels(device,mesh,instances.model_columns,second))
            check_gpu(SDLTestGPUColorsPending(device,mesh,instances.model_columns,first,second))
            check_gpu(SDLTestGPUColorsFailure(device,mesh,instances.model_columns,first))
            instances.colors := first
            device |> gpu_update_colored_instances(mesh,instances)
            check_gpu(SDLTestGPUColorsPixels(device,mesh,instances.model_columns,first))
            check_gpu(SDL_ReleaseGPULitMesh(device,mesh))
            verify(!SDL_UpdateGPUColoredInstances(device,mesh,instances.model_columns,first))
            let plain_vs = "{SDL_GetBasePath()}assets/shaders/instances.vert.{extension}"
            let plain_fs = "{SDL_GetBasePath()}assets/shaders/instances.frag.{extension}"
            let plain = SDLTestGPUInstancesOffscreen(device,positions,normals,uv,texels,indices,instances.model_columns,plain_vs,plain_fs,format)
            verify(plain != 0ul)
            verify(!SDL_UpdateGPUColoredInstances(device,plain,instances.model_columns,first))
            check_gpu(SDL_ReleaseGPULitMesh(device,plain))
            with_window("GPU instance RGBA contracts",160,120,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_colored_instanced_mesh(window,positions,normals,uv,indices,texels,1u,1u,vs,fs,format,instances) $(colored) {
                        device |> gpu_update_colored_instances(colored,instances)
                        draw(device,window,colored,unit)
                        check_gpu(SDLTestGPUResize(window))
                        draw(device,window,colored,unit)
                        check_gpu(SDLTestGPULitDepth(device,window,colored))
                        let another = try_with_gpu_device(format,true,"") $(other) {
                            verify(!SDL_UpdateGPUColoredInstances(other,colored,instances.model_columns,first))
                            let owned = SDLTestGPUColorsOffscreen(other,positions,normals,uv,texels,indices,instances.model_columns,first,vs,fs,format)
                            verify(owned != 0ul)
                            other |> gpu_update_colored_instances(owned,instances)
                        }
                        verify(another && SDLTestGPULitMeshes() == 1)
                        draw(device,window,colored,unit)
                    }
                    var caught = false
                    try {
                        device |> with_gpu_colored_instanced_mesh(window,positions,normals,uv,indices,texels,1u,1u,vs,fs,format,instances) $(colored) {
                            device |> gpu_update_colored_instances(colored,instances)
                            panic("colored instance scope sentinel")
                        }
                    } recover { caught = rtrim(this_context().last_exception) == "colored instance scope sentinel" }
                    verify(caught && SDLTestGPULitMeshes() == 0)
                    device |> with_gpu_colored_instanced_mesh(window,positions,normals,uv,indices,texels,1u,1u,vs,fs,format,instances) $(colored) {
                        device |> gpu_update_colored_instances(colored,instances)
                        clear(instances.colors)
                        clear(instances.model_columns)
                        clear(positions)
                        clear(normals)
                        clear(uv)
                        clear(texels)
                        clear(indices)
                        draw(device,window,colored,unit)
                        return
                    }
                    verify(SDLTestGPULitMeshes() == 0)
                }
            }
            print("Instance RGBA, pending snapshots and cleanup PASS: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    return available ? 0 : 77
}
