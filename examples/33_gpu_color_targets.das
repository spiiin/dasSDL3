options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_image_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : SdlStatus {
    return sdl_scope() {
        let texture : GpuTextureHandle = device |> with_gpu_color_target_texture(4u, 4u, 2u, 3u, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) |> sdl_use
        var pixels : array<uint8>
        resize(pixels, 64)
        sdl_scope() {
            let ticket : GpuReadbackHandle = device |> with_gpu_texture_readback(texture, uint2(0u, 1u), uint4(0u, 0u, 4u, 4u)) |> sdl_use
            device |> gpu_wait_readback(ticket) |> sdl_try
            device |> gpu_readback_bytes(ticket, pixels) |> sdl_try
            for (byte in pixels) { verify(byte == uint8(0)) }

            return sdl_ok()
        } |> sdl_try
        print("Owned SAMPLER|COLOR_TARGET texture: two layers, three initialized levels\n")

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_gpu_device(GPU_SHADER_FORMATS, true, "") |> sdl_use
        return run_gpu_example(device, smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation == "with_gpu_device" ? 77 : 1
    }
    return 0
}
