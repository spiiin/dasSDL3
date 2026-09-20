options gen2
require dassdl3/sdl3_gpu_utilities_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            let format = SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM
            var blocks, result : array<uint8>
            resize(blocks,32); resize(result,32)
            for (i in 0 .. 32) { blocks[i] = uint8(i*7) }
            let scope_ok_1 = device |> with_gpu_transfer_texture(8u,8u,1u,1u,format,SDL_GPU_TEXTURETYPE_2D) $(texture : uint64) {
                var operation_result_1 <- device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,8u,8u),blocks,16u)
                if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                let scope_ok_2 = device |> with_gpu_texture_readback(texture,uint2(0u),uint4(0u,0u,8u,8u)) $(ticket : uint64) {
                    var operation_result_2 <- device |> gpu_wait_readback(ticket)
                    if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                    var operation_result_3 <- device |> gpu_readback_bytes(ticket,result)
                    if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
                    for (i in 0 .. 32) { verify(blocks[i] == result[i]) }

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }
            print("BC1: four encoded blocks copied exactly; no CPU compression\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
