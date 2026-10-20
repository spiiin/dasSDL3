options gen2
module pipeline_app shared public
require animation_app public
require pipeline_assets public
require deformation_shaders as ds
require hdr_shaders as hs
require daslib/defer
struct PipelineComparison {raw,processed : array<AdvancedPart>}
def render_pipeline_comparison(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var r : PipelineComparison;var output : SDL_GPUTexture?;width,height : uint;state : LessonState) : SdlStatus {
 if(scene.size!=uint2(width,height)){if(scene.depth!=null){SDL_ReleaseGPUTexture(device,scene.depth);scene.depth=null};var d=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;scene.depth=d;scene.size=uint2(width,height)}
 let colors <- array(attachment(output));let depth=SDL_GPUDepthStencilTargetInfo(texture=scene.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 let no_colors : array<SDL_GPUColorTargetInfo>;let shadow=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[0],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,no_colors,shadow) $(var pass_){return sdl_ok()} |> sdl_try
 return with_native_gpu_render_pass(command,colors,depth) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,scene.solid)
  let split=state.mode==2;let count=split ? 2 : 1
  for(stage in 0..count){let raw=split ? stage==1 : state.mode==1;let w=split ? width/2u : width;let x=split ? uint(stage)*w : 0u
   SDL_SetGPUViewportRef(pass_,SDL_GPUViewport(x=float(x),w=float(w),h=float(height),min_depth=0.0,max_depth=1.0));SDL_SetGPUScissorRef(pass_,SDL_Rect(x=int(x),w=int(w),h=int(height)))
   let vp=camera_matrix(w,height,state.eye,state.target)
   for(i in 0..2){var part=raw ? r.raw[i] : r.processed[i];push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.spec.model,vp=vp,light0=single_light_matrix())) |> sdl_try
    let f=hs::AdvancedFragment(base=float4(1),eye=float4(state.eye,1.0),light=float4(0.4,0.8,0.6,0),ambient=float4(0.2),specular=float4(0.3,0.3,0.3,64),fog_color=float4(1),controls=float4(1,0,0,0));push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try
    let images <- array(SDL_GPUTextureSamplerBinding(texture=part.diffuse,sampler=scene.sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler));sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind raw/processed material") |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try
   }
  };return sdl_ok()
 }
}
def run_pipeline_comparison(smoke : bool) : int {
 return with_lesson_window(39) $(device,window){return with_advanced(device,SDL_GetGPUSwapchainTextureFormat(device,window),15) $(var scene){
  var r : PipelineComparison
  defer(){for(part in r.raw){release(device,part.mesh);if(part.diffuse!=null){SDL_ReleaseGPUTexture(device,part.diffuse)}};for(part in r.processed){release(device,part.mesh);if(part.diffuse!=null){SDL_ReleaseGPUTexture(device,part.diffuse)}}}
  let names=fixed_array("WaterBottle","BoxTextured");let folders=fixed_array("raw_water","raw_box")
  for(i in 0..2){var raw=load_raw_gltf(device,folders[i],"{names[i]}.gltf") |> sdl_try;let placement=i==0 ? identity_matrix() : model_matrix(float3(0.5,0.075,0),float3(0.15))
   push(r.raw,AdvancedPart(mesh=raw.mesh,spec=PartSpec(model=placement*raw.model)));var mesh=load_pipeline_mesh(device,"pipeline_{names[i]}.fmesh") |> sdl_try;push(r.processed,AdvancedPart(mesh=mesh,spec=PartSpec(model=placement)))
   var texture=load_texture(device,"pipeline_{names[i]}_baseColor") |> sdl_try;r.raw[i].diffuse=texture;texture=load_texture(device,"pipeline_{names[i]}_baseColor") |> sdl_try;r.processed[i].diffuse=texture
  }
  var pipeline_=advanced_pipeline(device,hs::cascade_vertex,hs::cascade_vertex_reflect,ds::forge_model_fragment,ds::forge_model_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window)) |> sdl_try;SDL_ReleaseGPUGraphicsPipeline(device,scene.solid);scene.solid=pipeline_
  var state=lesson_camera(float3(0.25,0.25,0.8),0.0,-0.174532925)
  return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var output : SDL_GPUTexture?;width,height : uint){return render_pipeline_comparison(device,command,scene,r,output,width,height,state)}
 }}
}
