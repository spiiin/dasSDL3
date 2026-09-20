options gen2
require daslib/defer
module sdl3_gpu_sampler_boost shared public
require dassdl3/sdl3_gpu_boost public

// Typed defaults: clamp all axes, no comparison/anisotropy, all mip levels.
def public gpu_sampler_info(filter : SDL_GPUFilter = SDL_GPUFilter.FILTER_NEAREST;
        address : SDL_GPUSamplerAddressMode = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE) : SDL_GPUSamplerCreateInfo {
    var info : SDL_GPUSamplerCreateInfo
    info.min_filter = filter; info.mag_filter = filter
    info.mipmap_mode = filter == SDL_GPUFilter.FILTER_LINEAR ? SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR : SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_NEAREST
    info.address_mode_u = address; info.address_mode_v = address; info.address_mode_w = address
    info.max_lod = 1000.0
    info.max_anisotropy = 1.0
    info.compare_op = SDL_GPUCompareOp.COMPAREOP_ALWAYS
    return info
}
def public with_gpu_sampler(device : SDL_GPUDevice?; info : SDL_GPUSamplerCreateInfo;
        blk : block<(sampler : uint64) : void>) {
    let id = SDL_CreateGPUCheckedSampler(device,info)
    if (id == 0ul) { return false }
    {
        defer() { SDL_ReleaseGPUCheckedSampler(device,id) }
        blk(id)
        return true
    }
}
def public with_gpu_sampler(device : SDL_GPUDevice?; blk : block<(sampler : uint64) : void>) {
    return with_gpu_sampler(device,gpu_sampler_info(),blk)
}
def public gpu_sampler_descriptor(device : SDL_GPUDevice?; sampler : uint64; var info : SDL_GPUSamplerCreateInfo) : bool {
    return SDL_GetGPUCheckedSamplerInfo(device,sampler,info)
}
