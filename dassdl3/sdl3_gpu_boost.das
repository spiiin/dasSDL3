options gen2
require daslib/defer
module sdl3_gpu_boost shared public
require dassdl3/sdl3_boost public
require dassdl3/sdl3_gpu_result public

// Formats permitted when creating a device; individual shaders still declare their format.
let public GPU_SHADER_FORMATS = (SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXBC |
    SDL_GPU_SHADERFORMAT_DXIL | SDL_GPU_SHADERFORMAT_MSL | SDL_GPU_SHADERFORMAT_METALLIB)

def public with_gpu_device(formats : uint; debug : bool; driver : string;
                           blk : block<(device : SDL_GPUDevice?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let device = SDL_CreateGPUDeviceScoped(formats, debug, driver)
    if (device == null) { return err(sdl_error("with_gpu_device"), type<TT>) }
    {
        defer() { if (!SDL_DestroyGPUDeviceScoped(device) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_DestroyGPUDeviceScoped"), type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(device) } else { scope_result <- blk(device) }
    }

    return <- scope_result
}

def public with_gpu_device(blk : block<(device : SDL_GPUDevice?) : $Result<auto(TT); SdlError> >) {
    return <- with_gpu_device(GPU_SHADER_FORMATS, true, "", blk)
}

// Window and device must outlive this scope. No renderer may use the same window.
def public with_gpu_window(device : SDL_GPUDevice?; window : SDL_Window?; blk : block<() : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    if (!SDL_ClaimGPUWindowScoped(device, window)) { return err(sdl_error("with_gpu_window"), type<TT>) }
    {
        defer() { if (!SDL_ReleaseGPUWindowScoped(device, window) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUWindowScoped"), type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk() } else { scope_result <- blk() }
    }

    return <- scope_result
}
