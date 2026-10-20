options gen2
module screen_app shared public
require spot_app public
require screen_shaders as sc
require hdr_shaders as hs
require daslib/defer
struct ScreenPasses { color,normal,world,depth,effect,blur : SDL_GPUTexture?; size : uint2; gather,filter,composite : SDL_GPUGraphicsPipeline?; params : sc::ScreenParams }
def release_screen_targets(device : SDL_GPUDevice?;var p : ScreenPasses){for(t in fixed_array(p.color,p.normal,p.world,p.depth,p.effect,p.blur)){if(t!=null){SDL_ReleaseGPUTexture(device,t)}};p.color=null;p.normal=null;p.world=null;p.depth=null;p.effect=null;p.blur=null;p.size=uint2(0u)}
def pcg(value : uint) : uint {let state=value*747796405u+2891336453u;let word=((state>>((state>>28u)+4u))^state)*277803737u;return (word>>22u)^word}
def ao_kernel : sc::ScreenParams {
 var p : sc::ScreenParams;var seed=12345u
 for(i in 0..64){seed=pcg(seed);let x=float(seed)/4294967296.0*2.0-1.0;seed=pcg(seed);let y=float(seed)/4294967296.0*2.0-1.0;seed=pcg(seed);let z=float(seed)/4294967296.0;seed=pcg(seed)
  let v=float3(x,y,z);let len=max(length(v),0.0001);let t=float(i)/64.0;let scale=max(0.01,(0.1+0.9*t*t)*float(seed)/4294967296.0);p.samples[i]=float4(v/len*scale,0.0)
 };seed=67890u
 for(i in 0..16){seed=pcg(seed);let x=float(seed)/4294967296.0*2.0-1.0;seed=pcg(seed);let y=float(seed)/4294967296.0*2.0-1.0;let len=max(sqrt(x*x+y*y),0.0001);p.noise[i]=float4(x/len,y/len,0.0,0.0)};return p
}
def screen_pipeline(device : SDL_GPUDevice?;depth_format : SDL_GPUTextureFormat=SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) {
 return sdl_scope(){
  var vertex : SDL_GPUShader? = device |> with_dsl_example_shader(hs::cascade_vertex,hs::cascade_vertex_reflect) |> sdl_use
  var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(sc::forge_gbuffer_fragment,sc::forge_gbuffer_fragment_reflect) |> sdl_use
  var info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST,rasterizer_state=SDL_GPURasterizerState(enable_depth_clip=true))
  info <- info |> depth_target(depth_format) |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS) |> depth_write(true)
  let buffers <- array(SDL_GPUVertexBufferDescription(pitch=32u));let attrs <- array(SDL_GPUVertexAttribute(format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),SDL_GPUVertexAttribute(location=1u,offset=12u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),SDL_GPUVertexAttribute(location=2u,offset=24u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2))
  let colors <- array(gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM),gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT),gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT))
  return <- device |> create_native_gpu_graphics_pipeline(info,buffers,attrs,colors)
 }
}
def screen_targets(device : SDL_GPUDevice?;var p : ScreenPasses;width,height : uint;depth_format : SDL_GPUTextureFormat=SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) : SdlStatus {
 if(p.size==uint2(width,height)){return sdl_ok()};release_screen_targets(device,p)
 let usage=SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER
 var t=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,usage)) |> sdl_try;p.color=t
 t=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,usage)) |> sdl_try;p.normal=t
 t=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,usage)) |> sdl_try;p.world=t
 t=device |> create_advanced_texture(gpu_texture(width,height,depth_format,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_try;p.depth=t
 t=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,usage)) |> sdl_try;p.effect=t
 t=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,usage)) |> sdl_try;p.blur=t
 p.size=uint2(width,height);return sdl_ok()
}
def single_light_matrix : float4x4 {
 var projection : float4x4;projection[0].x=1.0/15.0;projection[1].y=1.0/15.0;projection[2].z=-1.0/49.9;projection[3]=float4(0,0,-0.1/49.9,1)
 return projection*look_at_rh(normalize(float3(0.5,0.8,0.5))*20.0,float3(0),float3(0,1,0))
}
def draw_screen_scene(command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var p : ScreenPasses;width,height : uint;state : LessonState) : SdlStatus {
 let light=single_light_matrix();let no_colors : array<SDL_GPUColorTargetInfo>;let shadow_depth=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[0],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,no_colors,shadow_depth) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,scene.shadow_pipeline);for(part in scene.parts){push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.spec.model,vp=light)) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try};return sdl_ok()} |> sdl_try
 var vertex=hs::AdvancedVertex(model=identity_matrix(),vp=camera_matrix(width,height,state.eye,state.target),light0=light)
 let view=look_at_rh(state.eye,state.target,float3(0,1,0));let projection=vertex.vp*inverse(view)
 push_gpu_dsl_fragment_uniform(command,1u,sc::ScreenView(view=view,projection=projection,inverse_projection=inverse(projection))) |> sdl_try
 let colors <- array(attachment(p.color),attachment(p.normal,false,float4(0)),attachment(p.world,false,float4(0)))
 let depth=SDL_GPUDepthStencilTargetInfo(texture=p.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE,stencil_load_op=SDL_GPULoadOp.LOADOP_CLEAR,stencil_store_op=SDL_GPUStoreOp.STOREOP_STORE)
 return with_native_gpu_render_pass(command,colors,depth) $(var pass_){
  SDL_BindGPUGraphicsPipeline(pass_,scene.solid)
  var f=hs::AdvancedFragment(base=float4(0.15,0.55,0.85,1),diffuse=float4(0.04,0.04,0.08,1),eye=float4(state.eye,1.0),controls=float4(0,0,0,15))
  var images <- array(SDL_GPUTextureSamplerBinding(texture=scene.parts[0].diffuse,sampler=scene.sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler))
  sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind G-buffer grid") |> sdl_try;push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try;draw_mesh(pass_,scene.grid) |> sdl_try
  for(part in scene.parts){vertex.model=part.spec.model;f.base=part.spec.base;f.controls=float4(part.spec.diffuse!="" ? 1.0 : 0.0,0.0,0.0,0.0);images[0].texture=part.diffuse
   sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind G-buffer model") |> sdl_try;push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try
  };return sdl_ok()
 }
}
def render_screen(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var p : ScreenPasses;var output : SDL_GPUTexture?;width,height : uint;state : LessonState;lesson : int) : SdlStatus {
 screen_targets(device,p,width,height) |> sdl_try;draw_screen_scene(command,scene,p,width,height,state) |> sdl_try
 p.params.config=lesson==27 ? float4(0.5,0.025,1.0,0.0) : float4(0.15,20.0,0.15,128.0);p.params.size=float4(float(width),float(height),0.0,0.0)
 push_gpu_dsl_fragment_uniform(command,0u,p.params) |> sdl_try
 let targets <- array(attachment(p.effect))
 with_native_gpu_render_pass(command,targets) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,p.gather);var images : array<SDL_GPUTexture?>;if(lesson==27){images <- array(p.depth,p.normal)}else{images <- array(p.color,p.depth,p.normal,p.world)};bind_images(pass_,images,scene.shadow_sampler) |> sdl_try;SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()} |> sdl_try
 if(lesson==27){let blur_target <- array(attachment(p.blur));with_native_gpu_render_pass(command,blur_target) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,p.filter);var images <- array(p.effect);bind_images(pass_,images,scene.shadow_sampler) |> sdl_try;SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()} |> sdl_try}
 p.params.config=float4(float(state.effect ? state.mode : (lesson==27 ? 2 : 5)),lesson==27 ? 1.0 : 0.8,0.0,0.0);push_gpu_dsl_fragment_uniform(command,0u,p.params) |> sdl_try
 let output_target <- array(attachment(output))
 return with_native_gpu_render_pass(command,output_target) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,p.composite);var images <- array(p.color,lesson==27 ? p.blur : p.effect,p.normal,p.world);if(lesson==29){push(images,p.depth)};bind_images(pass_,images,scene.shadow_sampler) |> sdl_try;SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()}
}
def run_screen(lesson : int;smoke : bool) : int {
 return with_lesson_window(lesson) $(device,window){return with_advanced(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,15) $(var scene){
  var parts : array<AdvancedPart>;let truck <- truck_parts();add_parts(parts,truck,identity_matrix());let box <- box_parts()
  let positions=fixed_array(float3(-3.5,0.5,2),float3(-2.5,0.5,0.5),float3(3,0.5,-2),float3(-1,0.5,-3),float3(-3.5,1.5,2),float3(4,0.5,1.5),float3(-4.5,0.5,-1),float3(2,0.5,3.5));let angles=fixed_array(0.3,1.1,0.7,2.0,0.9,1.5,0.2,2.5)
  for(i in 0..(lesson==27 ? 5 : 8)){add_parts(parts,box,model_matrix(positions[i],float3(1),-angles[i]))};replace_parts(device,scene,parts) |> sdl_try
  var gbuffer=screen_pipeline(device) |> sdl_try;SDL_ReleaseGPUGraphicsPipeline(device,scene.solid);scene.solid=gbuffer
  var p=ScreenPasses(params=ao_kernel())
  defer(){release_screen_targets(device,p);for(resource in fixed_array(p.gather,p.filter,p.composite)){if(resource!=null){SDL_ReleaseGPUGraphicsPipeline(device,resource)}}}
  var pipeline_=device |> pipeline(hs::forge_post_vertex,hs::forge_post_vertex_reflect,lesson==27 ? sc::forge_ssao_fragment : sc::forge_ssr_fragment,lesson==27 ? sc::forge_ssao_fragment_reflect : sc::forge_ssr_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,false,false,false) |> sdl_try;p.gather=pipeline_
  pipeline_=device |> pipeline(hs::forge_post_vertex,hs::forge_post_vertex_reflect,sc::forge_ssao_blur_fragment,sc::forge_ssao_blur_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,false,false,false) |> sdl_try;p.filter=pipeline_
  pipeline_=device |> pipeline(hs::forge_post_vertex,hs::forge_post_vertex_reflect,lesson==27 ? sc::forge_ssao_composite_fragment : sc::forge_ssr_composite_fragment,lesson==27 ? sc::forge_ssao_composite_fragment_reflect : sc::forge_ssr_composite_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),false,false,false) |> sdl_try;p.composite=pipeline_
  var state=lesson_camera(lesson==27 ? float3(2,1.5,3.5) : float3(4,3,7),0.523598776,-0.13962634);state.mode=lesson==27 ? 1 : 0
  return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_screen(device,command,scene,p,target,width,height,state,lesson)}
 }}
}
