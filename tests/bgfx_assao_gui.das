options gen2
require ../examples/gpu_port_bgfx/example_30_assao/assao_gui.das as gui
require bgfx_multipass_checks
require dassdl3/sdl3_window_boost

def check(device : SDL_GPUDevice?; window : SDL_Window?) : SdlStatus {
    return with_imgui_gpu(window, device) {
        DisableIniPersistence()
        StyleColorsDark()
        var settings = gui::Settings()
        for (frame in range(5)) {
            ImGui_ImplSDLGPU3_NewFrame()
            ImGui_ImplSDL3_NewFrame()
            // Deterministic ImGui input after OS polling; first checkbox in the panel.
            unsafe {
                var io & = GetIO()
                io.ConfigInputTrickleEventQueue = false
                AddMousePosEvent(io, 524.0, 40.0)
                if (frame == 2) { AddMouseButtonEvent(io, 0, true) }
                if (frame == 3) { AddMouseButtonEvent(io, 0, false) }
            }
            NewFrame()
            gui::settings_panel(settings)
            Render()
        }
        verify(settings.mode == 1, "ImGui checkbox did not change SSAO settings")
        verify(ImGui_SDL3_WantCaptureMouse(), "Panel did not capture mouse")
        return gui::with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
            var info = gpu_texture(960u, 720u, SDL_GetGPUSwapchainTextureFormat(device, window), SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)
            return with_native_gpu_texture(device, info) $(var output) {
                settings.mode = 0
                // Equal fade endpoints are legal in the original panel.
                settings.fade_from = 0.0; settings.fade_to = 0.0
                with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
                    gui::draw(device, command, r, output, 960u, 720u, 0.0, settings) |> sdl_try
                    return native_gpu_submit(command)
                } |> sdl_try
                let before <- read_image(device, output, 960u, 720u, "assao-gui-before") |> sdl_try
                with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
                    ImGui_SDL3_GPU_Prepare(command)
                    var targets <- array(SDL_GPUColorTargetInfo(texture = output, load_op = SDL_GPULoadOp.LOADOP_LOAD, store_op = SDL_GPUStoreOp.STOREOP_STORE))
                    with_native_gpu_render_pass(command, targets) $(var pass_ : SDL_GPURenderPass?&) {
                        ImGui_SDL3_GPU_Render(command, pass_)
                        return sdl_ok()
                    } |> sdl_try
                    return native_gpu_submit(command)
                } |> sdl_try
                let after <- read_image(device, output, 960u, 720u, "assao-gui") |> sdl_try
                verify(changed(before, after) > 10000, "GPU overlay is missing")
                for (y in range(720)) { for (x in range(490)) { for (c in range(4)) {
                    let i = (y * 960 + x) * 4 + c
                    verify(before[i] == after[i], "Overlay destroyed scene outside panel")
                } } }
                return sdl_ok()
            }
        }
    }
}

[export]
def main(unused : bool) : int {
    var previous = GetCurrentContext()
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("ASSAO GUI test", 960, 720, SDL_WINDOW_HIDDEN) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device, window), "claim") |> sdl_try
        {
            defer() { SDL_ReleaseWindowFromGPUDevice(device, window) }
            return check(device, window)
        }
    }
    verify(GetCurrentContext() == previous, "ImGui context was not restored")
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }
    print("ASSAO ImGui: input, GPU overlay, LOAD preservation and cleanup PASS\n")
    return 0
}
