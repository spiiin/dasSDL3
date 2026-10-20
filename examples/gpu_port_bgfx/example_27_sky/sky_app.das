// Adapted from bgfx 36-sky. Copyright 2017 Stanislav Pidhorskyi.
// See the example README and group LICENSE-bgfx.txt.
options gen2
module sky_app shared public
require ../common/compute_support.das public
require ./shaders/sky_shaders.das as shaders
require ./sky_calendar.das public
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool; landscape : bool = true; lightmap : bool = true; hour : float = 0.0; time_scale : float = 1.0; latitude : float = 50.0; month : int = 5; turbidity : float = 2.15; prevent_banding : bool = true }

struct Resources { pipeline, landscape : SDL_GPUGraphicsPipeline ?; mesh, grid : GeometryBuffers; lightmap, depth : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; size : uint2 }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
 var r = Resources(); defer() { for (resource in fixed_array(r.pipeline, r.landscape)) { if (resource != null) { SDL_ReleaseGPUGraphicsPipeline(device, resource) } }; release(device, r.mesh); release(device,r.grid); for (resource in fixed_array(r.lightmap, r.depth)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }; if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) } }
 let targets <- array(gpu_color_target(format)); var p = sky_pipeline(device,format) |> sdl_try; r.pipeline = p
 p = pass_pipeline(device, shaders::sky_landscape_vertex, shaders::sky_landscape_vertex_reflect, shaders::sky_landscape_fragment, shaders::sky_landscape_fragment_reflect, targets) |> sdl_try; r.landscape = p
 let grid <- sky_grid();var uploaded=upload_geometry(device,grid) |> sdl_try;r.grid=uploaded
 let mesh <- load_geometry("{SDL_GetBasePath()}assets/bgfx/sky-landscape.mesh") |> sdl_try
 var geometry = upload_geometry(device, mesh) |> sdl_try; r.mesh = geometry
 var image = texture(device, 1024u, 1024u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.lightmap = image
 upload_texture(device, r.lightmap, "sky-lightmap.rgba8", 1024u, 1024u, 4u, 1u) |> sdl_try
 r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR))
 if (r.sampler == null) { return err(sdl_error("sky lightmap sampler"), type<SdlUnit>) }
 return body(r)
}
def parameters(width,height : uint; hour : float; settings : Settings) : shaders::Sky {
 let t=settings.mode==1 ? 8.0 : settings.turbidity
 return shaders::Sky(sun=float4(sun_direction(hour,settings.latitude,settings.month),0.0),sun_xyz=float4(sun_luminance(hour),0.0),zenith=float4(sky_luminance(hour),0.0),config=float4(float(width)/float(height),0.1,(settings.prevent_banding || settings.mode==2) ? 1.0 : 0.0,0.0),
 a = float4(float3(-0.2592, -0.2608, -1.4630) + float3(-0.0193, -0.0167, 0.1787) * t, 0.0),
 b = float4(float3(0.0008, 0.0092, 0.4275) + float3(-0.0665, -0.0950, -0.3554) * t, 0.0),
 c = float4(float3(0.2125, 0.2102, 5.3251) + float3(-0.0004, -0.0079, -0.0227) * t, 0.0),
 d = float4(float3(-0.8989, -1.6537, -2.5771) + float3(-0.0641, -0.0441, 0.1206) * t, 0.0),
 e = float4(float3(0.0452, 0.0529, 0.3703) + float3(-0.0033, -0.0109, -0.0670) * t, 0.0))
}

