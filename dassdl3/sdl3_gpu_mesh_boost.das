options gen2
module sdl3_gpu_mesh_boost shared public
require dassdl3/sdl3_gpu_boost public
require daslib/rtti
require daslib/strings_boost

// Immutable triangle-list: vertices float4(NDC x,y,u,v), tightly packed RGBA8 bytes.
// Arrays are copied before callback; no array pointer is retained by GPU work.
def public with_gpu_textured_mesh(device : SDL_GPUDevice?; window : SDL_Window?;
        vertices : array<float4>; pixels : array<uint8>; width, height : uint;
        vertex_file, fragment_file : string; format : uint; blk : block<(mesh : uint64) : void>) {
    let mesh = SDL_CreateGPUTexturedMesh(device, window, vertices, pixels, width, height, vertex_file, fragment_file, format)
    if (mesh == 0ul) { panic("GPU mesh: {SDL_GetError()}") }
    var failed = false
    var error = ""
    try { SDL_InvokeGPUHandle(blk, mesh) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    let released = SDL_ReleaseGPUTexturedMesh(device, mesh)
    if (!released && failed) { panic("{error}; {SDL_GetError()}") }
    if (failed) { panic(error) }
    if (!released) { panic("GPU mesh release: {SDL_GetError()}") }
}

def public with_gpu_indexed_textured_mesh(device : SDL_GPUDevice?; window : SDL_Window?;
        vertices : array<float4>; indices : array<uint>; pixels : array<uint8>; width, height : uint;
        vertex_file, fragment_file : string; format : uint; blk : block<(mesh : uint64) : void>) {
    let mesh = SDL_CreateGPUIndexedTexturedMesh(device, window, vertices, indices, pixels, width, height, vertex_file, fragment_file, format)
    if (mesh == 0ul) { panic("GPU mesh: {SDL_GetError()}") }
    var failed = false
    var error = ""
    try { SDL_InvokeGPUHandle(blk, mesh) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    let released = SDL_ReleaseGPUTexturedMesh(device, mesh)
    if (!released && failed) { panic("{error}; {SDL_GetError()}") }
    if (failed) { panic(error) }
    if (!released) { panic("GPU mesh release: {SDL_GetError()}") }
}

def public gpu_draw_textured_mesh(device : SDL_GPUDevice?; window : SDL_Window?; mesh : uint64) : bool {
    let status = SDL_DrawGPUTexturedMesh(device, window, mesh)
    if (status < 0) { panic("GPU mesh draw: {SDL_GetError()}") }
    return status == 1
}
