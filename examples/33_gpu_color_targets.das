options gen2
require dassdl3/sdl3_gpu_image_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            device |> with_gpu_color_target_texture(4u,4u,2u,3u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(texture) {
                var pixels : array<uint8>
                resize(pixels,64)
                device |> with_gpu_texture_readback(texture,uint2(0u,1u),uint4(0u,0u,4u,4u)) $(ticket) {
                    device |> gpu_wait_readback(ticket)
                    device |> gpu_readback_bytes(ticket,pixels)
                    for (byte in pixels) { verify(byte == uint8(0)) }
                }
                print("Owned SAMPLER|COLOR_TARGET texture: two layers, three initialized levels\n")
            }
        }
    }
    return available ? 0 : 77
}
