options gen2
module sdl3_gpu_instancing_boost shared public
require dassdl3/sdl3_gpu_3d_boost public
require daslib/rtti
require daslib/strings_boost

struct public GpuInstanceList {
    model_columns : array<float4>
}
def public gpu_instance_add(var instances : GpuInstanceList; model : float4x4) {
    if (length(instances.model_columns) >= 16384) { panic("GPU instancing: at most 4096 instances") }
    for (column in 0 .. 4) { push(instances.model_columns,model[column]) }
}

// Copied position(x,y,z,1), normal(x,y,z,0), UV and packed linear RGBA8 arrays.
def public with_gpu_instanced_mesh(device : SDL_GPUDevice?; window : SDL_Window?;
        positions, normals : array<float4>; uv : array<float2>; indices : array<uint>;
        pixels : array<uint8>; width, height : uint; vertex_file, fragment_file : string;
        format : uint; instances : GpuInstanceList; blk : block<(mesh : uint64) : void>) {
    let mesh = SDL_CreateGPUInstancedMesh(device,window,positions,normals,uv,pixels,width,height,indices,instances.model_columns,vertex_file,fragment_file,format)
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
def public gpu_update_instances(device : SDL_GPUDevice?; mesh : uint64; instances : GpuInstanceList) {
    if (!SDL_UpdateGPUInstances(device,mesh,instances.model_columns)) {
        panic("GPU instancing update: {SDL_GetError()}")
    }
}

// One indexed draw for the complete instance buffer.
def public gpu_draw_instanced_mesh(device : SDL_GPUDevice?; window : SDL_Window?; mesh : uint64;
        camera : float4x4; light_direction : float3; ambient : float = 0.2) : bool {
    let status = SDL_DrawGPUInstancedMesh(device,window,mesh,camera[0],camera[1],camera[2],camera[3],float4(light_direction,ambient))
    if (status < 0) { panic("GPU instancing draw: {SDL_GetError()}") }
    return status == 1
}
