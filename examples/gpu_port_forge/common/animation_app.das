options gen2
module animation_app shared public
require planar_app public
require animation_data public
require deformation_shaders as ds
require hdr_shaders as hs
require scene_shaders as sky31
require raw_bytes public
require daslib/defer
def with_deformation_shader(device : SDL_GPUDevice?;words,reflection,access : array<uint>;body : block<(var shader : SDL_GPUShader?) : $Result<auto(T);SdlError>>) {
 if(length(access)==0){return <- with_dsl_example_shader(device,words,reflection,body)}
 if((SDL_GetGPUShaderFormats(device)&SDL_GPU_SHADERFORMAT_SPIRV)!=0u){return <- with_gpu_dsl_shader(device,words,reflection,access,body)}
 static_if(typeinfo module_exists(sdl3_shader_dsl_cross)){return <- with_shadercross(){return <- with_gpu_dsl_shader_cross(device,words,reflection,access,body)}}else{return err(SdlError(operation="Deformation shader",message="Backend requires shadercross"),type<T>)}
}
def deformation_pipeline(device : SDL_GPUDevice?; vs,vr,access,fs,fr : array<uint>; format : SDL_GPUTextureFormat; stride : uint=32u; blend : bool=false; shadow : bool=false; lines : bool=false; overlay : bool=false; cull : bool=false) {
    return sdl_scope(){
        var vertex : SDL_GPUShader? = device |> with_deformation_shader(vs,vr,access) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(fs,fr) |> sdl_use
        var info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,primitive_type=lines ? SDL_GPUPrimitiveType.PRIMITIVETYPE_LINELIST : SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST,rasterizer_state=SDL_GPURasterizerState(enable_depth_clip=true,front_face=SDL_GPUFrontFace.FRONTFACE_COUNTER_CLOCKWISE))
        info <- info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL) |> depth_write(!blend)
        if(overlay){info.depth_stencil_state.enable_depth_test=false;info.depth_stencil_state.enable_depth_write=false}
        if(cull){info.rasterizer_state.cull_mode=SDL_GPUCullMode.CULLMODE_BACK}
        if(shadow){info.rasterizer_state.cull_mode=SDL_GPUCullMode.CULLMODE_FRONT;info.rasterizer_state.depth_bias_constant_factor=1.0;info.rasterizer_state.depth_bias_slope_factor=1.5}
        var buffers : array<SDL_GPUVertexBufferDescription>;var attributes : array<SDL_GPUVertexAttribute>
        if(stride!=0u){
            buffers <- array(SDL_GPUVertexBufferDescription(pitch=stride))
            attributes <- array(SDL_GPUVertexAttribute(format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3))
            if(lines){push(attributes,SDL_GPUVertexAttribute(location=1u,offset=12u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4))}
            elif(!shadow){
                push(attributes,SDL_GPUVertexAttribute(location=1u,offset=12u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3))
                push(attributes,SDL_GPUVertexAttribute(location=2u,offset=24u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2))
                if(stride==48u){push(attributes,SDL_GPUVertexAttribute(location=3u,offset=32u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4))}
            }
        }
        var colors : array<SDL_GPUColorTargetDescription>
        if(!shadow){
            var target=gpu_color_target(format)
            if(blend){target.blend_state=SDL_GPUColorTargetBlendState(enable_blend=true,src_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA,dst_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,color_blend_op=SDL_GPUBlendOp.BLENDOP_ADD,src_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,dst_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,alpha_blend_op=SDL_GPUBlendOp.BLENDOP_ADD)}
            push(colors,target)
        }
        return <- device |> create_native_gpu_graphics_pipeline(info,buffers,attributes,colors)
    }
}
struct AnimatedModel {name : string;data : AnimationData;pose : AnimationPose;placement : float4x4;start,count : int;joint_buffer : SDL_GPUBuffer?;speed : float=1.0;drive : bool}
struct AnimatedDraw {model,part,kind : int;weights : SDL_GPUBuffer?;morph_bytes : array<uint8>}
struct AnimationRender {models : array<AnimatedModel>;draws : array<AnimatedDraw>;solid,shadow : array<SDL_GPUGraphicsPipeline?>;blend : SDL_GPUGraphicsPipeline?;sky : SDL_GPUGraphicsPipeline?;environment,ground,depth : SDL_GPUTexture?;size : uint2}
def model_bytes_buffer(device : SDL_GPUDevice?;bytes : array<uint8>) {
 var b=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,size=uint(length(bytes)))) |> sdl_try
 var success=false;defer(){if(!success){SDL_ReleaseGPUBuffer(device,b)}}
 upload_bytes(device,b,bytes) |> sdl_try;success=true;return <- move_ok(b,type<SdlError>)
}
def append_model(device : SDL_GPUDevice?;var scene : AdvancedScene;var r : AnimationRender;name : string;parts : array<PartSpec>;placement : float4x4;kind : int;drive : bool=false) : SdlStatus {
 var data <- read_animation(name) |> sdl_try
 var model=AnimatedModel(name=name,data <- data,placement=placement,start=length(scene.parts),count=length(parts),drive=drive)
 if(name!="animated_truck" || !drive){model.speed=0.0};if(kind==1 || kind==2 || kind==3){model.speed=1.0};let index=length(r.models);emplace(r.models,model)
 if(kind==2){var empty : array<uint8>;resize(empty,8192);var buffer=model_bytes_buffer(device,empty) |> sdl_try;r.models[index].joint_buffer=buffer}
 for(i in 0..length(parts)){
  var part=AdvancedPart(spec=clone(parts[i]));part.spec.model=placement*parts[i].model;part.spec.minimum+=placement[3].xyz;part.spec.maximum+=placement[3].xyz;var mesh=load_mesh(device,part.spec.mesh) |> sdl_try;part.mesh=mesh
  push(scene.parts,part)
  // Register the part before acquiring further resources so cleanup sees it.
  let dest=length(scene.parts)-1
  var image=load_texture(device,parts[i].diffuse=="" ? "advanced_white" : parts[i].diffuse) |> sdl_try;scene.parts[dest].diffuse=image
  var item=AnimatedDraw(model=index,part=i,kind=kind)
  emplace(r.draws,item);let draw_index=length(r.draws)-1
  if(kind==1 || kind==2){let bytes <- load_file(asset(r.models[index].data.part_weights[i])) |> sdl_try;var b=model_bytes_buffer(device,bytes) |> sdl_try;r.draws[draw_index].weights=b}
  elif(kind==3){let morph=r.models[index].data.part_morphs[i];var bytes <- load_file(asset(morph.file)) |> sdl_try;r.draws[draw_index].morph_bytes <- bytes
   var initial : array<uint8>;resize(initial,morph.vertices*32);var b=model_bytes_buffer(device,initial) |> sdl_try;r.draws[draw_index].weights=b
  }
  elif(kind==4){let bytes <- load_file(asset("{parts[i].mesh}.fgm")) |> sdl_try;let nv=word(bytes,4);var vertices : array<uint8>;resize(vertices,int(nv*32u));for(j in 0..length(vertices)){vertices[j]=bytes[16+j]};var b=model_bytes_buffer(device,vertices) |> sdl_try;r.draws[draw_index].weights=b}
 }
 return sdl_ok()
}
def truck_path(time : float) : float4x4 {
 let points=fixed_array(float4(-5,0,22.5,0.5),float4(5,0,22.5,0.5),float4(12.8,0,20.3,0.75),float4(15,0,14,1),float4(15,0,0,1),float4(15,0,-14,1),float4(12.8,0,-20.3,-0.75),float4(5,0,-22.5,-0.5),float4(-5,0,-22.5,-0.5),float4(-12.8,0,-20.3,-0.25),float4(-15,0,-14,0),float4(-15,0,0,0),float4(-15,0,14,0),float4(-12.8,0,20.3,0.25))
 var total=0.0;for(i in 0..14){total+=length(points[(i+1)%14].xyz-points[i].xyz)};var distance=(time*8.0)%total
 for(i in 0..14){let a=points[i];let b=points[(i+1)%14];let length_=length(b.xyz-a.xyz)
  if(distance<=length_){let t=distance/length_;let qa=float4(0.0,sin(a.w*1.570796327),0.0,cos(a.w*1.570796327));let qb=float4(0.0,sin(b.w*1.570796327),0.0,cos(b.w*1.570796327));return trs_matrix(a.xyz*(1.0-t)+b.xyz*t,animation_slerp(qa,qb,t),float3(1))};distance-=length_
 };return identity_matrix()
}
def update_animated(device : SDL_GPUDevice?;var scene : AdvancedScene;var r : AnimationRender;time : float) : SdlStatus {
 for(model in r.models){if(model.name=="track" || model.name=="shape"){continue};if(model.name=="torus"){let m=model_matrix(float3(0,2.5,0),float3(1),-time*0.5);scene.parts[model.start].spec.model=m;continue};evaluate_animation(model.data,model.pose,time*model.speed);let placement=model.drive ? truck_path(time) : model.placement
  for(i in 0..model.count){let node=model.data.part_nodes[i];scene.parts[model.start+i].spec.model=model.data.part_skins[i]>=0 ? placement : placement*model.pose.world[node]}
 }
 for(model in r.models){if(model.joint_buffer!=null){var values : array<float>
  for(i in 0..length(model.data.skins[0].joints)){let matrix=joint_matrix(model.data,model.pose,0,i);for(c in 0..4){for(j in 0..4){push(values,matrix[c][j])}}}
  let bytes <- packed_floats(values);upload_bytes(device,model.joint_buffer,bytes) |> sdl_try
 }}
 for(item in r.draws){if(item.kind==3){let model & = unsafe(r.models[item.model]);let morph=model.data.part_morphs[item.part];let node=model.data.part_nodes[item.part]
  var values : array<float>;resize(values,morph.vertices*8)
  for(target in 0..morph.count){let weight=target<length(model.pose.weights[node]) ? model.pose.weights[node][target] : 0.0
   for(i in 0..length(values)){values[i]+=read_float(item.morph_bytes,(target*length(values)+i)*4)*weight}
  };let bytes <- packed_floats(values);upload_bytes(device,item.weights,bytes) |> sdl_try
 }};return sdl_ok()
}
def draw_animated_part(command : SDL_GPUCommandBuffer?;pass_ : SDL_GPURenderPass?;var scene : AdvancedScene;var r : AnimationRender;index : int;shadow : bool;vp,light : float4x4;eye : float3) : SdlStatus {
 var draw & = unsafe(r.draws[index]);var model & = unsafe(r.models[draw.model]);var part=scene.parts[index]
 if(shadow && part.spec.mode==2){return sdl_ok()}
 SDL_BindGPUGraphicsPipeline(pass_,shadow ? r.shadow[draw.kind] : (part.spec.mode==2 && r.blend!=null ? r.blend : r.solid[draw.kind]))
 push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.spec.model,vp=vp,light0=light)) |> sdl_try
 if(draw.kind==1){var joints : ds::SkinMatrices;let skin=model.data.part_skins[draw.part]
  for(i in 0..length(model.data.skins[skin].joints)){let m=joint_matrix(model.data,model.pose,skin,i);joints.joints[i]=ds::JointColumns(c0=m[0],c1=m[1],c2=m[2],c3=m[3])}
  push_gpu_dsl_vertex_uniform(command,1u,joints) |> sdl_try
 }
 if(draw.kind>0){var buffers <- array(draw.weights);if(draw.kind==2){push(buffers,model.joint_buffer)};sdl_status(SDL_BindGPUVertexStorageBuffersArray(pass_,0u,buffers),"Bind deformation storage") |> sdl_try}
 if(!shadow){
  var f=hs::AdvancedFragment(base=part.spec.base,eye=float4(eye,1.0),light=float4(-0.4,0.8,-0.4,0),ambient=float4(0.2),specular=float4(0.3,0.3,0.3,64),fog_color=float4(0.9,0.855,0.765,1),controls=float4(part.spec.diffuse!="" ? 1.0 : 0.0,float(part.spec.mode),0.0,0.0),shadow=float4(0,0,1,part.spec.cutoff))
  push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try
  let images <- array(SDL_GPUTextureSamplerBinding(texture=part.diffuse,sampler=scene.sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler));sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind animated material") |> sdl_try
 }
 if(draw.kind==4){SDL_BindGPUIndexBufferRef(pass_,SDL_GPUBufferBinding(buffer=part.mesh.ib),SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT);SDL_DrawGPUIndexedPrimitives(pass_,part.mesh.count,1u,0u,0,0u);return sdl_ok()}
 return draw_mesh(pass_,part.mesh)
}
def render_animated(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var r : AnimationRender;var output : SDL_GPUTexture?;width,height : uint;state : LessonState;lesson : int) : SdlStatus {
 update_animated(device,scene,r,state.time) |> sdl_try
 if(r.size!=uint2(width,height)){if(r.depth!=null){SDL_ReleaseGPUTexture(device,r.depth);r.depth=null};var d=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;r.depth=d;r.size=uint2(width,height)}
 let light=single_light_matrix()
 let no_colors : array<SDL_GPUColorTargetInfo>;let shadow_depth=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[0],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,no_colors,shadow_depth) $(var pass_){for(i in 0..length(r.draws)){draw_animated_part(command,pass_,scene,r,i,true,light,light,state.eye) |> sdl_try};return sdl_ok()} |> sdl_try
 let vp=lesson==31 ? planar_projection(width,height)*look_at_rh(state.eye,state.target,float3(0,1,0)) : camera_matrix(width,height,state.eye,state.target)
 let sky_colors <- array(attachment(output))
 if(lesson==31){planar_sky(command,r.sky,scene,r.environment,output,look_at_rh(state.eye,state.target,float3(0,1,0)),width,height) |> sdl_try}
 elif(r.sky!=null){with_native_gpu_render_pass(command,sky_colors) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,r.sky);SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()} |> sdl_try}
 let colors <- array(attachment(output,r.sky!=null));let depth=SDL_GPUDepthStencilTargetInfo(texture=r.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 return with_native_gpu_render_pass(command,colors,depth) $(var pass_){
  SDL_BindGPUGraphicsPipeline(pass_,r.solid[0]);push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=model_matrix(float3(0,lesson==31 ? -0.05 : 0.0,0),float3(1.2)),vp=vp,light0=light)) |> sdl_try
  var f=hs::AdvancedFragment(base=float4(0.15,0.55,0.85,1),diffuse=float4(0.04,0.04,0.08,1),eye=float4(state.eye,1.0),light=float4(-0.4,0.8,-0.4,0),ambient=float4(0.2),specular=float4(0.1,0.1,0.1,32),fog_color=float4(0.9,0.855,0.765,1),controls=float4(0,0,0,15))
  if(lesson==31){f.base=float4(1);f.controls=float4(1,0,8,0);f.specular=float4(.1,.1,.1,16)}
  push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try
  let images <- array(SDL_GPUTextureSamplerBinding(texture=lesson==31 ? r.ground : scene.parts[0].diffuse,sampler=scene.sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler));sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Animated grid") |> sdl_try;draw_mesh(pass_,scene.grid) |> sdl_try
  let order <- draw_order(scene.parts,state.eye,lesson!=45 || state.effect);for(i in order){draw_animated_part(command,pass_,scene,r,i,false,vp,light,state.eye) |> sdl_try};return sdl_ok()
 }
}
def append_shape(device : SDL_GPUDevice?;var scene : AdvancedScene;var r : AnimationRender;name : string;placement : float4x4;color : float4;animated : bool) : SdlStatus {
 var model=AnimatedModel(name=animated ? "torus" : "shape",placement=placement,start=length(scene.parts),count=1);let index=length(r.models);emplace(r.models,model)
 var mesh=load_mesh(device,name) |> sdl_try;push(scene.parts,AdvancedPart(mesh=mesh,spec=PartSpec(model=placement,base=color)))
 var item=AnimatedDraw(model=index,part=0,kind=0);emplace(r.draws,item)
 var texture=load_texture(device,"advanced_white") |> sdl_try;scene.parts[length(scene.parts)-1].diffuse=texture;return sdl_ok()
}

