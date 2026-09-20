options gen2
require dassdl3/sdl3_gpu_utilities_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            var face, result : array<uint8>
            resize(face,64); resize(result,64)
            let scope_ok_1 = device |> with_gpu_transfer_texture(4u,4u,6u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTURETYPE_CUBE) $(cube : uint64) {
                for (layer in 0u .. 6u) {
                    for (i in 0 .. 64) { face[i] = uint8(int(layer)*31+i) }
                    var operation_result_1 <- device |> gpu_upload_texture(cube,uint2(0u,layer),uint4(0u,0u,4u,4u),face,16u)
                    if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                }
                for (layer in 0u .. 6u) {
                    let scope_ok_2 = device |> with_gpu_texture_readback(cube,uint2(0u,layer),uint4(0u,0u,4u,4u)) $(ticket : uint64) {
                        var operation_result_2 <- device |> gpu_wait_readback(ticket)
                        if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                        var operation_result_3 <- device |> gpu_readback_bytes(ticket,result)
                        if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
                        for (i in 0 .. 64) { verify(result[i] == uint8(int(layer)*31+i)) }

                        return sdl_ok()
                    }
                    if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }
                }

                return sdl_ok()
            }
            if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }
            print("Six independent cubemap faces verified\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
