options gen2
module edge_app shared public
require decal_app public
require edge_shaders as es
require hdr_shaders as hs
require daslib/defer
def edge_parts {
 var parts : array<AdvancedPart>
 let positions=fixed_array(float3(2,0.5,-2),float3(-1.5,0.5,-1),float3(0,0.5,-3),float3(3,0.8,0),float3(-2.5,0.7,-3.5),float3(1,0.6,1),float3(0,1.5,-6),float3(-1.5,0.8,-8),float3(1.5,1,-8.5))
 let scales=fixed_array(float3(1),float3(1),float3(0.8),float3(1.2),float3(0.7),float3(0.6),float3(6,3,0.3),float3(1),float3(0.8))
 let colors=fixed_array(float4(0.6,0.6,0.6,1),float4(0.3,0.4,0.8,1),float4(0.8,0.3,0.3,1),float4(0.3,0.7,0.4,1),float4(0.9,0.5,0.2,1),float4(0.2,0.7,0.7,1),float4(0.5,0.45,0.4,1),float4(0.15,0.7,1,1),float4(0.15,0.7,1,1))
 for(i in 0..9){push(parts,AdvancedPart(spec=PartSpec(mesh=i==4 || i==5 || i==8 ? "remaining_sphere" : "advanced_box_0_0",model=model_matrix(positions[i],scales[i]),base=colors[i])))}
 return <- parts
}
def render_edges(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var r : StencilPasses;var p : ScreenPasses;edge_pipeline : SDL_GPUGraphicsPipeline?;var output : SDL_GPUTexture?;width,height : uint;state : LessonState) : SdlStatus {
 screen_targets(device,p,width,height,r.format) |> sdl_try;draw_screen_scene(command,scene,p,width,height,state) |> sdl_try
 push_gpu_dsl_fragment_uniform(command,0u,es::EdgeParams(texel=float4(1.0/float(width),1.0/float(height),0.0,0.0),config=float4(0.002,0.8,float(state.mode),state.effect ? 1.0 : 0.0))) |> sdl_try
 let colors <- array(attachment(output))
 with_native_gpu_render_pass(command,colors) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,edge_pipeline);var images <- array(p.depth,p.normal,p.color);bind_images(pass_,images,scene.shadow_sampler) |> sdl_try;SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()} |> sdl_try
 if(!state.effect){return sdl_ok()}
 let load_colors <- array(attachment(output,true));let load_depth=SDL_GPUDepthStencilTargetInfo(texture=p.depth,load_op=SDL_GPULoadOp.LOADOP_LOAD,store_op=SDL_GPUStoreOp.STOREOP_STORE,stencil_load_op=SDL_GPULoadOp.LOADOP_LOAD,stencil_store_op=SDL_GPUStoreOp.STOREOP_STORE)
 let vp=camera_matrix(width,height,state.eye,state.target)
 return with_native_gpu_render_pass(command,load_colors,load_depth) $(var pass_){
  SDL_SetGPUStencilReference(pass_,0u)
  for(i in 7..9){stencil_object(command,pass_,scene,r,5,vp,scene.parts[i].spec.model,float4(0),state.eye,i==8) |> sdl_try}
  for(i in 7..9){stencil_object(command,pass_,scene,r,6,vp,scene.parts[i].spec.model,float4(0.15,0.7,1,0.7),state.eye,i==8) |> sdl_try}
  return sdl_ok()
 }
}
def run_edges(smoke : bool) : int {
 return with_lesson_window(36) $(device,window){return with_advanced(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,15) $(var scene){return with_stencil(device,SDL_GetGPUSwapchainTextureFormat(device,window)) $(var r){
  let parts <- edge_parts();replace_parts(device,scene,parts) |> sdl_try;var p : ScreenPasses;var edge_pipeline : SDL_GPUGraphicsPipeline?
  defer(){release_screen_targets(device,p);if(edge_pipeline!=null){SDL_ReleaseGPUGraphicsPipeline(device,edge_pipeline)}}
  var g=screen_pipeline(device,r.format) |> sdl_try;SDL_ReleaseGPUGraphicsPipeline(device,scene.solid);scene.solid=g
  g=device |> pipeline(hs::forge_post_vertex,hs::forge_post_vertex_reflect,es::forge_edge_fragment,es::forge_edge_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),false,false,false) |> sdl_try;edge_pipeline=g
  var state=lesson_camera(float3(0,2,5),0.0,-0.15)
  return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var output : SDL_GPUTexture?;width,height : uint){return render_edges(device,command,scene,r,p,edge_pipeline,output,width,height,state)}
 }}}
}