def run_animated(lesson : int;smoke : bool) : int {
 return with_lesson_window(lesson) $(device,window){return with_advanced(device,SDL_GetGPUSwapchainTextureFormat(device,window),15) $(var scene){
  let empty : array<AdvancedPart>;replace_parts(device,scene,empty) |> sdl_try
  var r : AnimationRender
  defer(){if(r.environment!=null){SDL_ReleaseGPUTexture(device,r.environment)};if(r.ground!=null){SDL_ReleaseGPUTexture(device,r.ground)};if(r.blend!=null){SDL_ReleaseGPUGraphicsPipeline(device,r.blend)};if(r.sky!=null){SDL_ReleaseGPUGraphicsPipeline(device,r.sky)};for(model in r.models){if(model.joint_buffer!=null){SDL_ReleaseGPUBuffer(device,model.joint_buffer)}};for(draw in r.draws){if(draw.weights!=null){SDL_ReleaseGPUBuffer(device,draw.weights)}};for(p in r.solid){if(p!=null){SDL_ReleaseGPUGraphicsPipeline(device,p)}};for(p in r.shadow){if(p!=null){SDL_ReleaseGPUGraphicsPipeline(device,p)}};if(r.depth!=null){SDL_ReleaseGPUTexture(device,r.depth)}}
  let vertex_shaders=fixed_array(clone(hs::cascade_vertex),clone(ds::forge_skin_vertex),clone(ds::forge_storage_skin_vertex),clone(ds::forge_morph_vertex),clone(ds::forge_pulled_vertex))
  let vertex_reflections=fixed_array(clone(hs::cascade_vertex_reflect),clone(ds::forge_skin_vertex_reflect),clone(ds::forge_storage_skin_vertex_reflect),clone(ds::forge_morph_vertex_reflect),clone(ds::forge_pulled_vertex_reflect))
  let shadow_shaders=fixed_array(clone(hs::shadow_vertex),clone(ds::forge_skin_shadow_vertex),clone(ds::forge_storage_skin_shadow_vertex),clone(ds::forge_morph_shadow_vertex),clone(ds::forge_pulled_shadow_vertex))
  let shadow_reflections=fixed_array(clone(hs::shadow_vertex_reflect),clone(ds::forge_skin_shadow_vertex_reflect),clone(ds::forge_storage_skin_shadow_vertex_reflect),clone(ds::forge_morph_shadow_vertex_reflect),clone(ds::forge_pulled_shadow_vertex_reflect))
  let empty_access : array<uint>
  let vertex_access=fixed_array(clone(empty_access),clone(ds::forge_skin_vertex_access),clone(ds::forge_storage_skin_vertex_access),clone(ds::forge_morph_vertex_access),clone(ds::forge_pulled_vertex_access))
  let shadow_access=fixed_array(clone(empty_access),clone(ds::forge_skin_shadow_vertex_access),clone(ds::forge_storage_skin_shadow_vertex_access),clone(ds::forge_morph_shadow_vertex_access),clone(ds::forge_pulled_shadow_vertex_access))
  for(kind in 0..5){var p=deformation_pipeline(device,vertex_shaders[kind],vertex_reflections[kind],vertex_access[kind],ds::forge_model_fragment,ds::forge_model_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),kind==4 ? 0u : 32u) |> sdl_try;push(r.solid,p)
   p=deformation_pipeline(device,shadow_shaders[kind],shadow_reflections[kind],shadow_access[kind],hs::shadow_fragment,hs::shadow_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,kind==4 ? 0u : 32u,false,true) |> sdl_try;push(r.shadow,p)
  }
  var blend=advanced_pipeline(device,hs::cascade_vertex,hs::cascade_vertex_reflect,ds::forge_model_fragment,ds::forge_model_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),32u,true) |> sdl_try;r.blend=blend
  var sky_pipeline=device |> pipeline(hs::forge_post_vertex,hs::forge_post_vertex_reflect,ds::forge_studio_fragment,ds::forge_studio_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),false,false,false) |> sdl_try;r.sky=sky_pipeline
  if(lesson==40){
   for(i in 0..3){append_shape(device,scene,r,"remaining_sphere",model_matrix(float3(float(i-1)*2.0,1,0),float3(1)),i==0 ? float4(0.9,0.2,0.2,1) : (i==1 ? float4(0.2,0.8,0.3,1) : float4(0.2,0.3,0.9,1)),false) |> sdl_try}
   append_shape(device,scene,r,"remaining_torus",model_matrix(float3(0,2.5,0),float3(1)),float4(0.9,0.7,0.2,1),true) |> sdl_try
  }
  elif(lesson==41){
   let truck <- animated_truck_parts();append_model(device,scene,r,"animated_truck",truck,model_matrix(float3(-3,0,0),float3(1)),0) |> sdl_try
   let monkey <- model_suzanne_parts();append_model(device,scene,r,"model_suzanne",monkey,model_matrix(float3(0,1,0),float3(0.8)),0) |> sdl_try
   let duck <- model_duck_parts();append_model(device,scene,r,"model_duck",duck,model_matrix(float3(3.5,0,0),float3(1)),0) |> sdl_try
  }
  elif(lesson==45){let truck <- animated_truck_parts();append_model(device,scene,r,"animated_truck",truck,model_matrix(float3(-1.5,0,0),float3(1)),0) |> sdl_try;append_model(device,scene,r,"animated_truck",truck,model_matrix(float3(1.5,0,0),float3(1)),0) |> sdl_try}
  elif(lesson==43){
   let man <- cesiumman_parts();append_model(device,scene,r,"cesiumman",man,model_matrix(float3(-3,0,0),float3(2)),2) |> sdl_try
   let robot <- brainstem_parts();append_model(device,scene,r,"brainstem",robot,model_matrix(float3(0),float3(3)),2) |> sdl_try
   let cube <- animated_cube_parts();append_model(device,scene,r,"animated_cube",cube,model_matrix(float3(3.5,1.5,0),float3(1)),0) |> sdl_try
  }
  elif(lesson==32){let specs <- cesiumman_parts();append_model(device,scene,r,"cesiumman",specs,identity_matrix(),1) |> sdl_try}
  elif(lesson==44){let a <- morph_cube_parts();append_model(device,scene,r,"morph_cube",a,model_matrix(float3(-2,1,0),float3(1)),3) |> sdl_try;let b <- simple_morph_parts();append_model(device,scene,r,"simple_morph",b,model_matrix(float3(2,1,0),float3(1)),3) |> sdl_try}
  else{
   let truck <- animated_truck_parts();append_model(device,scene,r,"animated_truck",truck,identity_matrix(),lesson==33 ? 4 : 0,lesson==31) |> sdl_try
   if(lesson==33){let boxes <- animated_box_parts();for(i in 0..8){let angle=float(i)*6.28318530718/8.0;append_model(device,scene,r,"animated_box",boxes,model_matrix(float3(cos(angle)*5.0,0.5,sin(angle)*5.0),float3(1),-angle),4) |> sdl_try}}
   if(lesson==31){let tracks <- track_parts();let indices=fixed_array(3,6,3,5,3,6,3,7);let placements=fixed_array(float3(13.84,0,21.34),float3(15,0,0),float3(13.84,0,-21.34),float3(0,0,-22.5),float3(-13.84,0,-21.34),float3(-15,0,0),float3(-13.84,0,21.34),float3(0,0,22.5));let angles=fixed_array(1.5707963,0.0,3.14159265,1.5707963,-1.5707963,0.0,0.0,1.5707963)
    for(i in 0..8){var selected : array<PartSpec>;for(spec in tracks){if(spec.mesh=="extended_track_{indices[i]}_0"){var s=clone(spec);s.model=identity_matrix();push(selected,s)}};if(length(selected)>0){append_model(device,scene,r,"track",selected,model_matrix(placements[i],float3(1),-angles[i]),0) |> sdl_try}}
   }
  }
  if(lesson==45){for(part in scene.parts){if(part.spec.mesh=="extended_animated_truck_1_1"){part.spec.mode=2;part.spec.base=float4(.12,.5,.3,.3)}}}
  if(lesson==31){
   var env=texture(device,512u,512u,SDL_GPU_TEXTUREUSAGE_SAMPLER,true,true) |> sdl_try;r.environment=env
   let faces=fixed_array("px","nx","py","ny","pz","nz");for(i in 0..6){upload_png(device,r.environment,"extended_orchard_{faces[i]}.png",uint(i)) |> sdl_try}
   env=load_texture(device,"remaining_dirt") |> sdl_try;r.ground=env
   var p=device |> pipeline(sky31::fullscreen_vertex,sky31::fullscreen_vertex_reflect,sky31::sky_fragment,sky31::sky_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),false,false,false) |> sdl_try;SDL_ReleaseGPUGraphicsPipeline(device,r.sky);r.sky=p
  }
  var state=lesson==31 ? lesson_camera(float3(0,20,45),0.0,-0.436332313) : lesson_camera(float3(1.5,1,-2.5),3.14159265,-0.0872664626)
  if(lesson==40){state=lesson_camera(float3(0,2,5),0.0,-0.3)}
  if(lesson==41 || lesson==45){state=lesson_camera(float3(0,2.5,8),0.0,-0.2)}
  if(lesson==43 || lesson==44){state=lesson_camera(float3(0,3,8),0.0,-0.2)}
  if(lesson==33){state=lesson_camera(float3(4,3,7),0.523598776,-0.13962634)}
  return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_animated(device,command,scene,r,target,width,height,state,lesson)}
 }}
}
