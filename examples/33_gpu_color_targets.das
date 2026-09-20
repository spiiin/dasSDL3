options gen2
require dassdl3/sdl3_gpu_image_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            let scope_ok_1 = device |> with_gpu_color_target_texture(4u,4u,2u,3u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(texture : uint64) {
                var pixels : array<uint8>
                resize(pixels,64)
                let scope_ok_2 = device |> with_gpu_texture_readback(texture,uint2(0u,1u),uint4(0u,0u,4u,4u)) $(ticket : uint64) {
                    var operation_result_1 <- device |> gpu_wait_readback(ticket)
                    if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                    var operation_result_2 <- device |> gpu_readback_bytes(ticket,pixels)
                    if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                    for (byte in pixels) { verify(byte == uint8(0)) }

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }
                print("Owned SAMPLER|COLOR_TARGET texture: two layers, three initialized levels\n")

                return sdl_ok()
            }
            if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
