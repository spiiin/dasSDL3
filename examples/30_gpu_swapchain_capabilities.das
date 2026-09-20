options gen2
require dassdl3/sdl3_gpu_swapchain_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            with_window("SDL GPU swapchain",320,240,0ul) $(window) {
                device |> with_gpu_window(window) {
                    for (mode in SDL_GPU_PRESENTMODE_VSYNC .. SDL_GPU_PRESENTMODE_MAILBOX+1u) {
                        print("Present mode {mode}: {gpu_supports_present_mode(device,window,mode)}\n")
                    }
                    for (composition in SDL_GPU_SWAPCHAINCOMPOSITION_SDR .. SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084+1u) {
                        print("Composition {composition}: {gpu_supports_composition(device,window,composition)}\n")
                    }
                    print("Current texture format: {gpu_swapchain_format(device,window)}\n")
                    gpu_clear(device,window,float4(0.1,0.3,0.5,1.0))
                }
            }
        }
    }
    return available ? 0 : 77
}