def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
 if (r.size != uint2(width, height)) {
  if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth); r.depth = null }
  var depth = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try; r.depth = depth; r.size = uint2(width, height)
 }
 let forward = normalize(float3(-0.800103, 0.382683, 0.461940))
 let right = normalize(cross(float3(0.0, 1.0, 0.0), forward)); let up = cross(forward, right)
 var sky = parameters(width,height,time,settings)
 sky.right = float4(right, 0.0); sky.up = float4(up, 0.0); sky.forward = float4(forward, 0.0)
 sky.land = float4(time, settings.lightmap ? 1.0 : 0.0, 0.0, 0.0)
 let eye=float3(5.0,3.0,0.0)
 let vp=perspective(float(width)/float(height),1.7320508,0.1,2000.0)*look_at_lh(eye,eye+forward,float3(0,1,0))
 let targets <- array(attachment(output));let depth=depth_attachment(r.depth)
 return with_native_gpu_render_pass(command,targets,depth) $(var pass_ : SDL_GPURenderPass?&){
  push_gpu_dsl_fragment_uniform(command,0u,sky) |> sdl_try
  if(settings.landscape){
   push_gpu_dsl_vertex_uniform(command,0u,shaders::Landscape(vp=vp)) |> sdl_try
   SDL_BindGPUGraphicsPipeline(pass_,r.landscape)
   var images <- array(r.lightmap);bind_images(pass_,images,r.sampler) |> sdl_try
   draw_geometry(pass_,r.mesh) |> sdl_try
  }
  push_gpu_dsl_vertex_uniform(command,0u,sky) |> sdl_try
  SDL_BindGPUGraphicsPipeline(pass_,r.pipeline)
  return draw_geometry(pass_,r.grid)
 }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
 return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
  var settings = Settings(); var running = true; var frames = 0; var start = SDL_GetTicks(); var elapsed = settings.hour; var last = SDL_GetTicks()
  while (running) {
   for (event in poll_events()) {
    if (should_close(event, window)) { running = false }
    match (event) { if (SdlEvent(key_down = $v(k))) { if (!k.repeat) {
     if (k.keycode == SDLK_M) { settings.mode = (settings.mode + 1) % 3 }
     elif (k.keycode == SDLK_L) { settings.landscape = !settings.landscape }
     elif (k.keycode == SDLK_O) { settings.lightmap = !settings.lightmap }
     elif (k.keycode == SDLK_SPACE) { settings.paused = !settings.paused }
     elif (k.keycode == SDLK_R) { settings.reset = true; elapsed = 0.0 }
    } } if (_) {} }
   }
   if (!running) { break }
   let now = SDL_GetTicks(); if (!settings.paused) { elapsed = (elapsed + float(now - last) * 0.001*settings.time_scale) % 24.0 }; last = now
   with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, elapsed, settings) } |> sdl_try
   settings.reset = false
   set_title(window, "Perez sky + landscape | L: landscape | O: lightmap | M: {settings.mode} | Space: pause | R: reset") |> sdl_try
   frames++; if (smoke && frames >= 3) { break }
  }
  return sdl_ok()
 }
}

def sky_grid : Geometry {
 var g : Geometry
 for(y in 0..32){for(x in 0..32){vertex(g,float3(float(x)/31.0*2.0-1.0,float(y)/31.0*2.0-1.0,1.0),float3(0))}}
 for(y in 0u..31u){for(x in 0u..31u){let i=y*32u+x;for(j in fixed_array(i,i+1u,i+32u,i+1u,i+33u,i+32u)){push(g.indices,j)}}}
 return <- g
}
def sky_pipeline(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat) {
 return sdl_scope(){
  var vs : SDL_GPUShader? = with_example_shader(device,shaders::sky_vertex,shaders::sky_vertex_reflect) |> sdl_use
  var fs : SDL_GPUShader? = with_example_shader(device,shaders::sky_fragment,shaders::sky_fragment_reflect) |> sdl_use
  var info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vs,fragment_shader=fs,rasterizer_state=SDL_GPURasterizerState(enable_depth_clip=true))
  info <- info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) |> depth_test(SDL_GPUCompareOp.COMPAREOP_EQUAL) |> depth_write(false)
  let buffers <- array(SDL_GPUVertexBufferDescription(pitch=32u))
  let attributes <- array(SDL_GPUVertexAttribute(format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3))
  let targets <- array(gpu_color_target(format))
  return <- create_native_gpu_graphics_pipeline(device,info,buffers,attributes,targets)
 }
}
