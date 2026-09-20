options gen2
require dassdl3/sdl3_gpu_utilities_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            let names <- gpu_driver_names()
            for (name in names) {
                print("Preferred {name} (SDL_GPU_DRIVER takes precedence): {gpu_supports_shaders(GPU_CLEAR_FORMATS,name)}\n")
            }
            print("Selected: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    return available ? 0 : 77
}
