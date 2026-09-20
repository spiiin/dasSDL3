options gen2
require math
require dassdl3/sdl3_gpu_image_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            var base, tiny : array<uint8>
            resize(base,64); resize(tiny,4)
            for (y in 0 .. 4) { for (x in 0 .. 4) {
                let i = (y*4+x)*4
                base[i] = uint8(x*40); base[i+1] = uint8(y*40)
                base[i+2] = uint8(24); base[i+3] = uint8(255)
            } }
            device |> with_gpu_color_target_texture(4u,4u,1u,3u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(texture) {
                device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,4u,4u),base,16u)
                device |> gpu_generate_mipmaps(texture)
                device |> with_gpu_texture_readback(texture,uint2(2u,0u),uint4(0u,0u,1u,1u)) $(ticket) {
                    device |> gpu_wait_readback(ticket)
                    device |> gpu_readback_bytes(ticket,tiny)
                    verify(abs(int(tiny[0])-60) <= 1 && abs(int(tiny[1])-60) <= 1)
                    verify(tiny[2] == uint8(24) && tiny[3] == uint8(255))
                }
                print("Mip chain 4x4 -> 2x2 -> 1x1 matches the CPU average\n")
            }
        }
    }
    return available ? 0 : 77
}
