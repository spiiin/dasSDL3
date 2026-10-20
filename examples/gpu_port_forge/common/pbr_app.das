options gen2
module pbr_app shared public
require animation_app public
require ftex_assets public
require ui_app public
require pbr_shaders as ps
require hdr_shaders as hs
require deformation_shaders as ds
require daslib/json_boost
require strings
require dassdl3/sdl3_init_boost
require daslib/defer
struct PbrMaterialSpec {name,base,normal,mr,ao,emissive : string;base_factor : float4;emissive_factor : float3;metallic,roughness,normal_scale,occlusion_strength,alpha_cutoff : float}
struct PbrMaterialData {materials : array<PbrMaterialSpec>;part_materials : array<int>}
struct PbrMaterial {spec : PbrMaterialSpec;images : int[5]}
struct PbrPart {mesh : MeshBuffers;model : float4x4;material : int;profile : float}
struct PbrScene {materials : array<PbrMaterial>;parts : array<PbrPart>;textures : array<SDL_GPUTexture?>;names : array<string>;compressed,uncompressed : uint64;pipeline_,sky : SDL_GPUGraphicsPipeline?;size : uint2;depth : SDL_GPUTexture?;load_ms : uint64}
struct PbrSettings {metallic : float=0.0;roughness : float=0.5;base : float3=float3(0.8)}
def load_material_data(name : string) {
 let bytes <- load_file(asset(name)) |> sdl_try;var error : string;var value=read_json(string(bytes),error)
 if(value==null){return err(SdlError(operation=name,message=error),type<PbrMaterialData>)}
 {defer(){unsafe{delete value}};var result <- from_JV(value,type<PbrMaterialData>);if(length(result.materials)==0){return err(SdlError(operation=name,message="No materials"),type<PbrMaterialData>)};return <- move_ok(result,type<SdlError>)}
}
def cached_pbr_texture(device : SDL_GPUDevice?;var r : PbrScene;name : string) {
 for(i in 0..length(r.names)){if(r.names[i]==name){return ok(i,type<SdlError>)}}
 let bytes <- load_file(asset(name)) |> sdl_try;let info=ftex_info(bytes) |> sdl_try
 var texture=load_ftex(device,name) |> sdl_try;let index=length(r.textures);push(r.textures,texture);push(r.names,name);r.compressed+=info.payload
 var w=info.width;var h=info.height;for(level in 0u..info.levels){r.uncompressed+=uint64(w)*uint64(h)*4ul;w=max(1u,w/2u);h=max(1u,h/2u)};return ok(index,type<SdlError>)
}
def append_pbr_materials(device : SDL_GPUDevice?;var r : PbrScene;data : PbrMaterialData) : SdlStatus {
 for(spec in data.materials){var material=PbrMaterial(spec=clone(spec));let names=fixed_array(spec.base,spec.normal,spec.mr,spec.ao,spec.emissive)
  for(slot in 0..5){let index=cached_pbr_texture(device,r,names[slot]) |> sdl_try;material.images[slot]=index};push(r.materials,material)
 };return sdl_ok()
}
def append_pbr_parts(device : SDL_GPUDevice?;var r : PbrScene;parts : array<PartSpec>;mapping : array<int>;placement : float4x4;profile : float;material : int=-1) : SdlStatus {
 for(i in 0..length(parts)){let index=material>=0 ? material : mapping[i];if(index<0 || index>=length(r.materials)){return failure("PBR material","Primitive material index out of range")}
  var mesh=load_mesh(device,parts[i].mesh) |> sdl_try;push(r.parts,PbrPart(mesh=mesh,model=placement*parts[i].model,material=index,profile=profile))
 };return sdl_ok()
}
def pbr_panel(var ui : UiBatch;var settings : PbrSettings;r : PbrScene;lesson : int){
 sample_ui_mouse(ui);clear(ui.vertices);clear(ui.indices);let p=ui_window(ui,0,float2(340,lesson==51 ? 440.0 : 300.0),lesson==42 ? "Texture compression" : (lesson==51 ? "Blinn-Phong / Cook-Torrance" : "PBR texture materials"))
 if(lesson==51){
  ui_text(ui,p,"Metallic");ui_slider(ui,float4(p.x,p.y+24,310.0,20.0),settings.metallic,0.0,1.0)
  ui_text(ui,p+float2(0,64),"Roughness");ui_slider(ui,float4(p.x,p.y+88,310.0,20.0),settings.roughness,0.04,1.0)
  ui_text(ui,p+float2(0,128),"Base color R / G / B")
  ui_slider(ui,float4(p.x,p.y+156,310.0,20.0),settings.base.x,0.0,1.0);ui_slider(ui,float4(p.x,p.y+188,310.0,20.0),settings.base.y,0.0,1.0);ui_slider(ui,float4(p.x,p.y+220,310.0,20.0),settings.base.z,0.0,1.0)
  ui_text(ui,p+float2(0,270),"Left: Blinn-Phong");ui_text(ui,p+float2(0,302),"Right: Cook-Torrance GGX")
 }else{
  ui_text(ui,p,"{length(r.textures)} unique GPU textures");ui_text(ui,p+float2(0,28),"BC payload: {double(r.compressed)/1048576.0lf:0.2f} MiB")
  ui_text(ui,p+float2(0,56),"RGBA8 equivalent: {double(r.uncompressed)/1048576.0lf:0.2f} MiB");ui_text(ui,p+float2(0,84),"Load: {r.load_ms} ms")
  if(lesson==52){for(i in 0..min(6,length(r.materials))){ui_text(ui,p+float2(0,116+float(i)*22.0),r.materials[i].spec.name)}}
  else{ui_text(ui,p+float2(0,128),"BC7 sRGB / linear, BC5 normals");ui_text(ui,p+float2(0,156),"Full mip chains, aligned upload")}
 }
}
def render_pbr(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var r : PbrScene;var ui : UiBatch;var settings : PbrSettings;var output : SDL_GPUTexture?;width,height : uint;state : LessonState;lesson : int) : SdlStatus {
 pbr_panel(ui,settings,r,lesson)
 if(r.size!=uint2(width,height)){if(r.depth!=null){SDL_ReleaseGPUTexture(device,r.depth);r.depth=null};var d=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;r.depth=d;r.size=uint2(width,height)}
 let light=single_light_matrix();let no_colors : array<SDL_GPUColorTargetInfo>;let shadow_depth=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[0],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,no_colors,shadow_depth) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,scene.shadow_pipeline);for(part in r.parts){push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.model,vp=light)) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try};return sdl_ok()} |> sdl_try
 let sky_colors <- array(attachment(output));with_native_gpu_render_pass(command,sky_colors) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,r.sky);SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()} |> sdl_try
 let vp=camera_matrix(width,height,state.eye,state.target);let colors <- array(attachment(output,true));let depth=SDL_GPUDepthStencilTargetInfo(texture=r.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,colors,depth) $(var pass_){
  SDL_BindGPUGraphicsPipeline(pass_,r.pipeline_)
  for(part in r.parts){let material & = unsafe(r.materials[part.material]);var spec=clone(material.spec)
   if(lesson==51){spec.base_factor=float4(settings.base,1.0);spec.metallic=settings.metallic;spec.roughness=settings.roughness}
   push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.model,vp=vp,light0=light)) |> sdl_try
   let fragment=ps::PbrParams(base=spec.base_factor,eye=float4(state.eye,1.0),light=float4(0.4,0.8,0.6,0),emissive=float4(spec.emissive_factor,0.0),material=float4(spec.metallic,spec.roughness,spec.normal_scale,spec.occlusion_strength),surface=float4(0.15,64.0,0.4,spec.alpha_cutoff),config=float4(part.profile,0.0,0.0,0.0))
   push_gpu_dsl_fragment_uniform(command,0u,fragment) |> sdl_try
   var images : array<SDL_GPUTextureSamplerBinding>;for(index in material.images){push(images,SDL_GPUTextureSamplerBinding(texture=r.textures[index],sampler=scene.sampler))};push(images,SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler))
   sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind PBR material") |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try
  };return sdl_ok()
 } |> sdl_try
 return draw_ui_batch(device,command,ui,output,width,height,state.time,true)
}
def run_pbr(lesson : int;smoke : bool) : int {
 return with_lesson_window(lesson) $(device,window){return with_advanced(device,SDL_GetGPUSwapchainTextureFormat(device,window),15) $(var scene){return with_forge_ui(device,SDL_GetGPUSwapchainTextureFormat(device,window)) $(var ui){
  var r : PbrScene;let started=SDL_GetTicks()
  defer(){for(part in r.parts){release(device,part.mesh)};for(texture in r.textures){SDL_ReleaseGPUTexture(device,texture)};if(r.pipeline_!=null){SDL_ReleaseGPUGraphicsPipeline(device,r.pipeline_)};if(r.sky!=null){SDL_ReleaseGPUGraphicsPipeline(device,r.sky)};if(r.depth!=null){SDL_ReleaseGPUTexture(device,r.depth)}}
  if(lesson==42){let data <- load_material_data("pbr_chess_materials.json") |> sdl_try;append_pbr_materials(device,r,data) |> sdl_try;let parts <- chess_parts();append_pbr_parts(device,r,parts,data.part_materials,model_matrix(float3(0),float3(20)),0.0) |> sdl_try}
  elif(lesson==52){let data <- load_material_data("pbr_material_sets.json") |> sdl_try;append_pbr_materials(device,r,data) |> sdl_try;let parts <- shaderball_parts();let empty : array<int>
   for(i in 0..6){append_pbr_parts(device,r,parts,empty,model_matrix(float3(-2.5+float(i%2)*5.0,0,-5.0+float(i/2)*5.0),float3(1)),1.0,i) |> sdl_try}
  }else{
   let defaults=PbrMaterialSpec(base="pbr_white_srgb.ftex",normal="pbr_flat_normal.ftex",mr="pbr_white_linear.ftex",ao="pbr_white_linear.ftex",emissive="pbr_black_srgb.ftex",base_factor=float4(0.8,0.8,0.8,1),metallic=0.0,roughness=0.5,normal_scale=1.0,occlusion_strength=1.0)
   var data=PbrMaterialData(materials <- array(defaults));append_pbr_materials(device,r,data) |> sdl_try;let parts <- shaderball_parts();let empty : array<int>
   append_pbr_parts(device,r,parts,empty,model_matrix(float3(-2,0,0),float3(1)),0.0,0) |> sdl_try;append_pbr_parts(device,r,parts,empty,model_matrix(float3(2,0,0),float3(1)),1.0,0) |> sdl_try
  }
  var pipeline_=advanced_pipeline(device,ps::forge_pbr_vertex,ps::forge_pbr_vertex_reflect,ps::forge_pbr_fragment,ps::forge_pbr_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),48u) |> sdl_try;r.pipeline_=pipeline_
  pipeline_=device |> pipeline(hs::forge_post_vertex,hs::forge_post_vertex_reflect,ds::forge_studio_fragment,ds::forge_studio_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),false,false,false) |> sdl_try;r.sky=pipeline_
  pipeline_=advanced_pipeline(device,hs::shadow_vertex,hs::shadow_vertex_reflect,hs::shadow_fragment,hs::shadow_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),48u,false,true) |> sdl_try;SDL_ReleaseGPUGraphicsPipeline(device,scene.shadow_pipeline);scene.shadow_pipeline=pipeline_
  r.load_ms=SDL_GetTicks()-started;var settings=PbrSettings();var state=lesson_camera(float3(-1.5,2,7),0.0,-0.2)
  if(lesson==51 && (hint_string("DASSDL3_FORGE_VARIANT") |> unwrap_or(""))=="changed"){settings.metallic=1.0;settings.roughness=.15;settings.base=float3(.8,.3,.1)}
  if(lesson==52){state=lesson_camera(float3(0,3,10),0.0,-0.15)}elif(lesson==42){state=lesson_camera(float3(-8,7,12),-0.65,-0.55)}
  print("Forge {lesson}: {length(r.textures)} textures, {r.compressed} compressed payload bytes.\n")
  return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_pbr(device,command,scene,r,ui,settings,target,width,height,state,lesson)}
 }}}
}
