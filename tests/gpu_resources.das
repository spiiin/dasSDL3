options gen2
require dassdl3/sdl3_gpu_resources_boost
require dassdl3/sdl3_gpu_scene_boost
require daslib/rtti
require daslib/strings_boost

def check_gpu(ok : bool) {
    if (!ok) { panic("GPU batches test: {SDL_GetError()}") }
}
def draw(device : SDL_GPUDevice?; window : SDL_Window?; scene : uint64; list : GpuBatchList; camera : float4x4) {
    for (attempt in 0 .. 100) {
        SDL_PumpEvents()
        if (device |> gpu_draw_batches(window,scene,list,camera,float3(0.0,0.0,1.0))) { return }
        SDL_Delay(10u)
    }
    panic("GPU batches: no drawable")
}
def fill(var list : GpuBatchList; first, second : uint64; instances : GpuColoredInstanceList) {
    gpu_batch_clear(list)
    for (i in 0 .. 3) {
        var model : float4x4
        for (c in 0 .. 4) { model[c] = instances.model_columns[i*4+c] }
        list |> gpu_batch_add(i == 1 ? second : first,model,instances.colors[i])
    }
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
    instances.colors[0] = float4(1.0,0.4,0.6,0.5)
    instances.colors[1] = float4(0.3,1.0,0.8,0.75)
    var seed : GpuColoredInstanceList
    seed |> gpu_colored_instance_add(unit)
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
            var alternate <- array<uint8>(uint8(32),uint8(100),uint8(240),uint8(255))
            var bad_indices <- array<uint>(0u,1u,8u)
            verify(SDL_CreateGPUGeometry(device,positions,normals,uv,bad_indices) == 0ul)
            verify(SDLTestGPUGeometries() == 0)
            let geometry = SDL_CreateGPUGeometry(device,positions,normals,uv,indices)
            verify(geometry != 0ul)
            verify(SDLTestGPUMaterialOffscreen(device,texels,vs,"missing-shader",format) == 0ul)
            verify(SDLTestGPUMaterials() == 0 && SDLTestGPUGeometries() == 1)
            let warm = SDLTestGPUMaterialOffscreen(device,texels,vs,fs,format)
            let cool = SDLTestGPUMaterialOffscreen(device,alternate,vs,fs,format)
            verify(warm != 0ul && cool != 0ul)
            let first = SDL_CreateGPUSharedMesh(device,geometry,warm)
            let second = SDL_CreateGPUSharedMesh(device,geometry,cool)
            let alias = SDL_CreateGPUSharedMesh(device,geometry,warm)
            verify(first != 0ul && second != 0ul && alias != 0ul && first != alias)
            check_gpu(SDLTestGPUResourcesShared(device,geometry,warm,cool,first,second))
            verify(SDLTestGPUGeometries() == 1 && SDLTestGPUMaterials() == 2 && SDLTestGPUSharedMeshes() == 3)
            // Resource kinds are never interchangeable, even though IDs have the same script type.
            verify(SDL_CreateGPUSharedMesh(device,warm,geometry) == 0ul)
            verify(!SDL_ReleaseGPULitMesh(device,first) && !SDL_ReleaseGPUGeometry(device,warm))
            verify(!SDL_ReleaseGPUMaterial(device,geometry) && !SDL_ReleaseGPUSharedMesh(device,geometry))
            let scene = SDLTestGPUBatchesOffscreen(device)
            var list : GpuBatchList
            fill(list,first,alias,instances)
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == 1)
            check_gpu(SDL_ReleaseGPUSharedMesh(device,alias))
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == -1)
            fill(list,first,second,instances)
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == 2)
            check_gpu(SDLTestGPUBatchesPixels(device,scene,list.meshes,list.model_columns,list.colors,first,second))
            check_gpu(SDLTestGPUBatchesPending(device,scene,list.meshes,list.model_columns,list.colors,first,second))
            check_gpu(SDLTestGPUBatchesFailure(device,scene,list.meshes,list.model_columns,list.colors))
            check_gpu(SDLTestGPUBatchesPixels(device,scene,list.meshes,list.model_columns,list.colors,first,second))
            // An old owned mesh and new shared meshes may coexist in a single list.
            let legacy = SDLTestGPUColorsOffscreen(device,positions,normals,uv,texels,indices,seed.model_columns,seed.colors,vs,fs,format)
            fill(list,legacy,second,instances)
            check_gpu(SDLTestGPUBatchesPixels(device,scene,list.meshes,list.model_columns,list.colors,legacy,second))
            check_gpu(SDL_ReleaseGPULitMesh(device,legacy))
            // A material is also reusable with another geometry; changing neither allocation is required.
            let geometry2 = SDL_CreateGPUGeometry(device,positions,normals,uv,indices)
            let third = SDL_CreateGPUSharedMesh(device,geometry2,warm)
            fill(list,first,third,instances)
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == 2)
            let reference = SDLTestGPUColorsOffscreen(device,positions,normals,uv,texels,indices,seed.model_columns,seed.colors,vs,fs,format)
            var reference_list : GpuBatchList
            fill(reference_list,reference,reference,instances)
            check_gpu(SDLTestGPUCullingCompare(device,scene,reference_list.meshes,reference_list.model_columns,reference_list.colors,
                list.meshes,list.model_columns,list.colors,unit[0],unit[1],unit[2],unit[3],true))
            check_gpu(SDL_ReleaseGPULitMesh(device,reference))
            check_gpu(SDL_ReleaseGPUGeometry(device,geometry2))
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == -1)
            check_gpu(SDL_ReleaseGPUSharedMesh(device,third))
            fill(list,first,second,instances)
            check_gpu(SDL_ReleaseGPUMaterial(device,cool))
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == -1)
            check_gpu(SDL_ReleaseGPUSharedMesh(device,second))
            verify(!SDL_ReleaseGPUMaterial(device,cool))
            fill(list,first,first,instances)
            // Queue a frame, release parents and binding before waiting, then check pixels.
            check_gpu(SDLTestGPUResourcesPendingRelease(device,scene,geometry,warm,first,list.meshes,list.model_columns,list.colors))
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == -1)
            check_gpu(SDL_ReleaseGPUBatchScene(device,scene))
            verify(SDLTestGPUGeometries() == 0 && SDLTestGPUMaterials() == 0 && SDLTestGPUSharedMeshes() == 0)
            with_window("GPU shared geometry contracts",160,120,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_geometry(positions,normals,uv,indices) $(g) {
                        device |> with_gpu_material(window,texels,1u,1u,vs,fs,format) $(material) {
                            device |> with_gpu_shared_mesh(g,material) $(mesh) {
                                fill(list,mesh,mesh,instances)
                                device |> with_gpu_batch_scene(window) $(batch_scene) {
                                    draw(device,window,batch_scene,list,unit)
                                    check_gpu(SDLTestGPUResize(window))
                                    draw(device,window,batch_scene,list,unit)
                                    check_gpu(SDLTestGPUBatchesDepth(device,window,batch_scene))
                                    let another = try_with_gpu_device(format,true,"") $(other) {
                                        let og = SDL_CreateGPUGeometry(other,positions,normals,uv,indices)
                                        let om = SDLTestGPUMaterialOffscreen(other,texels,vs,fs,format)
                                        let own = SDL_CreateGPUSharedMesh(other,og,om)
                                        let own_scene = SDLTestGPUBatchesOffscreen(other)
                                        verify(og != 0ul && om != 0ul && own != 0ul)
                                        verify(SDL_CreateGPUSharedMesh(other,g,om) == 0ul)
                                        verify(SDL_CreateGPUSharedMesh(other,og,material) == 0ul)
                                        verify(!SDL_ReleaseGPUGeometry(other,g) && !SDL_ReleaseGPUMaterial(other,material) && !SDL_ReleaseGPUSharedMesh(other,mesh))
                                        var own_list : GpuBatchList
                                        fill(own_list,own,own,instances)
                                        check_gpu(SDLTestGPUBatchesPixels(other,own_scene,own_list.meshes,own_list.model_columns,own_list.colors,own,0ul))
                                        verify(SDLTestGPUBatchesCount(other,own_scene,list.meshes,list.model_columns,list.colors) == -1)
                                        // Device destruction cleans these resources, without touching the outer device.
                                    }
                                    verify(another && SDLTestGPUGeometries() == 1 && SDLTestGPUMaterials() == 1 && SDLTestGPUSharedMeshes() == 1)
                                    draw(device,window,batch_scene,list,unit)
                                }
                            }
                            device |> with_gpu_shared_mesh(g,material) $(mesh) { return }
                            verify(SDLTestGPUSharedMeshes() == 0)
                        }
                    }
                    // Copy source arrays and protected nested panic cleanup are exercised together.
                    var caught = false
                    try {
                        device |> with_gpu_geometry(positions,normals,uv,indices) $(g) {
                            device |> with_gpu_material(window,texels,1u,1u,vs,fs,format) $(material) {
                                device |> with_gpu_shared_mesh(g,material) $(mesh) {
                                    clear(positions)
                                    clear(normals)
                                    clear(uv)
                                    clear(indices)
                                    clear(texels)
                                    fill(list,mesh,mesh,instances)
                                    device |> with_gpu_batch_scene(window) $(batch_scene) {
                                        draw(device,window,batch_scene,list,unit)
                                        panic("shared resource scope sentinel")
                                    }
                                }
                            }
                        }
                    } recover { caught = rtrim(this_context().last_exception) == "shared resource scope sentinel" }
                    verify(caught && SDLTestGPUGeometries() == 0 && SDLTestGPUMaterials() == 0 && SDLTestGPUSharedMeshes() == 0 && SDLTestGPUBatchesLive() == 0)
                }
            }
            print("Shared geometry/material identity, CPU pixels, stale parents, pending release and scopes PASS: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    return available ? 0 : 77
}
