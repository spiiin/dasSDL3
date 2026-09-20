options gen2
require daslib/defer
module sdl3_gpu_boost shared public
require dassdl3/sdl3_boost public

// Formats permitted when creating a device; individual shaders still declare their format.
let public GPU_SHADER_FORMATS = (SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXBC |
    SDL_GPU_SHADERFORMAT_DXIL | SDL_GPU_SHADERFORMAT_MSL | SDL_GPU_SHADERFORMAT_METALLIB)

def public try_with_gpu_device(formats : uint; debug : bool; driver : string;
                              blk : block<(device : SDL_GPUDevice?) : void>) : bool {
    let device = SDL_CreateGPUDeviceScoped(formats, debug, driver)
    if (device == null) { return false }
    {
        defer() { SDL_DestroyGPUDeviceScoped(device) }
        blk(device)
        return true
    }
}

def public with_gpu_device(blk : block<(device : SDL_GPUDevice?) : void>) {
    return try_with_gpu_device(GPU_SHADER_FORMATS, true, "", blk)
}

// Window and device must outlive this scope. No renderer may use the same window.
def public with_gpu_window(device : SDL_GPUDevice?; window : SDL_Window?; blk : block<() : void>) {
    if (!SDL_ClaimGPUWindowScoped(device, window)) { return false }
    {
        defer() { SDL_ReleaseGPUWindowScoped(device,window) }
        blk()
        return true
    }
}
