options gen2
require dassdl3/sdl3_gpu_image_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            var pixels, scaled : array<uint8>
            resize(pixels,16); resize(scaled,64)
            for (i in 0 .. 16) { pixels[i] = uint8(i*16) }
            device |> with_gpu_rgba_texture(2u,2u) $(source) {
                device |> gpu_upload_texture(source,uint2(0u),uint4(0u,0u,2u,2u),pixels,8u)
                device |> with_gpu_color_target_texture(4u,4u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(target) {
                    device |> gpu_blit_texture(source,uint2(0u),uint4(0u,0u,2u,2u),target,uint2(0u),uint4(0u,0u,4u,4u))
                    device |> with_gpu_texture_readback(target,uint2(0u),uint4(0u,0u,4u,4u)) $(ticket) {
                        device |> gpu_wait_readback(ticket)
                        device |> gpu_readback_bytes(ticket,scaled)
                        for (y in 0 .. 4) { for (x in 0 .. 4) { for (c in 0 .. 4) {
                            verify(scaled[(y*4+x)*4+c] == pixels[(y/2*2+x/2)*4+c])
                        } } }
                    }
                    print("Nearest blit 2x2 -> 4x4 verified byte-for-byte\n")
                }
            }
        }
    }
    return available ? 0 : 77
}
