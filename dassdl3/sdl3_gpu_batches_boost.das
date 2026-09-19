options gen2
module sdl3_gpu_batches_boost shared public
require dassdl3/sdl3_gpu_instance_colors_boost public
require daslib/rtti
require daslib/strings_boost

// Values only: referenced colored mesh/material bundles must remain alive.
struct public GpuBatchList {
    meshes : array<uint64>
    model_columns : array<float4>
    colors : array<float4>
}
def public gpu_batch_add(var list : GpuBatchList; mesh : uint64; model : float4x4; color : float4 = float4(1.0)) {
    if (length(list.meshes) >= 4096) { panic("GPU batches: at most 4096 objects") }
    push(list.meshes,mesh)
    for (i in 0 .. 4) { push(list.model_columns,model[i]) }
    push(list.colors,color)
}
def public gpu_batch_clear(var list : GpuBatchList) {
    clear(list.meshes)
    clear(list.model_columns)
    clear(list.colors)
}
def public with_gpu_batch_scene(device : SDL_GPUDevice?; window : SDL_Window?; blk : block<(scene : uint64) : void>) {
    let scene = SDL_CreateGPUBatchScene(device,window)
    if (scene == 0ul) { panic("GPU scene: {SDL_GetError()}") }
    var failed = false
    var error = ""
    try { SDL_InvokeGPUHandle(blk,scene) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    let released = SDL_ReleaseGPUBatchScene(device,scene)
    if (!released && failed) { panic("{error}; {SDL_GetError()}") }
    if (failed) { panic(error) }
    if (!released) { panic("GPU scene release: {SDL_GetError()}") }
}
def public gpu_draw_batches(device : SDL_GPUDevice?; window : SDL_Window?; scene : uint64;
        list : GpuBatchList; camera : float4x4; light_direction : float3; ambient : float = 0.2) : bool {
    let status = SDL_DrawGPUBatches(device,window,scene,list.meshes,list.model_columns,list.colors,
        camera[0],camera[1],camera[2],camera[3],float4(light_direction,ambient))
    if (status < 0) { panic("GPU batches draw: {SDL_GetError()}") }
    return status == 1
}
