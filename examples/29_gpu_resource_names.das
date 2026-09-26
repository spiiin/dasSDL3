options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_utilities_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : SdlStatus {
    var data : array<uint8>
    resize(data, 16)
    sdl_scope() {
        let buffer : GpuBufferHandle = device |> with_gpu_buffer(data, SDL_GPU_BUFFERUSAGE_VERTEX) |> sdl_use
        device |> gpu_buffer_name(buffer, "example29 vertices") |> sdl_try
        let texture : GpuTextureHandle = device |> with_gpu_rgba_texture(2u, 2u) |> sdl_use
        device |> gpu_texture_name(texture, "example29 texture") |> sdl_try

        return sdl_ok()
    } |> sdl_try
    print("GPU resource names assigned (visibility depends on debug tools)\n")

    return sdl_ok()
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
