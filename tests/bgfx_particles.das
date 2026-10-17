options gen2
require ../examples/gpu_port_bgfx/example_23_particles/particles_app.das as demo
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
        for (i in 0..120) { demo::step(r, settings, 1.0 / 60.0) }
        verify(length(r.particles) > 500 && length(r.particles) <= 4096, "Emitter count invalid")
        settings.paused = true
        let additive <- render(device, r, settings, "particles-additive") |> sdl_try
        visible(additive)
        let paused <- render(device, r, settings, "particles-paused", 4.0) |> sdl_try
        verify(changed(additive, paused, 0) == 0, "Pause changes particles")
        settings.additive = false
        let alpha <- render(device, r, settings, "particles-alpha") |> sdl_try
        verify(changed(additive, alpha) > 100, "Alpha/additive modes identical")
        settings.reset = true; demo::step(r, settings, 0.1); verify(length(r.particles) == 0, "Reset did not clear particles")
        settings.reset = false; settings.paused = false
        for (shape in 0..5) { settings.mode = shape; for (i in 0..40) { demo::step(r, settings, 0.025) }; verify(length(r.particles) > 100) }
        for (p in r.particles) { verify(p.age < p.lifetime && p.lifetime > 0.0, "Expired particle retained") }
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
    print("particles: GPU regression PASS\n"); return 0
}
