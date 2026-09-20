options gen2
require dassdl3/sdl3_gpu_swapchain_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    return with_window("SDL GPU swapchain",320,240,0ul) $(window : SDL_Window?) {
        return device |> with_gpu_window(window) {
            for (mode in SDL_GPU_PRESENTMODE_VSYNC .. SDL_GPU_PRESENTMODE_MAILBOX+1u) {
                print("Present mode {mode}: {unwrap_or(gpu_supports_present_mode(device,window,mode),false)}\n")
            }
            for (composition in SDL_GPU_SWAPCHAINCOMPOSITION_SDR .. SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084+1u) {
                print("Composition {composition}: {unwrap_or(gpu_supports_composition(device,window,composition),false)}\n")
            }
            print("Current texture format: {gpu_swapchain_format(device,window)}\n")

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
