options gen2
require dassdl3/sdl3_gpu_utilities_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var data : array<uint8>
    resize(data,16)
    let gpu_buffer_result = device |> with_gpu_buffer(data,SDL_GPU_BUFFERUSAGE_VERTEX) $(buffer : uint64) {
        var gpu_buffer_name_result <- device |> gpu_buffer_name(buffer,"example29 vertices")
        if (is_err(gpu_buffer_name_result)) { return err(unwrap_err(gpu_buffer_name_result),type<SdlUnit>) }
        return device |> with_gpu_rgba_texture(2u,2u) $(texture : uint64) {
            var gpu_texture_name_result <- device |> gpu_texture_name(texture,"example29 texture")
            if (is_err(gpu_texture_name_result)) { return err(unwrap_err(gpu_texture_name_result),type<SdlUnit>) }

            return sdl_ok()
        }
    }
    if (is_err(gpu_buffer_result)) { return err(unwrap_err(gpu_buffer_result),type<SdlUnit>) }
    print("GPU resource names assigned (visibility depends on debug tools)\n")

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
