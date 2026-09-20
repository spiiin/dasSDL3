options gen2
module sdl3_gpu_scene_boost shared public
require dassdl3/sdl3_gpu_lit_boost public

// Value-only draw list. It does not own or prolong mesh lifetime.
struct GpuLitDrawList {
    meshes : array<uint64>
    model_columns : array<float4>
    lights : array<float4>
}

def public gpu_scene_add(var draws : GpuLitDrawList; mesh : uint64; model : float4x4;
        light_direction : float3; ambient : float = 0.2) {
    if (length(draws.meshes) >= 1024) { panic("GPU scene: at most 1024 objects") }
    push(draws.meshes,mesh)
    for (i in 0 .. 4) { push(draws.model_columns,model[i]) }
    push(draws.lights,float4(light_direction,ambient))
}
def public gpu_scene_clear(var draws : GpuLitDrawList) {
    clear(draws.meshes)
    clear(draws.model_columns)
    clear(draws.lights)
}
def public with_gpu_lit_scene(device : SDL_GPUDevice?; window : SDL_Window?; blk : block<(scene : uint64) : void>) {
    let scene = SDL_CreateGPULitScene(device,window)
    if (scene == 0ul) { panic("GPU scene: {SDL_GetError()}") }
    SDL_ScopeReleaseGPULitScene(device,scene,blk)
}
def public gpu_draw_lit_scene(device : SDL_GPUDevice?; window : SDL_Window?; scene : uint64;
        draws : GpuLitDrawList; camera : float4x4) : bool {
    let status = SDL_DrawGPULitScene(device,window,scene,draws.meshes,draws.model_columns,draws.lights,
        camera[0],camera[1],camera[2],camera[3])
    if (status < 0) { panic("GPU scene draw: {SDL_GetError()}") }
    return status == 1
}
