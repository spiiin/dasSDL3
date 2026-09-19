options gen2
require dassdl3/sdl3_gpu_utilities_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            var face, result : array<uint8>
            resize(face,64); resize(result,64)
            device |> with_gpu_transfer_texture(4u,4u,6u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTURETYPE_CUBE) $(cube) {
                for (layer in 0u .. 6u) {
                    for (i in 0 .. 64) { face[i] = uint8(int(layer)*31+i) }
                    device |> gpu_upload_texture(cube,uint2(0u,layer),uint4(0u,0u,4u,4u),face,16u)
                }
                for (layer in 0u .. 6u) {
                    device |> with_gpu_texture_readback(cube,uint2(0u,layer),uint4(0u,0u,4u,4u)) $(ticket) {
                        device |> gpu_wait_readback(ticket)
                        device |> gpu_readback_bytes(ticket,result)
                        for (i in 0 .. 64) { verify(result[i] == uint8(int(layer)*31+i)) }
                    }
                }
            }
            print("Six independent cubemap faces verified\n")
        }
    }
    return available ? 0 : 77
}
