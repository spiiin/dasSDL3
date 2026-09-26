options gen2
require daslib/defer
module sdl3_gpu_volume_boost shared public
require dassdl3/sdl3_gpu_formats_boost public

// Uncompressed color 3D texture, sample 1, SAMPLER usage. All mips start zeroed.
def public create_gpu_volume(device : SDL_GPUDevice?; size : uint3; levels : uint; format : SDL_GPUTextureFormat) {
    return checked_handle_result(SDL_CreateGPUVolume(device, size, levels, uint(format)), "SDL_CreateGPUVolume")
}

def public request_gpu_volume_readback(device : SDL_GPUDevice?; volume : GpuVolumeHandle; mip : uint; origin, size : uint3) {
    return checked_handle_result(SDL_RequestGPUVolumeReadback(device, volume, mip, origin, size), "SDL_RequestGPUVolumeReadback")
}

def public with_gpu_volume(device : SDL_GPUDevice?; size : uint3; levels : uint; format : SDL_GPUTextureFormat;
                           blk : block<(volume : GpuVolumeHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let acquired = create_gpu_volume(device, size, levels, format)
    if (is_err(acquired)) { return err(unwrap_err(acquired), type<TT>) }
    let id = unwrap(acquired)
    {
        defer() { if (!SDL_ReleaseGPUVolume(device, id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUVolume"), type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}
def public with_gpu_volume(device : SDL_GPUDevice?; size : uint3; blk : block<(volume : GpuVolumeHandle) : $Result<auto(TT); SdlError> >) {
    return <- with_gpu_volume(device, size, 1u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, blk)
}
// Origin/size in texels; row_pitch and slice_pitch in bytes, including padding.
def public gpu_upload_volume(device : SDL_GPUDevice?; volume : GpuVolumeHandle; mip : uint; origin, size : uint3;
                             bytes : array<uint8>; row_pitch, slice_pitch : uint; cycle : bool = false) {
    return sdl_status(SDL_UploadGPUVolume(device, volume, mip, origin, size, bytes, row_pitch, slice_pitch, cycle), "gpu_upload_volume")
}
def public gpu_copy_volume(device : SDL_GPUDevice?; source : GpuVolumeHandle; source_mip : uint; source_origin, size : uint3;
                           destination : GpuVolumeHandle; dest_mip : uint; dest_origin : uint3) {
    return sdl_status(SDL_CopyGPUVolume(device, source, source_mip, source_origin, size, destination, dest_mip, dest_origin), "gpu_copy_volume")
}
// Shared fence ticket; output is tightly packed x bytes, then y rows, then z slices.
def public with_gpu_volume_readback(device : SDL_GPUDevice?; volume : GpuVolumeHandle; mip : uint; origin, size : uint3;
                                    blk : block<(ticket : GpuReadbackHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let acquired = request_gpu_volume_readback(device, volume, mip, origin, size)
    if (is_err(acquired)) { return err(unwrap_err(acquired), type<TT>) }
    let id = unwrap(acquired)
    {
        defer() { if (!SDL_ReleaseGPUReadback(device, id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUReadback"), type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}
