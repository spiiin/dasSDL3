options gen2
module indirect_app shared public
require animation_app public
require indirect_shaders as ids
require deformation_shaders as ds
require hdr_shaders as hs
require ../example_26_procedural_sky/atmosphere_app.das
require dassdl3/sdl3_shader_storage
require daslib/defer
require forge_readback
require dassdl3/sdl3_init_boost
def indirect_pipeline(device : SDL_GPUDevice?; vs,vr,access,fs,fr : array<uint>; format : SDL_GPUTextureFormat; shadow : bool=false) {
    return sdl_scope(){
        var vertex : SDL_GPUShader? = device |> with_deformation_shader(vs,vr,access) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(fs,fr) |> sdl_use
        var info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST,rasterizer_state=SDL_GPURasterizerState(enable_depth_clip=true,front_face=SDL_GPUFrontFace.FRONTFACE_COUNTER_CLOCKWISE))
        info <- info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL) |> depth_write(true)
        if(shadow){info.rasterizer_state.cull_mode=SDL_GPUCullMode.CULLMODE_FRONT;info.rasterizer_state.depth_bias_constant_factor=1.0;info.rasterizer_state.depth_bias_slope_factor=1.5}
        let buffers <- array(SDL_GPUVertexBufferDescription(pitch=32u),SDL_GPUVertexBufferDescription(slot=1u,pitch=4u,input_rate=SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE))
        var attributes <- array(SDL_GPUVertexAttribute(format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),SDL_GPUVertexAttribute(location=3u,buffer_slot=1u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UINT))
        if(!shadow){push(attributes,SDL_GPUVertexAttribute(location=1u,offset=12u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3));push(attributes,SDL_GPUVertexAttribute(location=2u,offset=24u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2))}
        var colors : array<SDL_GPUColorTargetDescription>
        if(!shadow){
            var target=gpu_color_target(format)
            push(colors,target)
        }
        return <- device |> create_native_gpu_graphics_pipeline(info,buffers,attributes,colors)
    }
}
struct IndirectRender {objects,commands,shadow_commands,visibility,id_buffer : SDL_GPUBuffer?;box_texture : SDL_GPUTexture?;box : MeshBuffers;solid,shadow : SDL_GPUGraphicsPipeline?;depth : SDL_GPUTexture?;size : uint2;count : uint=200u}
def frustum_planes(vp : float4x4;enabled : bool;count : uint) : ids::CullParams {
 var p=ids::CullParams(config=uint4(count,enabled ? 1u : 0u,0u,0u));var rows : float4[4]
 for(i in 0..4){rows[i]=float4(vp[0][i],vp[1][i],vp[2][i],vp[3][i])}
 p.planes[0]=rows[3]+rows[0];p.planes[1]=rows[3]-rows[0];p.planes[2]=rows[3]+rows[1];p.planes[3]=rows[3]-rows[1];p.planes[4]=rows[2];p.planes[5]=rows[3]-rows[2]
 for(plane in p.planes){plane/=length(plane.xyz)};return p
}
def indirect_objects(indices : uint) {
 var objects : array<ids::IndirectObject>;var previous=float3(0)
 for(i in 0..200){var pos=float3(float(i%15-7)*2.8,0.5,float(i/15-7)*2.8)
  if(abs(pos.x)<3.0 && abs(pos.z)<3.0){pos.x+=pos.x>=0.0 ? 4.0 : -4.0}
  if(i>0 && i%7==0){pos.x=previous.x;pos.z=previous.z;pos.y=1.5};previous=pos
  let scale=0.8+float(i%3)*0.2;let m=model_matrix(pos,float3(scale),-float(i)*0.4)
  push(objects,ids::IndirectObject(c0=m[0],c1=m[1],c2=m[2],c3=m[3],color=float4(1),bounds=float4(pos,scale*0.866),draw=uint4(indices,0u,0u,0u)))
 };return <- objects
}
def cull_indirect(command : SDL_GPUCommandBuffer?;compute : SDL_GPUComputePipeline?;var r : IndirectRender;var target : SDL_GPUBuffer?;vp : float4x4;enabled : bool) : SdlStatus {
 push_gpu_dsl_compute_uniform(command,0u,frustum_planes(vp,enabled,r.count)) |> sdl_try
 let textures : array<SDL_GPUStorageTextureReadWriteBinding>;let buffers <- array(SDL_GPUStorageBufferReadWriteBinding(buffer=target),SDL_GPUStorageBufferReadWriteBinding(buffer=r.visibility))
 return with_native_gpu_compute_pass(command,textures,buffers) $(var pass_){SDL_BindGPUComputePipeline(pass_,compute);let inputs <- array(r.objects);sdl_status(SDL_BindGPUComputeStorageBuffersArray(pass_,0u,inputs),"Bind cull objects") |> sdl_try;SDL_DispatchGPUCompute(pass_,(r.count+63u)/64u,1u,1u);return sdl_ok()}
}
def indirect_draw(command : SDL_GPUCommandBuffer?;pass_ : SDL_GPURenderPass?;var r : IndirectRender;var scene : AdvancedScene;var buffer : SDL_GPUBuffer?;vp,light : float4x4;eye : float3;shadow : bool) : SdlStatus {
 SDL_BindGPUGraphicsPipeline(pass_,shadow ? r.shadow : r.solid)
 push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(vp=vp,light0=light)) |> sdl_try
 let objects <- array(r.objects);sdl_status(SDL_BindGPUVertexStorageBuffersArray(pass_,0u,objects),"Bind indirect transforms") |> sdl_try
 let vertices <- array(SDL_GPUBufferBinding(buffer=r.box.vb),SDL_GPUBufferBinding(buffer=r.id_buffer));sdl_status(SDL_BindGPUVertexBuffersArray(pass_,0u,vertices),"Bind indirect mesh/IDs") |> sdl_try;SDL_BindGPUIndexBufferRef(pass_,SDL_GPUBufferBinding(buffer=r.box.ib),SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
 if(!shadow){let f=hs::AdvancedFragment(base=float4(1),eye=float4(eye,1.0),light=float4(0.4,0.8,0.4,0),ambient=float4(0.15),specular=float4(0.4,0.4,0.4,64),fog_color=float4(1),controls=float4(1,0,0,0));push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try
  let images <- array(SDL_GPUTextureSamplerBinding(texture=r.box_texture,sampler=scene.sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler));sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind indirect texture/shadow") |> sdl_try
 }
 SDL_DrawGPUIndexedPrimitivesIndirect(pass_,buffer,0u,r.count);return sdl_ok()
}
def render_indirect(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;compute : SDL_GPUComputePipeline?;var r : IndirectRender;var scene : AdvancedScene;var output : SDL_GPUTexture?;width,height : uint;state : LessonState) : SdlStatus {
 if(r.size!=uint2(width,height)){if(r.depth!=null){SDL_ReleaseGPUTexture(device,r.depth);r.depth=null};var d=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;r.depth=d;r.size=uint2(width,height)}
 let vp=camera_matrix(width,height,state.eye,state.target);let light=single_light_matrix()
 cull_indirect(command,compute,r,r.shadow_commands,light,state.effect) |> sdl_try
 cull_indirect(command,compute,r,r.commands,vp,state.effect) |> sdl_try
 let no_colors : array<SDL_GPUColorTargetInfo>;let shadow_depth=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[0],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,no_colors,shadow_depth) $(var pass_){indirect_draw(command,pass_,r,scene,r.shadow_commands,light,light,state.eye,true) |> sdl_try;SDL_BindGPUGraphicsPipeline(pass_,scene.shadow_pipeline);for(part in scene.parts){push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.spec.model,vp=light)) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try};return sdl_ok()} |> sdl_try
 let colors <- array(attachment(output));let depth=SDL_GPUDepthStencilTargetInfo(texture=r.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 return with_native_gpu_render_pass(command,colors,depth) $(var pass_){indirect_draw(command,pass_,r,scene,r.commands,vp,light,state.eye,false) |> sdl_try
  SDL_BindGPUGraphicsPipeline(pass_,scene.solid);let images <- array(SDL_GPUTextureSamplerBinding(texture=scene.parts[0].diffuse,sampler=scene.sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler));sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind static truck") |> sdl_try
  let f=hs::AdvancedFragment(base=float4(1),eye=float4(state.eye,1.0),light=float4(0.4,0.8,0.4,0),ambient=float4(0.15),specular=float4(0.4,0.4,0.4,64),fog_color=float4(1),controls=float4(1,0,0,0));push_gpu_dsl_fragment_uniform(command,0u,f) |> sdl_try
  for(part in scene.parts){push_gpu_dsl_vertex_uniform(command,0u,hs::AdvancedVertex(model=part.spec.model,vp=vp,light0=light)) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try};return sdl_ok()
 }
}
def run_indirect(smoke : bool) : int {
 return with_lesson_window(38) $(device,window){return with_advanced(device,SDL_GetGPUSwapchainTextureFormat(device,window),15) $(var scene){
  var keep : array<AdvancedPart>;for(part in scene.parts){if(part.spec.mesh!="advanced_box_0_0"){push(keep,AdvancedPart(spec=clone(part.spec),material=part.material))}};replace_parts(device,scene,keep) |> sdl_try
  var r=IndirectRender();defer(){if(r.box_texture!=null){SDL_ReleaseGPUTexture(device,r.box_texture)};for(resource in fixed_array(r.objects,r.commands,r.shadow_commands,r.visibility,r.id_buffer)){if(resource!=null){SDL_ReleaseGPUBuffer(device,resource)}};release(device,r.box);if(r.depth!=null){SDL_ReleaseGPUTexture(device,r.depth)};if(r.solid!=null){SDL_ReleaseGPUGraphicsPipeline(device,r.solid)};if(r.shadow!=null){SDL_ReleaseGPUGraphicsPipeline(device,r.shadow)}}
  var box_image=load_texture(device,"advanced_box_CesiumLogoFlat") |> sdl_try;r.box_texture=box_image
  var box=load_mesh(device,"advanced_box_0_0") |> sdl_try;r.box=box
  let objects <- indirect_objects(box.count);let bytes <- gpu_dsl_storage_bytes(objects) |> sdl_try;var buffer=model_bytes_buffer(device,bytes) |> sdl_try;r.objects=buffer
  var indices : array<uint>;for(i in 0u..200u){push(indices,i)};let id_bytes <- packed_uints(indices);buffer=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_VERTEX,size=800u)) |> sdl_try;r.id_buffer=buffer;upload_bytes(device,r.id_buffer,id_bytes) |> sdl_try
  buffer=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_INDIRECT|SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE,size=4000u)) |> sdl_try;r.commands=buffer
  buffer=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_INDIRECT|SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE,size=4000u)) |> sdl_try;r.shadow_commands=buffer
  buffer=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE,size=800u)) |> sdl_try;r.visibility=buffer
  var p=indirect_pipeline(device,ids::forge_indirect_vertex,ids::forge_indirect_vertex_reflect,ids::forge_indirect_vertex_access,ds::forge_model_fragment,ds::forge_model_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window)) |> sdl_try;r.solid=p
  p=indirect_pipeline(device,ids::forge_indirect_shadow_vertex,ids::forge_indirect_shadow_vertex_reflect,ids::forge_indirect_shadow_vertex_access,hs::shadow_fragment,hs::shadow_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,true) |> sdl_try;r.shadow=p
  p=advanced_pipeline(device,hs::cascade_vertex,hs::cascade_vertex_reflect,ds::forge_model_fragment,ds::forge_model_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window)) |> sdl_try;SDL_ReleaseGPUGraphicsPipeline(device,scene.solid);scene.solid=p
  return with_atmosphere_compute(device,ids::forge_frustum_compute,ids::forge_frustum_compute_reflect,ids::forge_frustum_compute_access) $(var compute){
   var state=lesson_camera(float3(15,8,15),0.785398163,-0.34906585)
   lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_indirect(device,command,compute,r,scene,target,width,height,state)} |> sdl_try
   let capture_path=hint_string("DASSDL3_FORGE_CAPTURE") |> unwrap_or("")
   if(capture_path!=""){
    let readback_data <- read_buffer(device,r.commands,4000u) |> sdl_try;let planes=frustum_planes(camera_matrix(1280u,720u,state.eye,state.target),state.effect,200u);var visible=0
    for(i in 0..200){let obj=objects[i];var expected=true;if(state.effect){for(plane in planes.planes){if(dot(obj.bounds.xyz,plane.xyz)+plane.w < -obj.bounds.w){expected=false}}}
     if(word(readback_data,i*20)!=box.count || word(readback_data,i*20+4)!=(expected ? 1u : 0u) || word(readback_data,i*20+16)!=uint(i)){return failure("Indirect readback","Command {i} differs from CPU frustum oracle")};if(expected){visible++}
    };print("Indirect: 200 GPU commands match the CPU frustum oracle ({visible} visible).\n")
   };return sdl_ok()
  }
 }}
}
