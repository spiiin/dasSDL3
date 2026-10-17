options gen2
require ../examples/gpu/ibl_app.das as demo
require bgfx_multipass_checks
require daslib/defer

def render(device : SDL_GPUDevice?; var r : demo::Resources; settings : demo::Settings; name : string) {
    return sdl_scope() {
        var output : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(640u, 480u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        sdl_scope() {
            var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
            demo::draw(device, command, r, output, 640u, 480u, 0.6, settings) |> sdl_try
            return native_gpu_submit(command)
        } |> sdl_try
        return read_image(device, output, 640u, 480u, name)
    }
}
def check(device : SDL_GPUDevice?) : SdlStatus {
    return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
        let baseline <- render(device, r, demo::Settings(), "ibl-baseline") |> sdl_try
        visible(baseline)
        for (i in 0..4) {
            var settings = demo::Settings()
            if (i == 0) { settings.gloss = 0.1 }
            elif (i == 1) { settings.diffuse = false; settings.specular = false }
            elif (i == 2) { settings.exposure = 1.0 }
            else { settings.specular_workflow = true }
            let image <- render(device, r, settings, "ibl-{i}") |> sdl_try
            visible(image)
            let pixels = changed(image, baseline)
            verify(pixels > 100, "IBL control has no visible effect")
            print("IBL case={i}: {pixels} changed pixels.\n")
        }
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
    return 0
}
