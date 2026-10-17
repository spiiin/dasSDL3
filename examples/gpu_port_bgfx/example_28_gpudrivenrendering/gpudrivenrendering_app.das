// Adapted from bgfx 37-gpudrivenrendering. Copyright 2018 Kostas Anagnostou.
// See the example README and group LICENSE-bgfx.txt.
options gen2
module gpudrivenrendering_app shared public
require ../common/compute_support.das public
require ./shaders/gpudrivenrendering_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool }

struct Resources { cube : GeometryBuffers; pipeline, occluder : SDL_GPUGraphicsPipeline ?; copy, reduce, cull, compact : SDL_GPUComputePipeline ?; hiz, predicates, instances, commands : SDL_GPUBuffer ?; depth : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; size : uint2 }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
 var r = Resources(); defer() {
  release(device, r.cube); for (resource in fixed_array(r.pipeline, r.occluder)) { if (resource != null) { SDL_ReleaseGPUGraphicsPipeline(device, resource) } }
  for (resource in fixed_array(r.copy, r.reduce, r.cull, r.compact)) { if (resource != null) { SDL_ReleaseGPUComputePipeline(device, resource) } }
  for (resource in fixed_array(r.hiz, r.predicates, r.instances, r.commands)) { if (resource != null) { SDL_ReleaseGPUBuffer(device, resource) } }
  if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth) }; if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
 }
 let cube <- cube_geometry(); var g = upload_geometry(device, cube) |> sdl_try; r.cube = g
 var buf = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE, size = 87380u)) |> sdl_try; r.hiz = buf
 buf = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE, size = 4096u)) |> sdl_try; r.predicates = buf
 buf = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE | SDL_GPU_BUFFERUSAGE_VERTEX, size = 4096u)) |> sdl_try; r.instances = buf
 buf = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE | SDL_GPU_BUFFERUSAGE_INDIRECT, size = 20u)) |> sdl_try; r.commands = buf
 var cp = compute_pipeline(device, shaders::gdr_copy, shaders::gdr_copy_reflect, shaders::gdr_copy_access) |> sdl_try; r.copy = cp
 cp = compute_pipeline(device, shaders::gdr_reduce, shaders::gdr_reduce_reflect, shaders::gdr_reduce_access) |> sdl_try; r.reduce = cp
 cp = compute_pipeline(device, shaders::gdr_cull, shaders::gdr_cull_reflect, shaders::gdr_cull_access) |> sdl_try; r.cull = cp
 cp = compute_pipeline(device, shaders::gdr_compact, shaders::gdr_compact_reflect, shaders::gdr_compact_access) |> sdl_try; r.compact = cp
 r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_NEAREST)); if (r.sampler == null) { return err(sdl_error("HiZ sampler"), type<SdlUnit>) }
 let targets <- array(gpu_color_target(format))
 var p = pass_pipeline(device, shaders::gdr_occluder, shaders::gdr_occluder_reflect, shaders::gdr_fragment, shaders::gdr_fragment_reflect, targets) |> sdl_try; r.occluder = p
 p = sdl_scope() {
  var vs : SDL_GPUShader? = with_example_shader(device, shaders::gdr_vertex, shaders::gdr_vertex_reflect) |> sdl_use
  var fs : SDL_GPUShader? = with_example_shader(device, shaders::gdr_fragment, shaders::gdr_fragment_reflect) |> sdl_use
  var info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vs, fragment_shader = fs, rasterizer_state = SDL_GPURasterizerState(enable_depth_clip = true, cull_mode = SDL_GPUCullMode.CULLMODE_BACK, front_face = SDL_GPUFrontFace.FRONTFACE_CLOCKWISE))
  info <- info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL) |> depth_write(true)
  let streams <- array(SDL_GPUVertexBufferDescription(pitch = 32u), SDL_GPUVertexBufferDescription(slot = 1u, pitch = 4u, input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE))
  let attrs <- array(SDL_GPUVertexAttribute(format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3), SDL_GPUVertexAttribute(location = 1u, offset = 12u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3), SDL_GPUVertexAttribute(location = 3u, buffer_slot = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UINT))
  return create_native_gpu_graphics_pipeline(device, info, streams, attrs, targets)
 } |> sdl_try; r.pipeline = p
 return body(r)
}
def dispatch(command : SDL_GPUCommandBuffer?; pipeline : SDL_GPUComputePipeline?; var buffers : array<SDL_GPUBuffer?>; groups : uint) : SdlStatus {
 var textures : array<SDL_GPUStorageTextureReadWriteBinding>; var bindings : array<SDL_GPUStorageBufferReadWriteBinding>
 for (buf in buffers) { push(bindings, SDL_GPUStorageBufferReadWriteBinding(buffer = buf)) }
 return with_native_gpu_compute_pass(command, textures, bindings) $(var pass_ : SDL_GPUComputePass?&) { SDL_BindGPUComputePipeline(pass_, pipeline); SDL_DispatchGPUCompute(pass_, groups, 1u, 1u); return sdl_ok() }
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
 if (r.size != uint2(width, height)) { if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth); r.depth = null }; var tex = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.depth = tex; r.size = uint2(width, height) }
 let vp = camera_matrix(width, height, float3(sin(time * 0.2) * 15.0, 4.0, -65.0), float3(0.0))
 let colors <- array(attachment(output, float4(0.025, 0.035, 0.05, 1.0))); var depth = depth_attachment(r.depth); depth.store_op = SDL_GPUStoreOp.STOREOP_STORE
 push_gpu_dsl_vertex_uniform(command, 0u, shaders::Camera(vp = vp)) |> sdl_try
 with_native_gpu_render_pass(command, colors, depth) $(var pass_ : SDL_GPURenderPass?&) { SDL_BindGPUGraphicsPipeline(pass_, r.occluder); return draw_geometry(pass_, r.cube) } |> sdl_try
 push_gpu_dsl_compute_uniform(command, 0u, shaders::Pyramid(viewport = float4(float(width), float(height), 0.0, 0.0))) |> sdl_try
 var textures : array<SDL_GPUStorageTextureReadWriteBinding>; let bindings <- array(SDL_GPUStorageBufferReadWriteBinding(buffer = r.hiz))
 with_native_gpu_compute_pass(command, textures, bindings) $(var pass_ : SDL_GPUComputePass?&) {
  SDL_BindGPUComputePipeline(pass_, r.copy); let samplers <- array(SDL_GPUTextureSamplerBinding(texture = r.depth, sampler = r.sampler)); sdl_status(SDL_BindGPUComputeSamplersArray(pass_, 0u, samplers), "HiZ source") |> sdl_try; SDL_DispatchGPUCompute(pass_, 256u, 1u, 1u); return sdl_ok()
 } |> sdl_try
 var w = 64u; var previous = 0u; var next = 16384u; var buffers <- array(r.hiz)
 for (level in 0..7) { push_gpu_dsl_compute_uniform(command, 0u, shaders::Pyramid(level = uint4(w, previous, next, 0u))) |> sdl_try; dispatch(command, r.reduce, buffers, (w * w + 63u) / 64u) |> sdl_try; previous = next; next += w * w; w /= 2u }
 push_gpu_dsl_compute_uniform(command, 0u, shaders::Camera(vp = vp, config = float4(float(width), float(height), settings.mode == 1 ? 1.0 : 0.0, 0.0))) |> sdl_try
 buffers <- array(r.hiz, r.predicates); dispatch(command, r.cull, buffers, 16u) |> sdl_try
 buffers <- array(r.predicates, r.instances, r.commands); dispatch(command, r.compact, buffers, 1u) |> sdl_try
 let load <- array(attachment(output, float4(0.0), true)); depth.load_op = SDL_GPULoadOp.LOADOP_LOAD
 return with_native_gpu_render_pass(command, load, depth) $(var pass_ : SDL_GPURenderPass?&) {
  SDL_BindGPUGraphicsPipeline(pass_, r.pipeline); let vbs <- array(SDL_GPUBufferBinding(buffer = r.cube.vb), SDL_GPUBufferBinding(buffer = r.instances)); sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, vbs), "Compacted instances") |> sdl_try
  SDL_BindGPUIndexBufferRef(pass_, SDL_GPUBufferBinding(buffer = r.cube.ib), SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT); SDL_DrawGPUIndexedPrimitivesIndirect(pass_, r.commands, 0u, 1u); return sdl_ok()
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
   set_title(window, "GPU-driven | HiZ culling/all | 1024 instances | M: {settings.mode} | Space: pause | R: reset") |> sdl_try
   frames++; if (smoke && frames >= 3) { break }
  }
  return sdl_ok()
 }
}
