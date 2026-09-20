options gen2
require dassdl3/sdl3_gpu_image_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            let scope_ok_1 = device |> with_gpu_color_target_texture(4u,4u,2u,3u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(texture) {
                var pixels : array<uint8>
                resize(pixels,64)
                let scope_ok_2 = device |> with_gpu_texture_readback(texture,uint2(0u,1u),uint4(0u,0u,4u,4u)) $(ticket) {
                    if (!(device |> gpu_wait_readback(ticket))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    if (!(device |> gpu_readback_bytes(ticket,pixels))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    for (byte in pixels) { verify(byte == uint8(0)) }
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
                print("Owned SAMPLER|COLOR_TARGET texture: two layers, three initialized levels\n")
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
