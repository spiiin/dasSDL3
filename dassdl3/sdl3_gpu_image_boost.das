options gen2
require daslib/defer
module sdl3_gpu_image_boost shared public
require dassdl3/sdl3_gpu_formats_boost public

def public with_gpu_color_target_texture(device : SDL_GPUDevice?; width, height, layers, levels, format : uint;
        blk : block<(texture : GpuTextureHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let id = SDL_CreateGPUColorTargetTexture(device,width,height,layers,levels,format)
    if (*id == 0ul) { return err(sdl_error("with_gpu_color_target_texture"), type<TT>) }
    {
        defer() { if (!SDL_ReleaseGPUTransferTexture(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUTransferTexture"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}

// All layers; generate from mip 0 through the last allocated mip.
def public gpu_generate_mipmaps(device : SDL_GPUDevice?; texture : GpuTextureHandle) {
    return sdl_status(SDL_GenerateGPUTextureMipmapsChecked(device,texture), "gpu_generate_mipmaps")
}
// Distinct resources, same RGBA8/BGRA8 format; preserves pixels outside dest_rect.
def public gpu_blit_texture(device : SDL_GPUDevice?; source : GpuTextureHandle; source_sub : uint2; source_rect : uint4;
        destination : GpuTextureHandle; dest_sub : uint2; dest_rect : uint4; filter_mode : uint = SDL_GPU_FILTER_NEAREST) {
    return sdl_status(SDL_BlitGPUTextureChecked(device,source,source_sub,source_rect,destination,dest_sub,dest_rect,filter_mode), "gpu_blit_texture")
}
