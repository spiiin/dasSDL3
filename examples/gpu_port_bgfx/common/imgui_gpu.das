options gen2
module imgui_gpu shared public
require dassdl3/sdl3_imgui public
require ./multipass_support.das public

def begin_gui() {
    ImGui_ImplSDLGPU3_NewFrame()
    ImGui_ImplSDL3_NewFrame()
    NewFrame()
}

def draw_gui(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?) : SdlStatus {
    ImGui_SDL3_GPU_Prepare(command)
    var targets <- array(attachment(output, float4(0.0), true))
    return with_native_gpu_render_pass(command, targets) $(var pass_ : SDL_GPURenderPass?&) {
        ImGui_SDL3_GPU_Render(command, pass_)
        return sdl_ok()
    }
}
