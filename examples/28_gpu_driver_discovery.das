options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_utilities_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    let names <- gpu_driver_names() |> sdl_try
    for (name in names) {
        let supported = gpu_supports_shaders(GPU_SHADER_FORMATS,name) |> sdl_try
        print("Preferred {name} (SDL_GPU_DRIVER takes precedence): {supported}\n")
    }
    print("Selected: {SDL_GetGPUDeviceDriver(device)}\n")

    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_gpu_device(GPU_SHADER_FORMATS,true,"") |> sdl_use
        return run_gpu_example(device, smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
