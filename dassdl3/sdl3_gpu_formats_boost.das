options gen2
module sdl3_gpu_formats_boost shared public
require dassdl3/sdl3_gpu_texture_transfer_boost public

def public gpu_format_block_bytes(format : uint) : uint {
    let size = SDL_GPUFormatBlockSizeChecked(format)
    return size
}
def public gpu_format_bytes(format, width, height : uint; depth_or_layers : uint = 1u) : uint {
    let size = SDL_GPUFormatSizeChecked(format,width,height,depth_or_layers)
    return size
}
def public gpu_supports_format(device : SDL_GPUDevice?; format, texture_type, usage : uint) : bool {
    let state = SDL_GPUFormatSupportedChecked(device,format,texture_type,usage)
    return state == 1
}
// sample_count is an SDL_GPU_SAMPLECOUNT_* enum constant, not 1/2/4/8.
def public gpu_supports_samples(device : SDL_GPUDevice?; format, sample_count : uint) : bool {
    let state = SDL_GPUSampleCountSupportedChecked(device,format,sample_count)
    return state == 1
}

// Texel dimensions of an encoded block; uncompressed formats return uint2(1u).
def public gpu_format_block_extent(format : uint) : uint2 {
    let size = SDL_GPUFormatBlockExtentChecked(format)
    return size
}

// Support for the bounded 2D/array/cube transfer API, including backend exclusions.
def public gpu_supports_texture_transfer(device : SDL_GPUDevice?; format, texture_type : uint) : bool {
    let result = SDL_GPUTextureTransferSupportedChecked(device,format,texture_type)
    return result == 1
}
