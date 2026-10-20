options gen2
module stencil_app shared public
require animation_app public
require stencil_shaders as st
require deformation_shaders as ds
require hdr_shaders as hs
require daslib/defer
struct StencilPasses {pipelines : array<SDL_GPUGraphicsPipeline?>;cube,sphere : MeshBuffers;depth : SDL_GPUTexture?;format : SDL_GPUTextureFormat;size : uint2}
def stencil_pipeline(device : SDL_GPUDevice?;format,depth_format : SDL_GPUTextureFormat;mode : int){
 return sdl_scope(){
  var vertex : SDL_GPUShader? = device |> with_dsl_example_shader(mode==9 ? hs::forge_post_vertex : (mode==6 ? st::forge_ghost_vertex : hs::cascade_vertex),mode==9 ? hs::forge_post_vertex_reflect : (mode==6 ? st::forge_ghost_vertex_reflect : hs::cascade_vertex_reflect)) |> sdl_use
  var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(mode==3 || mode==1 || mode==4 ? st::forge_flat_fragment : (mode==6 ? st::forge_ghost_fragment : (mode==7 || mode==9 ? st::forge_id_fragment : ds::forge_model_fragment)),mode==3 || mode==1 || mode==4 ? st::forge_flat_fragment_reflect : (mode==6 ? st::forge_ghost_fragment_reflect : (mode==7 || mode==9 ? st::forge_id_fragment_reflect : ds::forge_model_fragment_reflect))) |> sdl_use
  var info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST,rasterizer_state=SDL_GPURasterizerState(enable_depth_clip=true))
  info <- info |> depth_target(depth_format) |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL) |> depth_write(mode==0 || mode==2 || mode==7 || mode==8)
  if(mode!=0 && mode!=7){
   info.depth_stencil_state.enable_stencil_test=true;info.depth_stencil_state.compare_mask=255u8;info.depth_stencil_state.write_mask=(mode==1 || mode==4 || mode==5 || mode==8) ? 255u8 : 0u8
   info.depth_stencil_state.front_stencil_state.fail_op=SDL_GPUStencilOp.STENCILOP_KEEP
   info.depth_stencil_state.front_stencil_state.compare_op=(mode==1 || mode==4 || mode==5 || mode==8) ? SDL_GPUCompareOp.COMPAREOP_ALWAYS : (mode==3 || mode==6 ? SDL_GPUCompareOp.COMPAREOP_NOT_EQUAL : SDL_GPUCompareOp.COMPAREOP_EQUAL)
   info.depth_stencil_state.front_stencil_state.pass_op=(mode==1 || mode==4 || mode==8) ? SDL_GPUStencilOp.STENCILOP_REPLACE : SDL_GPUStencilOp.STENCILOP_KEEP
   info.depth_stencil_state.front_stencil_state.depth_fail_op=mode==5 ? SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_WRAP : SDL_GPUStencilOp.STENCILOP_KEEP
   if(mode==3 || mode==4){info.depth_stencil_state.compare_mask=128u8;info.depth_stencil_state.write_mask=mode==4 ? 128u8 : 0u8};if(mode==9){info.depth_stencil_state.compare_mask=127u8}
   info.depth_stencil_state.back_stencil_state=info.depth_stencil_state.front_stencil_state
  }
  if(mode==6 || mode==9){info.depth_stencil_state.enable_depth_test=false}
  var color=gpu_color_target(format)
  if(mode==1 || mode==4 || mode==5){color.blend_state.enable_color_write_mask=true;color.blend_state.color_write_mask=0u8}
  if(mode==6){color.blend_state=SDL_GPUColorTargetBlendState(enable_blend=true,src_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,dst_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,color_blend_op=SDL_GPUBlendOp.BLENDOP_ADD,src_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,dst_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,alpha_blend_op=SDL_GPUBlendOp.BLENDOP_ADD)}
  let colors <- array(color);var buffers <- array(SDL_GPUVertexBufferDescription(pitch=32u));var attrs <- array(SDL_GPUVertexAttribute(format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),SDL_GPUVertexAttribute(location=1u,offset=12u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),SDL_GPUVertexAttribute(location=2u,offset=24u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2))
  if(mode==9){clear(buffers);clear(attrs)};return <- device |> create_native_gpu_graphics_pipeline(info,buffers,attrs,colors)
 }
}
def with_stencil(device : SDL_GPUDevice?;format : SDL_GPUTextureFormat;body : block<(var r : StencilPasses) : SdlStatus>) : SdlStatus {
 var r=StencilPasses(format=SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM_S8_UINT)
 if(!SDL_GPUTextureSupportsFormat(device,r.format,SDL_GPUTextureType.TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)){r.format=SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT_S8_UINT}
 defer(){for(p in r.pipelines){SDL_ReleaseGPUGraphicsPipeline(device,p)};release(device,r.cube);release(device,r.sphere);if(r.depth!=null){SDL_ReleaseGPUTexture(device,r.depth)}}
 var cube=load_mesh(device,"advanced_box_0_0") |> sdl_try;r.cube=cube;var sphere=load_mesh(device,"remaining_sphere") |> sdl_try;r.sphere=sphere
 for(mode in 0..10){var p=stencil_pipeline(device,format,r.format,mode) |> sdl_try;push(r.pipelines,p)}
 return body(r)
}
def stencil_target(device : SDL_GPUDevice?;var r : StencilPasses;width,height : uint) : SdlStatus {
 if(r.size==uint2(width,height)){return sdl_ok()};if(r.depth!=null){SDL_ReleaseGPUTexture(device,r.depth);r.depth=null}
 var t=device |> create_advanced_texture(gpu_texture(width,height,r.format,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;r.depth=t;r.size=uint2(width,height);return sdl_ok()
}
def stencil_object(command : SDL_GPUCommandBuffer?;pass_ : SDL_GPURenderPass?;var scene : AdvancedScene;var r : StencilPasses;mode : int;vp,model : float4x4;color : float4;eye : float3;sphere : bool=false;id : int=0) : SdlStatus {
 SDL_BindGPUGraphicsPipeline(pass_,r.pipelines[mode]);push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=model,vp=vp,light0=single_light_matrix())) |> sdl_try
 let f=hs::AdvancedFragment(base=color,eye=float4(eye,1.0),light=float4(-0.4,0.8,0.6,0),ambient=float4(0.12),specular=float4(0.4,0.4,0.4,64),fog_color=float4(1),controls=float4(float(id),0.0,0.0,0.0))
 push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try
 let images <- array(SDL_GPUTextureSamplerBinding(texture=scene.parts[0].diffuse,sampler=scene.sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler));sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind stencil lighting") |> sdl_try
 if(sphere){return draw_mesh(pass_,r.sphere)}else{return draw_mesh(pass_,r.cube)}
}
def render_stencil(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var r : StencilPasses;var output : SDL_GPUTexture?;width,height : uint;state : LessonState) : SdlStatus {
 stencil_target(device,r,width,height) |> sdl_try
 // Shadow map belongs to the underlying SDL scene and is explicitly cleared.
 let no_colors : array<SDL_GPUColorTargetInfo>;let shadow=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[0],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,no_colors,shadow) $(var pass_){return sdl_ok()} |> sdl_try
 let vp=planar_projection(width,height)*look_at_rh(state.eye,state.target,float3(0,1,0))
 let colors <- array(attachment(output,false,float4(0.05,0.05,0.08,1)))
 let depth=SDL_GPUDepthStencilTargetInfo(texture=r.depth,clear_depth=1.0,clear_stencil=0u8,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE,stencil_load_op=SDL_GPULoadOp.LOADOP_CLEAR,stencil_store_op=SDL_GPUStoreOp.STOREOP_STORE)
 return with_native_gpu_render_pass(command,colors,depth) $(var pass_){
  let positions=fixed_array(float3(2,0.5,-3),float3(-1,0.5,-2),float3(-1,1.5,-2),float3(3,0.5,1));let scales=fixed_array(1.0,1.0,0.8,1.2);let colors_=fixed_array(float4(0.8,0.2,0.2,1),float4(0.2,0.3,0.8,1),float4(0.2,0.8,0.8,1),float4(0.2,0.7,0.3,1))
  // Floor is real geometry; a thin cube avoids a separate application mesh format.
  stencil_object(command,pass_,scene,r,0,vp,model_matrix(float3(0,-0.05,0),float3(100,0.1,100)),float4(0.12,0.14,0.18,1),state.eye) |> sdl_try
  for(i in 0..4){stencil_object(command,pass_,scene,r,0,vp,model_matrix(positions[i],float3(scales[i])),colors_[i],state.eye) |> sdl_try}
  // Door frame, including side posts and lintel, occludes the masked world.
  for(x in fixed_array(-1.1,1.1)){stencil_object(command,pass_,scene,r,0,vp,model_matrix(float3(x,1.5,-5),float3(0.2,3,0.2)),float4(0.3,0.32,0.35,1),state.eye) |> sdl_try}
  stencil_object(command,pass_,scene,r,0,vp,model_matrix(float3(0,3.1,-5),float3(2.4,0.2,0.2)),float4(0.3,0.32,0.35,1),state.eye) |> sdl_try
  if(state.effect){
   SDL_SetGPUStencilReference(pass_,1u);stencil_object(command,pass_,scene,r,1,vp,model_matrix(float3(0,1.5,-5),float3(2,3,0.001)),float4(0),state.eye) |> sdl_try
   let sphere_pos=fixed_array(float3(0,1,-7),float3(-1.5,0.6,-6),float3(1.2,0.5,-8));let sizes=fixed_array(0.8,0.6,0.5);let sphere_colors=fixed_array(float4(1,0.8,0.2,1),float4(0.8,0.2,0.8,1),float4(0.2,0.8,0.8,1))
   for(i in 0..3){stencil_object(command,pass_,scene,r,2,vp,model_matrix(sphere_pos[i],float3(sizes[i])),sphere_colors[i],state.eye,true) |> sdl_try}
   for(i in fixed_array(1,3)){let model=model_matrix(positions[i],float3(scales[i]));SDL_SetGPUStencilReference(pass_,128u);stencil_object(command,pass_,scene,r,4,vp,model,float4(0),state.eye) |> sdl_try
    stencil_object(command,pass_,scene,r,3,vp,model_matrix(positions[i],float3(scales[i]*1.04)),i==1 ? float4(1,1,0,1) : float4(0,1,0.3,1),state.eye) |> sdl_try
   }
  };return sdl_ok()
 }
}
def run_stencil(smoke : bool) : int {
 return with_lesson_window(34) $(device,window){return with_advanced(device,SDL_GetGPUSwapchainTextureFormat(device,window),15) $(var scene){return with_stencil(device,SDL_GetGPUSwapchainTextureFormat(device,window)) $(var r){
  var state=lesson_camera(float3(1,2.5,5),-0.15,-0.25)
  return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_stencil(device,command,scene,r,target,width,height,state)}
 }}}
}
