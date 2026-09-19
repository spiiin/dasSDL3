options gen2
require dassdl3/sdl3_gpu_culling_boost

def check_pixels(device : SDL_GPUDevice?; scene : uint64; all, visible : GpuBatchList; camera : float4x4; expect_pixels : bool) {
    if (!SDLTestGPUCullingCompare(device,scene,all.meshes,all.model_columns,all.colors,
        visible.meshes,visible.model_columns,visible.colors,camera[0],camera[1],camera[2],camera[3],expect_pixels)) { panic("GPU culling: {SDL_GetError()}") }
}

def filter(var visible : GpuBatchList; all : GpuBatchList; camera : float4x4) {
    gpu_batch_clear(visible)
    let frustum = gpu_frustum(camera)
    for (i in 0 .. length(all.meshes)) {
        var model : float4x4
        for (c in 0 .. 4) { model[c] = all.model_columns[4*i+c] }
        visible |> gpu_batch_add_visible(frustum,all.meshes[i],model,float4(0.0,0.0,0.0,1.1),all.colors[i])
    }
}

[export]
def main(smoke : bool) : int {
    var unit : float4x4
    identity(unit)
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
            var normals <- array<float4>(float4(0.0,0.0,1.0,0.0),float4(0.0,0.0,1.0,0.0),float4(0.0,0.0,1.0,0.0))
            var uv <- array<float2>(float2(0.0),float2(0.0),float2(0.0))
            var indices <- array<uint>(0u,1u,2u)
            var texels <- array<uint8>(uint8(160),uint8(210),uint8(96),uint8(255))
            var alternate <- array<uint8>(uint8(32),uint8(100),uint8(240),uint8(255))
            let first = SDLTestGPUColorsOffscreen(device,positions,normals,uv,texels,indices,seed.model_columns,seed.colors,vs,fs,format)
            let second = SDLTestGPUColorsOffscreen(device,positions,normals,uv,alternate,indices,seed.model_columns,seed.colors,vs,fs,format)
            let scene = SDLTestGPUBatchesOffscreen(device)
            verify(first != 0ul && second != 0ul && scene != 0ul)
            var all : GpuBatchList
            var visible : GpuBatchList
            // Visible and edge-clipped triangles, nonuniform/reflected/sheared transforms.
            for (i in 0 .. 9) {
                var model = unit
                model[0] = float4(i == 1 ? -0.4 : 0.4,0.0,0.0,0.0)
                model[1] = float4(0.1,0.5,0.0,0.0)
                model[2] = float4(0.0,0.0,0.3,0.0)
                model[3] = float4(-0.4+float(i)*0.5,0.0,0.3+float(i)*0.1,1.0)
                if (i == 2) { model[3].x = 1.05 }
                if (i == 3) { model[3] = float4(8.0,0.0,0.5,1.0) }
                if (i == 4) { model[3] = float4(0.0,8.0,0.5,1.0) }
                if (i == 5) { model[3] = float4(0.0,0.0,-8.0,1.0) }
                if (i == 6) { model[3] = float4(0.0,0.0,8.0,1.0) }
                // Actual triangles cross near and far, not merely their bounding spheres.
                if (i == 7 || i == 8) {
                    model[0].z = 0.4
                    model[3] = float4(-0.2,i == 7 ? 0.5 : -0.5,i == 7 ? 0.05 : 0.95,1.0)
                }
                all |> gpu_batch_add(i%2 == 0 ? first : second,model,float4(1.0,0.7,0.9,1.0))
            }
            filter(visible,all,unit)
            verify(length(visible.meshes) == 5)
            check_pixels(device,scene,all,visible,unit,true)
            // Real perspective cameras, including changed aspect; each must remove objects.
            for (i in 0 .. 3) {
                let camera = gpu_camera(float3(float(i)*0.3,0.1,3.0),float3(0.0,0.0,0.5),float3(0.0,1.0,0.0),1.0,1.0+float(i)*0.4,0.1,6.0)
                filter(visible,all,camera)
                verify(length(visible.meshes) > 0 && length(visible.meshes) < length(all.meshes))
                check_pixels(device,scene,all,visible,camera,true)
            }
            // Cull every object: compare an actual all-offscreen render to the empty clear.
            for (i in 0 .. length(all.meshes)) { all.model_columns[i*4+3].x += 100.0 }
            filter(visible,all,unit)
            verify(length(visible.meshes) == 0)
            check_pixels(device,scene,all,visible,unit,false)
            gpu_batch_clear(all)
            filter(visible,all,unit)
            check_pixels(device,scene,all,visible,unit,false)
            verify(SDL_ReleaseGPUBatchScene(device,scene))
            verify(SDL_ReleaseGPULitMesh(device,second) && SDL_ReleaseGPULitMesh(device,first))
            print("Culling ON/OFF pixel equality, clip boundaries, perspective/resize and empty frame PASS: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    return available ? 0 : 77
}
