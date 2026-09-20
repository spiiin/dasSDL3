options gen2
require dassdl3/sdl3_gpu_formats_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    let format = SDL_GPU_TEXTUREFORMAT_R8_UNORM
    verify(unwrap_or(device |> gpu_supports_format(format,SDL_GPU_TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_SAMPLER), false))
    var gray, result : array<uint8>
    resize(gray,15); resize(result,15)
    for (i in 0 .. 15) { gray[i] = uint8(i*17) }
    return device |> with_gpu_color_texture(5u,3u,1u,1u,format) $(texture : uint64) {
        var gpu_upload_texture_result <- device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,5u,3u),gray,5u)
        if (is_err(gpu_upload_texture_result)) { return gpu_upload_texture_result }
        return device |> with_gpu_texture_readback(texture,uint2(0u),uint4(0u,0u,5u,3u)) $(ticket : uint64) {
            var gpu_wait_readback_result <- device |> gpu_wait_readback(ticket)
            if (is_err(gpu_wait_readback_result)) { return gpu_wait_readback_result }
            var gpu_readback_bytes_result <- device |> gpu_readback_bytes(ticket,result)
            if (is_err(gpu_readback_bytes_result)) { return gpu_readback_bytes_result }
            for (i in 0 .. 15) { verify(gray[i] == result[i]) }
            print("R8 5x3: 15 bytes match ({SDL_GetGPUDeviceDriver(device)})\n")

            return sdl_ok()
        }
    }
}

[export]
def main(smoke : bool) : int {
    print("BC1 7x5: {unwrap_or(gpu_format_bytes(SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM,7u,5u),0u)} bytes\n")
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
