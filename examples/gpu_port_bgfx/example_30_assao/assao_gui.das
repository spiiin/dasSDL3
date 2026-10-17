// Settings and SDL GPU overlay for the bgfx 39-assao port.
options gen2
module assao_gui shared public
require ./assao_app.das public
require dassdl3/sdl3_imgui public

// ImGui borrows field addresses only for each synchronous widget call.
// Same controls and ranges as bgfx 39-assao. Changes feed GPU uniforms next draw.
def settings_panel(var settings : Settings) {
    SetNextWindowPos(ImVec2(510.0, 10.0), ImGuiCond.FirstUseEver)
    SetNextWindowSize(ImVec2(440.0, 650.0), ImGuiCond.FirstUseEver)
    if (Begin("Settings")) {
        var enabled = settings.mode != 1
        if (Checkbox("Enable SSAO", unsafe(addr(enabled)))) { settings.mode = enabled ? 0 : 1 }
        Checkbox("Enable Texturing & Lighting", unsafe(addr(settings.textured)))
        Separator()
        PushItemWidth(GetWindowWidth() * 0.42)
        let names = fixed_array("Lowest (Half Resolution)", "Low", "Medium", "High", "Adaptive")
        if (BeginCombo("Quality Level", names[clamp(settings.quality + 1, 0, 4)])) {
            for (i in range(5)) {
                if (Selectable(names[i], settings.quality == i - 1)) { settings.quality = i - 1; if (settings.mode == 3) { settings.mode = 0 } }
            }
            EndCombo()
        }
        Checkbox("Generate Normals", unsafe(addr(settings.generate_normals)))
        Checkbox("Framebuffer Gutter", unsafe(addr(settings.gutter)))
        SliderFloat("Effect Radius", unsafe(addr(settings.radius)), 0.0, 4.0)
        SliderFloat("Effect Strength", unsafe(addr(settings.strength)), 0.0, 5.0)
        SliderFloat("Effect Power", unsafe(addr(settings.power)), 0.5, 4.0)
        SliderFloat("Effect Max Limit", unsafe(addr(settings.shadow_clamp)), 0.0, 1.0)
        SliderFloat("Horizon Angle Threshold", unsafe(addr(settings.horizon)), 0.0, 0.2)
        SliderFloat("Fade Out From", unsafe(addr(settings.fade_from)), 0.0, 100.0)
        SliderFloat("Fade Out To", unsafe(addr(settings.fade_to)), 0.0, 300.0)
        if (settings.quality == 3) { SliderFloat("Adaptive Quality Limit", unsafe(addr(settings.adaptive_limit)), 0.0, 1.0) }
        SliderInt("Blur Pass Count", unsafe(addr(settings.blur_passes)), 0, 6)
        SliderFloat("Sharpness", unsafe(addr(settings.sharpness)), 0.0, 1.0)
        SliderFloat("Temporal Angle Offset", unsafe(addr(settings.sample_angle)), 0.0, 3.14159265)
        SliderFloat("Temporal Radius Offset", unsafe(addr(settings.sample_scale)), 0.0, 2.0)
        SliderFloat("Detail Shadow Strength", unsafe(addr(settings.detail)), 0.0, 4.0)
        PopItemWidth()
        Separator()
        Text("WASD: move | Arrows: look | R: reset camera")
        if (Button("Reset settings")) { settings = Settings() }
    }
    End()
}

def run_gui(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_imgui_gpu(window, device) {
        DisableIniPersistence()
        StyleColorsDark()
        return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
            var settings = Settings()
            var raw = SDL_MakeEvent()
            var running = true
            var frames = 0
            var elapsed = 0.0
            while (running) {
                while (is_some(poll_event(raw))) {
                    ImGui_SDL3_ProcessEvent(raw)
                    let event = decode_event(raw)
                    if (!(event is key_down) && should_close(event, window)) { running = false }
                    if (!ImGui_SDL3_WantCaptureKeyboard()) {
                        if (should_close(event, window)) { running = false }
                        handle_key(event, settings, elapsed)
                    }
                }
                if (!running) { break }
                ImGui_ImplSDLGPU3_NewFrame()
                ImGui_ImplSDL3_NewFrame()
                NewFrame()
                settings_panel(settings)
                Render()
                with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) {
                    draw(device, command, r, output, width, height, elapsed, settings) |> sdl_try
                    // Upload ImGui geometry before opening its LOAD overlay pass.
                    ImGui_SDL3_GPU_Prepare(command)
                    var targets <- array(SDL_GPUColorTargetInfo(texture = output, load_op = SDL_GPULoadOp.LOADOP_LOAD, store_op = SDL_GPUStoreOp.STOREOP_STORE))
                    return with_native_gpu_render_pass(command, targets) $(var pass_ : SDL_GPURenderPass?&) {
                        ImGui_SDL3_GPU_Render(command, pass_)
                        return sdl_ok()
                    }
                } |> sdl_try
                frames++
                if (smoke && frames >= 3) { break }
            }
            return sdl_ok()
        }
    }
}
