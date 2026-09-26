options gen2
require daslib/defer
module sdl3_gpu_sampler_boost shared public
require dassdl3/sdl3_gpu_boost public

// Typed defaults: clamp all axes, no comparison/anisotropy, all mip levels.
def public create_gpu_sampler(device : SDL_GPUDevice?; info : SDL_GPUSamplerCreateInfo) {
    return checked_handle_result(SDL_CreateGPUCheckedSampler(device, info), "SDL_CreateGPUCheckedSampler")
}

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
                            blk : block<(sampler : GpuSamplerHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let acquired = create_gpu_sampler(device, info)
    if (is_err(acquired)) { return err(unwrap_err(acquired), type<TT>) }
    let id = unwrap(acquired)
    {
        defer() { if (!SDL_ReleaseGPUCheckedSampler(device, id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUCheckedSampler"), type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}
def public with_gpu_sampler(device : SDL_GPUDevice?; blk : block<(sampler : GpuSamplerHandle) : $Result<auto(TT); SdlError> >) {
    return <- with_gpu_sampler(device, gpu_sampler_info(), blk)
}
def public gpu_sampler_descriptor(device : SDL_GPUDevice?; sampler : GpuSamplerHandle; var info : SDL_GPUSamplerCreateInfo) {
    return sdl_status(SDL_GetGPUCheckedSamplerInfo(device, sampler, info), "gpu_sampler_descriptor")
}

def public gpu_sampler_descriptor(device : SDL_GPUDevice?; sampler : GpuSamplerHandle) {
    var info : SDL_GPUSamplerCreateInfo
    let status = gpu_sampler_descriptor(device, sampler, info)
    if (is_err(status)) { return err(unwrap_err(status), type<SDL_GPUSamplerCreateInfo>) }
    var value = info
    return <- move_ok(value, type<SdlError>)
}

// Builders mutate the native descriptor and never own a GPU resource.
def public gpu_sampler() : SDL_GPUSamplerCreateInfo { return gpu_sampler_info() }
// Value builders return an owned descriptor. Always use the result.
// Pipeline arrays move out of the input; no reference escapes and no unsafe is needed.
[nodiscard]
def public filters(var settings : SDL_GPUSamplerCreateInfo; minification, magnification : SDL_GPUFilter) : SDL_GPUSamplerCreateInfo {
    settings.min_filter = minification
    settings.mag_filter = magnification
    return <- settings
}
[nodiscard]
def public filters(var settings : SDL_GPUSamplerCreateInfo; filter : SDL_GPUFilter) : SDL_GPUSamplerCreateInfo {
    return <- filters(settings, filter, filter)
}
[nodiscard]
def public mipmap_mode(var settings : SDL_GPUSamplerCreateInfo; mode : SDL_GPUSamplerMipmapMode) : SDL_GPUSamplerCreateInfo {
    settings.mipmap_mode = mode
    return <- settings
}
[nodiscard]
def public address_modes(var settings : SDL_GPUSamplerCreateInfo; u, v, w : SDL_GPUSamplerAddressMode) : SDL_GPUSamplerCreateInfo {
    settings.address_mode_u = u
    settings.address_mode_v = v
    settings.address_mode_w = w
    return <- settings
}
[nodiscard]
def public address_modes(var settings : SDL_GPUSamplerCreateInfo; mode : SDL_GPUSamplerAddressMode) : SDL_GPUSamplerCreateInfo {
    return <- address_modes(settings, mode, mode, mode)
}
[nodiscard]
def public lod_range(var settings : SDL_GPUSamplerCreateInfo; minimum, maximum : float) : SDL_GPUSamplerCreateInfo {
    settings.min_lod = minimum
    settings.max_lod = maximum
    return <- settings
}
[nodiscard]
def public lod_bias(var settings : SDL_GPUSamplerCreateInfo; bias : float) : SDL_GPUSamplerCreateInfo {
    settings.mip_lod_bias = bias
    return <- settings
}
[nodiscard]
def public anisotropy(var settings : SDL_GPUSamplerCreateInfo; maximum : float; enabled : bool = true) : SDL_GPUSamplerCreateInfo {
    settings.max_anisotropy = maximum
    settings.enable_anisotropy = enabled
    return <- settings
}
[nodiscard]
def public comparison(var settings : SDL_GPUSamplerCreateInfo; operation : SDL_GPUCompareOp; enabled : bool = true) : SDL_GPUSamplerCreateInfo {
    settings.compare_op = operation
    settings.enable_compare = enabled
    return <- settings
}
