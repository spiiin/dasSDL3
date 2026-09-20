options gen2
require dassdl3/sdl3_gpu_swapchain_boost
require daslib/rtti

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        let devices = SDLTestGPUDevices()
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            verify(SDLTestGPUDevices() == devices+1)
            let scope_ok_1 = with_window("GPU ownership",128,96,SDL_WINDOW_HIDDEN) $(window) {
                let claims = SDLTestGPUClaims()
                var caught = false
                {
                    let scope_ok_2 = device |> with_gpu_window(window) {
                        verify(SDLTestGPUClaims() == claims+1)
                        verify(!SDL_ClaimGPUWindowScoped(device,window))
                        verify(gpu_swapchain_format(device,window) != SDL_GPU_TEXTUREFORMAT_INVALID)
                        caught = !set_title(null,"expected SDL failure"); return
                    }
                    verify(scope_ok_2)
                }
                verify(caught && SDLTestGPUClaims() == claims)
                let scope_ok_3 = device |> with_gpu_window(window) { return }
                verify(scope_ok_3)
                verify(SDLTestGPUClaims() == claims)
            }
            verify(scope_ok_1)
            var caught = false
            {
                let scope_ok_4 = with_gpu_device() $(second) { caught = !set_title(null,"expected SDL failure"); return }
                verify(scope_ok_4)
            }
            verify(caught && SDLTestGPUDevices() == devices+1)
        }
        verify(SDLTestGPUDevices() == devices)
    }
    verify(scope_ok_0)
    return available ? 0 : 77
}
