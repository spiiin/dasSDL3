options gen2
require dassdl3/sdl3_gpu_image_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            var pixels, scaled : array<uint8>
            resize(pixels,16); resize(scaled,64)
            for (i in 0 .. 16) { pixels[i] = uint8(i*16) }
            let scope_ok_1 = device |> with_gpu_rgba_texture(2u,2u) $(source : uint64) {
                var operation_result_1 <- device |> gpu_upload_texture(source,uint2(0u),uint4(0u,0u,2u,2u),pixels,8u)
                if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                let scope_ok_2 = device |> with_gpu_color_target_texture(4u,4u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(target : uint64) {
                    var operation_result_2 <- device |> gpu_blit_texture(source,uint2(0u),uint4(0u,0u,2u,2u),target,uint2(0u),uint4(0u,0u,4u,4u))
                    if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                    let scope_ok_3 = device |> with_gpu_texture_readback(target,uint2(0u),uint4(0u,0u,4u,4u)) $(ticket : uint64) {
                        var operation_result_3 <- device |> gpu_wait_readback(ticket)
                        if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
                        var operation_result_4 <- device |> gpu_readback_bytes(ticket,scaled)
                        if (is_err(operation_result_4)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_4).message}\n"); return err(unwrap_err(operation_result_4),type<SdlUnit>) }
                        for (y in 0 .. 4) { for (x in 0 .. 4) { for (c in 0 .. 4) {
                            verify(scaled[(y*4+x)*4+c] == pixels[(y/2*2+x/2)*4+c])
                        } } }

                        return sdl_ok()
                    }
                    if (is_err(scope_ok_3)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_3).message}\n") ; return err(unwrap_err(scope_ok_3),type<SdlUnit>) }
                    print("Nearest blit 2x2 -> 4x4 verified byte-for-byte\n")

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

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
