options gen2
require dassdl3/sdl3_gpu_utilities_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var face, result : array<uint8>
    resize(face,64); resize(result,64)
    let gpu_transfer_texture_result = device |> with_gpu_transfer_texture(4u,4u,6u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTURETYPE_CUBE) $(cube : uint64) {
        for (layer in 0u .. 6u) {
            for (i in 0 .. 64) { face[i] = uint8(int(layer)*31+i) }
            var gpu_upload_texture_result <- device |> gpu_upload_texture(cube,uint2(0u,layer),uint4(0u,0u,4u,4u),face,16u)
            if (is_err(gpu_upload_texture_result)) { return err(unwrap_err(gpu_upload_texture_result),type<SdlUnit>) }
        }
        for (layer in 0u .. 6u) {
            let gpu_texture_readback_result = device |> with_gpu_texture_readback(cube,uint2(0u,layer),uint4(0u,0u,4u,4u)) $(ticket : uint64) {
                var gpu_wait_readback_result <- device |> gpu_wait_readback(ticket)
                if (is_err(gpu_wait_readback_result)) { return err(unwrap_err(gpu_wait_readback_result),type<SdlUnit>) }
                var gpu_readback_bytes_result <- device |> gpu_readback_bytes(ticket,result)
                if (is_err(gpu_readback_bytes_result)) { return err(unwrap_err(gpu_readback_bytes_result),type<SdlUnit>) }
                for (i in 0 .. 64) { verify(result[i] == uint8(int(layer)*31+i)) }

                return sdl_ok()
            }
            if (is_err(gpu_texture_readback_result)) { return err(unwrap_err(gpu_texture_readback_result),type<SdlUnit>) }
        }

        return sdl_ok()
    }
    if (is_err(gpu_transfer_texture_result)) { return err(unwrap_err(gpu_transfer_texture_result),type<SdlUnit>) }
    print("Six independent cubemap faces verified\n")

    return sdl_ok()
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
