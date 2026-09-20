options gen2
require dassdl3/sdl3_gpu_image_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            var pixels, scaled : array<uint8>
            resize(pixels,16); resize(scaled,64)
            for (i in 0 .. 16) { pixels[i] = uint8(i*16) }
            let scope_ok_1 = device |> with_gpu_rgba_texture(2u,2u) $(source) {
                if (!(device |> gpu_upload_texture(source,uint2(0u),uint4(0u,0u,2u,2u),pixels,8u))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                let scope_ok_2 = device |> with_gpu_color_target_texture(4u,4u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(target) {
                    if (!(device |> gpu_blit_texture(source,uint2(0u),uint4(0u,0u,2u,2u),target,uint2(0u),uint4(0u,0u,4u,4u)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    let scope_ok_3 = device |> with_gpu_texture_readback(target,uint2(0u),uint4(0u,0u,4u,4u)) $(ticket) {
                        if (!(device |> gpu_wait_readback(ticket))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(device |> gpu_readback_bytes(ticket,scaled))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        for (y in 0 .. 4) { for (x in 0 .. 4) { for (c in 0 .. 4) {
                            verify(scaled[(y*4+x)*4+c] == pixels[(y/2*2+x/2)*4+c])
                        } } }
                    }
                    if (!scope_ok_3) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
                    print("Nearest blit 2x2 -> 4x4 verified byte-for-byte\n")
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
