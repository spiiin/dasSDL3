options gen2
require daslib/defer
module sdl3_gpu_image_boost shared public
require dassdl3/sdl3_gpu_formats_boost public

def public with_gpu_color_target_texture(device : SDL_GPUDevice?; width, height, layers, levels, format : uint;
        blk : block<(texture : uint64) : void>) {
    let id = SDL_CreateGPUColorTargetTexture(device,width,height,layers,levels,format)
    if (id == 0ul) { return false }
    {
        defer() { SDL_ReleaseGPUTransferTexture(device,id) }
        blk(id)
        return true
    }
}

// All layers; generate from mip 0 through the last allocated mip.
def public gpu_generate_mipmaps(device : SDL_GPUDevice?; texture : uint64) {
    return SDL_GenerateGPUTextureMipmapsChecked(device,texture)
}
// Distinct resources, same RGBA8/BGRA8 format; preserves pixels outside dest_rect.
def public gpu_blit_texture(device : SDL_GPUDevice?; source : uint64; source_sub : uint2; source_rect : uint4;
        destination : uint64; dest_sub : uint2; dest_rect : uint4; filter_mode : uint = SDL_GPU_FILTER_NEAREST) {
    return SDL_BlitGPUTextureChecked(device,source,source_sub,source_rect,destination,dest_sub,dest_rect,filter_mode)
}
