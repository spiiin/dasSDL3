options gen2
require dassdl3/sdl3_gpu_utilities_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            let format = SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM
            var blocks, result : array<uint8>
            resize(blocks,32); resize(result,32)
            for (i in 0 .. 32) { blocks[i] = uint8(i*7) }
            device |> with_gpu_transfer_texture(8u,8u,1u,1u,format,SDL_GPU_TEXTURETYPE_2D) $(texture) {
                device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,8u,8u),blocks,16u)
                device |> with_gpu_texture_readback(texture,uint2(0u),uint4(0u,0u,8u,8u)) $(ticket) {
                    device |> gpu_wait_readback(ticket)
                    device |> gpu_readback_bytes(ticket,result)
                    for (i in 0 .. 32) { verify(blocks[i] == result[i]) }
                }
            }
            print("BC1: four encoded blocks copied exactly; no CPU compression\n")
        }
    }
    return available ? 0 : 77
}
