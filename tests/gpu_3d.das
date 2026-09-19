options gen2
require dassdl3/sdl3_gpu_3d_boost
require daslib/rtti
require daslib/strings_boost

def check_gpu(ok : bool) {
    if (!ok) { panic("GPU 3D test: {SDL_GetError()}") }
}
def pixels(device : SDL_GPUDevice?; mesh : uint64; matrix : float4x4) {
    check_gpu(SDLTestGPU3DPixels(device,mesh,matrix[0],matrix[1],matrix[2],matrix[3]))
}
def draw(device : SDL_GPUDevice?; window : SDL_Window?; mesh : uint64; matrix : float4x4) {
    for (attempt in 0 .. 100) {
        SDL_PumpEvents()
        if (device |> gpu_draw_3d_mesh(window,mesh,matrix)) { return }
        SDL_Delay(10u)
    }
    panic("GPU 3D: no drawable")
}

[export]
def main(smoke : bool) : int {
    verify(SDLTestGPU3DGuards())
    var unit : float4x4
    identity(unit)
    let projection = perspective_rh_0_to_1(1.0,1.25,0.1,20.0)
    let near_clip = projection * float4(0.0,0.0,-0.1,1.0)
    let far_clip = projection * float4(0.0,0.0,-20.0,1.0)
    verify(abs(near_clip.w-0.1) < 0.00001 && abs(near_clip.z/near_clip.w) < 0.00001)
    verify(abs(far_clip.z/far_clip.w-1.0) < 0.00001)
    let camera = gpu_camera(float3(0.3,0.2,3.0),float3(0.0),float3(0.0,1.0,0.0),1.0,1.25,0.1,20.0)
    var model : float4x4
    identity(model)
    model[0] = float4(0.8,0.0,-0.6,0.0)
    model[2] = float4(0.6,0.0,0.8,0.0)
    model[3] = float4(0.1,-0.1,0.1,1.0)
    var caught = false
    try { let invalid = gpu_camera(float3(0.0),float3(0.0),float3(0.0,1.0,0.0),1.0,1.0,0.1,10.0) } recover { caught = true }
    verify(caught)
    caught = false
    try { let invalid = gpu_camera(float3(0.0,0.0,3.0),float3(0.0),float3(0.0,1.0,0.0),1.0,0.0,0.1,10.0) } recover { caught = true }
    verify(caught)
    var available = false
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL,true,"") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let shaders = "{SDL_GetBasePath()}assets/shaders/scene3d"
            let vs = "{shaders}.vert.{extension}"
            let fs = "{shaders}.frag.{extension}"
            print("GPU 3D tests: {SDL_GetGPUDeviceDriver(device)}\n")
            var positions <- array<float4>(float4(-0.8,-0.7,0.25,1.0),float4(0.8,-0.7,0.25,1.0),float4(0.0,0.8,0.25,1.0),
                float4(-0.6,-0.6,0.75,1.0),float4(0.8,-0.6,0.75,1.0),float4(0.1,0.7,0.75,1.0))
            var colors <- array<float4>(float4(1.0,0.0,0.0,1.0),float4(1.0,0.0,0.0,1.0),float4(1.0,0.0,0.0,1.0),
                float4(0.0,1.0,0.0,1.0),float4(0.0,1.0,0.0,1.0),float4(0.0,1.0,0.0,1.0))
            var indices <- array<uint>(0u,1u,2u,3u,4u,5u)
            verify(SDLTestGPUCreate3DOffscreen(device,positions,colors,indices,"missing",fs,format) == 0ul)
            verify(SDLTestGPUCreate3DOffscreen(device,positions,colors,indices,vs,"missing",format) == 0ul)
            verify(SDLTestGPUShaders() == 0 && SDLTestGPU3DMeshes() == 0)
            indices[5] = 6u
            verify(SDLTestGPUCreate3DOffscreen(device,positions,colors,indices,vs,fs,format) == 0ul)
            indices[5] = 5u
            positions[0].w = 0.0
            verify(SDLTestGPUCreate3DOffscreen(device,positions,colors,indices,vs,fs,format) == 0ul)
            positions[0].w = 1.0
            colors[0].x = 2.0
            verify(SDLTestGPUCreate3DOffscreen(device,positions,colors,indices,vs,fs,format) == 0ul)
            colors[0].x = 1.0
            var stale = 0ul
            with_window("GPU 3D contracts",160,120,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_3d_mesh(window,positions,colors,indices,vs,fs,format) $(mesh) {
                        stale = mesh
                        verify(SDLTestGPU3DForeign(device,mesh))
                        draw(device,window,mesh,camera)
                        verify(SDLTestGPU3DDepthMatches(device,window,mesh))
                        verify(SDLTestGPUResize(window))
                        draw(device,window,mesh,camera)
                        verify(SDLTestGPU3DDepthMatches(device,window,mesh))
                        check_gpu(SDLTestGPU3DDepthContracts(device,mesh))
                        draw(device,window,mesh,camera)
                        verify(SDLTestGPU3DDepthMatches(device,window,mesh))
                        return
                    }
                    verify(SDLTestGPU3DMeshes() == 0 && SDLTestGPU3DDepths() == 0)
                    verify(!SDL_ReleaseGPU3DMesh(device,stale))
                    verify(SDL_DrawGPU3DMesh(device,window,stale,unit[0],unit[1],unit[2],unit[3]) == -1)
                    caught = false
                    try {
                        device |> with_gpu_3d_mesh(window,positions,colors,indices,vs,fs,format) $(mesh) {
                            draw(device,window,mesh,camera)
                            panic("3d-panic")
                        }
                    } recover {
                        caught = true
                        verify(rtrim(this_context().last_exception) == "3d-panic")
                    }
                    verify(caught && SDLTestGPU3DMeshes() == 0 && SDLTestGPU3DDepths() == 0)
                }
            }
            let first = SDLTestGPUCreate3DOffscreen(device,positions,colors,indices,vs,fs,format)
            check_gpu(first != 0ul)
            var reverse <- array<uint>(3u,4u,5u,0u,1u,2u)
            let reversed = SDLTestGPUCreate3DOffscreen(device,positions,colors,reverse,vs,fs,format)
            check_gpu(reversed != 0ul)
            pixels(device,first,unit)
            pixels(device,reversed,unit)
            pixels(device,first,camera)
            pixels(device,reversed,camera)
            pixels(device,first,camera * model)
            pixels(device,reversed,camera * model)
            var other_id = 0ul
            verify(try_with_gpu_device(format,true,SDL_GetGPUDeviceDriver(device)) $(other) {
                other_id = SDLTestGPUCreate3DOffscreen(other,positions,colors,indices,vs,fs,format)
                check_gpu(other_id != 0ul)
                verify(!SDL_ReleaseGPU3DMesh(other,first) && !SDL_ReleaseGPU3DMesh(device,other_id))
                pixels(other,other_id,camera)
                pixels(device,first,unit)
            })
            verify(SDLTestGPU3DMeshes() == 2 && SDLTestGPU3DDepths() == 2)
            verify(!SDL_ReleaseGPU3DMesh(device,other_id))
            clear(positions)
            clear(colors)
            clear(indices)
            clear(reverse)
            pixels(device,first,camera)
            pixels(device,first,unit)
            check_gpu(SDL_ReleaseGPU3DMesh(device,first))
            // Second raw ID deliberately left to device shutdown.
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
        verify(SDLTestGPU3DMeshes() == 0 && SDLTestGPU3DDepths() == 0 && SDLTestGPUShaders() == 0)
    }
    if (!available) { return 77 }
    print("3D matrices, depth/order pixel reference, resize, copy, panic and two-device cleanup PASS\n")
    return 0
}
