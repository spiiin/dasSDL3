options gen2
module sdl3_gpu_transform_boost shared public
require dassdl3/sdl3_gpu_mesh_boost public
require math public

def public with_gpu_transform_mesh(device : SDL_GPUDevice?; window : SDL_Window?;
        vertices : array<float4>; indices : array<uint>; pixels : array<uint8>; width, height : uint;
        vertex_file, fragment_file : string; format : uint; blk : block<(mesh : uint64) : void>) {
    let mesh = SDL_CreateGPUTransformMesh(device, window, vertices, indices, pixels, width, height, vertex_file, fragment_file, format)
    if (mesh == 0ul) { panic("GPU mesh: {SDL_GetError()}") }
    SDL_ScopeReleaseGPUTexturedMesh(device,mesh,blk)
}

def public gpu_draw_transform_mesh(device : SDL_GPUDevice?; window : SDL_Window?; mesh : uint64;
        translation : float2; scale : float2; angle : float) : bool {
    let c = cos(angle)
    let s = sin(angle)
    let x = float4(c * scale.x, -s * scale.y, 0.0, translation.x)
    let y = float4(s * scale.x, c * scale.y, 0.0, translation.y)
    let status = SDL_DrawGPUTransformMesh(device,window,mesh,x,y)
    if (status < 0) { panic("GPU transform draw: {SDL_GetError()}") }
    return status == 1
}
