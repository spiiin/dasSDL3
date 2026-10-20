options gen2
require ../examples/gpu_port_bgfx/example_22_rsm/rsm_app.das as demo
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
        let indirect <- render(device, r, settings, "rsm-indirect") |> sdl_try
        visible(indirect); settings.mode = 1
        let direct <- render(device, r, settings, "rsm-direct") |> sdl_try
        visible(direct); verify(changed(indirect, direct) > 500, "No reflected illumination")
        settings.mode = 0; settings.bounce = 0.0
        let zero <- render(device, r, settings, "rsm-zero-bounce") |> sdl_try
        verify(changed(zero, direct, 0) == 0, "Zero bounce differs from direct-only")
        settings.bounce=0.7;settings.radius=20.0
        let wide <- render(device,r,settings,"rsm-wide-radius") |> sdl_try
        verify(changed(indirect,wide)>500,"VPL radius/amount does not reach shader")
        settings.azimuth=90.0;settings.elevation=80.0
        let relit <- render(device,r,settings,"rsm-relit") |> sdl_try
        verify(changed(wide,relit)>500,"Light controls have no effect")
        settings.mode = 2
        let flux <- render(device, r, settings, "rsm-flux") |> sdl_try; visible(flux)
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
    print("rsm: GPU regression PASS\n"); return 0
}
