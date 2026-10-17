// Adapted from bgfx 39-assao. Copyright 2018 Attila Kocsis.
// See the example README and group LICENSE-bgfx.txt.
options gen2
module assao_app shared public
require ../common/compute_support.das public
require ./shaders/assao_shaders.das as shaders
require dassdl3/sdl3_shader_storage_spirv
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool; quality : int = 3; blur_passes : int = 2; adaptive_limit : float = 0.45; detail : float = 0.5; generate_normals : bool = true; radius : float = 1.2; strength : float = 1.0; eye : float3 = float3(0.0, 1.5, 0.0); yaw : float = 0.01; pitch : float = -0.3; textured : bool = true; gutter : bool = true; power : float = 1.5; shadow_clamp : float = 0.98; horizon : float = 0.06; sharpness : float = 0.98; fade_from : float = 50.0; fade_to : float = 200.0; sample_angle : float; sample_scale : float = 1.0 }

struct Model { mesh : int; position : float3 }
struct Resources { meshes : array<GeometryBuffers>; models : array<Model>; ground : SDL_GPUTexture ?; material_sampler : SDL_GPUSampler ?; geometry, combine : SDL_GPUGraphicsPipeline ?; prepare, generate, importance, blur, mip, smooth, clear, apply : SDL_GPUComputePipeline ?; position, normal, albedo, depth : SDL_GPUTexture ?; points, normals, ao, adaptive, importance_map, blurred, ping, base, mips, counter, importance_temp, applied : SDL_GPUBuffer ?; sampler : SDL_GPUSampler ?; size : uint2; count : uint }
// Same MWC seeds, call order and uint32 wraparound as bx::RngMwc.
def mwc(var z, w : uint&) : uint { z = 36969u * (z & 65535u) + (z >> 16u); w = 18000u * (w & 65535u) + (w >> 16u); return (z << 16u) + w }
def clear_targets(device : SDL_GPUDevice?; var r : Resources) {
 for (resource in fixed_array(r.position, r.normal, r.albedo, r.depth)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }
 for (resource in fixed_array(r.points, r.normals, r.ao, r.adaptive, r.importance_map, r.blurred, r.ping, r.base, r.mips, r.counter, r.importance_temp, r.applied)) { if (resource != null) { SDL_ReleaseGPUBuffer(device, resource) } }
 r.albedo = null; r.position = null; r.normal = null; r.depth = null; r.points = null; r.normals = null; r.ao = null; r.adaptive = null; r.importance_map = null; r.blurred = null; r.ping = null; r.base = null; r.mips = null; r.counter = null; r.importance_temp = null; r.applied = null; r.size = uint2(0u)
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
 var r = Resources(); defer() { clear_targets(device, r); for (resource in r.meshes) { release(device, resource) }; if (r.ground != null) { SDL_ReleaseGPUTexture(device, r.ground) }; if (r.material_sampler != null) { SDL_ReleaseGPUSampler(device, r.material_sampler) }; for (resource in fixed_array(r.geometry, r.combine)) { if (resource != null) { SDL_ReleaseGPUGraphicsPipeline(device, resource) } }; for (resource in fixed_array(r.prepare, r.generate, r.importance, r.blur, r.mip, r.smooth, r.clear, r.apply)) { if (resource != null) { SDL_ReleaseGPUComputePipeline(device, resource) } }; if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) } }
 for (name in fixed_array("cube", "orb", "column", "bunny_decimated", "tree", "hollowcube")) {
  let mesh <- load_geometry("{SDL_GetBasePath()}assets/bgfx/assao-{name}.msh") |> sdl_try
  var g = upload_geometry(device, mesh) |> sdl_try; push(r.meshes, g)
 }
 var z = 12345u; var w = 65435u
 for (i in 0..120) { let mesh = int(mwc(z, w) % 5u) + 1; let x = (float(mwc(z, w) % 256u) - 128.0) / 20.0; let zz = (float(mwc(z, w) % 256u) - 128.0) / 20.0; push(r.models, Model(mesh = mesh, position = float3(x, 0.0, zz))) }
 var ground = SDL_CreateGPUTextureRef(device, gpu_texture(512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) |> mip_levels(10u)); r.ground = ground
 if (ground == null) { return err(sdl_error("ASSAO ground"), type<SdlUnit>) }
 upload_texture(device, r.ground, "assao-fieldstone.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
 sdl_scope() {
  var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
  SDL_GenerateMipmapsForGPUTexture(command, r.ground)
  return native_gpu_submit(command)
 } |> sdl_try
 var sampling = gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR, SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT)
 sampling.mipmap_mode = SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR; sampling.max_lod = 9.0
 r.material_sampler = SDL_CreateGPUSamplerRef(device, sampling)
 if (r.material_sampler == null) { return err(sdl_error("ASSAO material sampler"), type<SdlUnit>) }
 let mrt <- array(gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT), gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT), gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)); let target <- array(gpu_color_target(format))
 var p = pass_pipeline(device, shaders::assao_geometry, shaders::assao_geometry_reflect, shaders::assao_gbuffer, shaders::assao_gbuffer_reflect, mrt) |> sdl_try; r.geometry = p
 p = sdl_scope() {
  var vs : SDL_GPUShader? = with_example_shader(device, shaders::assao_screen, shaders::assao_screen_reflect) |> sdl_use
  var fs = create_fragment(device) |> sdl_try
  { defer() { SDL_ReleaseGPUShader(device, fs) }
    let info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vs, fragment_shader = fs)
    var streams : array<SDL_GPUVertexBufferDescription>; var attrs : array<SDL_GPUVertexAttribute>
    return create_native_gpu_graphics_pipeline(device, info, streams, attrs, target)
  }
 } |> sdl_try; r.combine = p
 var cp = compute_pipeline(device, shaders::assao_prepare, shaders::assao_prepare_reflect, shaders::assao_prepare_access) |> sdl_try; r.prepare = cp
 cp = compute_pipeline(device, shaders::assao_generate, shaders::assao_generate_reflect, shaders::assao_generate_access) |> sdl_try; r.generate = cp
 cp = compute_pipeline(device, shaders::assao_importance, shaders::assao_importance_reflect, shaders::assao_importance_access) |> sdl_try; r.importance = cp
 cp = compute_pipeline(device, shaders::assao_blur, shaders::assao_blur_reflect, shaders::assao_blur_access) |> sdl_try; r.blur = cp
 cp = compute_pipeline(device, shaders::assao_depth_mip, shaders::assao_depth_mip_reflect, shaders::assao_depth_mip_access) |> sdl_try; r.mip = cp
 cp = compute_pipeline(device, shaders::assao_importance_smooth, shaders::assao_importance_smooth_reflect, shaders::assao_importance_smooth_access) |> sdl_try; r.smooth = cp
 cp = compute_pipeline(device, shaders::assao_clear_counter, shaders::assao_clear_counter_reflect, shaders::assao_clear_counter_access) |> sdl_try; r.clear = cp
 cp = compute_pipeline(device, shaders::assao_apply, shaders::assao_apply_reflect, shaders::assao_apply_access) |> sdl_try; r.apply = cp
 r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_NEAREST)); if (r.sampler == null) { return err(sdl_error("ASSAO sampler"), type<SdlUnit>) }
 return body(r)
}
def dispatch(command : SDL_GPUCommandBuffer?; pipeline : SDL_GPUComputePipeline?; var buffers : array<SDL_GPUBuffer?>; count : uint) : SdlStatus {
 var textures : array<SDL_GPUStorageTextureReadWriteBinding>; var bindings : array<SDL_GPUStorageBufferReadWriteBinding>; for (buf in buffers) { push(bindings, SDL_GPUStorageBufferReadWriteBinding(buffer = buf)) }
 return with_native_gpu_compute_pass(command, textures, bindings) $(var pass_ : SDL_GPUComputePass?&) { SDL_BindGPUComputePipeline(pass_, pipeline); SDL_DispatchGPUCompute(pass_, (count + 63u) / 64u, 1u, 1u); return sdl_ok() }
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; output_width, output_height : uint; time : float; settings : Settings) : SdlStatus {
 let border = settings.gutter ? (min(output_width, output_height) / 12u) / 2u * 2u : 0u
 let width = output_width + border * 2u; let height = output_height + border * 2u
 let tan_y = 0.57735027 * float(height) / float(output_height)
 let tan_x = tan_y * float(width) / float(height)
 let dims = uint4(width, height, (width + 1u) / 2u, (height + 1u) / 2u)
 if (r.size != uint2(width, height)) {
  clear_targets(device, r); r.count = dims.z * dims.w * 4u
  let usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER
  var tex = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.position = tex
  tex = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.normal = tex
  tex = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, usage) |> sdl_try; r.albedo = tex
  tex = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try; r.depth = tex
  var buf = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE, size = r.count * 16u)) |> sdl_try; r.points = buf
  buf = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE, size = r.count * 16u)) |> sdl_try; r.normals = buf
  let info = SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE | SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ, size = r.count * 16u)
  buf = create_native_gpu_buffer(device, info) |> sdl_try; r.ao = buf; buf = create_native_gpu_buffer(device, info) |> sdl_try; r.adaptive = buf; buf = create_native_gpu_buffer(device, info) |> sdl_try; r.importance_map = buf; buf = create_native_gpu_buffer(device, info) |> sdl_try; r.blurred = buf; buf = create_native_gpu_buffer(device, info) |> sdl_try; r.ping = buf
  buf = create_native_gpu_buffer(device, info) |> sdl_try; r.base = buf
  buf = create_native_gpu_buffer(device, info) |> sdl_try; r.mips = buf
  buf = create_native_gpu_buffer(device, info) |> sdl_try; r.importance_temp = buf
  buf = create_native_gpu_buffer(device, info) |> sdl_try; r.applied = buf
  buf = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE, size = 4u)) |> sdl_try; r.counter = buf
  r.size = uint2(width, height)
 }
 let colors <- array(attachment(r.position), attachment(r.normal), attachment(r.albedo)); let depth = depth_attachment(r.depth)
 let forward = float3(cos(settings.pitch) * sin(settings.yaw), sin(settings.pitch), cos(settings.pitch) * cos(settings.yaw))
 let view = look_at_lh(settings.eye, settings.eye + forward, float3(0.0, 1.0, 0.0)); let vp = perspective(float(width) / float(height), 1.0 / tan_y, 0.1, 1000.0) * view
 with_native_gpu_render_pass(command, colors, depth) $(var pass_ : SDL_GPURenderPass?&) {
  SDL_BindGPUGraphicsPipeline(pass_, r.geometry)
  var images <- array(r.ground); bind_images(pass_, images, r.material_sampler) |> sdl_try
  let scales = fixed_array(0.25, 0.5, 0.05, 0.5, 0.05, 0.25)
  for (model in r.models) {
   push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model_matrix(model.position, float3(scales[model.mesh]), 0.0), view = view, vp = vp, material = float4(0.0))) |> sdl_try
   draw_geometry(pass_, r.meshes[model.mesh]) |> sdl_try
  }
  push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model_matrix(float3(0.0, -10.0, 0.0), float3(10.0), 0.0), view = view, vp = vp, material = float4(1.0))) |> sdl_try
  return draw_geometry(pass_, r.meshes[0])
 } |> sdl_try
 var config = shaders::Config(size = dims, params = float4(max(settings.radius, 0.001), settings.strength * 4.3, float(settings.mode), 0.0), quality = float4(float(settings.mode == 3 ? 3 : settings.quality), 1.0, settings.adaptive_limit, 0.0), tuning = float4(settings.detail, 1.0 - settings.sharpness, settings.fade_from, max(settings.fade_from + 0.001, settings.fade_to)), controls = float4(settings.generate_normals ? 1.0 : 0.0, 0.0, 0.0, 0.0), lighting = view * float4(normalize(float3(-0.8, 0.75, -1.0)), 0.0), appearance = float4(settings.textured ? 1.0 : 0.0, 0.0, 0.0, 0.0), camera = float4(tan_x, tan_y, float(border), 0.0), effect = float4(settings.power, settings.shadow_clamp, settings.horizon, 0.0), temporal = float4(settings.sample_angle, settings.sample_scale, 0.0, 0.0)); push_gpu_dsl_compute_uniform(command, 0u, config) |> sdl_try
 var textures : array<SDL_GPUStorageTextureReadWriteBinding>; let bindings <- array(SDL_GPUStorageBufferReadWriteBinding(buffer = r.points), SDL_GPUStorageBufferReadWriteBinding(buffer = r.normals))
 with_native_gpu_compute_pass(command, textures, bindings) $(var pass_ : SDL_GPUComputePass?&) { SDL_BindGPUComputePipeline(pass_, r.prepare); let images <- array(SDL_GPUTextureSamplerBinding(texture = r.position, sampler = r.sampler), SDL_GPUTextureSamplerBinding(texture = r.normal, sampler = r.sampler)); sdl_status(SDL_BindGPUComputeSamplersArray(pass_, 0u, images), "ASSAO prepare") |> sdl_try; SDL_DispatchGPUCompute(pass_, (r.count + 63u) / 64u, 1u, 1u); return sdl_ok() } |> sdl_try
 var buffers <- array(r.counter); dispatch(command, r.clear, buffers, 1u) |> sdl_try
 if (config.quality.x >= 2.0) {
  for (level in 0u..4u) {
   config.quality.w = float(level); push_gpu_dsl_compute_uniform(command, 0u, config) |> sdl_try
   let size = max(uint2(dims.z, dims.w) >> int(level), uint2(1u)); buffers <- array(r.points, r.mips); dispatch(command, r.mip, buffers, size.x * size.y * 4u) |> sdl_try
  }
 }
 config.quality.w = 0.0; config.params.w = config.quality.x == 3.0 ? 1.0 : 0.0
 push_gpu_dsl_compute_uniform(command, 0u, config) |> sdl_try
 var destination = config.quality.x == 3.0 ? r.base : r.ao
 // Base input is unused during the base pass; avoid binding the output twice.
 buffers <- array(r.points, r.normals, r.importance_map, destination, r.mips, r.adaptive, r.counter); dispatch(command, r.generate, buffers, r.count) |> sdl_try
 if (config.quality.x == 3.0) {
  let quarter = (uint2(dims.z, dims.w) + uint2(1u)) / 2u; let count = quarter.x * quarter.y
  buffers <- array(r.base, r.importance_map); dispatch(command, r.importance, buffers, count) |> sdl_try
  buffers <- array(r.importance_map, r.importance_temp, r.counter); dispatch(command, r.smooth, buffers, count) |> sdl_try
  config.quality.w = 1.0; push_gpu_dsl_compute_uniform(command, 0u, config) |> sdl_try
  buffers <- array(r.importance_temp, r.importance_map, r.counter); dispatch(command, r.smooth, buffers, count) |> sdl_try
  config.params.w = 2.0; push_gpu_dsl_compute_uniform(command, 0u, config) |> sdl_try
  buffers <- array(r.points, r.normals, r.importance_map, r.ao, r.mips, r.base, r.counter); dispatch(command, r.generate, buffers, r.count) |> sdl_try
 }
 var source = r.ao
 var passes = clamp(settings.blur_passes, 0, 6)
 if (config.quality.x <= 0.0) { passes = min(passes, 1) }
 if (config.quality.x == 3.0) { passes = max(passes, 1) }
 for (i in 0..passes) {
  config.quality.y = passes - i > 2 ? 2.0 : 1.0; push_gpu_dsl_compute_uniform(command, 0u, config) |> sdl_try
  destination = i % 2 == 0 ? r.blurred : r.ping
  buffers <- array(source, destination); dispatch(command, r.blur, buffers, r.count) |> sdl_try; source = destination
 }
 buffers <- array(source, r.applied); dispatch(command, r.apply, buffers, width * height) |> sdl_try
 push_gpu_dsl_fragment_uniform(command, 0u, config) |> sdl_try
 let target <- array(attachment(output))
 return with_native_gpu_render_pass(command, target) $(var pass_ : SDL_GPURenderPass?&) {
  SDL_BindGPUGraphicsPipeline(pass_, r.combine); var images <- array(r.normal, r.albedo); bind_images(pass_, images, r.sampler) |> sdl_try
  let storage <- array(r.applied); sdl_status(SDL_BindGPUFragmentStorageBuffersArray(pass_, 0u, storage), "ASSAO result") |> sdl_try; SDL_DrawGPUPrimitives(pass_, 3u, 1u, 0u, 0u); return sdl_ok()
 }
}

