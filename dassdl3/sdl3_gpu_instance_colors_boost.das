options gen2
module sdl3_gpu_instance_colors_boost shared public
require dassdl3/sdl3_gpu_instancing_boost public
require daslib/rtti
require daslib/strings_boost

struct public GpuColoredInstanceList {
    model_columns : array<float4>
    colors : array<float4>
}
def public gpu_colored_instance_add(var instances : GpuColoredInstanceList; model : float4x4; color : float4 = float4(1.0)) {
    if (length(instances.model_columns) >= 16384) { panic("GPU instancing: at most 4096 instances") }
    push(instances.colors,color)
    for (column in 0 .. 4) { push(instances.model_columns,model[column]) }
}

// Copied position(x,y,z,1), normal(x,y,z,0), UV and packed linear RGBA8 arrays.
def public with_gpu_colored_instanced_mesh(device : SDL_GPUDevice?; window : SDL_Window?;
        positions, normals : array<float4>; uv : array<float2>; indices : array<uint>;
        pixels : array<uint8>; width, height : uint; vertex_file, fragment_file : string;
        format : uint; instances : GpuColoredInstanceList; blk : block<(mesh : uint64) : void>) {
    let mesh = SDL_CreateGPUColoredInstancedMesh(device,window,positions,normals,uv,pixels,width,height,indices,instances.model_columns,instances.colors,vertex_file,fragment_file,format)
    if (mesh == 0ul) { panic("GPU lit mesh: {SDL_GetError()}") }
    var failed = false
    var error = ""
    try { SDL_InvokeGPUHandle(blk,mesh) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    let released = SDL_ReleaseGPULitMesh(device,mesh)
    if (!released && failed) { panic("{error}; {SDL_GetError()}") }
    if (failed) { panic(error) }
    if (!released) { panic("GPU lit release: {SDL_GetError()}") }
}

// Copies the entire list; count must match creation. GPU upload is asynchronous.
def public gpu_update_colored_instances(device : SDL_GPUDevice?; mesh : uint64; instances : GpuColoredInstanceList) {
    if (!SDL_UpdateGPUColoredInstances(device,mesh,instances.model_columns,instances.colors)) {
        panic("GPU instancing update: {SDL_GetError()}")
    }
}

