options gen2
require ../examples/gpu_port_bgfx/example_16_vectordisplay/vectordisplay_app.das as demo
require bgfx_multipass_checks
require bgfx_buffer_checks
require daslib/defer

def render(device : SDL_GPUDevice?; var r : demo::Resources; settings : demo::Settings; name : string; time : float = 0.6) {
    return sdl_scope() {
        var output : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(640u, 480u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        sdl_scope() {
            var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
            demo::draw(device, command, r, output, 640u, 480u, time, settings) |> sdl_try
            return native_gpu_submit(command)
        } |> sdl_try
        return read_image(device, output, 640u, 480u, name)
    }
}
def check(device : SDL_GPUDevice?) : SdlStatus {
    return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
        var settings = demo::Settings()
        let baseline <- render(device, r, settings, "vectordisplay-glow") |> sdl_try
        visible(baseline)
        settings.mode = 1
        let no_glow <- render(device, r, settings, "vectordisplay-lines") |> sdl_try
        verify(changed(baseline, no_glow) > 500, "Glow missing")
        settings.mode = 0
        let persistent <- render(device, r, settings, "vectordisplay-history", 1.5) |> sdl_try
        settings.reset = true
        let fresh <- render(device, r, settings, "vectordisplay-reset", 1.5) |> sdl_try
        verify(changed(persistent, fresh) > 200, "Phosphor history missing")
        return sdl_ok()
    }
}
[export]
def main(unused : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use
        return check(device)
    }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }
    print("vectordisplay: GPU regression PASS\n"); return 0
}
