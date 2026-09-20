options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_gpu_swapchain_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    return with_window("SDL GPU swapchain",320,240,0ul) $(window : SDL_Window?) {
        return device |> with_gpu_window(window) {
            for (mode in SDL_GPU_PRESENTMODE_VSYNC .. SDL_GPU_PRESENTMODE_MAILBOX+1u) {
                let configured = gpu_configure_swapchain(device,window,SDL_GPU_SWAPCHAINCOMPOSITION_SDR,mode) |> sdl_try
                if (configured) {
                    print("Present mode {mode} selected\n")
                    for (i in 0 .. (smoke ? 3 : 60)) {
                        var event = SDL_MakeEvent()
                        while (is_some(poll_event(event))) {}
                    }
                } else { print("Present mode {mode} unsupported\n") }
            }

            return sdl_ok()
        }
    }
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl() {
        return with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            return run_gpu_example(device, smoke)
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
