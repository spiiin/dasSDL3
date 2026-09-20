options gen2
require dassdl3/sdl3_gpu_utilities_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            let names <- gpu_driver_names()
            for (name in names) {
                print("Preferred {name} (SDL_GPU_DRIVER takes precedence): {gpu_supports_shaders(GPU_SHADER_FORMATS,name)}\n")
            }
            print("Selected: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
