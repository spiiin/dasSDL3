options gen2
require daslib/defer
module sdl3_gpu_shader_boost shared public
require dassdl3/sdl3_gpu_boost public

// Resource counts must match trusted offline-validated code and SDL binding ABI.
def public create_gpu_shader(device : SDL_GPUDevice?; bytes : array<uint8>; info : SDL_GPUShaderCreateInfo;
                             entrypoint : string) {
    return checked_handle_result(SDL_CreateGPUCheckedShader(device, bytes, info, entrypoint), "SDL_CreateGPUCheckedShader")
}

def public load_gpu_shader(device : SDL_GPUDevice?; path : string; info : SDL_GPUShaderCreateInfo;
                           entrypoint : string) {
    return checked_handle_result(SDL_LoadGPUCheckedShader(device, path, info, entrypoint), "SDL_LoadGPUCheckedShader")
}

def public gpu_shader_info(format : uint; stage : SDL_GPUShaderStage) : SDL_GPUShaderCreateInfo {
    var info : SDL_GPUShaderCreateInfo
    info.format = format; info.stage = stage
    return info
}
def public with_gpu_shader(device : SDL_GPUDevice?; bytes : array<uint8>; info : SDL_GPUShaderCreateInfo;
                           entrypoint : string; blk : block<(shader : GpuShaderHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let acquired = create_gpu_shader(device, bytes, info, entrypoint)
    if (is_err(acquired)) { return err(unwrap_err(acquired), type<TT>) }
    let id = unwrap(acquired)
    {
        defer() { if (!SDL_ReleaseGPUCheckedShader(device, id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUCheckedShader"), type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}
def public with_gpu_shader(device : SDL_GPUDevice?; bytes : array<uint8>; info : SDL_GPUShaderCreateInfo;
                           blk : block<(shader : GpuShaderHandle) : $Result<auto(TT); SdlError> >) {
    return <- with_gpu_shader(device, bytes, info, "main", blk)
}
def public with_gpu_shader_file(device : SDL_GPUDevice?; path : string; info : SDL_GPUShaderCreateInfo;
                                entrypoint : string; blk : block<(shader : GpuShaderHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let acquired = load_gpu_shader(device, path, info, entrypoint)
    if (is_err(acquired)) { return err(unwrap_err(acquired), type<TT>) }
    let id = unwrap(acquired)
    {
        defer() { if (!SDL_ReleaseGPUCheckedShader(device, id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUCheckedShader"), type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}
def public with_gpu_shader_file(device : SDL_GPUDevice?; path : string; info : SDL_GPUShaderCreateInfo;
                                blk : block<(shader : GpuShaderHandle) : $Result<auto(TT); SdlError> >) {
    return <- with_gpu_shader_file(device, path, info, "main", blk)
}
def public gpu_shader_descriptor(device : SDL_GPUDevice?; shader : GpuShaderHandle; var info : SDL_GPUShaderCreateInfo) {
    return sdl_status(SDL_GetGPUCheckedShaderInfo(device, shader, info), "gpu_shader_descriptor")
}
def public gpu_shader_entrypoint(device : SDL_GPUDevice?; shader : GpuShaderHandle) {
    var value : string
    if (!SDL_GetGPUShaderEntryPointValue(device, shader, value)) {return err(sdl_error("gpu_shader_entrypoint"), type<string>)}
    return ok(value, type<SdlError>)
}

def public gpu_shader_descriptor(device : SDL_GPUDevice?; shader : GpuShaderHandle) {
    var info : SDL_GPUShaderCreateInfo
    let status = gpu_shader_descriptor(device, shader, info)
    if (is_err(status)) { return err(unwrap_err(status), type<SDL_GPUShaderCreateInfo>) }
    var value = info
    return <- move_ok(value, type<SdlError>)
}

struct GpuShaderOptions {
    path : string
    entrypoint : string = "main"
    info : SDL_GPUShaderCreateInfo
}
def public with_gpu_shader_file(device : SDL_GPUDevice?; settings : GpuShaderOptions;
                                blk : block<(shader : GpuShaderHandle) : $Result<auto(TT); SdlError>>) {
    return <- with_gpu_shader_file(device, settings.path, settings.info, settings.entrypoint, blk)
}

// These declarations describe trusted bytecode; they do not reflect shader code.
def public gpu_shader(path : string; format : uint; stage : SDL_GPUShaderStage) : GpuShaderOptions {
    return GpuShaderOptions(path = path, info = gpu_shader_info(format, stage))
}
// Value builders return an owned descriptor. Always use the result.
// Pipeline arrays move out of the input; no reference escapes and no unsafe is needed.
[nodiscard]
def public entrypoint(var settings : GpuShaderOptions; name : string) : GpuShaderOptions {
    settings.entrypoint = name
    return <- settings
}
[nodiscard]
def public samplers(var settings : GpuShaderOptions; count : uint) : GpuShaderOptions {
    settings.info.num_samplers = count
    return <- settings
}
[nodiscard]
def public uniform_buffers(var settings : GpuShaderOptions; count : uint) : GpuShaderOptions {
    settings.info.num_uniform_buffers = count
    return <- settings
}
[nodiscard]
def public storage_buffers(var settings : GpuShaderOptions; count : uint) : GpuShaderOptions {
    settings.info.num_storage_buffers = count
    return <- settings
}
[nodiscard]
def public storage_textures(var settings : GpuShaderOptions; count : uint) : GpuShaderOptions {
    settings.info.num_storage_textures = count
    return <- settings
}
