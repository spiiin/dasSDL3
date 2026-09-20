options gen2
require dassdl3/sdl3_gpu_formats_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    print("BC1 7x5: {gpu_format_bytes(SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM,7u,5u)} bytes\n")
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            let format = SDL_GPU_TEXTUREFORMAT_R8_UNORM
            verify(device |> gpu_supports_format(format,SDL_GPU_TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_SAMPLER))
            var gray, result : array<uint8>
            resize(gray,15); resize(result,15)
            for (i in 0 .. 15) { gray[i] = uint8(i*17) }
            let scope_ok_1 = device |> with_gpu_color_texture(5u,3u,1u,1u,format) $(texture) {
                if (!(device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,5u,3u),gray,5u))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                let scope_ok_2 = device |> with_gpu_texture_readback(texture,uint2(0u),uint4(0u,0u,5u,3u)) $(ticket) {
                    if (!(device |> gpu_wait_readback(ticket))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    if (!(device |> gpu_readback_bytes(ticket,result))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    for (i in 0 .. 15) { verify(gray[i] == result[i]) }
                    print("R8 5x3: 15 bytes match ({SDL_GetGPUDeviceDriver(device)})\n")
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
