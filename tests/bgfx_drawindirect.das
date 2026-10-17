options gen2
require ../examples/gpu_port_bgfx/example_38_drawindirect/drawindirect_app.das as demo
require bgfx_multipass_checks
require bgfx_buffer_checks
def render(device : SDL_GPUDevice?; var r : demo::Resources; s : demo::Settings; name : string) {
 demo::prepare(device, r, s) |> sdl_try
 return sdl_scope(){var output : SDL_GPUTexture ? = with_native_gpu_texture(device, gpu_texture(640u, 360u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
 sdl_scope(){var command : SDL_GPUCommandBuffer ? & = with_native_gpu_commands(device) |> sdl_use; demo::draw(device, command, r, output, 640u, 360u, s) |> sdl_try; return native_gpu_submit(command)} |> sdl_try
 return read_image(device, output, 640u, 360u, name)}
}
def check(device : SDL_GPUDevice?) : SdlStatus {return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r){
 var s = demo::Settings(time = 0.7); let a <- render(device, r, s, "drawindirect-default") |> sdl_try; visible(a)
 let args <- read_buffer(device, r.commands, 121u * 20u) |> sdl_try
 for (i in 0..121){verify(word(args, i * 20) == ((i % 2) == 0 ? 36u : 12u)); verify(word(args, i * 20 + 4) == 1u); verify(word(args, i * 20 + 8) == ((i % 2) == 0 ? 0u : 36u)); verify(word(args, i * 20 + 12) == ((i % 2) == 0 ? 0u : 8u)); verify(word(args, i * 20 + 16) == uint(i))}
 for (v in 0..3){for (i in 0..3){s.vertex_mode = v; s.index_mode = i; let b <- render(device, r, s, "drawindirect-buffers") |> sdl_try; verify(changed(a, b) == 0, "Base offsets alter scene")}}
 s.side = 81; let c <- render(device, r, s, "drawindirect-max") |> sdl_try; visible(c); verify(changed(a, c) > 5000)
 let last <- read_buffer(device, r.commands, 6561u * 20u) |> sdl_try; verify(word(last, 6560 * 20 + 16) == 6560u)
 s.side = 1; let d <- render(device, r, s, "drawindirect-one") |> sdl_try; visible(d); verify(changed(c, d) > 5000)
return sdl_ok()}}
[export]
def main(unused : bool) : int {
    let result = sdl_scope() { with_sdl(SDL_INIT_VIDEO) |> sdl_use; let device : SDL_GPUDevice ? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use; return check(device) }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }; print("GPU regression PASS\n"); return 0
}
