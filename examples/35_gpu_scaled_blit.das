options gen2
require dassdl3/sdl3_gpu_image_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var pixels, scaled : array<uint8>
    resize(pixels,16); resize(scaled,64)
    for (i in 0 .. 16) { pixels[i] = uint8(i*16) }
    return device |> with_gpu_rgba_texture(2u,2u) $(source : uint64) {
        var gpu_upload_texture_result <- device |> gpu_upload_texture(source,uint2(0u),uint4(0u,0u,2u,2u),pixels,8u)
        if (is_err(gpu_upload_texture_result)) { return err(unwrap_err(gpu_upload_texture_result),type<SdlUnit>) }
        return device |> with_gpu_color_target_texture(4u,4u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(target : uint64) {
            var gpu_blit_texture_result <- device |> gpu_blit_texture(source,uint2(0u),uint4(0u,0u,2u,2u),target,uint2(0u),uint4(0u,0u,4u,4u))
            if (is_err(gpu_blit_texture_result)) { return err(unwrap_err(gpu_blit_texture_result),type<SdlUnit>) }
            let gpu_texture_readback_result = device |> with_gpu_texture_readback(target,uint2(0u),uint4(0u,0u,4u,4u)) $(ticket : uint64) {
                var gpu_wait_readback_result <- device |> gpu_wait_readback(ticket)
                if (is_err(gpu_wait_readback_result)) { return err(unwrap_err(gpu_wait_readback_result),type<SdlUnit>) }
                var gpu_readback_bytes_result <- device |> gpu_readback_bytes(ticket,scaled)
                if (is_err(gpu_readback_bytes_result)) { return err(unwrap_err(gpu_readback_bytes_result),type<SdlUnit>) }
                for (y in 0 .. 4) { for (x in 0 .. 4) { for (c in 0 .. 4) {
                    verify(scaled[(y*4+x)*4+c] == pixels[(y/2*2+x/2)*4+c])
                } } }

                return sdl_ok()
            }
            if (is_err(gpu_texture_readback_result)) { return err(unwrap_err(gpu_texture_readback_result),type<SdlUnit>) }
            print("Nearest blit 2x2 -> 4x4 verified byte-for-byte\n")

            return sdl_ok()
        }
    }
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl() {
        return with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            return run_gpu_example(device, smoke)
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
