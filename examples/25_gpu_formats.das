options gen2
require dassdl3/sdl3_gpu_formats_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    print("BC1 7x5: {unwrap_or(gpu_format_bytes(SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM,7u,5u),0u)} bytes\n")
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            let format = SDL_GPU_TEXTUREFORMAT_R8_UNORM
            verify(unwrap_or(device |> gpu_supports_format(format,SDL_GPU_TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_SAMPLER), false))
            var gray, result : array<uint8>
            resize(gray,15); resize(result,15)
            for (i in 0 .. 15) { gray[i] = uint8(i*17) }
            let scope_ok_1 = device |> with_gpu_color_texture(5u,3u,1u,1u,format) $(texture : uint64) {
                var operation_result_1 <- device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,5u,3u),gray,5u)
                if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                let scope_ok_2 = device |> with_gpu_texture_readback(texture,uint2(0u),uint4(0u,0u,5u,3u)) $(ticket : uint64) {
                    var operation_result_2 <- device |> gpu_wait_readback(ticket)
                    if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                    var operation_result_3 <- device |> gpu_readback_bytes(ticket,result)
                    if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
                    for (i in 0 .. 15) { verify(gray[i] == result[i]) }
                    print("R8 5x3: 15 bytes match ({SDL_GetGPUDeviceDriver(device)})\n")

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
