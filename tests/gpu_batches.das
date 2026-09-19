options gen2
require dassdl3/sdl3_gpu_batches_boost
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
            let first = SDLTestGPUColorsOffscreen(device,positions,normals,uv,texels,indices,seed.model_columns,seed.colors,vs,fs,format)
            let second = SDLTestGPUColorsOffscreen(device,positions,normals,uv,alternate,indices,seed.model_columns,seed.colors,vs,fs,format)
            verify(first != 0ul && second != 0ul)
            let scene = SDLTestGPUBatchesOffscreen(device)
            verify(scene != 0ul)
            var list : GpuBatchList
            fill(list,first,second,instances)
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == 2)
            list.meshes[2] = 0ul // A late invalid material must not upload earlier objects.
            check_gpu(SDLTestGPUBatchesPreflight(device,scene,list.meshes,list.model_columns,list.colors))
            fill(list,first,second,instances)
            list.colors[2].x = 2.0
            check_gpu(SDLTestGPUBatchesPreflight(device,scene,list.meshes,list.model_columns,list.colors))
            fill(list,first,second,instances)
            list.model_columns[8] = float4(0.0)
            check_gpu(SDLTestGPUBatchesPreflight(device,scene,list.meshes,list.model_columns,list.colors))
            fill(list,first,second,instances)
            resize(list.meshes,4097)
            check_gpu(SDLTestGPUBatchesPreflight(device,scene,list.meshes,list.model_columns,list.colors))
            fill(list,first,second,instances)
            pop(list.colors)
            check_gpu(SDLTestGPUBatchesPreflight(device,scene,list.meshes,list.model_columns,list.colors))
            fill(list,first,second,instances)
            pop(list.model_columns)
            check_gpu(SDLTestGPUBatchesPreflight(device,scene,list.meshes,list.model_columns,list.colors))
            fill(list,first,second,instances)
            let plain = SDLTestGPUInstancesOffscreen(device,positions,normals,uv,texels,indices,seed.model_columns,
                "{SDL_GetBasePath()}assets/shaders/instances.vert.{extension}","{SDL_GetBasePath()}assets/shaders/instances.frag.{extension}",format)
            verify(plain != 0ul)
            list.meshes[2] = plain
            check_gpu(SDLTestGPUBatchesPreflight(device,scene,list.meshes,list.model_columns,list.colors))
            check_gpu(SDL_ReleaseGPULitMesh(device,plain))
            fill(list,first,second,instances)
            check_gpu(SDLTestGPUBatchesPixels(device,scene,list.meshes,list.model_columns,list.colors,first,second))
            // B,A,A: reverse group order while retaining each object's values.
            swap(list.meshes[0],list.meshes[1])
            swap(list.colors[0],list.colors[1])
            for (i in 0 .. 4) { swap(list.model_columns[i],list.model_columns[4+i]) }
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == 2)
            check_gpu(SDLTestGPUBatchesPixels(device,scene,list.meshes,list.model_columns,list.colors,first,second))
            check_gpu(SDLTestGPUBatchesPending(device,scene,list.meshes,list.model_columns,list.colors,first,second))
            check_gpu(SDLTestGPUBatchesFailure(device,scene,list.meshes,list.model_columns,list.colors))
            check_gpu(SDLTestGPUBatchesPixels(device,scene,list.meshes,list.model_columns,list.colors,first,second))
            gpu_batch_clear(list)
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == 0)
            check_gpu(SDLTestGPUBatchesPixels(device,scene,list.meshes,list.model_columns,list.colors,first,second))
            fill(list,first,first,instances)
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == 1)
            check_gpu(SDLTestGPUBatchesPixels(device,scene,list.meshes,list.model_columns,list.colors,first,second))
            check_gpu(SDL_ReleaseGPULitMesh(device,first))
            verify(SDLTestGPUBatchesCount(device,scene,list.meshes,list.model_columns,list.colors) == -1)
            check_gpu(SDL_ReleaseGPULitMesh(device,second))
            check_gpu(SDL_ReleaseGPUBatchScene(device,scene))
            verify(!SDL_ReleaseGPUBatchScene(device,scene))
            with_window("GPU material batches contracts",160,120,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_colored_instanced_mesh(window,positions,normals,uv,indices,texels,1u,1u,vs,fs,format,seed) $(a) {
                        device |> with_gpu_colored_instanced_mesh(window,positions,normals,uv,indices,alternate,1u,1u,vs,fs,format,seed) $(b) {
                            fill(list,a,b,instances)
                            device |> with_gpu_batch_scene(window) $(batch_scene) {
                                verify(!SDL_ReleaseGPUBatchScene(device,a) && !SDL_ReleaseGPULitMesh(device,batch_scene))
                                draw(device,window,batch_scene,list,unit)
                                check_gpu(SDLTestGPUResize(window))
                                draw(device,window,batch_scene,list,unit)
                                check_gpu(SDLTestGPUBatchesDepth(device,window,batch_scene))
                                let another = try_with_gpu_device(format,true,"") $(other) {
                                    let owned = SDLTestGPUColorsOffscreen(other,positions,normals,uv,texels,indices,seed.model_columns,seed.colors,vs,fs,format)
                                    let own_scene = SDLTestGPUBatchesOffscreen(other)
                                    verify(owned != 0ul && own_scene != 0ul)
                                    verify(SDLTestGPUBatchesCount(other,own_scene,list.meshes,list.model_columns,list.colors) == -1)
                                    verify(!SDL_ReleaseGPUBatchScene(other,batch_scene))
                                    var own_list : GpuBatchList
                                    fill(own_list,owned,owned,instances)
                                    check_gpu(SDLTestGPUBatchesPixels(other,own_scene,own_list.meshes,own_list.model_columns,own_list.colors,owned,0ul))
                                    // Device cleanup owns both the pending-capable scene and material.
                                }
                                verify(another && SDLTestGPUBatchesLive() == 1 && SDLTestGPULitMeshes() == 2)
                                draw(device,window,batch_scene,list,unit)
                            }
                            var caught = false
                            try {
                                device |> with_gpu_batch_scene(window) $(batch_scene) {
                                    draw(device,window,batch_scene,list,unit)
                                    panic("batch scope sentinel")
                                }
                            } recover { caught = rtrim(this_context().last_exception) == "batch scope sentinel" }
                            verify(caught && SDLTestGPUBatchesLive() == 0)
                            device |> with_gpu_batch_scene(window) $(batch_scene) {
                                draw(device,window,batch_scene,list,unit)
                                return
                            }
                            verify(SDLTestGPUBatchesLive() == 0)
                        }
                    }
                }
            }
            verify(SDLTestGPULitMeshes() == 0)
            print("Material groups, shared-depth CPU pixels, queued frames and cleanup PASS: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    return available ? 0 : 77
}
