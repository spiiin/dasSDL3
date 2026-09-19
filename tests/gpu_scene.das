options gen2
require dassdl3/sdl3_gpu_scene_boost
require daslib/rtti
require daslib/strings_boost

def check_gpu(ok : bool) {
    if (!ok) { panic("GPU scene test: {SDL_GetError()}") }
}
def preflight(device : SDL_GPUDevice?; scene : uint64; draws : GpuLitDrawList; camera : float4x4; valid : bool) {
    check_gpu(SDLTestGPUScenePreflight(device,scene,draws.meshes,draws.model_columns,draws.lights,
        camera[0],camera[1],camera[2],camera[3],valid))
}
def pixels(device : SDL_GPUDevice?; scene : uint64; draws : GpuLitDrawList; camera : float4x4; red, green : uint64) {
    check_gpu(SDLTestGPUScenePixels(device,scene,draws.meshes,draws.model_columns,draws.lights,
        camera[0],camera[1],camera[2],camera[3],red,green))
}
def draw(device : SDL_GPUDevice?; window : SDL_Window?; scene : uint64; draws : GpuLitDrawList; camera : float4x4) {
    for (attempt in 0 .. 100) {
        SDL_PumpEvents()
        if (device |> gpu_draw_lit_scene(window,scene,draws,camera)) { return }
        SDL_Delay(10u)
    }
    panic("GPU scene: no drawable")
}
[export]
def main(smoke : bool) : int {
    verify(SDLTestGPUSceneSizes())
    var unit : float4x4
    identity(unit)
    var front = unit
    front[3] = float4(-0.15,0.0,0.25,1.0)
    var back = unit
    back[3] = float4(0.15,0.0,0.75,1.0)
    let camera = gpu_camera(float3(0.3,0.2,3.0),float3(0.0),float3(0.0,1.0,0.0),1.0,1.25,0.1,20.0)
    let toward = float3(0.0,0.0,1.0)
    let away = float3(0.0,0.0,-1.0)
    var available = false
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL,true,"") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let vs = "{SDL_GetBasePath()}assets/shaders/lit.vert.{extension}"
            let fs = "{SDL_GetBasePath()}assets/shaders/lit.frag.{extension}"
            print("GPU scene: {SDL_GetGPUDeviceDriver(device)}\n")
            var positions <- array<float4>(float4(-0.8,-0.7,0.0,1.0),float4(0.8,-0.7,0.0,1.0),float4(0.0,0.8,0.0,1.0))
            var normals <- array<float4>(float4(0.0,0.0,1.0,0.0),float4(0.0,0.0,1.0,0.0),float4(0.0,0.0,1.0,0.0))
            var uv <- array<float2>(float2(0.0),float2(0.0),float2(0.0))
            var indices <- array<uint>(0u,1u,2u)
            var red_tex <- array<uint8>(uint8(255),uint8(0),uint8(0),uint8(255))
            var green_tex <- array<uint8>(uint8(0),uint8(255),uint8(0),uint8(255))
            var draws : GpuLitDrawList
            var stale_scene = 0ul
            with_window("GPU shared depth contracts",160,120,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_lit_mesh(window,positions,normals,uv,indices,red_tex,1u,1u,vs,fs,format) $(mesh) {
                        draws |> gpu_scene_add(mesh,front,toward)
                        draws |> gpu_scene_add(mesh,back,away,0.5)
                        device |> with_gpu_lit_scene(window) $(scene) {
                            stale_scene = scene
                            verify(!SDL_ReleaseGPULitScene(device,mesh) && !SDL_ReleaseGPULitMesh(device,scene))
                            draw(device,window,scene,draws,unit)
                            verify(SDLTestGPUSceneDepth(device,window,scene))
                            check_gpu(SDLTestGPUSceneDepthFailure(device,window,scene))
                            draw(device,window,scene,draws,unit)
                            verify(SDLTestGPUSceneDepth(device,window,scene))
                            verify(SDLTestGPUResize(window))
                            draw(device,window,scene,draws,unit)
                            verify(SDLTestGPUSceneDepth(device,window,scene))
                            // Empty list clears the same pass; subsequent populated frame still works.
                            draws |> gpu_scene_clear()
                            draw(device,window,scene,draws,unit)
                            draws |> gpu_scene_add(mesh,front,toward)
                            draw(device,window,scene,draws,unit)
                            return
                        }
                        verify(SDLTestGPUScenes() == 0)
                        verify(!SDL_ReleaseGPULitScene(device,stale_scene))
                        verify(SDL_DrawGPULitScene(device,window,stale_scene,draws.meshes,draws.model_columns,draws.lights,unit[0],unit[1],unit[2],unit[3]) == -1)
                        var caught = false
                        try {
                            device |> with_gpu_lit_scene(window) $(scene) {
                                draw(device,window,scene,draws,unit)
                                panic("scene-panic")
                            }
                        } recover {
                            caught = true
                            verify(rtrim(this_context().last_exception) == "scene-panic")
                        }
                        verify(caught && SDLTestGPUScenes() == 0)
                    }
                }
            }
            draws |> gpu_scene_clear()
            let red = SDLTestGPUCreateLitOffscreen(device,positions,normals,uv,red_tex,1u,1u,indices,vs,fs,format)
            let green = SDLTestGPUCreateLitOffscreen(device,positions,normals,uv,green_tex,1u,1u,indices,vs,fs,format)
            let scene = SDLTestGPUSceneOffscreen(device)
            check_gpu(red != 0ul && green != 0ul && scene != 0ul)
            // Empty, one object, two distinct pipelines/textures, both orders and camera transforms.
            pixels(device,scene,draws,unit,red,green)
            draws |> gpu_scene_add(red,front,toward,1.0)
            pixels(device,scene,draws,unit,red,green)
            draws |> gpu_scene_add(green,back,away,0.5)
            preflight(device,scene,draws,unit,true)
            pixels(device,scene,draws,unit,red,green)
            pixels(device,scene,draws,camera,red,green)
            draws |> gpu_scene_clear()
            draws |> gpu_scene_add(green,back,away,0.5)
            draws |> gpu_scene_add(red,front,toward,1.0)
            pixels(device,scene,draws,unit,red,green)
            pixels(device,scene,draws,camera,red,green)
            // Invalid final item must reject the whole list before acquisition.
            draws.meshes[1] = 0ul
            preflight(device,scene,draws,unit,false)
            draws.meshes[1] = scene
            preflight(device,scene,draws,unit,false)
            draws.meshes[1] = red
            draws.model_columns[4] = float4(0.0)
            preflight(device,scene,draws,unit,false)
            draws.model_columns[4] = front[0]
            draws.lights[1] = float4(0.0)
            preflight(device,scene,draws,unit,false)
            draws.lights[1] = float4(toward,1.0)
            push(draws.model_columns,float4(0.0))
            preflight(device,scene,draws,unit,false)
            draws |> gpu_scene_clear()
            // Repeated mesh with independent transforms/lights is supported (ordinary draws, not instancing).
            draws |> gpu_scene_add(red,front,toward,1.0)
            draws |> gpu_scene_add(red,back,away,0.5)
            pixels(device,scene,draws,unit,red,green)
            draws |> gpu_scene_clear()
            for (i in 0 .. 1024) { draws |> gpu_scene_add(red,front,toward) }
            preflight(device,scene,draws,unit,true)
            var caught = false
            try { draws |> gpu_scene_add(red,front,toward) } recover { caught = true }
            verify(caught && length(draws.meshes) == 1024)
            push(draws.meshes,red)
            preflight(device,scene,draws,unit,false)
            draws |> gpu_scene_clear()
            draws |> gpu_scene_add(red,front,toward,1.0)
            draws |> gpu_scene_add(green,back,away,0.5)
            var other_scene = 0ul
            verify(try_with_gpu_device(format,true,SDL_GetGPUDeviceDriver(device)) $(other) {
                let other_mesh = SDLTestGPUCreateLitOffscreen(other,positions,normals,uv,red_tex,1u,1u,indices,vs,fs,format)
                other_scene = SDLTestGPUSceneOffscreen(other)
                check_gpu(other_mesh != 0ul && other_scene != 0ul)
                verify(!SDL_ReleaseGPULitScene(other,scene) && !SDL_ReleaseGPULitScene(device,other_scene))
                draws.meshes[1] = other_mesh
                preflight(device,scene,draws,unit,false)
                draws.meshes[1] = green
                var other_draws : GpuLitDrawList
                other_draws |> gpu_scene_add(other_mesh,front,toward,1.0)
                pixels(other,other_scene,other_draws,unit,other_mesh,0ul)
                pixels(device,scene,draws,unit,red,green)
            })
            verify(SDLTestGPUScenes() == 1 && SDLTestGPULitMeshes() == 2)
            verify(!SDL_ReleaseGPULitScene(device,other_scene))
            clear(positions)
            clear(normals)
            clear(uv)
            clear(indices)
            clear(red_tex)
            clear(green_tex)
            pixels(device,scene,draws,unit,red,green)
            check_gpu(SDL_ReleaseGPULitMesh(device,green))
            preflight(device,scene,draws,unit,false)
            draws |> gpu_scene_clear()
            draws |> gpu_scene_add(red,front,toward,1.0)
            pixels(device,scene,draws,unit,red,green)
            // Scene and red mesh deliberately left for device-specific shutdown cleanup.
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
        verify(SDLTestGPUScenes() == 0 && SDLTestGPULitMeshes() == 0)
    }
    if (!available) { return 77 }
    print("Scene shared-depth pixels, atomic validation, resize/failure, scopes and two-device cleanup PASS\n")
    return 0
}
