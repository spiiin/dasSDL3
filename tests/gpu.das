options gen2
require dassdl3/sdl3_gpu_swapchain_boost
require daslib/rtti

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        let devices = SDLTestGPUDevices()
        available = with_gpu_device(GPU_SHADER_FORMATS, true, "") $(device : SDL_GPUDevice?) {
            verify(SDLTestGPUDevices() == devices + 1)
            let scope_ok_1 = with_window("GPU ownership", 128, 96, SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
                let claims = SDLTestGPUClaims()
                var caught = false
                {
                    let scope_ok_2 = device |> with_gpu_window(window) {
                        verify(SDLTestGPUClaims() == claims + 1)
                        verify(!SDL_ClaimGPUWindowScoped(device, window))
                        verify(unwrap_or(gpu_swapchain_format(device, window), 0u) != SDL_GPU_TEXTUREFORMAT_INVALID)
                        caught = !is_ok(set_title(null, "expected SDL failure")); return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_2)
                }
                verify(caught && SDLTestGPUClaims() == claims)
                let scope_ok_3 = device |> with_gpu_window(window) { return sdl_ok()
                } |> is_ok
                verify(scope_ok_3)
                verify(SDLTestGPUClaims() == claims)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_1)
            var caught = false
            {
                let scope_ok_4 = with_gpu_device() $(second : SDL_GPUDevice?) { caught = !is_ok(set_title(null, "expected SDL failure")); return sdl_ok()
                } |> is_ok
                verify(scope_ok_4)
            }
            verify(caught && SDLTestGPUDevices() == devices + 1)

            return sdl_ok()
        } |> is_ok
        verify(SDLTestGPUDevices() == devices)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
    return available ? 0 : 77
}
