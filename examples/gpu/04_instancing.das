options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_window_boost
require daslib/defer
require cubes_app

[export]
def main(unused : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let settings = window_options("bgfx instancing | Space: pause | R: reset | Esc: exit", int2(960, 540))
        let window : SDL_Window? = with_window(settings) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(GPU_SHADER_FORMATS, true, "") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device, window), "SDL_ClaimWindowForGPUDevice") |> sdl_try
        {
            defer() { SDL_ReleaseWindowFromGPUDevice(device, window) }
            return run(device, window, false)
        }
    }
    if (is_err(result)) { let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1 }
    return 0
}
