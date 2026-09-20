options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_gpu_formats_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    let format = SDL_GPU_TEXTUREFORMAT_R8_UNORM
    let supported = device |> gpu_supports_format(format,SDL_GPU_TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try
    verify(supported)
    var gray, result : array<uint8>
    resize(gray,15); resize(result,15)
    for (i in 0 .. 15) { gray[i] = uint8(i*17) }
    return device |> with_gpu_color_texture(5u,3u,1u,1u,format) $(texture : uint64) {
        device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,5u,3u),gray,5u) |> sdl_try
        return device |> with_gpu_texture_readback(texture,uint2(0u),uint4(0u,0u,5u,3u)) $(ticket : uint64) {
            device |> gpu_wait_readback(ticket) |> sdl_try
            device |> gpu_readback_bytes(ticket,result) |> sdl_try
            for (i in 0 .. 15) { verify(gray[i] == result[i]) }
            print("R8 5x3: 15 bytes match ({SDL_GetGPUDeviceDriver(device)})\n")

            return sdl_ok()
        }
    }
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl() {
        let byte_count = gpu_format_bytes(SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM,7u,5u) |> sdl_try
        print("BC1 7x5: {byte_count} bytes\n")
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
