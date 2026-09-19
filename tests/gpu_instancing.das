options gen2
require dassdl3/sdl3_gpu_instancing_boost
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
    var instances : GpuInstanceList
    var model = unit
    model[0] = float4(0.6,0.0,0.0,0.0)
    model[1] = float4(0.0,0.8,0.0,0.0)
    model[3] = float4(-0.3,0.0,0.25,1.0)
    instances |> gpu_instance_add(model)
    model[0] = float4(0.8,0.0,0.2,0.0)
    model[2] = float4(-0.1,0.0,0.4,0.0)
    model[3] = float4(0.25,0.0,0.6,1.0)
    instances |> gpu_instance_add(model)
    model = unit
    model[0] = float4(-0.3,0.0,0.0,0.0)
    model[1] = float4(0.0,0.4,0.0,0.0)
    model[2] = float4(0.0,0.0,-0.8,0.0)
    model[3] = float4(0.0,0.45,0.1,1.0)
    instances |> gpu_instance_add(model)
    var available = false
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL,true,"") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let vs = "{SDL_GetBasePath()}assets/shaders/instances.vert.{extension}"
            let fs = "{SDL_GetBasePath()}assets/shaders/instances.frag.{extension}"
            var positions <- array<float4>(float4(-0.8,-0.7,0.0,1.0),float4(0.8,-0.7,0.0,1.0),float4(0.0,0.8,0.0,1.0))
            var normals <- array<float4>(float4(1.0,0.0,1.0,0.0),float4(1.0,0.0,1.0,0.0),float4(1.0,0.0,1.0,0.0))
            var uv <- array<float2>(float2(0.0),float2(0.0),float2(0.0))
            var indices <- array<uint>(0u,1u,2u)
            var texels <- array<uint8>(uint8(255),uint8(255),uint8(255),uint8(255))
            var bad : GpuInstanceList
            verify(SDLTestGPUInstancesOffscreen(device,positions,normals,uv,texels,indices,bad.model_columns,vs,fs,format) == 0ul)
            push(bad.model_columns,float4(1.0))
            verify(SDLTestGPUInstancesOffscreen(device,positions,normals,uv,texels,indices,bad.model_columns,vs,fs,format) == 0ul)
            resize(bad.model_columns,16388)
            verify(SDLTestGPUInstancesOffscreen(device,positions,normals,uv,texels,indices,bad.model_columns,vs,fs,format) == 0ul)
            clear(bad.model_columns)
            bad |> gpu_instance_add(unit)
            model = unit
            model[0] = float4(0.0)
            bad |> gpu_instance_add(model)
            verify(SDLTestGPUInstancesOffscreen(device,positions,normals,uv,texels,indices,bad.model_columns,vs,fs,format) == 0ul)
            verify(SDLTestGPULitMeshes() == 0)
            verify(SDLTestGPUInstancesOffscreen(device,positions,normals,uv,texels,indices,instances.model_columns,vs,"missing-shader",format) == 0ul)
            verify(SDLTestGPULitMeshes() == 0)
            let offscreen = SDLTestGPUInstancesOffscreen(device,positions,normals,uv,texels,indices,instances.model_columns,vs,fs,format)
            verify(offscreen != 0ul)
            // Mutate upload inputs: pixel checks below must still see the original GPU copy.
            let saved_position = positions[0]
            positions[0] = float4(99.0)
            texels[0] = uint8(0)
            check_gpu(SDLTestGPUInstancesPreflight(device,offscreen))
            check_gpu(SDLTestGPUInstancesPixels(device,offscreen,instances.model_columns,unit[0],unit[1],unit[2],unit[3]))
            let camera = gpu_camera(float3(0.2,0.1,3.0),float3(0.0),float3(0.0,1.0,0.0),1.0,1.0,0.1,20.0)
            check_gpu(SDLTestGPUInstancesPixels(device,offscreen,instances.model_columns,camera[0],camera[1],camera[2],camera[3]))
            var changed : GpuInstanceList
            for (column in instances.model_columns) { push(changed.model_columns,column) }
            changed.model_columns[0] = float4(0.35,0.08,0.0,0.0)
            changed.model_columns[1] = float4(0.0,0.65,0.0,0.0)
            changed.model_columns[3] = float4(0.25,-0.1,0.2,1.0)
            changed.model_columns[7] = float4(-0.25,0.1,0.65,1.0)
            changed.model_columns[11] = float4(0.2,0.4,0.1,1.0)
            device |> gpu_update_instances(offscreen,changed)
            check_gpu(SDLTestGPUInstancesPixels(device,offscreen,changed.model_columns,unit[0],unit[1],unit[2],unit[3]))
            verify(!SDL_UpdateGPUInstances(device,offscreen,bad.model_columns))
            bad.model_columns := changed.model_columns
            bad.model_columns[8] = float4(0.0) // Late singular item must preserve the previous GPU data.
            verify(!SDL_UpdateGPUInstances(device,offscreen,bad.model_columns))
            check_gpu(SDLTestGPUInstancesPixels(device,offscreen,changed.model_columns,unit[0],unit[1],unit[2],unit[3]))
            check_gpu(SDLTestGPUInstancesPending(device,offscreen,instances.model_columns,changed.model_columns))
            check_gpu(SDLTestGPUInstancesFailedSubmit(device,offscreen,changed.model_columns))
            device |> gpu_update_instances(offscreen,changed)
            check_gpu(SDLTestGPUInstancesPixels(device,offscreen,changed.model_columns,unit[0],unit[1],unit[2],unit[3]))
            check_gpu(SDL_ReleaseGPULitMesh(device,offscreen))
            verify(!SDL_UpdateGPUInstances(device,offscreen,changed.model_columns))
            positions[0] = saved_position
            texels[0] = uint8(255)
            clear(bad.model_columns)
            for (i in 0 .. 4096) { bad |> gpu_instance_add(unit) }
            let maximum = SDLTestGPUInstancesOffscreen(device,positions,normals,uv,texels,indices,bad.model_columns,vs,fs,format)
            verify(maximum != 0ul)
            check_gpu(SDL_ReleaseGPULitMesh(device,maximum))
            // Reverse instance order: the depth result must remain the same.
            for (i in 0 .. 4) { swap(instances.model_columns[i],instances.model_columns[8+i]) }
            let reversed = SDLTestGPUInstancesOffscreen(device,positions,normals,uv,texels,indices,instances.model_columns,vs,fs,format)
            verify(reversed != 0ul)
            check_gpu(SDLTestGPUInstancesPixels(device,reversed,instances.model_columns,unit[0],unit[1],unit[2],unit[3]))
            check_gpu(SDL_ReleaseGPULitMesh(device,reversed))
            with_window("GPU instancing contracts",160,120,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    var stale = 0ul
                    device |> with_gpu_instanced_mesh(window,positions,normals,uv,indices,texels,1u,1u,vs,fs,format,instances) $(mesh) {
                        stale = mesh
                        device |> gpu_update_instances(mesh,instances)
                        draw(device,window,mesh,unit)
                        check_gpu(SDLTestGPULitDepth(device,window,mesh))
                        verify(SDL_DrawGPULitMesh(device,window,mesh,unit[0],unit[1],unit[2],unit[3],unit[0],unit[1],unit[2],unit[3],float4(0.0,0.0,1.0,0.2)) == -1)
                        device |> with_gpu_lit_scene(window) $(scene) {
                            var draws : GpuLitDrawList
                            draws |> gpu_scene_add(mesh,unit,float3(0.0,0.0,1.0))
                            verify(SDL_DrawGPULitScene(device,window,scene,draws.meshes,draws.model_columns,draws.lights,unit[0],unit[1],unit[2],unit[3]) == -1)
                        }
                        check_gpu(SDLTestGPUResize(window))
                        draw(device,window,mesh,unit)
                        check_gpu(SDLTestGPULitDepth(device,window,mesh))
                        let second = try_with_gpu_device(format,true,"") $(other) {
                            verify(SDL_DrawGPUInstancedMesh(other,window,mesh,unit[0],unit[1],unit[2],unit[3],float4(0.0,0.0,1.0,0.2)) == -1)
                            let owned_by_other = SDLTestGPUInstancesOffscreen(other,positions,normals,uv,texels,indices,instances.model_columns,vs,fs,format)
                            verify(owned_by_other != 0ul && SDLTestGPULitMeshes() == 2)
                            verify(!SDL_UpdateGPUInstances(other,mesh,instances.model_columns))
                            other |> gpu_update_instances(owned_by_other,instances)
                            // Deliberately leave this bundle to device-specific cleanup.
                        }
                        verify(second && SDLTestGPULitMeshes() == 1)
                        draw(device,window,mesh,unit)
                    }
                    verify(!SDL_ReleaseGPULitMesh(device,stale))
                    var caught = false
                    try {
                        device |> with_gpu_instanced_mesh(window,positions,normals,uv,indices,texels,1u,1u,vs,fs,format,instances) $(mesh) {
                            device |> gpu_update_instances(mesh,instances)
                            panic("instancing scope sentinel")
                        }
                    } recover { caught = rtrim(this_context().last_exception) == "instancing scope sentinel" }
                    verify(caught && SDLTestGPULitMeshes() == 0)
                    device |> with_gpu_instanced_mesh(window,positions,normals,uv,indices,texels,1u,1u,vs,fs,format,instances) $(mesh) {
                        clear(positions)
                        clear(normals)
                        clear(uv)
                        clear(indices)
                        clear(texels)
                        clear(instances.model_columns)
                        draw(device,window,mesh,unit)
                        return
                    }
                    verify(SDLTestGPULitMeshes() == 0)
                }
            }
            print("Instancing contracts and CPU pixels PASS: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    if (!available) { return 77 }
    return 0
}
