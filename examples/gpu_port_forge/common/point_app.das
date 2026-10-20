options gen2
module point_app shared public
require hdr_app public
require point_shaders as ps
require hdr_shaders as hs
require daslib/defer
struct PointMaps { cubes : array<SDL_GPUTexture?>;depth : SDL_GPUTexture?;shadow : SDL_GPUGraphicsPipeline? }
def point_parameters(time : float;state : LessonState) : ps::PointParams {
 var p=ps::PointParams(base=float4(1),eye=float4(state.eye,1.0),material=float4(0.02,1,64,0),shadow=float4(25.0,state.effect ? 1.0 : 0.0,0.0,0.0))
 p.positions[0]=float4(4.0*cos(time*0.5),3.5,4.0*sin(time*0.5),8.0);p.positions[1]=float4(6.0,2.5,-3.0,6.0);p.positions[2]=float4(-5.0,4.0,-2.0,5.0);p.positions[3]=float4(2.0,3.0,5.0,6.0)
 p.colors[0]=float4(0.08,0.55,0.93,1);p.colors[1]=float4(1.0,0.16,0.05,1.0);p.colors[2]=float4(0.13,0.51,0.14,1);p.colors[3]=float4(0.42,0.06,0.51,1)
 return p
}
def cube_matrix(position : float3;face : int) : float4x4 {
 let directions=fixed_array(float3(1,0,0),float3(-1,0,0),float3(0,1,0),float3(0,-1,0),float3(0,0,1),float3(0,0,-1))
 let ups=fixed_array(float3(0,-1,0),float3(0,-1,0),float3(0,0,1),float3(0,0,-1),float3(0,-1,0),float3(0,-1,0))
 var projection : float4x4;projection[0].x=1.0;projection[1].y=1.0;projection[2]=float4(0,0,-25.0/24.9,-1);projection[3].z=-2.5/24.9
 return projection*look_at_rh(position,position+directions[face],ups[face])
}
def with_point_maps(device : SDL_GPUDevice?;body : block<(var maps : PointMaps) : SdlStatus>) : SdlStatus {
 var r : PointMaps
 defer(){for(t in r.cubes){SDL_ReleaseGPUTexture(device,t)};if(r.depth!=null){SDL_ReleaseGPUTexture(device,r.depth)};if(r.shadow!=null){SDL_ReleaseGPUGraphicsPipeline(device,r.shadow)}}
 for(i in 0..4){var t=device |> create_advanced_texture(gpu_texture(512u,512u,SDL_GPUTextureFormat.TEXTUREFORMAT_R32_FLOAT,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER) |> texture_shape(SDL_GPUTextureType.TEXTURETYPE_CUBE,6u)) |> sdl_try;push(r.cubes,t)}
 var depth=device |> create_advanced_texture(gpu_texture(512u,512u,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;r.depth=depth
 var p=advanced_pipeline(device,ps::forge_radial_shadow_vertex,ps::forge_radial_shadow_vertex_reflect,ps::forge_radial_shadow_fragment,ps::forge_radial_shadow_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_R32_FLOAT) |> sdl_try;r.shadow=p
 return body(r)
}
def render_point(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var maps : PointMaps;var post : HdrPasses;var output : SDL_GPUTexture?;width,height : uint;state : LessonState) : SdlStatus {
 hdr_targets(device,post,width,height,true) |> sdl_try
 if(scene.size!=uint2(width,height)){if(scene.depth!=null){SDL_ReleaseGPUTexture(device,scene.depth);scene.depth=null};var d=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;scene.depth=d;scene.size=uint2(width,height)}
 var params=point_parameters(state.time,state)
 for(light in 0..4){for(face in 0..6){
  let depth=SDL_GPUDepthStencilTargetInfo(texture=maps.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_DONT_CARE)
  let colors <- array(SDL_GPUColorTargetInfo(texture=maps.cubes[light],layer_or_depth_plane=uint(face),clear_color=SDL_FColor(r=1.0,a=1.0),load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE))
  push_gpu_dsl_fragment_uniform(command,0u,ps::PointParams(eye=params.positions[light],shadow=float4(25.0))) |> sdl_try
  with_native_gpu_render_pass(command,colors,depth) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,maps.shadow)
   for(part in scene.parts){push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.spec.model,vp=cube_matrix(params.positions[light].xyz,face))) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try}
   return sdl_ok()
  } |> sdl_try
 }}
 var vertex=hs::AdvancedVertex(model=identity_matrix(),vp=camera_matrix(width,height,state.eye,state.target))
 let colors <- array(attachment(post.hdr,false,float4(0.008,0.008,0.026,1)))
 let depth=SDL_GPUDepthStencilTargetInfo(texture=scene.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,colors,depth) $(var pass_){
  SDL_BindGPUGraphicsPipeline(pass_,scene.solid)
  params.base=float4(0.15,0.55,0.85,1);params.grid=float4(0.04,0.04,0.08,1);params.eye.w=0.0;params.material=float4(0.02,0.5,32,0)
  push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,params) |> sdl_try
  var bindings <- array(SDL_GPUTextureSamplerBinding(texture=scene.parts[0].diffuse,sampler=scene.sampler))
  for(t in maps.cubes){push(bindings,SDL_GPUTextureSamplerBinding(texture=t,sampler=scene.shadow_sampler))}
  sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,bindings),"Bind point maps") |> sdl_try;draw_mesh(pass_,scene.grid) |> sdl_try
  for(part in scene.parts){vertex.model=part.spec.model;params.base=part.spec.base;params.grid.w=0.0;params.eye.w=part.spec.diffuse!="" ? 1.0 : 0.0;params.material=float4(0.02,1,64,0)
   bindings[0].texture=part.diffuse;sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,bindings),"Bind point material") |> sdl_try
   push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,params) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try
  }
  SDL_BindGPUGraphicsPipeline(pass_,post.emissive)
  for(i in 0..4){vertex.model=model_matrix(params.positions[i].xyz,float3(0.2));let f=hs::AdvancedFragment(base=float4(params.colors[i].rgb*30.0,1.0));push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try;draw_mesh(pass_,post.sphere) |> sdl_try}
  return sdl_ok()
 } |> sdl_try
 return bloom_and_tone(command,post,output,scene.shadow_sampler,state,true)
}
def run_point(smoke : bool) : int {
 return with_lesson_window(23) $(device,window){return with_advanced(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,15) $(var scene){
  var solid=advanced_pipeline(device,hs::advanced_vertex,hs::advanced_vertex_reflect,ps::forge_point_fragment,ps::forge_point_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT) |> sdl_try;SDL_ReleaseGPUGraphicsPipeline(device,scene.solid);scene.solid=solid
  return with_point_maps(device) $(var maps){return with_hdr_passes(device,SDL_GetGPUSwapchainTextureFormat(device,window),true) $(var post){
   var state=lesson_camera(float3(5,4,8),0.593411946,-0.34906585)
   return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_point(device,command,scene,maps,post,target,width,height,state)}
  }}
 }}
}
