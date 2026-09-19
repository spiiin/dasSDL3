options gen2
module sdl3_gpu_resources_boost shared public
require dassdl3/sdl3_gpu_culling_boost public
require daslib/rtti
require daslib/strings_boost

def public with_gpu_geometry(device : SDL_GPUDevice?; positions, normals : array<float4>; uv : array<float2>; indices : array<uint>; blk : block<(id : uint64) : void>) {
    let id = SDL_CreateGPUGeometry(device,positions,normals,uv,indices)
    if (id == 0ul) { panic("GPU geometry: {SDL_GetError()}") }
    var failed = false
    var error = ""
    try { SDL_InvokeGPUHandle(blk,id) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    let released = SDL_ReleaseGPUGeometry(device,id)
    if (!released && failed) { panic("{error}; {SDL_GetError()}") }
    if (failed) { panic(error) }
    if (!released) { panic("GPU geometry release: {SDL_GetError()}") }
}

def public with_gpu_material(device : SDL_GPUDevice?; window : SDL_Window?; pixels : array<uint8>; width, height : uint; vertex_file, fragment_file : string; format : uint; blk : block<(id : uint64) : void>) {
    let id = SDL_CreateGPUMaterial(device,window,pixels,width,height,vertex_file,fragment_file,format)
    if (id == 0ul) { panic("GPU material: {SDL_GetError()}") }
    var failed = false
    var error = ""
    try { SDL_InvokeGPUHandle(blk,id) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    let released = SDL_ReleaseGPUMaterial(device,id)
    if (!released && failed) { panic("{error}; {SDL_GetError()}") }
    if (failed) { panic(error) }
    if (!released) { panic("GPU material release: {SDL_GetError()}") }
}

def public with_gpu_shared_mesh(device : SDL_GPUDevice?; geometry, material : uint64; blk : block<(id : uint64) : void>) {
    let id = SDL_CreateGPUSharedMesh(device,geometry,material)
    if (id == 0ul) { panic("GPU shared_mesh: {SDL_GetError()}") }
    var failed = false
    var error = ""
    try { SDL_InvokeGPUHandle(blk,id) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    let released = SDL_ReleaseGPUSharedMesh(device,id)
    if (!released && failed) { panic("{error}; {SDL_GetError()}") }
    if (failed) { panic(error) }
    if (!released) { panic("GPU shared_mesh release: {SDL_GetError()}") }
}

