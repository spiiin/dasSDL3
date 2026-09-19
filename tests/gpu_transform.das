options gen2
require dassdl3/sdl3_gpu_transform_boost
require daslib/rtti
require daslib/strings_boost

def check_gpu(ok : bool) {
    if (!ok) { panic("GPU mesh: {SDL_GetError()}") }
}

def check_transform_pixels(device : SDL_GPUDevice?; mesh : uint64) : bool {
    // Asymmetric rows exercise row ordering, translation, nonuniform scale, rotation and reflection.
    return (SDLTestGPUTransformPixels(device,mesh,float4(1.0,0.0,0.0,0.0),float4(0.0,1.0,0.0,0.0))
        && SDLTestGPUTransformPixels(device,mesh,float4(0.5,0.0,0.0,0.25),float4(0.0,0.75,0.0,-0.125))
        && SDLTestGPUTransformPixels(device,mesh,float4(0.0,-0.7,0.0,0.1),float4(0.5,0.0,0.0,0.15))
        && SDLTestGPUTransformPixels(device,mesh,float4(0.6,-0.2,0.0,-0.1),float4(0.2,0.6,0.0,0.1))
        && SDLTestGPUTransformPixels(device,mesh,float4(-0.6,0.0,0.0,0.1),float4(0.0,0.6,0.0,0.0)))
}

