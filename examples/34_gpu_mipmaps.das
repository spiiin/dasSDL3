options gen2
require math
require dassdl3/sdl3_gpu_image_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            var base, tiny : array<uint8>
            resize(base,64); resize(tiny,4)
            for (y in 0 .. 4) { for (x in 0 .. 4) {
                let i = (y*4+x)*4
                base[i] = uint8(x*40); base[i+1] = uint8(y*40)
                base[i+2] = uint8(24); base[i+3] = uint8(255)
            } }
            let scope_ok_1 = device |> with_gpu_color_target_texture(4u,4u,1u,3u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(texture : uint64) {
                var operation_result_1 <- device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,4u,4u),base,16u)
                if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                var operation_result_2 <- device |> gpu_generate_mipmaps(texture)
                if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                let scope_ok_2 = device |> with_gpu_texture_readback(texture,uint2(2u,0u),uint4(0u,0u,1u,1u)) $(ticket : uint64) {
                    var operation_result_3 <- device |> gpu_wait_readback(ticket)
                    if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
                    var operation_result_4 <- device |> gpu_readback_bytes(ticket,tiny)
                    if (is_err(operation_result_4)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_4).message}\n"); return err(unwrap_err(operation_result_4),type<SdlUnit>) }
                    verify(abs(int(tiny[0])-60) <= 1 && abs(int(tiny[1])-60) <= 1)
                    verify(tiny[2] == uint8(24) && tiny[3] == uint8(255))

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }
                print("Mip chain 4x4 -> 2x2 -> 1x1 matches the CPU average\n")

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
