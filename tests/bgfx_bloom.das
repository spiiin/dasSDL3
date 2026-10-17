options gen2
require ../examples/gpu_port_bgfx/example_29_bloom/bloom_app.das as demo
require bgfx_multipass_checks
require bgfx_buffer_checks
require daslib/defer

def render(device : SDL_GPUDevice?; var r : demo::Resources; settings : demo::Settings; name : string; time : float = 0.6; width : uint = 640u; height : uint = 480u) {
 return sdl_scope() {
  var output : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
  sdl_scope() {
   var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
   demo::draw(device, command, r, output, width, height, time, settings) |> sdl_try
   return native_gpu_submit(command)
  } |> sdl_try
  return read_image(device, output, width, height, name)
 }
}
def check(device : SDL_GPUDevice?) : SdlStatus {
 return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
 var settings = demo::Settings()
 let glow <- render(device, r, settings, "bloom-on") |> sdl_try; visible(glow)
 verify(length(r.down) == 5 && r.sizes[4] == uint2(20u, 15u), "Invalid bloom pyramid")
 settings.mode = 1
 let original <- render(device, r, settings, "bloom-off") |> sdl_try; visible(original); verify(changed(glow, original) > 10000, "No bloom contribution")
 settings.mode = 2
 let only <- render(device, r, settings, "bloom-only") |> sdl_try; visible(only); verify(changed(only, original) > 10000, "Bloom-only matches scene")
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
 print("bloom: GPU regression PASS\n"); return 0
}
