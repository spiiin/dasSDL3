options gen2
require dassdl3/sdl3_gpu_formats_boost

// Encoded block bytes only: this example neither encodes nor samples ASTC pixels.

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var selected = 0u
    for (format in SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM .. SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT+1u) {
        if (unwrap_or(device |> gpu_supports_texture_transfer(format,SDL_GPU_TEXTURETYPE_2D), false)) {
            selected = format
            break
        }
    }
    if (selected == 0u) {
        let extent = unwrap_or(gpu_format_block_extent(SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM), uint2(0u))
        print("ASTC transfer unavailable on {SDL_GetGPUDeviceDriver(device)}; metadata: {int(extent.x)}x{int(extent.y)} texels per 16-byte block\n")
        return sdl_ok()
    }
    let extent = unwrap_or(gpu_format_block_extent(selected), uint2(0u))
    let region = uint4(0u,0u,extent.x*2u,extent.y*2u)
    var padded, expected, actual : array<uint8>
    resize(padded,67); resize(expected,64); resize(actual,64)
    for (i in 0 .. 67) { padded[i] = uint8(i*7+11) }
    for (y in 0 .. 2) { for (x in 0 .. 32) { expected[y*32+x] = padded[y*35+x] } }
    let gpu_transfer_texture_result = device |> with_gpu_transfer_texture(region.z,region.w,1u,1u,selected,SDL_GPU_TEXTURETYPE_2D) $(texture : uint64) {
        var gpu_upload_texture_result <- device |> gpu_upload_texture(texture,uint2(0u),region,padded,35u,true)
        if (is_err(gpu_upload_texture_result)) { return err(unwrap_err(gpu_upload_texture_result),type<SdlUnit>) }
        return device |> with_gpu_texture_readback(texture,uint2(0u),region) $(ticket : uint64) {
            var gpu_wait_readback_result <- device |> gpu_wait_readback(ticket)
            if (is_err(gpu_wait_readback_result)) { return err(unwrap_err(gpu_wait_readback_result),type<SdlUnit>) }
            var gpu_readback_bytes_result <- device |> gpu_readback_bytes(ticket,actual)
            if (is_err(gpu_readback_bytes_result)) { return err(unwrap_err(gpu_readback_bytes_result),type<SdlUnit>) }

            return sdl_ok()
        }
    }
    if (is_err(gpu_transfer_texture_result)) { return err(unwrap_err(gpu_transfer_texture_result),type<SdlUnit>) }
    for (i in 0 .. 64) { verify(actual[i] == expected[i]) }
    print("ASTC encoded 2x2 blocks, padded upload and 64-byte readback PASS ({SDL_GetGPUDeviceDriver(device)})\n")

    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl() {
        return with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            return run_gpu_example(device, smoke)
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
