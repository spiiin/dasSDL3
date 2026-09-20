options gen2
require dassdl3/sdl3_gpu_image_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    return device |> with_gpu_color_target_texture(4u,4u,2u,3u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(texture : uint64) {
        var pixels : array<uint8>
        resize(pixels,64)
        let gpu_texture_readback_result = device |> with_gpu_texture_readback(texture,uint2(0u,1u),uint4(0u,0u,4u,4u)) $(ticket : uint64) {
            var gpu_wait_readback_result <- device |> gpu_wait_readback(ticket)
            if (is_err(gpu_wait_readback_result)) { return gpu_wait_readback_result }
            var gpu_readback_bytes_result <- device |> gpu_readback_bytes(ticket,pixels)
            if (is_err(gpu_readback_bytes_result)) { return gpu_readback_bytes_result }
            for (byte in pixels) { verify(byte == uint8(0)) }

            return sdl_ok()
        }
        if (is_err(gpu_texture_readback_result)) { return gpu_texture_readback_result }
        print("Owned SAMPLER|COLOR_TARGET texture: two layers, three initialized levels\n")

        return sdl_ok()
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
