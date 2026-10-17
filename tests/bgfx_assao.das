options gen2
require ../examples/gpu_port_bgfx/example_30_assao/assao_app.das as demo
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
 var settings = demo::Settings(); settings.gutter = false
 verify(length(r.models) == 120 && length(r.meshes) == 6, "Original scene resources missing")
 verify(r.models[0].mesh == 2 && r.models[0].position == float3(-3.8, 0.0, -0.05), "MWC model sequence mismatch")
 let on <- render(device, r, settings, "assao-on") |> sdl_try; visible(on)
 let values <- read_buffer(device, r.applied, 640u * 480u * 4u) |> sdl_try
 var minimum = 1.0; var maximum = 0.0
 for (i in range(0, 640 * 480)) { let v = uint_bits_to_float(word(values, i * 4)); verify(v >= 0.0 && v <= 1.0, "Invalid AO value"); minimum = min(minimum, v); maximum = max(maximum, v) }
 verify(minimum < 0.95 && maximum > 0.99, "AO is constant")
 settings.mode = 1
 let off <- render(device, r, settings, "assao-off") |> sdl_try; verify(changed(on, off) > 1000, "AO does not affect lighting")
 settings.mode = 2
 let only <- render(device, r, settings, "assao-only") |> sdl_try; visible(only)
 settings.mode = 3
 let adaptive <- render(device, r, settings, "assao-adaptive") |> sdl_try; visible(adaptive)
 let importance <- read_buffer(device, r.importance_map, 160u * 120u * 4u) |> sdl_try; var selected = 0
 for (i in range(0, 160 * 120)) { let v = uint_bits_to_float(word(importance, i * 4)); verify(v >= 0.0 && v <= 1.0); if (v > 0.05) { selected++ } }
 verify(selected > 100, "Importance map does not allocate extra taps")
 let count <- read_buffer(device, r.counter, 4u) |> sdl_try
 var expected = 0u
 for (y in range(0, 120)) { for (x in range(0, 160)) { if (x % 3 == 0 && y % 3 == 0) { expected += uint(uint_bits_to_float(word(importance, (y * 160 + x) * 4)) * 255.0 + 0.5) } } }
 verify(word(count, 0) == expected && expected > 0u, "Adaptive GPU load counter mismatch")
 let baseline <- read_buffer(device, r.base, r.count * 16u) |> sdl_try
 let adaptive_ao <- read_buffer(device, r.ao, r.count * 16u) |> sdl_try
 var extra = 0; var active = 0
 for (i in range(0, int(r.count))) { let taps = uint_bits_to_float(word(adaptive_ao, i * 16 + 12)); verify(taps >= 0.0 && taps <= 32.0); if (taps > 5.0) { extra++ }; if (taps > 0.0) { active++; verify(uint_bits_to_float(word(baseline, i * 16 + 12)) == 5.0, "Adaptive baseline must use five taps") } }
 verify(extra > 100 && active > 1000, "Adaptive extension missing")
 settings.adaptive_limit = 0.0
 let limited <- render(device, r, settings, "assao-budget-zero") |> sdl_try; visible(limited)
 let limited_ao <- read_buffer(device, r.ao, r.count * 16u) |> sdl_try
 for (i in range(0, int(r.count))) { verify(uint_bits_to_float(word(limited_ao, i * 16 + 12)) <= 5.0, "Zero budget still adds taps") }
 settings.adaptive_limit = 0.45; settings.mode = 0
 for (quality in range(-1, 4)) {
  settings.quality = quality
  let image <- render(device, r, settings, "assao-quality-{quality}") |> sdl_try; visible(image)
  let quality_values <- read_buffer(device, r.applied, 640u * 480u * 4u) |> sdl_try
  for (i in range(0, 640 * 480)) { let v = uint_bits_to_float(word(quality_values, i * 4)); verify(v >= 0.0 && v <= 1.0, "Invalid reconstructed AO") }
  let samples <- read_buffer(device, r.ao, r.count * 16u) |> sdl_try
  for (i in range(0, int(r.count))) { let taps = uint_bits_to_float(word(samples, i * 16 + 12)); if (quality < 3 && taps > 0.0) { verify(taps == float(quality <= 0 ? 3 : (quality == 1 ? 5 : 12)), "Quality tap count mismatch") } }
 }
 settings.quality = 2; settings.blur_passes = 0
 let unblurred <- render(device, r, settings, "assao-no-blur") |> sdl_try; visible(unblurred)
 settings.blur_passes = 6
 let wide <- render(device, r, settings, "assao-wide-blur") |> sdl_try; visible(wide); verify(changed(unblurred, wide, 0) > 1000, "Wide/smart blur missing")
 settings.generate_normals = false
 let supplied <- render(device, r, settings, "assao-supplied-normals") |> sdl_try; visible(supplied)
 let odd <- render(device, r, settings, "assao-odd", 0.6, 641u, 479u) |> sdl_try; visible(odd); verify(r.count == 321u * 240u * 4u, "Odd extent lost pixels")
 settings.gutter = true
 let expanded <- render(device, r, settings, "assao-gutter") |> sdl_try; visible(expanded)
 verify(r.size == uint2(720u, 560u), "Framebuffer gutter extent mismatch")
 settings.textured = false
 let untextured <- render(device, r, settings, "assao-untextured") |> sdl_try; verify(changed(expanded, untextured) > 10000, "Albedo/lighting toggle missing")
 let reference <- render(device, r, demo::Settings(), "assao-bgfx-view", 0.0, 640u, 360u) |> sdl_try; visible(reference)
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
 print("assao: GPU regression PASS\n"); return 0
}
