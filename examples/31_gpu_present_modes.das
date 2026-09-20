options gen2
require dassdl3/sdl3_gpu_swapchain_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            let scope_ok_1 = with_window("SDL GPU swapchain",320,240,0ul) $(window) {
                let scope_ok_2 = device |> with_gpu_window(window) {
                    for (mode in SDL_GPU_PRESENTMODE_VSYNC .. SDL_GPU_PRESENTMODE_MAILBOX+1u) {
                        if (gpu_try_configure_swapchain(device,window,SDL_GPU_SWAPCHAINCOMPOSITION_SDR,mode)) {
                            print("Present mode {mode} selected\n")
                            for (i in 0 .. (smoke ? 3 : 60)) {
                                var event = SDL_MakeEvent()
                                while (poll_event(event)) {}
                            }
                        } else { print("Present mode {mode} unsupported\n") }
                    }
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
