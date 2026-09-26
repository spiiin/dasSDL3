options gen2
module sdl3_gpu_formats_boost shared public
require dassdl3/sdl3_gpu_texture_transfer_boost public

def public gpu_format_block_bytes(format : uint) {
    let size = SDL_GPUFormatBlockSizeChecked(format)
    let value = size
    if (value == 0u) { return err(sdl_error("gpu_format_block_bytes"), type<uint>) }
    return ok(value, type<SdlError>)
}
def public gpu_format_bytes(format, width, height : uint; depth_or_layers : uint = 1u) {
    let size = SDL_GPUFormatSizeChecked(format, width, height, depth_or_layers)
    let value = size
    if (value == 0u) { return err(sdl_error("gpu_format_bytes"), type<uint>) }
    return ok(value, type<SdlError>)
}
def public gpu_supports_format(device : SDL_GPUDevice?; format, texture_type, usage : uint) {
    let state = SDL_GPUFormatSupportedChecked(device, format, texture_type, usage)
    if (state < 0) { return err(sdl_error("gpu_supports_format"), type<bool>) }
    return ok(state == 1, type<SdlError>)
}
// sample_count is an SDL_GPU_SAMPLECOUNT_* enum constant, not 1/2/4/8.
def public gpu_supports_samples(device : SDL_GPUDevice?; format, sample_count : uint) {
    let state = SDL_GPUSampleCountSupportedChecked(device, format, sample_count)
    if (state < 0) { return err(sdl_error("gpu_supports_samples"), type<bool>) }
    return ok(state == 1, type<SdlError>)
}

// Texel dimensions of an encoded block; uncompressed formats return uint2(1u).
def public gpu_format_block_extent(format : uint) {
    let size = SDL_GPUFormatBlockExtentChecked(format)
    let value = size
    if (value.x == 0u) { return err(sdl_error("gpu_format_block_extent"), type<uint2>) }
    return ok(value, type<SdlError>)
}

// Support for the bounded 2D/array/cube transfer API, including backend exclusions.
def public gpu_supports_texture_transfer(device : SDL_GPUDevice?; format, texture_type : uint) {
    let state = SDL_GPUTextureTransferSupportedChecked(device, format, texture_type)
    if (state < 0) { return err(sdl_error("gpu_supports_texture_transfer"), type<bool>) }
    return ok(state == 1, type<SdlError>)
}
