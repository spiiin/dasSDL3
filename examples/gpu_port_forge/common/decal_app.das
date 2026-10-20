options gen2
module decal_app shared public
require stencil_app public
require decal_shaders as dec
require screen_shaders as sc
require hdr_shaders as hs
require scene_shaders as display
require daslib/defer
struct DecalVolume {model : float4x4;color : float4;shape : int}
def decal_hash(value : uint) : uint {var seed=(value^61u)^(value>>16u);seed*=9u;seed=seed^(seed>>4u);seed*=0x27d4eb2du;return seed^(seed>>15u)}
def decal_random(var seed : uint&) : float {seed=decal_hash(seed);return float(seed)/4294967296.0}
def rotated(v,axis : float3;angle : float) : float3 {return v*cos(angle)+cross(axis,v)*sin(angle)+axis*dot(axis,v)*(1.0-cos(angle))}
def make_decal_volumes {
 var volumes : array<DecalVolume>;var seed=decal_hash(0xDECA1u);let scales=fixed_array(1.0,0.8,1.2,0.9,1.1,0.7)
 let palette=fixed_array(float4(0.31,0.76,0.97,1),float4(1,0.44,0.26,1),float4(0.4,0.73,0.42,1),float4(0.67,0.28,0.74,1),float4(1,0.84,0.31,1))
 for(obj in 0..6){let angle=float(obj)*6.28318530718/6.0;let center=float3(sin(angle)*5.0,1.0,cos(angle)*5.0)
  for(i in 0..12){let theta=acos(1.0-2.0*decal_random(seed));let phi=6.28318530718*decal_random(seed);let dir=float3(sin(theta)*cos(phi),sin(theta)*sin(phi),cos(theta));let f=-dir;let initial_up=abs(f.y)>0.99 ? float3(1,0,0) : float3(0,1,0);let right=normalize(cross(initial_up,f));let up=cross(f,right);let roll=decal_random(seed)*6.28318530718
   let size=(0.15+decal_random(seed)*0.35)*scales[obj];let shape=int(decal_random(seed)*8.0)%8;let color=int(decal_random(seed)*5.0)%5
   var m=identity_matrix();m[0]=float4(rotated(right,f,roll)*size,0.0);m[1]=float4(rotated(up,f,roll)*size*0.6,0.0);m[2]=float4(f*size,0.0);m[3]=float4(center+dir*(0.9*scales[obj]),1.0);push(volumes,DecalVolume(model=m,color=palette[color],shape=shape))
  }
 }
 for(i in 0..15){let x=(decal_random(seed)*2.0-1.0)*7.0;let z=(decal_random(seed)*2.0-1.0)*7.0;let yaw=decal_random(seed)*6.28318530718;let size=0.4+decal_random(seed)*0.8;let shape=int(decal_random(seed)*8.0)%8;let color=int(decal_random(seed)*5.0)%5
  var m=identity_matrix();m[0]=float4(rotated(float3(1,0,0),float3(0,1,0),yaw)*size,0.0);m[1]=float4(0,0,-size*0.6,0);m[2]=float4(0,-size,0,0);m[3]=float4(x,0.05,z,1.0);push(volumes,DecalVolume(model=m,color=palette[color],shape=shape))
 };for(volume in volumes){volume.model[0]*=2.0;volume.model[1]*=2.0;volume.model[2]*=2.0};return <- volumes
}
def decal_pipeline(device : SDL_GPUDevice?;format : SDL_GPUTextureFormat) {
 return sdl_scope(){
  var vertex : SDL_GPUShader? = device |> with_dsl_example_shader(hs::shadow_vertex,hs::shadow_vertex_reflect) |> sdl_use
  var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(dec::forge_decal_fragment,dec::forge_decal_fragment_reflect) |> sdl_use
  let info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST,rasterizer_state=SDL_GPURasterizerState(cull_mode=SDL_GPUCullMode.CULLMODE_FRONT,front_face=SDL_GPUFrontFace.FRONTFACE_COUNTER_CLOCKWISE,enable_depth_clip=true))
  let buffers <- array(SDL_GPUVertexBufferDescription(pitch=32u));let attrs <- array(SDL_GPUVertexAttribute(format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3));var color=gpu_color_target(format)
  color.blend_state=SDL_GPUColorTargetBlendState(enable_blend=true,src_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA,dst_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,color_blend_op=SDL_GPUBlendOp.BLENDOP_ADD,src_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,dst_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,alpha_blend_op=SDL_GPUBlendOp.BLENDOP_ADD)
  let colors <- array(color);return <- device |> create_native_gpu_graphics_pipeline(info,buffers,attrs,colors)
 }
}
def render_decals(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var targets : ScreenPasses;decal_pipeline_,display_pipeline : SDL_GPUGraphicsPipeline?;var cube : MeshBuffers;volumes : array<DecalVolume>;var output : SDL_GPUTexture?;width,height : uint;state : LessonState) : SdlStatus {
 screen_targets(device,targets,width,height) |> sdl_try;draw_screen_scene(command,scene,targets,width,height,state) |> sdl_try
 let colors <- array(attachment(output))
 with_native_gpu_render_pass(command,colors) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,display_pipeline);var images <- array(targets.color);bind_images(pass_,images,scene.shadow_sampler) |> sdl_try;SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()} |> sdl_try
 if(!state.effect){return sdl_ok()}
 let vp=camera_matrix(width,height,state.eye,state.target);let view=look_at_rh(state.eye,state.target,float3(0,1,0));let color_load <- array(attachment(output,true))
 return with_native_gpu_render_pass(command,color_load) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,decal_pipeline_);var images <- array(targets.depth,targets.normal,scene.shadows[0]);bind_images(pass_,images,scene.shadow_sampler) |> sdl_try
  for(volume in volumes){push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=volume.model,vp=vp)) |> sdl_try
   let p=dec::DecalParams(inverse_vp=inverse(vp),inverse_model=inverse(volume.model),inverse_view=inverse(view),light_vp=single_light_matrix(),color=volume.color,eye=float4(state.eye,1.0),size=float4(float(width),float(height),float(volume.shape),0.0));push_gpu_dsl_fragment_uniform(command,0u,p) |> sdl_try;draw_mesh(pass_,cube) |> sdl_try
  };return sdl_ok()
 }
}
def run_decals(smoke : bool) : int {
 return with_lesson_window(35) $(device,window){return with_advanced(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,15) $(var scene){
  var parts : array<AdvancedPart>;let monkey <- suzanne_parts();let scales=fixed_array(1.0,0.8,1.2,0.9,1.1,0.7)
  for(i in 0..6){let a=float(i)*6.28318530718/6.0;add_parts(parts,monkey,model_matrix(float3(sin(a)*5.0,1.0,cos(a)*5.0),float3(scales[i]),-a-3.14159265))};replace_parts(device,scene,parts) |> sdl_try
  var p : ScreenPasses;var decal_p,display_p : SDL_GPUGraphicsPipeline?;var cube : MeshBuffers
  defer(){release_screen_targets(device,p);if(decal_p!=null){SDL_ReleaseGPUGraphicsPipeline(device,decal_p)};if(display_p!=null){SDL_ReleaseGPUGraphicsPipeline(device,display_p)};release(device,cube)}
  var g=screen_pipeline(device) |> sdl_try;SDL_ReleaseGPUGraphicsPipeline(device,scene.solid);scene.solid=g
  g=decal_pipeline(device,SDL_GetGPUSwapchainTextureFormat(device,window)) |> sdl_try;decal_p=g
  g=device |> pipeline(display::fullscreen_vertex,display::fullscreen_vertex_reflect,display::fullscreen_fragment,display::fullscreen_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),false,false,false) |> sdl_try;display_p=g
  var mesh=load_mesh(device,"advanced_box_0_0") |> sdl_try;cube=mesh;let volumes <- make_decal_volumes();var state=lesson_camera(float3(0,7,14),0.0,-0.4)
  return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var output : SDL_GPUTexture?;width,height : uint){return render_decals(device,command,scene,p,decal_p,display_p,cube,volumes,output,width,height,state)}
 }}
}
