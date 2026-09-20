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
                        if (gpu_try_configure_swapchain(device,window,SDL_GPU_SWAPCHAINCOMPOSITION_SDR,mode)) {
                            print("Present mode {mode} selected\n")
                            for (i in 0 .. (smoke ? 3 : 60)) {
                                var event = SDL_MakeEvent()
                                while (poll_event(event)) {}
                                gpu_clear(device,window,float4(0.2*float(mode),0.25,0.5,1.0))
                            }
                        } else { print("Present mode {mode} unsupported\n") }
                    }
                }
            }
        }
    }
    return available ? 0 : 77
}
