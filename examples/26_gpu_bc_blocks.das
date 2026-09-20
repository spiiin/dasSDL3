options gen2
require dassdl3/sdl3_gpu_utilities_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            let format = SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM
            var blocks, result : array<uint8>
            resize(blocks,32); resize(result,32)
            for (i in 0 .. 32) { blocks[i] = uint8(i*7) }
            let scope_ok_1 = device |> with_gpu_transfer_texture(8u,8u,1u,1u,format,SDL_GPU_TEXTURETYPE_2D) $(texture) {
                if (!(device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,8u,8u),blocks,16u))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                let scope_ok_2 = device |> with_gpu_texture_readback(texture,uint2(0u),uint4(0u,0u,8u,8u)) $(ticket) {
                    if (!(device |> gpu_wait_readback(ticket))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    if (!(device |> gpu_readback_bytes(ticket,result))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    for (i in 0 .. 32) { verify(blocks[i] == result[i]) }
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            print("BC1: four encoded blocks copied exactly; no CPU compression\n")
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
