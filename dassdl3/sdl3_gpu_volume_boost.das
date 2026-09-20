options gen2
require daslib/defer
module sdl3_gpu_volume_boost shared public
require dassdl3/sdl3_gpu_formats_boost public

// Uncompressed color 3D texture, sample 1, SAMPLER usage. All mips start zeroed.
def public with_gpu_volume(device : SDL_GPUDevice?; size : uint3; levels : uint; format : SDL_GPUTextureFormat;
        blk : block<(volume : uint64) : void>) {
    let id = SDL_CreateGPUVolume(device,size,levels,uint(format))
    if (id == 0ul) { return false }
    {
        defer() { SDL_ReleaseGPUVolume(device,id) }
        blk(id)
        return true
    }
}
def public with_gpu_volume(device : SDL_GPUDevice?; size : uint3; blk : block<(volume : uint64) : void>) {
    return with_gpu_volume(device,size,1u,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,blk)
}
// Origin/size in texels; row_pitch and slice_pitch in bytes, including padding.
def public gpu_upload_volume(device : SDL_GPUDevice?; volume : uint64; mip : uint; origin, size : uint3;
        bytes : array<uint8>; row_pitch, slice_pitch : uint; cycle : bool = false) {
    return SDL_UploadGPUVolume(device,volume,mip,origin,size,bytes,row_pitch,slice_pitch,cycle)
}
def public gpu_copy_volume(device : SDL_GPUDevice?; source : uint64; source_mip : uint; source_origin, size : uint3;
        destination : uint64; dest_mip : uint; dest_origin : uint3) {
    return SDL_CopyGPUVolume(device,source,source_mip,source_origin,size,destination,dest_mip,dest_origin)
}
// Shared fence ticket; output is tightly packed x bytes, then y rows, then z slices.
def public with_gpu_volume_readback(device : SDL_GPUDevice?; volume : uint64; mip : uint; origin, size : uint3;
        blk : block<(ticket : uint64) : void>) {
    let id = SDL_RequestGPUVolumeReadback(device,volume,mip,origin,size)
    if (id == 0ul) { return false }
    {
        defer() { SDL_ReleaseGPUReadback(device,id) }
        blk(id)
        return true
    }
}
