options gen2
require dassdl3/sdl3_gpu_swapchain_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            let scope_ok_1 = with_window("SDL GPU swapchain",320,240,0ul) $(window : SDL_Window?) {
                let scope_ok_2 = device |> with_gpu_window(window) {
                    for (mode in SDL_GPU_PRESENTMODE_VSYNC .. SDL_GPU_PRESENTMODE_MAILBOX+1u) {
                        print("Present mode {mode}: {unwrap_or(gpu_supports_present_mode(device,window,mode),false)}\n")
                    }
                    for (composition in SDL_GPU_SWAPCHAINCOMPOSITION_SDR .. SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084+1u) {
                        print("Composition {composition}: {unwrap_or(gpu_supports_composition(device,window,composition),false)}\n")
                    }
                    print("Current texture format: {gpu_swapchain_format(device,window)}\n")

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
