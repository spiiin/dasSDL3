options gen2
// Adapted from bgfx 23-vectordisplay. Copyright 2014 Kai Jourdan.
// BSD-2-Clause: examples/gpu_port_bgfx/LICENSE-bgfx.txt.
require ./vectordisplay_app.das
require dassdl3/sdl3_scope
require dassdl3/sdl3_window_boost
require daslib/defer

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window(WindowOptions(title = "Vector display", size = int2(960, 720), flags = SDL_WINDOW_RESIZABLE)) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device, window), "SDL_ClaimWindowForGPUDevice") |> sdl_try
        {
            defer() {
                SDL_ReleaseWindowFromGPUDevice(device, window)
            }
            return run(device, window, smoke)
        }
    }
    if (is_err(result)) {
        let e = unwrap_err(result)
        print("{e.operation}: {e.message}\n")
        return 1
    }
    return 0
}
