options gen2
module planar_app shared public
require screen_app public
require planar_shaders as water
require scene_shaders as sky_shader
require hdr_shaders as hs
require daslib/defer
struct PlanarPasses {
 reflection,main_depth,ref_depth,environment : SDL_GPUTexture?
 solid,reflected,sky,ref_sky,water_pipeline : SDL_GPUGraphicsPipeline?
 size : uint2
}
def release_planar_targets(device : SDL_GPUDevice?;var r : PlanarPasses){for(t in fixed_array(r.reflection,r.main_depth,r.ref_depth)){if(t!=null){SDL_ReleaseGPUTexture(device,t)}};r.reflection=null;r.main_depth=null;r.ref_depth=null;r.size=uint2(0u)}
def oblique_projection(projection : float4x4;plane : float4) : float4x4 {
 var p=projection;let q=float4((sign(plane.x)+p[2].x)/p[0].x,(sign(plane.y)+p[2].y)/p[1].y,-1.0,(1.0+p[2].z)/p[3].z)
 let denominator=dot(plane,q);if(abs(denominator)<1e-6){return p};let c=plane/denominator;p[0].z=c.x;p[1].z=c.y;p[2].z=c.z;p[3].z=c.w;return p
}
def planar_projection(width,height : uint) : float4x4 {var p : float4x4;p[0].x=1.7320508*float(height)/float(width);p[1].y=1.7320508;p[2]=float4(0,0,-200.0/199.9,-1);p[3].z=-20.0/199.9;return p}
def planar_light : float4x4 {var p : float4x4;p[0].x=0.05;p[1].y=0.05;p[2].z=-1.0/59.9;p[3]=float4(0,0,-0.1/59.9,1);return p*look_at_rh(normalize(float3(0.4,0.7,0.5))*25.0,float3(0),float3(0,1,0))}
def planar_sky(command : SDL_GPUCommandBuffer?;pipeline_ : SDL_GPUGraphicsPipeline?;var scene : AdvancedScene;var env,output : SDL_GPUTexture?;view : float4x4;width,height : uint) : SdlStatus {
 let inv=inverse(view);let f=-inv[2].xyz;let right=inv[0].xyz;let up=inv[1].xyz
 push_gpu_dsl_fragment_uniform(command,0u,sky_shader::SkyParams(right=float4(right*(float(width)/float(height)/1.7320508),0.0),up=float4(up/1.7320508,0.0),forward=float4(f,0.0))) |> sdl_try
 let targets <- array(attachment(output))
 return with_native_gpu_render_pass(command,targets) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,pipeline_);var images <- array(env);bind_images(pass_,images,scene.shadow_sampler) |> sdl_try;SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()}
}
def planar_scene(command : SDL_GPUCommandBuffer?;pipeline_ : SDL_GPUGraphicsPipeline?;var scene : AdvancedScene;var output,depth : SDL_GPUTexture?;vp : float4x4;eye : float3) : SdlStatus {
 let colors <- array(attachment(output,true));let depth_info=SDL_GPUDepthStencilTargetInfo(texture=depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 return with_native_gpu_render_pass(command,colors,depth_info) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,pipeline_)
  var vertex=hs::AdvancedVertex(model=model_matrix(float3(0,-2,0),float3(1.2)),vp=vp,light0=planar_light())
  var f=hs::AdvancedFragment(base=float4(0.76,0.70,0.50,1),eye=float4(eye,1.0),specular=float4(0.1,0,0,16))
  var images <- array(SDL_GPUTextureSamplerBinding(texture=scene.parts[0].diffuse,sampler=scene.sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler))
  sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Planar floor") |> sdl_try;push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try;draw_mesh(pass_,scene.grid) |> sdl_try
  for(part in scene.parts){vertex.model=part.spec.model;f.base=part.spec.base;f.controls.x=part.spec.diffuse!="" ? 1.0 : 0.0;f.specular=float4(0.3,0,0,64);images[0].texture=part.diffuse
   sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Planar model") |> sdl_try;push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try
  };return sdl_ok()
 }
}
def render_planar(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var r : PlanarPasses;var output : SDL_GPUTexture?;width,height : uint;state : LessonState) : SdlStatus {
 if(r.size!=uint2(width,height)){release_planar_targets(device,r)
  var t=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_try;r.reflection=t
  t=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;r.main_depth=t
  t=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;r.ref_depth=t;r.size=uint2(width,height)
 }
 let colors : array<SDL_GPUColorTargetInfo>;let depth=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[0],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,colors,depth) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,scene.shadow_pipeline);for(part in scene.parts){push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.spec.model,vp=planar_light())) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try};return sdl_ok()} |> sdl_try
 let projection=planar_projection(width,height);let view=look_at_rh(state.eye,state.target,float3(0,1,0));var mirror=identity_matrix();mirror[1].y=-1.0
 let reflected_view=view*mirror;let plane=transpose(inverse(reflected_view))*float4(0,1,0,0);let ref_vp=oblique_projection(projection,plane)*reflected_view
 planar_sky(command,r.ref_sky,scene,r.environment,r.reflection,reflected_view,width,height) |> sdl_try
 planar_scene(command,r.reflected,scene,r.reflection,r.ref_depth,ref_vp,float3(state.eye.x,-state.eye.y,state.eye.z)) |> sdl_try
 planar_sky(command,r.sky,scene,r.environment,output,view,width,height) |> sdl_try
 planar_scene(command,r.solid,scene,output,r.main_depth,projection*view,state.eye) |> sdl_try
 if(state.eye.y<=0.0){return sdl_ok()}
 let water_colors <- array(attachment(output,true));let water_depth=SDL_GPUDepthStencilTargetInfo(texture=r.main_depth,load_op=SDL_GPULoadOp.LOADOP_LOAD,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=model_matrix(float3(0),float3(1.2)),vp=projection*view)) |> sdl_try
 push_gpu_dsl_fragment_uniform(command,0u,hs::AdvancedFragment(eye=float4(state.eye,1.0),fog=float4(float(width),float(height),0.0,0.0),shadow=float4(0,0,state.effect ? 1.0 : 0.0,0))) |> sdl_try
 return with_native_gpu_render_pass(command,water_colors,water_depth) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,r.water_pipeline);var images <- array(r.reflection);bind_images(pass_,images,scene.shadow_sampler) |> sdl_try;draw_mesh(pass_,scene.grid) |> sdl_try;return sdl_ok()}
}
def with_planar(device : SDL_GPUDevice?;format : SDL_GPUTextureFormat;body : block<(var scene : AdvancedScene;var r : PlanarPasses) : SdlStatus>) : SdlStatus {
 return with_advanced(device,format,15) $(var scene){
  var parts : array<AdvancedPart>;let boat <- boat_parts();add_parts(parts,boat,model_matrix(float3(3,0.3,3),float3(1)));let rocks <- rocks_parts();add_parts(parts,rocks,model_matrix(float3(0),float3(0.66)));replace_parts(device,scene,parts) |> sdl_try
  var r : PlanarPasses
  defer(){release_planar_targets(device,r);if(r.environment!=null){SDL_ReleaseGPUTexture(device,r.environment)};for(resource in fixed_array(r.solid,r.reflected,r.sky,r.ref_sky,r.water_pipeline)){if(resource!=null){SDL_ReleaseGPUGraphicsPipeline(device,resource)}}}
  var env=texture(device,512u,512u,SDL_GPU_TEXTUREUSAGE_SAMPLER,true,true) |> sdl_try;r.environment=env
  let faces=fixed_array("px","nx","py","ny","pz","nz");for(i in 0..6){upload_png(device,r.environment,"extended_orchard_{faces[i]}.png",uint(i)) |> sdl_try}
  var p=advanced_pipeline(device,hs::cascade_vertex,hs::cascade_vertex_reflect,water::forge_planar_scene_fragment,water::forge_planar_scene_fragment_reflect,format) |> sdl_try;r.solid=p
  p=advanced_pipeline(device,hs::cascade_vertex,hs::cascade_vertex_reflect,water::forge_planar_scene_fragment,water::forge_planar_scene_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB) |> sdl_try;r.reflected=p
  p=device |> pipeline(sky_shader::fullscreen_vertex,sky_shader::fullscreen_vertex_reflect,sky_shader::sky_fragment,sky_shader::sky_fragment_reflect,format,false,false,false) |> sdl_try;r.sky=p
  p=device |> pipeline(sky_shader::fullscreen_vertex,sky_shader::fullscreen_vertex_reflect,sky_shader::sky_fragment,sky_shader::sky_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB,false,false,false) |> sdl_try;r.ref_sky=p
  p=advanced_pipeline(device,water::forge_water_vertex,water::forge_water_vertex_reflect,water::forge_water_fragment,water::forge_water_fragment_reflect,format,32u,true) |> sdl_try;r.water_pipeline=p
  return body(scene,r)
 }
}
def run_planar(smoke : bool) : int {
 return with_lesson_window(30) $(device,window){return with_planar(device,SDL_GetGPUSwapchainTextureFormat(device,window)) $(var scene;var r){
  var state=lesson_camera(float3(6,3,8),0.523598776,-0.174532925)
  return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_planar(device,command,scene,r,target,width,height,state)}
 }}
}