def handle_key(event : SdlEvent; var settings : Settings; var elapsed : float&) {
    match (event) { if (SdlEvent(key_down = $v(k))) { {
     let forward = float3(sin(settings.yaw), 0.0, cos(settings.yaw)); let right = float3(forward.z, 0.0, -forward.x)
     if (k.keycode == SDLK_W) { settings.eye += forward * 0.25 }
     elif (k.keycode == SDLK_S) { settings.eye -= forward * 0.25 }
     elif (k.keycode == SDLK_A) { settings.eye -= right * 0.25 }
     elif (k.keycode == SDLK_D) { settings.eye += right * 0.25 }
     elif (k.keycode == SDLK_LEFT) { settings.yaw -= 0.05 }
     elif (k.keycode == SDLK_RIGHT) { settings.yaw += 0.05 }
     elif (k.keycode == SDLK_UP) { settings.pitch = min(settings.pitch + 0.05, 1.4) }
     elif (k.keycode == SDLK_DOWN) { settings.pitch = max(settings.pitch - 0.05, -1.4) }
     elif (k.keycode == SDLK_G && !k.repeat) { settings.gutter = !settings.gutter }
     elif (k.keycode == SDLK_T && !k.repeat) { settings.textured = !settings.textured }
     elif (k.keycode == SDLK_MINUS) { settings.radius = max(0.05, settings.radius - 0.1) }
     elif (k.keycode == SDLK_EQUALS) { settings.radius = min(4.0, settings.radius + 0.1) }
    }
    if (!k.repeat) {
     if (k.keycode == SDLK_M) { settings.mode = (settings.mode + 1) % 4 }
     elif (k.keycode == SDLK_Q) { settings.quality = (settings.quality + 2) % 5 - 1; if (settings.mode == 3) { settings.mode = 0 } }
     elif (k.keycode == SDLK_B) { settings.blur_passes = (settings.blur_passes + 1) % 7 }
     elif (k.keycode == SDLK_N) { settings.generate_normals = !settings.generate_normals }

     elif (k.keycode == SDLK_R) { settings.reset = true; settings.eye = float3(0.0, 1.5, 0.0); settings.yaw = 0.01; settings.pitch = -0.3; elapsed = 0.0 }
    } } if (_) {} }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
 return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
  var settings = Settings(); var running = true; var frames = 0; var start = SDL_GetTicks(); var elapsed = 0.0; var last = SDL_GetTicks()
  while (running) {
   for (event in poll_events()) {
    if (should_close(event, window)) { running = false }
    handle_key(event, settings, elapsed)
   }
   if (!running) { break }
   let now = SDL_GetTicks(); if (!settings.paused) { elapsed += float(now - last) * 0.001 }; last = now
   with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, elapsed, settings) } |> sdl_try
   settings.reset = false
   set_title(window, "ASSAO | Q: {settings.quality} B: {settings.blur_passes} M: {settings.mode} | WASD/arrows | T: material G: gutter | +/- radius: {settings.radius}") |> sdl_try
   frames++; if (smoke && frames >= 3) { break }
  }
  return sdl_ok()
 }
}

