options gen2
module sdl3_gpu_formats_boost shared public
require dassdl3/sdl3_gpu_texture_transfer_boost public

def public gpu_format_block_bytes(format : uint) : uint {
    let size = SDL_GPUFormatBlockSizeChecked(format)
    if (size == 0u) { panic("GPU format block: {SDL_GetError()}") }
    return size
}
def public gpu_format_bytes(format, width, height : uint; depth_or_layers : uint = 1u) : uint {
    let size = SDL_GPUFormatSizeChecked(format,width,height,depth_or_layers)
    if (size == 0u) { panic("GPU format size: {SDL_GetError()}") }
    return size
}
def public gpu_supports_format(device : SDL_GPUDevice?; format, texture_type, usage : uint) : bool {
    let state = SDL_GPUFormatSupportedChecked(device,format,texture_type,usage)
    if (state < 0) { panic("GPU format support: {SDL_GetError()}") }
    return state == 1
}
// sample_count is an SDL_GPU_SAMPLECOUNT_* enum constant, not 1/2/4/8.
def public gpu_supports_samples(device : SDL_GPUDevice?; format, sample_count : uint) : bool {
    let state = SDL_GPUSampleCountSupportedChecked(device,format,sample_count)
    if (state < 0) { panic("GPU sample support: {SDL_GetError()}") }
    return state == 1
}
