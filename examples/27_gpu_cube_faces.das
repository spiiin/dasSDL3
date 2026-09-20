options gen2
require dassdl3/sdl3_gpu_utilities_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            var face, result : array<uint8>
            resize(face,64); resize(result,64)
            let scope_ok_1 = device |> with_gpu_transfer_texture(4u,4u,6u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTURETYPE_CUBE) $(cube) {
                for (layer in 0u .. 6u) {
                    for (i in 0 .. 64) { face[i] = uint8(int(layer)*31+i) }
                    if (!(device |> gpu_upload_texture(cube,uint2(0u,layer),uint4(0u,0u,4u,4u),face,16u))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                }
                for (layer in 0u .. 6u) {
                    let scope_ok_2 = device |> with_gpu_texture_readback(cube,uint2(0u,layer),uint4(0u,0u,4u,4u)) $(ticket) {
                        if (!(device |> gpu_wait_readback(ticket))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(device |> gpu_readback_bytes(ticket,result))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        for (i in 0 .. 64) { verify(result[i] == uint8(int(layer)*31+i)) }
                    }
                    if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
                }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            print("Six independent cubemap faces verified\n")
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
