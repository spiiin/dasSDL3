options gen2
require ../examples/gpu_port_bgfx/example_28_gpudrivenrendering/gpudrivenrendering_app.das as demo
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
 let culled <- render(device, r, settings, "gdr-culled", 0.0) |> sdl_try; visible(culled)
 let command <- read_buffer(device, r.commands, 20u) |> sdl_try; let count = word(command, 4)
 verify(word(command, 0) == 36u && count > 0u && count < 1024u, "Culling did not reduce indirect instance count")
 let predicates <- read_buffer(device, r.predicates, 4096u) |> sdl_try
 let instances <- read_buffer(device, r.instances, 4096u) |> sdl_try
 var total = 0u; var last = 0u
 for (i in 0..1024) { let p = word(predicates, i * 4); verify(p <= 1u); total += p }
 verify(total == count, "Prefix scan count differs from visibility sum")
 for (i in range(0, int(count))) { let id = word(instances, i * 4); verify(id < 1024u && word(predicates, int(id) * 4) == 1u, "Compacted invisible ID"); if (i > 0) { verify(id > last, "Compaction must be stable and unique") }; last = id }
 settings.mode = 1
 let all <- render(device, r, settings, "gdr-all", 0.0) |> sdl_try
 let all_command <- read_buffer(device, r.commands, 20u) |> sdl_try; verify(word(all_command, 4) == 1024u, "Disabled culling omitted instances")
 verify(changed(culled, all, 1) < 30, "HiZ culled visible pixels")
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
 print("gpudrivenrendering: GPU regression PASS\n"); return 0
}
