options gen2
require daslib/defer
module sdl3_gpu_shader_boost shared public
require dassdl3/sdl3_gpu_boost public

// Resource counts must match trusted offline-validated code and SDL binding ABI.
def public gpu_shader_info(format : uint; stage : SDL_GPUShaderStage) : SDL_GPUShaderCreateInfo {
    var info : SDL_GPUShaderCreateInfo
    info.format = format; info.stage = stage
    return info
}
def public with_gpu_shader(device : SDL_GPUDevice?; bytes : array<uint8>; info : SDL_GPUShaderCreateInfo;
        entrypoint : string; blk : block<(shader : uint64) : void>) {
    let id = SDL_CreateGPUCheckedShader(device,bytes,info,entrypoint)
    if (id == 0ul) { return false }
    {
        defer() { SDL_ReleaseGPUCheckedShader(device,id) }
        blk(id)
        return true
    }
}
def public with_gpu_shader(device : SDL_GPUDevice?; bytes : array<uint8>; info : SDL_GPUShaderCreateInfo;
        blk : block<(shader : uint64) : void>) {
    return with_gpu_shader(device,bytes,info,"main",blk)
}
def public with_gpu_shader_file(device : SDL_GPUDevice?; path : string; info : SDL_GPUShaderCreateInfo;
        entrypoint : string; blk : block<(shader : uint64) : void>) {
    let id = SDL_LoadGPUCheckedShader(device,path,info,entrypoint)
    if (id == 0ul) { return false }
    {
        defer() { SDL_ReleaseGPUCheckedShader(device,id) }
        blk(id)
        return true
    }
}
def public with_gpu_shader_file(device : SDL_GPUDevice?; path : string; info : SDL_GPUShaderCreateInfo;
        blk : block<(shader : uint64) : void>) {
    return with_gpu_shader_file(device,path,info,"main",blk)
}
def public gpu_shader_descriptor(device : SDL_GPUDevice?; shader : uint64; var info : SDL_GPUShaderCreateInfo) : bool {
    return SDL_GetGPUCheckedShaderInfo(device,shader,info)
}
def public gpu_shader_entrypoint(device : SDL_GPUDevice?; shader : uint64) : string {
    let name = SDL_GetGPUCheckedShaderEntryPoint(device,shader)
    return name
}
