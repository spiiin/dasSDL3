options gen2
require ../examples/gpu_port_bgfx/example_39_hextile/hextile_app.das as demo
require bgfx_multipass_checks
require bgfx_buffer_checks
def render(device : SDL_GPUDevice?; var r : demo::Resources; s : demo::Settings; name : string) {

 return sdl_scope(){var output : SDL_GPUTexture ? = with_native_gpu_texture(device, gpu_texture(640u, 360u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
 sdl_scope(){var command : SDL_GPUCommandBuffer ? & = with_native_gpu_commands(device) |> sdl_use; demo::draw(device, command, r, output, 640u, 360u, s) |> sdl_try; return native_gpu_submit(command)} |> sdl_try
 return read_image(device, output, 640u, 360u, name)}
}
def check(device : SDL_GPUDevice?) : SdlStatus {return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r){
 var s = demo::Settings(time = 5.0); let a <- render(device, r, s, "hextile-default") |> sdl_try; visible(a)
 s.regular = true; let b <- render(device, r, s, "hextile-regular") |> sdl_try; visible(b); verify(changed(a, b) > 5000)
 s.regular = false; s.weights = true; let c <- render(device, r, s, "hextile-weights") |> sdl_try; visible(c); verify(changed(a, c) > 5000)
 s.weights = false; s.rotation = 10.0; let d <- render(device, r, s, "hextile-rotation") |> sdl_try; visible(d); verify(changed(a, d) > 5000)
 s.rate = 25; let e <- render(device, r, s, "hextile-rate") |> sdl_try; visible(e); verify(changed(d, e) > 5000)
return sdl_ok()}}
[export]
def main(unused : bool) : int {
    let result = sdl_scope() { with_sdl(SDL_INIT_VIDEO) |> sdl_use; let device : SDL_GPUDevice ? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use; return check(device) }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }; print("GPU regression PASS\n"); return 0
}