def create_fragment(device : SDL_GPUDevice?) {
 let info = gpu_dsl_shader_info(shaders::assao_combine_reflect, shaders::assao_combine_access) |> sdl_try
 var words <- gpu_dsl_storage_spirv(shaders::assao_combine, shaders::assao_combine_reflect, shaders::assao_combine_access) |> sdl_try
 var bytes <- gpu_dsl_spirv_bytes(words) |> sdl_try
 if ((SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u) {
  var result = SDL_CreateGPUShaderBytes(device, info, bytes, "main")
  if (result == null) { return err(sdl_error("ASSAO fragment"), type<SDL_GPUShader?>) }; return <- move_ok(result, type<SdlError>)
 }
 static_if (typeinfo module_exists(sdl3_shader_dsl_cross)) {
  return with_shadercross() { return compile_graphics_shader_spirv(device, bytes, "main", SDL_ShaderCross_ShaderStage.SHADERSTAGE_FRAGMENT, SDL_ShaderCross_GraphicsShaderResourceInfo(num_samplers = info.num_samplers, num_storage_buffers = info.num_storage_buffers, num_uniform_buffers = info.num_uniform_buffers)) }
 } else { return err(SdlError(operation = "ASSAO", message = "Use shadercross runner"), type<SDL_GPUShader?>) }
}
