options gen2
require ../examples/gpu_port_bgfx/example_26_dynamic/dynamic_app.das as demo
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
 let first <- render(device, r, settings, "dynamic-first", 0.0) |> sdl_try; visible(first)
 let before <- read_buffer(device, r.cubes[61].vb, 1152u) |> sdl_try
 let changed_frame <- render(device, r, settings, "dynamic-updated", 0.6) |> sdl_try; visible(changed_frame)
 let after <- read_buffer(device, r.cubes[61].vb, 1152u) |> sdl_try
 verify(changed(before, after, 0) > 0, "Dynamic upload left vertex buffer unchanged")
 verify(r.updates == 2u, "Expected exactly one updated cube per tick")
 let repeat <- render(device, r, settings, "dynamic-repeat", 0.6) |> sdl_try
 verify(changed(changed_frame, repeat, 0) == 0 && r.updates == 2u, "Frozen tick mutates dynamic buffer")
 settings.mode = 1
 let all <- render(device, r, settings, "dynamic-all", 0.9) |> sdl_try; visible(all); verify(r.updates == 123u, "Full update omitted a buffer")
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
 print("dynamic: GPU regression PASS\n"); return 0
}
