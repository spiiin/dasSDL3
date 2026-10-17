// Adapted from bgfx 38-bloom. Copyright 2018 Eric Arnebäck.
// See the example README and group LICENSE-bgfx.txt.
options gen2
module bloom_app shared public
require ../common/compute_support.das public
require ./shaders/bloom_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool }

struct Resources { cube : GeometryBuffers; geometry, downsample, upsample, combine : SDL_GPUGraphicsPipeline ?; hdr, depth : SDL_GPUTexture ?; down, up : array<SDL_GPUTexture?>; sizes : array<uint2>; sampler : SDL_GPUSampler ?; size : uint2 }
def clear_targets(device : SDL_GPUDevice?; var r : Resources) {
 for (resource in r.down) { SDL_ReleaseGPUTexture(device, resource) }; clear(r.down)
 for (resource in r.up) { SDL_ReleaseGPUTexture(device, resource) }; clear(r.up); clear(r.sizes)
 if (r.hdr != null) { SDL_ReleaseGPUTexture(device, r.hdr); r.hdr = null }; if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth); r.depth = null }; r.size = uint2(0u)
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
 var r = Resources(); defer() { clear_targets(device, r); release(device, r.cube); for (resource in fixed_array(r.geometry, r.downsample, r.upsample, r.combine)) { if (resource != null) { SDL_ReleaseGPUGraphicsPipeline(device, resource) } }; if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) } }
 let cube <- cube_geometry(); var g = upload_geometry(device, cube) |> sdl_try; r.cube = g
 let hdr <- array(gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT)); let target <- array(gpu_color_target(format))
 var p = pass_pipeline(device, shaders::bloom_geometry, shaders::bloom_geometry_reflect, shaders::bloom_emissive, shaders::bloom_emissive_reflect, hdr) |> sdl_try; r.geometry = p
 p = pass_pipeline(device, shaders::bloom_screen, shaders::bloom_screen_reflect, shaders::bloom_downsample, shaders::bloom_downsample_reflect, hdr, false, false) |> sdl_try; r.downsample = p
 p = pass_pipeline(device, shaders::bloom_screen, shaders::bloom_screen_reflect, shaders::bloom_upsample, shaders::bloom_upsample_reflect, hdr, false, false) |> sdl_try; r.upsample = p
 p = pass_pipeline(device, shaders::bloom_screen, shaders::bloom_screen_reflect, shaders::bloom_combine, shaders::bloom_combine_reflect, target, false, false) |> sdl_try; r.combine = p
 r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR)); if (r.sampler == null) { return err(sdl_error("Bloom sampler"), type<SdlUnit>) }
 return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
 if (r.size != uint2(width, height)) {
  clear_targets(device, r); let usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER
  var tex = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.hdr = tex
  tex = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try; r.depth = tex
  var size = uint2(width, height)
  for (i in 0..5) { size = max(size / 2u, uint2(1u)); push(r.sizes, size); tex = texture(device, size.x, size.y, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; push(r.down, tex); tex = texture(device, size.x, size.y, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; push(r.up, tex) }; r.size = uint2(width, height)
 }
 let colors <- array(attachment(r.hdr, float4(0.002, 0.003, 0.005, 1.0))); let depth = depth_attachment(r.depth)
 with_native_gpu_render_pass(command, colors, depth) $(var pass_ : SDL_GPURenderPass?&) {
  SDL_BindGPUGraphicsPipeline(pass_, r.geometry)
  for (i in 0..25) { let tint = i % 3 == 0 ? float3(8.0, 1.2, 0.3) : (i % 3 == 1 ? float3(0.3, 3.0, 8.0) : float3(0.8, 8.0, 0.4))
   push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model_matrix(float3(float(i % 5) * 3.0 - 6.0, float(i / 5) * 3.0 - 6.0, 0.0), float3(0.5), time * 0.4 + float(i)), vp = camera_matrix(width, height, float3(0.0, 0.0, -27.0), float3(0.0)), tint = float4(tint, 1.0))) |> sdl_try; draw_geometry(pass_, r.cube) |> sdl_try
  }; return sdl_ok()
 } |> sdl_try
 var source = r.hdr
 for (i in 0..5) {
  let sz = r.sizes[i]; push_gpu_dsl_fragment_uniform(command, 0u, shaders::Filter(pixel = float4(1.0 / float(sz.x), 1.0 / float(sz.y), 0.0, 0.0))) |> sdl_try
  var images <- array(source); fullscreen(command, r.downsample, r.down[i], images, r.sampler) |> sdl_try; source = r.down[i]
 }
 var level = 3
 while (level >= 0) {
  let sz = r.sizes[level]; push_gpu_dsl_fragment_uniform(command, 0u, shaders::Filter(pixel = float4(1.0 / float(sz.x), 1.0 / float(sz.y), 0.0, 0.0))) |> sdl_try
  var images <- array(source, r.down[level]); fullscreen(command, r.upsample, r.up[level], images, r.sampler) |> sdl_try; source = r.up[level]; level--
 }
 push_gpu_dsl_fragment_uniform(command, 0u, shaders::Filter(config = float4(settings.mode == 1 ? 0.0 : 0.22, float(settings.mode), 0.0, 0.0))) |> sdl_try
 var images <- array(r.hdr, source); return fullscreen(command, r.combine, output, images, r.sampler)
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
 return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
  var settings = Settings(); var running = true; var frames = 0; var start = SDL_GetTicks(); var elapsed = 0.0; var last = SDL_GetTicks()
  while (running) {
   for (event in poll_events()) {
    if (should_close(event, window)) { running = false }
    match (event) { if (SdlEvent(key_down = $v(k))) { if (!k.repeat) {
     if (k.keycode == SDLK_M) { settings.mode = (settings.mode + 1) % 3 }
     elif (k.keycode == SDLK_SPACE) { settings.paused = !settings.paused }
     elif (k.keycode == SDLK_R) { settings.reset = true; elapsed = 0.0 }
    } } if (_) {} }
   }
   if (!running) { break }
   let now = SDL_GetTicks(); if (!settings.paused) { elapsed += float(now - last) * 0.001 }; last = now
   with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, elapsed, settings) } |> sdl_try
   settings.reset = false
   set_title(window, "Bloom | on/off/glow only | M: {settings.mode} | Space: pause | R: reset") |> sdl_try
   frames++; if (smoke && frames >= 3) { break }
  }
  return sdl_ok()
 }
}
