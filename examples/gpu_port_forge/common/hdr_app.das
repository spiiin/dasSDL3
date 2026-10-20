options gen2
module hdr_app shared public
require advanced_app public
require hdr_shaders as hs
require lesson_host public
require daslib/defer
struct HdrPasses {
 tone,down,up,emissive : SDL_GPUGraphicsPipeline?
 hdr : SDL_GPUTexture?
 mips : array<SDL_GPUTexture?>
 sizes : array<uint2>
 size : uint2
 sphere : MeshBuffers
}
def release_hdr_targets(device : SDL_GPUDevice?;var p : HdrPasses){
 if(p.hdr!=null){SDL_ReleaseGPUTexture(device,p.hdr);p.hdr=null}
 for(t in p.mips){SDL_ReleaseGPUTexture(device,t)};clear(p.mips);clear(p.sizes);p.size=uint2(0u)
}
def additive_pipeline(device : SDL_GPUDevice?) {
 return sdl_scope(){
  var vertex : SDL_GPUShader? = device |> with_dsl_example_shader(hs::forge_post_vertex,hs::forge_post_vertex_reflect) |> sdl_use
  var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(hs::forge_bloom_up_fragment,hs::forge_bloom_up_fragment_reflect) |> sdl_use
  let info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
  let buffers : array<SDL_GPUVertexBufferDescription>;let attrs : array<SDL_GPUVertexAttribute>
  var color=gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT)
  color.blend_state=SDL_GPUColorTargetBlendState(enable_blend=true,src_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,dst_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,color_blend_op=SDL_GPUBlendOp.BLENDOP_ADD,src_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,dst_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ZERO,alpha_blend_op=SDL_GPUBlendOp.BLENDOP_ADD)
  let colors <- array(color);return <- device |> create_native_gpu_graphics_pipeline(info,buffers,attrs,colors)
 }
}
def with_hdr_passes(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; bloom : bool; body : block<(var passes : HdrPasses) : SdlStatus>) : SdlStatus {
 var p : HdrPasses
 defer(){release_hdr_targets(device,p);release(device,p.sphere);for(resource in fixed_array(p.tone,p.down,p.up,p.emissive)){if(resource!=null){SDL_ReleaseGPUGraphicsPipeline(device,resource)}}}
 var t=device |> pipeline(hs::forge_post_vertex,hs::forge_post_vertex_reflect,bloom ? hs::forge_bloom_tone_fragment : hs::forge_tone_fragment,bloom ? hs::forge_bloom_tone_fragment_reflect : hs::forge_tone_fragment_reflect,format,false,false,false) |> sdl_try;p.tone=t
 if(bloom){
  t=device |> pipeline(hs::forge_post_vertex,hs::forge_post_vertex_reflect,hs::forge_bloom_down_fragment,hs::forge_bloom_down_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,false,false,false) |> sdl_try;p.down=t
  // Upsample adds into the existing larger mip, exactly as the original.
  t=additive_pipeline(device) |> sdl_try;p.up=t
  t=advanced_pipeline(device,hs::advanced_vertex,hs::advanced_vertex_reflect,hs::forge_emissive_fragment,hs::forge_emissive_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT) |> sdl_try;p.emissive=t
  var mesh=load_mesh(device,"remaining_sphere") |> sdl_try;p.sphere=mesh
 }
 return body(p)
}
def hdr_targets(device : SDL_GPUDevice?;var p : HdrPasses;width,height : uint;bloom : bool) : SdlStatus {
 if(p.size==uint2(width,height)){return sdl_ok()}
 release_hdr_targets(device,p)
 var hdr=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_try;p.hdr=hdr
 if(bloom){var size=uint2(width,height);for(i in 0..5){size=max(size/2u,uint2(1u));var t=device |> create_advanced_texture(gpu_texture(size.x,size.y,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_try;push(p.mips,t);push(p.sizes,size)}}
 p.size=uint2(width,height);return sdl_ok()
}
def bloom_and_tone(command : SDL_GPUCommandBuffer?;var p : HdrPasses;var target : SDL_GPUTexture?;var sampler : SDL_GPUSampler?;state : LessonState;bloom : bool) : SdlStatus {
 if(bloom){
  var src=p.hdr;var size=p.size
  for(i in 0..length(p.mips)){
   push_gpu_dsl_fragment_uniform(command,0u,hs::PostParams(config=float4(state.threshold,i==0 ? 1.0 : 0.0,0.0,0.0),texel=float4(1.0/float(size.x),1.0/float(size.y),0.0,0.0))) |> sdl_try
   let targets <- array(attachment(p.mips[i]))
   with_native_gpu_render_pass(command,targets) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,p.down);var images <- array(src);bind_images(pass_,images,sampler) |> sdl_try;SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()} |> sdl_try
   src=p.mips[i];size=p.sizes[i]
  }
  for(step in 0..length(p.mips)-1){let i=length(p.mips)-1-step;let up_size=p.sizes[i]
   push_gpu_dsl_fragment_uniform(command,0u,hs::PostParams(texel=float4(1.0/float(up_size.x),1.0/float(up_size.y),0.0,0.0))) |> sdl_try
   let targets <- array(attachment(p.mips[i-1],true))
   with_native_gpu_render_pass(command,targets) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,p.up);var images <- array(p.mips[i]);bind_images(pass_,images,sampler) |> sdl_try;SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()} |> sdl_try
  }
 }
 push_gpu_dsl_fragment_uniform(command,0u,hs::PostParams(config=float4(state.exposure,float(state.mode),bloom && state.effect ? state.strength : 0.0,0.0))) |> sdl_try
 let targets <- array(attachment(target))
 return with_native_gpu_render_pass(command,targets) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,p.tone);var images <- array(p.hdr);if(bloom){push(images,p.mips[0])};bind_images(pass_,images,sampler) |> sdl_try;SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()}
}
def render_hdr_scene(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var p : HdrPasses;var output : SDL_GPUTexture?;width,height : uint;state : LessonState;lesson : int) : SdlStatus {
 hdr_targets(device,p,width,height,lesson!=21) |> sdl_try
 if(scene.size!=uint2(width,height)){
  if(scene.depth!=null){SDL_ReleaseGPUTexture(device,scene.depth);scene.depth=null}
  var t=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;scene.depth=t;scene.size=uint2(width,height)
 }
 let camera=AdvancedSettings(eye=state.eye,target=state.target)
 let splits=cascade_splits()
 var vertex=hs::AdvancedVertex(model=identity_matrix(),vp=camera_matrix(width,height,state.eye,state.target),light0=cascade_matrix(camera,float(width)/float(height),0.1,splits.x),light1=cascade_matrix(camera,float(width)/float(height),splits.x,splits.y),light2=cascade_matrix(camera,float(width)/float(height),splits.y,splits.z))
 if(lesson==21){let matrices=fixed_array(vertex.light0,vertex.light1,vertex.light2)
  for(i in 0..3){let colors : array<SDL_GPUColorTargetInfo>;let depth=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[i],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
   with_native_gpu_render_pass(command,colors,depth) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,scene.shadow_pipeline);for(part in scene.parts){push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.spec.model,vp=matrices[i])) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try};return sdl_ok()} |> sdl_try
  }
 }
 let light=lesson==21 ? float3(1,1,0.5) : float3(cos(state.time*0.6283+1.04719755)*4.0,2.0,sin(state.time*0.6283+1.04719755)*4.0)
 let colors <- array(attachment(p.hdr,false,float4(0.008,0.008,0.026,1.0)))
 let depth=SDL_GPUDepthStencilTargetInfo(texture=scene.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,colors,depth) $(var pass_){
  SDL_BindGPUGraphicsPipeline(pass_,scene.solid)
  var f=hs::AdvancedFragment(base=float4(0.15,0.55,0.85,1),light=float4(light,0.0),eye=float4(state.eye,1.0),ambient=float4(0.15),diffuse=float4(0.04,0.04,0.08,1),specular=float4(0.5,0.5,0.5,32),controls=float4(0,0,0,15),splits=float4(splits,0.0),shadow=float4(1.0/2048.0,0.0053,lesson==21 ? 1.0 : 0.0,0.5),fog=float4(lesson==21 ? 3.0 : 5.0,lesson==21 ? 0.0 : 1.0,0.0,0.0))
  push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try
  let images <- shadow_bindings(scene,scene.parts[0].diffuse);sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind HDR grid") |> sdl_try
  draw_mesh(pass_,scene.grid) |> sdl_try
  for(part in scene.parts){vertex.model=part.spec.model;f.base=part.spec.base;f.controls=float4(part.spec.diffuse!="" ? 1.0 : 0.0,0.0,0.0,0.0);f.ambient=float4(0.1);f.specular=float4(1,1,1,64)
   push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try
   let material_images <- shadow_bindings(scene,part.diffuse);sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,material_images),"Bind HDR material") |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try
  }
  if(lesson!=21){vertex.model=model_matrix(light,float3(0.3));f.base=float4(50,45,40,1);SDL_BindGPUGraphicsPipeline(pass_,p.emissive);push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try;draw_mesh(pass_,p.sphere) |> sdl_try}
  return sdl_ok()
 } |> sdl_try
 return bloom_and_tone(command,p,output,scene.shadow_sampler,state,lesson!=21)
}
def run_hdr(lesson : int;smoke : bool) : int {
 return with_lesson_window(lesson) $(device,window){
  return with_advanced(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,15) $(var scene){
   var solid=advanced_pipeline(device,hs::cascade_vertex,hs::cascade_vertex_reflect,hs::forge_hdr_scene_fragment,hs::forge_hdr_scene_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT) |> sdl_try
   SDL_ReleaseGPUGraphicsPipeline(device,scene.solid);scene.solid=solid
   return with_hdr_passes(device,SDL_GetGPUSwapchainTextureFormat(device,window),lesson!=21) $(var passes){
    var state=lesson_camera(float3(-6.1,7,4.4),-0.872664626,-0.872664626)
    return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_hdr_scene(device,command,scene,passes,target,width,height,state,lesson)}
   }
  }
 }
}
