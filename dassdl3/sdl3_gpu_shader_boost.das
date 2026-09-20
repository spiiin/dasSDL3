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
        entrypoint : string; blk : block<(shader : uint64) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let id = SDL_CreateGPUCheckedShader(device,bytes,info,entrypoint)
    if (id == 0ul) { return err(sdl_error("with_gpu_shader"), type<TT>) }
    {
        defer() { if (!SDL_ReleaseGPUCheckedShader(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUCheckedShader"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}
def public with_gpu_shader(device : SDL_GPUDevice?; bytes : array<uint8>; info : SDL_GPUShaderCreateInfo;
        blk : block<(shader : uint64) : $Result<auto(TT); SdlError> >) {
    return <- with_gpu_shader(device,bytes,info,"main",blk)
}
def public with_gpu_shader_file(device : SDL_GPUDevice?; path : string; info : SDL_GPUShaderCreateInfo;
        entrypoint : string; blk : block<(shader : uint64) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let id = SDL_LoadGPUCheckedShader(device,path,info,entrypoint)
    if (id == 0ul) { return err(sdl_error("with_gpu_shader_file"), type<TT>) }
    {
        defer() { if (!SDL_ReleaseGPUCheckedShader(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUCheckedShader"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}
def public with_gpu_shader_file(device : SDL_GPUDevice?; path : string; info : SDL_GPUShaderCreateInfo;
        blk : block<(shader : uint64) : $Result<auto(TT); SdlError> >) {
    return <- with_gpu_shader_file(device,path,info,"main",blk)
}
def public gpu_shader_descriptor(device : SDL_GPUDevice?; shader : uint64; var info : SDL_GPUShaderCreateInfo) {
    return sdl_status(SDL_GetGPUCheckedShaderInfo(device,shader,info), "gpu_shader_descriptor")
}
def public gpu_shader_entrypoint(device : SDL_GPUDevice?; shader : uint64) {
    var value : string
    if (!SDL_GetGPUShaderEntryPointValue(device,shader,value)) {return err(sdl_error("gpu_shader_entrypoint"),type<string>)}
    return ok(value,type<SdlError>)
}

def public gpu_shader_descriptor(device : SDL_GPUDevice?; shader : uint64) {
    var info : SDL_GPUShaderCreateInfo
    let status = gpu_shader_descriptor(device,shader,info)
    if (is_err(status)) { return err(unwrap_err(status),type<SDL_GPUShaderCreateInfo>) }
    var value = info
    return <- move_ok(value,type<SdlError>)
}
