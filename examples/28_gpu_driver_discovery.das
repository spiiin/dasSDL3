options gen2
require dassdl3/sdl3_gpu_utilities_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            let names <- move_unwrap(gpu_driver_names())
            for (name in names) {
                print("Preferred {name} (SDL_GPU_DRIVER takes precedence): {unwrap_or(gpu_supports_shaders(GPU_SHADER_FORMATS,name),false)}\n")
            }
            print("Selected: {SDL_GetGPUDeviceDriver(device)}\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
