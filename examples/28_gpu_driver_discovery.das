options gen2
require dassdl3/sdl3_gpu_utilities_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    let names <- move_unwrap(gpu_driver_names())
    for (name in names) {
        print("Preferred {name} (SDL_GPU_DRIVER takes precedence): {unwrap_or(gpu_supports_shaders(GPU_SHADER_FORMATS,name),false)}\n")
    }
    print("Selected: {SDL_GetGPUDeviceDriver(device)}\n")

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
