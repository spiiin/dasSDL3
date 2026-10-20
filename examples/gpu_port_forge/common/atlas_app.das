options gen2
module atlas_app shared public
require animation_app public
require atlas_names
require atlas_shaders as at
require hdr_shaders as hs
require daslib/defer

def run_atlas(smoke : bool) : int {
 return with_lesson_window(47) $(device,window){return with_advanced(device,SDL_GetGPUSwapchainTextureFormat(device,window),15) $(var scene){
  let names <- atlas_names();var parts : array<AdvancedPart>
  for(i in 0..30){push(parts,AdvancedPart(spec=PartSpec(mesh="remaining_atlas_cube",diffuse=names[i],base=float4(1),model=model_matrix(float3(float(i%6)*1.6-4.0,0.45,float(i/6)*1.6-3.2),float3(0.9)))))}
  replace_parts(device,scene,parts) |> sdl_try
  var atlas=load_texture(device,"remaining_atlas") |> sdl_try
  {defer(){SDL_ReleaseGPUTexture(device,atlas)}
   var pipeline_=advanced_pipeline(device,hs::cascade_vertex,hs::cascade_vertex_reflect,at::forge_atlas_fragment,at::forge_atlas_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window)) |> sdl_try
   SDL_ReleaseGPUGraphicsPipeline(device,scene.solid);scene.solid=pipeline_
   var state=lesson_camera(float3(0,6,12),0.0,-0.4)
   return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){
    let light=single_light_matrix();let vp=camera_matrix(width,height,state.eye,state.target)
    if(scene.size!=uint2(width,height)){if(scene.depth!=null){SDL_ReleaseGPUTexture(device,scene.depth);scene.depth=null};var d=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;scene.depth=d;scene.size=uint2(width,height)}
    let empty : array<SDL_GPUColorTargetInfo>;let shadow=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[0],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
    with_native_gpu_render_pass(command,empty,shadow) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,scene.shadow_pipeline);for(part in scene.parts){push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.spec.model,vp=light)) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try};return sdl_ok()} |> sdl_try
    let colors <- array(attachment(target,false,float4(0.08,0.1,0.15,1)));let depth=SDL_GPUDepthStencilTargetInfo(texture=scene.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
    with_native_gpu_render_pass(command,colors,depth) $(var pass_){
     SDL_BindGPUGraphicsPipeline(pass_,scene.solid)
     var images <- array(SDL_GPUTextureSamplerBinding(texture=atlas,sampler=scene.sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler))
     sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind atlas once") |> sdl_try
     for(i in 0..30){var part & = unsafe(scene.parts[i]);var rect=float4(0,0,1,1)
      if(state.effect){rect=float4(float(i%6*264+4)/1584.0,float(i/6*264+4)/1320.0,256.0/1584.0,256.0/1320.0)}else{images[0].texture=part.diffuse;sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind individual texture") |> sdl_try}
      push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.spec.model,vp=vp,light0=light)) |> sdl_try
      push_gpu_dsl_fragment_uniform(command,0u,hs::AdvancedFragment(eye=float4(state.eye,1.0),light=float4(0.4,0.8,0.6,0),ambient=float4(0.15),specular=float4(0.4,0.4,0.4,64),fog=rect)) |> sdl_try
      draw_mesh(pass_,part.mesh) |> sdl_try
     };return sdl_ok()
    } |> sdl_try
    sdl_status(SDL_SetWindowTitle(window,state.effect ? "Forge 47 | atlas: 1 material bind | E: individual" : "Forge 47 | individual: 30 material binds | E: atlas"),"Atlas title") |> sdl_try
    return sdl_ok()
   }
  }
 }}
}
