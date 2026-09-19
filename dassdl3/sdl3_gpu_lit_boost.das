options gen2
module sdl3_gpu_lit_boost shared public
require dassdl3/sdl3_gpu_3d_boost public
require daslib/rtti
require daslib/strings_boost

// Copied position(x,y,z,1), normal(x,y,z,0), UV and packed linear RGBA8 arrays.
def public with_gpu_lit_mesh(device : SDL_GPUDevice?; window : SDL_Window?;
        positions, normals : array<float4>; uv : array<float2>; indices : array<uint>;
        pixels : array<uint8>; width, height : uint; vertex_file, fragment_file : string;
        format : uint; blk : block<(mesh : uint64) : void>) {
    let mesh = SDL_CreateGPULitMesh(device,window,positions,normals,uv,pixels,width,height,indices,vertex_file,fragment_file,format)
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

// Light direction points toward the light in world space; ambient is 0..1.
// Native code validates and computes inverse-transpose normals before acquiring a command.
def public gpu_draw_lit_mesh(device : SDL_GPUDevice?; window : SDL_Window?; mesh : uint64;
        camera, model : float4x4; light_direction : float3; ambient : float = 0.2) : bool {
    let mvp = camera * model
    let status = SDL_DrawGPULitMesh(device,window,mesh,mvp[0],mvp[1],mvp[2],mvp[3],
        model[0],model[1],model[2],model[3],float4(light_direction,ambient))
    if (status < 0) { panic("GPU lit draw: {SDL_GetError()}") }
    return status == 1
}
