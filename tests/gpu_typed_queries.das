options gen2
require dassdl3/sdl3_gpu_formats_boost

def check_format(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat) {
    verify(SDL_GPUTextureFormatTexelBlockSize(format) == unwrap_or(gpu_format_block_bytes(uint(format)), 0u))
    verify(SDL_CalculateGPUTextureFormatSize(format, 7u, 5u, 2u) == unwrap_or(gpu_format_bytes(uint(format), 7u, 5u, 2u), 0u))
    verify(SDL_GPUTextureSupportsFormat(device, format, SDL_GPUTextureType.TEXTURETYPE_2D, SDL_GPU_TEXTUREUSAGE_SAMPLER)
        == unwrap_or(gpu_supports_format(device, uint(format), SDL_GPU_TEXTURETYPE_2D, SDL_GPU_TEXTUREUSAGE_SAMPLER), false))
    verify(SDL_GPUTextureSupportsFormat(device, format, SDL_GPUTextureType.TEXTURETYPE_2D_ARRAY, SDL_GPU_TEXTUREUSAGE_SAMPLER)
        == unwrap_or(gpu_supports_format(device, uint(format), SDL_GPU_TEXTURETYPE_2D_ARRAY, SDL_GPU_TEXTUREUSAGE_SAMPLER), false))
}
def check_samples(device : SDL_GPUDevice?; count : SDL_GPUSampleCount) {
    let format = SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM
    verify(SDL_GPUTextureSupportsSampleCount(device, format, count) == unwrap_or(gpu_supports_samples(device, uint(format), uint(count)), false))
}
// Raw-binding lifetime test: the descriptor is borrowed only during creation.
// Successful handles are released before assertions or any other script calls.
def check_samplers(device : SDL_GPUDevice?) {
    for (configuration in 0 .. 4) {
        var info = SDL_GPUSamplerCreateInfo(min_filter = configuration == 0 ? SDL_GPUFilter.FILTER_NEAREST : SDL_GPUFilter.FILTER_LINEAR)
        info.mag_filter = info.min_filter
        info.mipmap_mode = configuration == 0 ? SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_NEAREST : SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR
        info.address_mode_u = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE
        info.address_mode_v = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT
        info.address_mode_w = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_MIRRORED_REPEAT
        info.max_lod = 16.0
        info.compare_op = SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL
        info.enable_compare = configuration == 2
        info.max_anisotropy = 2.0
        info.enable_anisotropy = configuration == 3
        var created = false
        unsafe {
            let sampler = SDL_CreateGPUSampler(device, addr(info))
            created = sampler != null
            if (created) { SDL_ReleaseGPUSampler(device, sampler) }
        }
        verify(created)
    }
}

[export]
def main(smoke : bool) : int {
    verify(SDL_GPUTextureFormatTexelBlockSize(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) == 4u)
    verify(SDL_CalculateGPUTextureFormatSize(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, 3u, 5u, 2u) == 120u)
    verify(SDL_GPUTextureFormatTexelBlockSize(SDL_GPUTextureFormat.TEXTUREFORMAT_BC1_RGBA_UNORM) == 8u)
    verify(SDL_CalculateGPUTextureFormatSize(SDL_GPUTextureFormat.TEXTUREFORMAT_BC1_RGBA_UNORM, 7u, 5u, 2u) == 64u)
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS, true, "") $(device : SDL_GPUDevice?) {
            check_samplers(device)
            check_format(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
            check_format(device, SDL_GPUTextureFormat.TEXTUREFORMAT_B8G8R8A8_UNORM)
            check_format(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT)
            check_format(device, SDL_GPUTextureFormat.TEXTUREFORMAT_BC1_RGBA_UNORM)
            check_samples(device, SDL_GPUSampleCount.SAMPLECOUNT_1)
            check_samples(device, SDL_GPUSampleCount.SAMPLECOUNT_2)
            check_samples(device, SDL_GPUSampleCount.SAMPLECOUNT_4)
            check_samples(device, SDL_GPUSampleCount.SAMPLECOUNT_8)
            print("Generated typed GPU queries PASS: {SDL_GetGPUDeviceDriver(device)}\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
    return available ? 0 : 77
}
