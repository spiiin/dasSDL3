options gen2
module spot_app shared public
require hdr_app public
require spot_shaders as ss
require hdr_shaders as hs
require extended_assets public
require daslib/defer
def spot_matrix : float4x4 {
 var p : float4x4;p[0].x=1.7320508;p[1].y=1.7320508;p[2]=float4(0,0,-30.0/29.5,-1);p[3].z=-15.0/29.5
 return p*look_at_rh(float3(6,5,4),float3(0),float3(0,1,0))
}
def replace_parts(device : SDL_GPUDevice?;var scene : AdvancedScene;specs : array<AdvancedPart>) : SdlStatus {
 for(part in scene.parts){release(device,part.mesh);if(part.diffuse!=null){SDL_ReleaseGPUTexture(device,part.diffuse)};if(part.normal!=null){SDL_ReleaseGPUTexture(device,part.normal)}};clear(scene.parts)
 for(spec in specs){var copy=AdvancedPart(spec=clone(spec.spec),material=spec.material);push(scene.parts,copy)}
 for(part in scene.parts){var m=load_mesh(device,part.spec.mesh) |> sdl_try;part.mesh=m;var t=load_texture(device,part.spec.diffuse=="" ? "advanced_white" : part.spec.diffuse) |> sdl_try;part.diffuse=t}
 return sdl_ok()
}
def render_spot(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var passes : HdrPasses;var gobo : SDL_GPUTexture?;var output : SDL_GPUTexture?;width,height : uint;state : LessonState) : SdlStatus {
 hdr_targets(device,passes,width,height,true) |> sdl_try
 if(scene.size!=uint2(width,height)){if(scene.depth!=null){SDL_ReleaseGPUTexture(device,scene.depth);scene.depth=null};var d=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;scene.depth=d;scene.size=uint2(width,height)}
 let light_vp=spot_matrix()
 let no_colors : array<SDL_GPUColorTargetInfo>
 let shadow_depth=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[0],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,no_colors,shadow_depth) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,scene.shadow_pipeline);for(part in scene.parts){push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.spec.model,vp=light_vp)) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try};return sdl_ok()} |> sdl_try
 var vertex=hs::AdvancedVertex(model=identity_matrix(),vp=camera_matrix(width,height,state.eye,state.target),light0=light_vp)
 let colors <- array(attachment(passes.hdr,false,float4(0.008,0.008,0.026,1)))
 let depth=SDL_GPUDepthStencilTargetInfo(texture=scene.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,colors,depth) $(var pass_){
  SDL_BindGPUGraphicsPipeline(pass_,scene.solid)
  var f=hs::AdvancedFragment(base=float4(0.15,0.55,0.85,1),diffuse=float4(0.04,0.04,0.08,1),eye=float4(state.eye,1.0),light=float4(6,5,4,0),controls=float4(0,0,0,15),shadow=float4(0,0,state.effect ? 1.0 : 0.0,0))
  var images <- array(SDL_GPUTextureSamplerBinding(texture=scene.parts[0].diffuse,sampler=scene.sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler),SDL_GPUTextureSamplerBinding(texture=gobo,sampler=scene.shadow_sampler))
  sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind spotlight") |> sdl_try
  push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try;draw_mesh(pass_,scene.grid) |> sdl_try
  for(part in scene.parts){vertex.model=part.spec.model;f.base=part.spec.base;f.controls=float4(part.spec.diffuse!="" ? 1.0 : 0.0,0.0,float(part.material),0.0)
   images[0].texture=part.diffuse;sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind spotlight material") |> sdl_try
   push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try
  };return sdl_ok()
 } |> sdl_try
 return bloom_and_tone(command,passes,output,scene.shadow_sampler,state,true)
}
def run_spot(smoke : bool) : int {
 return with_lesson_window(24) $(device,window){return with_advanced(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,15) $(var scene){
  var parts : array<AdvancedPart>;let truck <- truck_parts();add_parts(parts,truck,identity_matrix());let box <- box_parts()
  let positions=fixed_array(float3(-3.5,0.5,2),float3(-2.5,0.5,0.5),float3(3,0.5,-2),float3(-1,0.5,-3),float3(-3.5,1.5,2));let angles=fixed_array(0.3,1.1,0.7,2.0,0.9)
  for(i in 0..5){add_parts(parts,box,model_matrix(positions[i],float3(1),-angles[i]))}
  let lamp <- searchlight_parts();let start=length(parts);add_parts(parts,lamp,model_matrix(float3(6,1,4),float3(0.003),-3.926990817))
  if(length(parts)>start+1){parts[start+1].material=1}
  replace_parts(device,scene,parts) |> sdl_try
  var solid=advanced_pipeline(device,hs::cascade_vertex,hs::cascade_vertex_reflect,ss::forge_spot_fragment,ss::forge_spot_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT) |> sdl_try;SDL_ReleaseGPUGraphicsPipeline(device,scene.solid);scene.solid=solid
  SDL_ReleaseGPUTexture(device,scene.shadows[0]);scene.shadows[0]=null
  var shadow=device |> create_advanced_texture(gpu_texture(1024u,1024u,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_try;scene.shadows[0]=shadow
  var gobo=load_texture(device,"extended_gobo",false,false) |> sdl_try
  {defer(){SDL_ReleaseGPUTexture(device,gobo)}
   return with_hdr_passes(device,SDL_GetGPUSwapchainTextureFormat(device,window),true) $(var post){var state=lesson_camera(float3(-2.7,2.5,8.4),-0.34906585,-0.20943951);state.strength=0.5
    return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_spot(device,command,scene,post,gobo,target,width,height,state)}
   }
  }
 }}
}
