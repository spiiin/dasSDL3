// Adapted from bgfx 35-dynamic. Copyright 2011-2026 Branimir Karadzic.
// See the example README and group LICENSE-bgfx.txt.
options gen2
module dynamic_app shared public
require ../common/compute_support.das public
require ./shaders/dynamic_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool }

struct Resources { cubes : array<GeometryBuffers>; source : Geometry; transfer : SDL_GPUTransferBuffer ?; pipeline : SDL_GPUGraphicsPipeline ?; depth : SDL_GPUTexture ?; size : uint2; tick : int = -1; updates : uint }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
 var r = Resources()
 defer() { for (g in r.cubes) { release(device, g) }; if (r.transfer != null) { SDL_ReleaseGPUTransferBuffer(device, r.transfer) }; if (r.pipeline != null) { SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline) }; if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth) } }
 r.source <- cube_geometry()
 for (i in 0..36) { for (c in 0..3) { r.source.vertices[i * 8 + 3 + c] = (r.source.vertices[i * 8 + c] + 1.0) * 0.5 } }
 for (i in 0..121) { var g = upload_geometry(device, r.source) |> sdl_try; push(r.cubes, g) }
 r.transfer = SDL_CreateGPUTransferBufferRef(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = 1152u))
 if (r.transfer == null) { return err(sdl_error("Dynamic transfer"), type<SdlUnit>) }
 let targets <- array(gpu_color_target(format))
 var p = pass_pipeline(device, shaders::dynamic_vertex, shaders::dynamic_vertex_reflect, shaders::dynamic_fragment, shaders::dynamic_fragment_reflect, targets) |> sdl_try; r.pipeline = p
 return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
 replace_depth(device, r.depth, r.size, width, height) |> sdl_try
 let tick = int(time * 30.0)
 if (r.tick != tick || settings.reset) {
  let count = settings.mode == 0 ? 1 : 121
  for (k in 0..count) {
   let id = (tick * 37 + k) % 121; var values <- clone(r.source.vertices); let a = float(tick) * 0.37
   for (i in 0..36) { let x = values[i * 8]; let y = values[i * 8 + 1]; values[i * 8] = x * cos(a) - y * sin(a); values[i * 8 + 1] = x * sin(a) + y * cos(a)
    values[i * 8 + 3] = 0.5 + 0.5 * sin(a); values[i * 8 + 4] = 0.5 + 0.5 * sin(a + 2.0); values[i * 8 + 5] = 0.5 + 0.5 * sin(a + 4.0)
   }
   upload_floats(device, command, r.cubes[id].vb, r.transfer, 1152u, values) |> sdl_try; r.updates++
  }
  r.tick = tick
 }
 let targets <- array(attachment(output, float4(0.025, 0.035, 0.05, 1.0))); let depth = depth_attachment(r.depth)
 return with_native_gpu_render_pass(command, targets, depth) $(var pass_ : SDL_GPURenderPass?&) {
  SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
  for (i in 0..121) { push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model_matrix(float3(float(i % 11) * 3.0 - 15.0, float(i / 11) * 3.0 - 15.0, 0.0), float3(0.8), time), vp = camera_matrix(width, height, float3(0.0, 0.0, -52.0), float3(0.0)))) |> sdl_try; draw_geometry(pass_, r.cubes[i]) |> sdl_try }
  return sdl_ok()
 }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
 return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
  var settings = Settings(); var running = true; var frames = 0; var start = SDL_GetTicks(); var elapsed = 0.0; var last = SDL_GetTicks()
  while (running) {
   for (event in poll_events()) {
    if (should_close(event, window)) { running = false }
    match (event) { if (SdlEvent(key_down = $v(k))) { if (!k.repeat) {
     if (k.keycode == SDLK_M) { settings.mode = (settings.mode + 1) % 2 }
     elif (k.keycode == SDLK_SPACE) { settings.paused = !settings.paused }
     elif (k.keycode == SDLK_R) { settings.reset = true; elapsed = 0.0 }
    } } if (_) {} }
   }
   if (!running) { break }
   let now = SDL_GetTicks(); if (!settings.paused) { elapsed += float(now - last) * 0.001 }; last = now
   with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, elapsed, settings) } |> sdl_try
   settings.reset = false
   set_title(window, "Dynamic buffers | one/all updates | M: {settings.mode} | Space: pause | R: reset") |> sdl_try
   frames++; if (smoke && frames >= 3) { break }
  }
  return sdl_ok()
 }
}
