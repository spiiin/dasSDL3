options gen2
require fontsdf_app
require dassdl3/sdl3_scope
require dassdl3/sdl3_window_boost
require daslib/defer
require dassdl3/sdl3_ttf_boost

[export]
def main(unused : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window(WindowOptions(title = "SDF text", size = int2(960, 720), flags = SDL_WINDOW_RESIZABLE)) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device, window), "SDL_ClaimWindowForGPUDevice") |> sdl_try
        {
            defer() {
                SDL_ReleaseWindowFromGPUDevice(device, window)
            }
            return run(device, window)
        }
    }
    if (is_err(result)) {
        let e = unwrap_err(result)
        print("{e.operation}: {e.message}\n")
        return 1
    }
    return 0
}