[export]
def main(smoke : bool) : int {
    verify(SDLTestGPUMeshGuards() && SDLTestGPUTransformGuards())
    var available = false
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL, true, "") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let shaders = "{SDL_GetBasePath()}assets/shaders/transform"
            let vs = "{shaders}.vert.{extension}"
            let fs = "{shaders}.frag.{extension}"
            print("GPU transform tests: {SDL_GetGPUDeviceDriver(device)}\n")
            var vertices <- array<float4>(
                float4(-0.75,0.75,0.0,0.0), float4(0.75,0.75,1.0,0.0), float4(0.75,-0.75,1.0,1.0),
                float4(-0.75, -0.75, 0.0, 1.0))
            var indices <- array<uint>(0u,1u,2u,0u,2u,3u)
            var pixels <- array<uint8>(uint8(255), uint8(0), uint8(0), uint8(255), uint8(0), uint8(255), uint8(0), uint8(255), uint8(0), uint8(0), uint8(255), uint8(255), uint8(255), uint8(255), uint8(0), uint8(255))
            verify(SDLTestGPUCreateTransformMeshOffscreen(device,vertices,indices,pixels,"missing-shader",fs,format) == 0ul)
            verify(SDLTestGPUCreateTransformMeshOffscreen(device,vertices,indices,pixels,vs,"missing-shader",format) == 0ul)
            verify(SDLTestGPUShaders() == 0 && SDLTestGPUMeshes() == 0)
            vertices[0].z = 2.0
            verify(SDLTestGPUCreateTransformMeshOffscreen(device,vertices,indices,pixels,vs,fs,format) == 0ul)
            vertices[0].z = 0.0
            indices[5] = 4u
            verify(SDLTestGPUCreateTransformMeshOffscreen(device,vertices,indices,pixels,vs,fs,format) == 0ul)
            indices[5] = 0xffffffffu
            verify(SDLTestGPUCreateTransformMeshOffscreen(device,vertices,indices,pixels,vs,fs,format) == 0ul)
            indices[5] = 3u
            var empty_indices : array<uint>
            verify(SDLTestGPUCreateTransformMeshOffscreen(device,vertices,empty_indices,pixels,vs,fs,format) == 0ul)
            var incomplete <- array<uint>(0u,1u)
            verify(SDLTestGPUCreateTransformMeshOffscreen(device,vertices,incomplete,pixels,vs,fs,format) == 0ul)
            verify(SDLTestGPUMeshes() == 0 && SDLTestGPUShaders() == 0)
            var stale = 0ul
            with_window("GPU mesh contracts",128,128,0ul) $(window) {
                device |> with_gpu_window(window) {
                    let plain_shaders = "{SDL_GetBasePath()}assets/shaders/mesh"
                    let plain = SDL_CreateGPUIndexedTexturedMesh(device,window,vertices,indices,pixels,2u,2u,
                        "{plain_shaders}.vert.{extension}","{plain_shaders}.frag.{extension}",format)
                    check_gpu(plain != 0ul)
                    verify(SDL_DrawGPUTransformMesh(device,window,plain,float4(1.0,0.0,0.0,0.0),float4(0.0,1.0,0.0,0.0)) == -1)
                    verify(SDL_ReleaseGPUTexturedMesh(device,plain))
                    device |> with_gpu_transform_mesh(window,vertices,indices,pixels,2u,2u,vs,fs,format) $(mesh) {
                        stale = mesh
                        verify(SDL_DrawGPUTexturedMesh(device,window,mesh) == -1)
                        verify(SDL_DrawGPUTransformMesh(device,window,mesh,float4(1.0,0.0,1.0,0.0),float4(0.0,1.0,0.0,0.0)) == -1)
                        verify(SDLTestGPUForeignMesh(device,mesh))
                        var frames = 0
                        for (attempt in 0 .. 100) {
                            if (device |> gpu_draw_transform_mesh(window,mesh,float2(0.2,-0.1),float2(0.5,0.8),0.3)) { frames++ }
                            if (frames == 3) { break }
                        }
                        verify(frames == 3)
                        return
                    }
                    verify(SDLTestGPUMeshes() == 0)
                    verify(!SDL_ReleaseGPUTexturedMesh(device,stale))
                    verify(SDL_DrawGPUTexturedMesh(device,window,stale) == -1)
                    verify(SDL_DrawGPUTransformMesh(device,window,stale,float4(1.0,0.0,0.0,0.0),float4(0.0,1.0,0.0,0.0)) == -1)
                    var caught = false
                    try {
                        device |> with_gpu_transform_mesh(window,vertices,indices,pixels,2u,2u,vs,fs,format) $(mesh) {
                            verify(mesh != stale)
                            panic("mesh scoped panic")
                        }
                    } recover {
                        caught = true
                        verify(rtrim(this_context().last_exception) == "mesh scoped panic")
                    }
                    verify(caught && SDLTestGPUMeshes() == 0)
                }
            }
            let reference = SDLTestGPUCreateTransformMeshOffscreen(device,vertices,indices,pixels,vs,fs,format)
            check_gpu(reference != 0ul)
            let shutdown_owned = SDLTestGPUCreateTransformMeshOffscreen(device,vertices,indices,pixels,vs,fs,format)
            check_gpu(shutdown_owned != 0ul && shutdown_owned != reference)
            var other_id = 0ul
            let other_available = try_with_gpu_device(format, true, SDL_GetGPUDeviceDriver(device)) $(other) {
                other_id = SDLTestGPUCreateTransformMeshOffscreen(other,vertices,indices,pixels,vs,fs,format)
                check_gpu(other_id != 0ul)
                verify(!SDL_ReleaseGPUTexturedMesh(device,other_id))
                verify(!SDL_ReleaseGPUTexturedMesh(other,reference))
                check_gpu(check_transform_pixels(other,other_id))
                check_gpu(check_transform_pixels(device,reference))
                verify(SDLTestGPUMeshes() == 3)
                // Device B owns this deliberately unscoped ID and must clean up only B.
            }
            check_gpu(other_available)
            verify(SDLTestGPUMeshes() == 2)
            verify(!SDL_ReleaseGPUTexturedMesh(device,other_id))
            clear(indices)
                        clear(vertices)
            clear(pixels)
            check_gpu(check_transform_pixels(device,reference))
            check_gpu(check_transform_pixels(device,reference))
            verify(SDL_ReleaseGPUTexturedMesh(device,reference))
            verify(SDLTestGPUMeshes() == 1 && SDLTestGPUShaders() == 0)
            // Deliberately leave one raw ID: device shutdown must invalidate and release it.
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
    }
    if (!available) { return 77 }
    verify(SDLTestGPUMeshes() == 0)
    print("GPU textured mesh: uniform rows, transforms, scopes and pixel reference PASS\n")
    return 0
}
