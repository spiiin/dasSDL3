options gen2
require dassdl3/sdl3_gpu_formats_boost

// Encoded block bytes only: this example neither encodes nor samples ASTC pixels.
var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            var selected = 0u
            for (format in SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM .. SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT+1u) {
                if (unwrap_or(device |> gpu_supports_texture_transfer(format,SDL_GPU_TEXTURETYPE_2D), false)) {
                    selected = format
                    break
                }
            }
            if (selected == 0u) {
                let extent = unwrap_or(gpu_format_block_extent(SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM), uint2(0u))
                print("ASTC transfer unavailable on {SDL_GetGPUDeviceDriver(device)}; metadata: {int(extent.x)}x{int(extent.y)} texels per 16-byte block\n")
                return sdl_ok()
            }
            let extent = unwrap_or(gpu_format_block_extent(selected), uint2(0u))
            let region = uint4(0u,0u,extent.x*2u,extent.y*2u)
            var padded, expected, actual : array<uint8>
            resize(padded,67); resize(expected,64); resize(actual,64)
            for (i in 0 .. 67) { padded[i] = uint8(i*7+11) }
            for (y in 0 .. 2) { for (x in 0 .. 32) { expected[y*32+x] = padded[y*35+x] } }
            let scope_ok_1 = device |> with_gpu_transfer_texture(region.z,region.w,1u,1u,selected,SDL_GPU_TEXTURETYPE_2D) $(texture : uint64) {
                var operation_result_1 <- device |> gpu_upload_texture(texture,uint2(0u),region,padded,35u,true)
                if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                let scope_ok_2 = device |> with_gpu_texture_readback(texture,uint2(0u),region) $(ticket : uint64) {
                    var operation_result_2 <- device |> gpu_wait_readback(ticket)
                    if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                    var operation_result_3 <- device |> gpu_readback_bytes(ticket,actual)
                    if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }
            for (i in 0 .. 64) { verify(actual[i] == expected[i]) }
            print("ASTC encoded 2x2 blocks, padded upload and 64-byte readback PASS ({SDL_GetGPUDeviceDriver(device)})\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
