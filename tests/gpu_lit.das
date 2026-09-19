options gen2
require dassdl3/sdl3_gpu_lit_boost
require daslib/rtti
require daslib/strings_boost

def check_gpu(ok : bool) {
    if (!ok) { panic("GPU lit test: {SDL_GetError()}") }
}
def pixels(device : SDL_GPUDevice?; mesh : uint64; camera, model : float4x4; light : float4) {
    let m = camera * model
    check_gpu(SDLTestGPULitPixels(device,mesh,m[0],m[1],m[2],m[3],model[0],model[1],model[2],model[3],light))
}
def draw(device : SDL_GPUDevice?; window : SDL_Window?; mesh : uint64; camera, model : float4x4) {
    for (attempt in 0 .. 100) {
        SDL_PumpEvents()
        if (device |> gpu_draw_lit_mesh(window,mesh,camera,model,float3(0.3,0.8,1.0),0.2)) { return }
        SDL_Delay(10u)
    }
    panic("GPU lit: no drawable")
}

[export]
def main(smoke : bool) : int {
    verify(SDLTestGPULitGuards())
    var unit : float4x4
    identity(unit)
    let camera = gpu_camera(float3(0.3,0.2,3.0),float3(0.0),float3(0.0,1.0,0.0),1.0,1.25,0.1,20.0)
    var model : float4x4
    identity(model)
    // Rotation and nonuniform scale distinguish inverse-transpose from model multiplication.
    model[0] = float4(1.2,0.0,-0.9,0.0)
    model[1] = float4(0.0,0.7,0.0,0.0)
    model[2] = float4(0.3,0.0,0.4,0.0)
    model[3] = float4(0.1,-0.1,0.1,1.0)
    let light = float4(0.3,0.8,1.0,0.2)
    var caught = false
    var available = false
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL,true,"") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let shaders = "{SDL_GetBasePath()}assets/shaders/lit"
            let vs = "{shaders}.vert.{extension}"
            let fs = "{shaders}.frag.{extension}"
            print("GPU lit tests: {SDL_GetGPUDeviceDriver(device)}\n")
            var positions <- array<float4>(float4(-0.8,-0.7,0.25,1.0),float4(0.8,-0.7,0.25,1.0),float4(0.0,0.8,0.25,1.0),
                float4(-0.6,-0.6,0.75,1.0),float4(0.8,-0.6,0.75,1.0),float4(0.1,0.7,0.75,1.0))
            var normals <- array<float4>(float4(1.0,0.0,1.0,0.0),float4(1.0,0.0,1.0,0.0),float4(1.0,0.0,1.0,0.0),
                float4(0.0,1.0,1.0,0.0),float4(0.0,1.0,1.0,0.0),float4(0.0,1.0,1.0,0.0))
            var uv <- array<float2>(float2(0.0,1.0),float2(1.0,1.0),float2(0.5,0.0),float2(0.0,1.0),float2(1.0,1.0),float2(0.5,0.0))
            var texels <- array<uint8>(uint8(240),uint8(60),uint8(30),uint8(255),uint8(30),uint8(220),uint8(80),uint8(210),uint8(50),uint8(80),uint8(240),uint8(170),uint8(220),uint8(190),uint8(40),uint8(130))
            var indices <- array<uint>(0u,1u,2u,3u,4u,5u)
            verify(SDLTestGPUCreateLitOffscreen(device,positions,normals,uv,texels,2u,2u,indices,"missing",fs,format) == 0ul)
            verify(SDLTestGPUCreateLitOffscreen(device,positions,normals,uv,texels,2u,2u,indices,vs,"missing",format) == 0ul)
            verify(SDLTestGPUShaders() == 0 && SDLTestGPULitMeshes() == 0)
            indices[5] = 6u
            verify(SDLTestGPUCreateLitOffscreen(device,positions,normals,uv,texels,2u,2u,indices,vs,fs,format) == 0ul)
            indices[5] = 5u
            positions[0].w = 0.0
            verify(SDLTestGPUCreateLitOffscreen(device,positions,normals,uv,texels,2u,2u,indices,vs,fs,format) == 0ul)
            positions[0].w = 1.0
            normals[0] = float4(0.0)
            verify(SDLTestGPUCreateLitOffscreen(device,positions,normals,uv,texels,2u,2u,indices,vs,fs,format) == 0ul)
            normals[0] = float4(1.0,0.0,1.0,0.0)
            uv[0].x = 2.0
            verify(SDLTestGPUCreateLitOffscreen(device,positions,normals,uv,texels,2u,2u,indices,vs,fs,format) == 0ul)
            uv[0].x = 0.0
            var stale = 0ul
            with_window("GPU lit contracts",160,120,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_lit_mesh(window,positions,normals,uv,indices,texels,2u,2u,vs,fs,format) $(mesh) {
                        stale = mesh
                        verify(!SDL_ReleaseGPU3DMesh(device,mesh))
                        var singular = model
                        singular[0] = float4(0.0)
                        caught = false
                        try {
                            device |> gpu_draw_lit_mesh(window,mesh,camera,singular,float3(0.0,0.0,1.0))
                        } recover { caught = true }
                        verify(caught)
                        caught = false
                        try {
                            device |> gpu_draw_lit_mesh(window,mesh,camera,model,float3(0.0))
                        } recover { caught = true }
                        verify(caught)
                        draw(device,window,mesh,camera,model)
                        verify(SDLTestGPULitDepth(device,window,mesh))
                        verify(SDLTestGPUResize(window))
                        draw(device,window,mesh,camera,model)
                        verify(SDLTestGPULitDepth(device,window,mesh))
                        draw(device,window,mesh,camera,model)
                        verify(SDLTestGPULitDepth(device,window,mesh))
                        return
                    }
                    verify(SDLTestGPULitMeshes() == 0)
                    verify(!SDL_ReleaseGPULitMesh(device,stale))
                    verify(SDL_DrawGPULitMesh(device,window,stale,unit[0],unit[1],unit[2],unit[3],unit[0],unit[1],unit[2],unit[3],light) == -1)
                    caught = false
                    try {
                        device |> with_gpu_lit_mesh(window,positions,normals,uv,indices,texels,2u,2u,vs,fs,format) $(mesh) {
                            draw(device,window,mesh,camera,model)
                            panic("lit-panic")
                        }
                    } recover {
                        caught = true
                        verify(rtrim(this_context().last_exception) == "lit-panic")
                    }
                    verify(caught && SDLTestGPULitMeshes() == 0)
                }
            }
            let first = SDLTestGPUCreateLitOffscreen(device,positions,normals,uv,texels,2u,2u,indices,vs,fs,format)
            check_gpu(first != 0ul)
            var reverse <- array<uint>(3u,4u,5u,0u,1u,2u)
            let reversed = SDLTestGPUCreateLitOffscreen(device,positions,normals,uv,texels,2u,2u,reverse,vs,fs,format)
            check_gpu(reversed != 0ul)
            pixels(device,first,unit,unit,light)
            pixels(device,reversed,unit,unit,light)
            pixels(device,first,camera,unit,light)
            pixels(device,reversed,camera,unit,light)
            pixels(device,first,camera,model,light)
            pixels(device,reversed,camera,model,light)
            pixels(device,first,camera,model,float4(0.0,0.0,-1.0,0.0))
            pixels(device,first,camera,model,float4(0.0,0.0,1.0,1.0))
            var mirror = model
            mirror[0] = -mirror[0]
            pixels(device,first,camera,mirror,light)
            var other_id = 0ul
            verify(try_with_gpu_device(format,true,SDL_GetGPUDeviceDriver(device)) $(other) {
                other_id = SDLTestGPUCreateLitOffscreen(other,positions,normals,uv,texels,2u,2u,indices,vs,fs,format)
                check_gpu(other_id != 0ul)
                verify(!SDL_ReleaseGPULitMesh(other,first) && !SDL_ReleaseGPULitMesh(device,other_id))
                verify(!SDLTestGPULitPixels(other,first,unit[0],unit[1],unit[2],unit[3],unit[0],unit[1],unit[2],unit[3],light))
                pixels(other,other_id,camera,unit,light)
                pixels(device,first,unit,unit,light)
            })
            verify(SDLTestGPULitMeshes() == 2)
            verify(!SDL_ReleaseGPULitMesh(device,other_id))
            clear(positions)
            clear(normals)
            clear(uv)
            clear(texels)
            clear(indices)
            clear(reverse)
            pixels(device,first,camera,unit,light)
            pixels(device,first,unit,unit,light)
            check_gpu(SDL_ReleaseGPULitMesh(device,first))
            // Second raw ID deliberately left to device shutdown.
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
        verify(SDLTestGPULitMeshes() == 0 && SDLTestGPUShaders() == 0)
    }
    if (!available) { return 77 }
    print("Texture, Lambert light, normal matrix and depth pixel reference, resize, copy, panic and two-device cleanup PASS\n")
    return 0
}
