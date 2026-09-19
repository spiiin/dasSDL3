options gen2
require dassdl3/sdl3_gpu_formats_boost

[export]
def main(smoke : bool) : int {
    print("BC1 7x5: {gpu_format_bytes(SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM,7u,5u)} bytes\n")
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            let format = SDL_GPU_TEXTUREFORMAT_R8_UNORM
            verify(device |> gpu_supports_format(format,SDL_GPU_TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_SAMPLER))
            var gray, result : array<uint8>
            resize(gray,15); resize(result,15)
            for (i in 0 .. 15) { gray[i] = uint8(i*17) }
            device |> with_gpu_color_texture(5u,3u,1u,1u,format) $(texture) {
                device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,5u,3u),gray,5u)
                device |> with_gpu_texture_readback(texture,uint2(0u),uint4(0u,0u,5u,3u)) $(ticket) {
                    device |> gpu_wait_readback(ticket)
                    device |> gpu_readback_bytes(ticket,result)
                    for (i in 0 .. 15) { verify(gray[i] == result[i]) }
                    print("R8 5x3: 15 bytes match ({SDL_GetGPUDeviceDriver(device)})\n")
                }
            }
        }
    }
    return available ? 0 : 77
}
