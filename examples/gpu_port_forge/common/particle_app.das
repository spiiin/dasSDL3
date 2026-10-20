options gen2
module particle_app shared public
require animation_app public
require particle_shaders as ps
require ../example_26_procedural_sky/atmosphere_app.das
require ui_app public
require daslib/defer
require forge_readback
require dassdl3/sdl3_init_boost

def particle_pipeline(device : SDL_GPUDevice?;format : SDL_GPUTextureFormat;additive : bool){
 return sdl_scope(){
  var vertex : SDL_GPUShader? = device |> with_deformation_shader(ps::forge_particle_vertex,ps::forge_particle_vertex_reflect,ps::forge_particle_vertex_access) |> sdl_use
  var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(ps::forge_particle_fragment,ps::forge_particle_fragment_reflect) |> sdl_use
  var info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST,rasterizer_state=SDL_GPURasterizerState(enable_depth_clip=true))
  var color=gpu_color_target(format);color.blend_state=SDL_GPUColorTargetBlendState(enable_blend=true,src_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA,dst_color_blendfactor=additive ? SDL_GPUBlendFactor.BLENDFACTOR_ONE : SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,color_blend_op=SDL_GPUBlendOp.BLENDOP_ADD,src_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,dst_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,alpha_blend_op=SDL_GPUBlendOp.BLENDOP_ADD)
  let colors <- array(color);let buffers : array<SDL_GPUVertexBufferDescription>;let attributes : array<SDL_GPUVertexAttribute>
  return <- device |> create_native_gpu_graphics_pipeline(info,buffers,attributes,colors)
 }
}
def run_particles(smoke : bool) : int {
 return with_lesson_window(46) $(device,window){return with_atmosphere_compute(device,ps::forge_particle_compute,ps::forge_particle_compute_reflect,ps::forge_particle_compute_access) $(var compute){
  var pool,budget : SDL_GPUBuffer?;var atlas : SDL_GPUTexture?;var additive,alpha : SDL_GPUGraphicsPipeline?;var sampler_ : SDL_GPUSampler?
  defer(){for(resource in fixed_array(pool,budget)){if(resource!=null){SDL_ReleaseGPUBuffer(device,resource)}};if(atlas!=null){SDL_ReleaseGPUTexture(device,atlas)};if(sampler_!=null){SDL_ReleaseGPUSampler(device,sampler_)};for(pipeline_value in fixed_array(additive,alpha)){if(pipeline_value!=null){SDL_ReleaseGPUGraphicsPipeline(device,pipeline_value)}}}
  var buffer=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ|SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE|SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,size=4096u*64u)) |> sdl_try;pool=buffer
  var zeros : array<uint8>;resize(zeros,4096*64);upload_bytes(device,pool,zeros) |> sdl_try
  buffer=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ|SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE,size=4u)) |> sdl_try;budget=buffer
  var image=load_texture(device,"remaining_particles",false) |> sdl_try;atlas=image
  var sampler_value=SDL_CreateGPUSamplerRef(device,gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR));if(sampler_value==null){return err(sdl_error("Particle sampler"),type<SdlUnit>)};sampler_=sampler_value
  var p=particle_pipeline(device,SDL_GetGPUSwapchainTextureFormat(device,window),true) |> sdl_try;additive=p;p=particle_pipeline(device,SDL_GetGPUSwapchainTextureFormat(device,window),false) |> sdl_try;alpha=p
  var state=lesson_camera(float3(0,3,4),0.0,-0.35);state.mode=0;var frame=0u;var previous=-1;var last_time=0.0
  lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){
   let emitter=clamp(state.mode,0,2);if(emitter!=previous){frame=0u;previous=emitter}
   let dt=smoke ? 1.0/60.0 : clamp(state.time-last_time,0.0,0.1);last_time=state.time
   let counts <- array(64u);let bytes <- packed_uints(counts);upload_bytes(device,budget,bytes) |> sdl_try
   push_gpu_dsl_compute_uniform(command,0u,ps::ParticleSim(physics=float4(dt,-9.8,0.3,0),emitter=float4(float(emitter),0.0,0.0,0.0),extra=float4(1.0,1.0,0.5,0.0),frame=uint4(frame,0u,0u,0u))) |> sdl_try
   let textures : array<SDL_GPUStorageTextureReadWriteBinding>;let outputs <- array(SDL_GPUStorageBufferReadWriteBinding(buffer=pool),SDL_GPUStorageBufferReadWriteBinding(buffer=budget))
   with_native_gpu_compute_pass(command,textures,outputs) $(var pass_){SDL_BindGPUComputePipeline(pass_,compute);SDL_DispatchGPUCompute(pass_,16u,1u,1u);return sdl_ok()} |> sdl_try
   let forward=normalize(state.target-state.eye);let right=normalize(cross(forward,float3(0,1,0)));let up=cross(right,forward)
   push_gpu_dsl_vertex_uniform(command,0u,ps::ParticleView(vp=camera_matrix(width,height,state.eye,state.target),right=float4(right,0.0),up=float4(up,0.0))) |> sdl_try
   let colors <- array(attachment(target,false,float4(0.02,0.025,0.04,1)))
   with_native_gpu_render_pass(command,colors) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,emitter==2 ? alpha : additive);let storage <- array(pool);sdl_status(SDL_BindGPUVertexStorageBuffersArray(pass_,0u,storage),"Particle storage") |> sdl_try;let images <- array(SDL_GPUTextureSamplerBinding(texture=atlas,sampler=sampler_));sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Particle atlas") |> sdl_try;SDL_DrawGPUPrimitives(pass_,4096u*6u,1u,0u,0u);return sdl_ok()} |> sdl_try
   frame++;return sdl_ok()
  } |> sdl_try
  let capture_path=hint_string("DASSDL3_FORGE_CAPTURE") |> unwrap_or("")
  if(capture_path!=""){
   let readback_data <- read_buffer(device,pool,4096u*64u) |> sdl_try;var alive=0
   for(i in 0..4096){for(j in 0..16){let value=read_float(readback_data,i*64+j*4);if(!(abs(value)<100000.0)){return failure("Particle readback","Non-finite particle state")}};if(read_float(readback_data,i*64+12)>0.0){alive++}}
   if(alive<3000){return failure("Particle readback","Particle pool was not populated")}
   if(clamp(state.mode,0,2)==0){
    var seed=ps::particle_hash(0u);var randoms : float[5];for(i in 0..5){seed=ps::particle_hash(seed);randoms[i]=float(seed)/4294967296.0}
    var velocity=float3(-2.0+randoms[0]*4.0,5.0+randoms[1]*5.0,-2.0+randoms[2]*4.0);let life=2.0+randoms[4]*2.0;let fraction=float(ps::particle_hash(ps::particle_hash(42u)))/4294967296.0;var position=velocity*(life*(1.0-fraction));let dt=1.0/60.0
    for(i in 0..2){velocity.y-=9.8*dt;velocity*=1.0-.3*dt;position+=velocity*dt}
    let actual=float3(read_float(readback_data,0),read_float(readback_data,4),read_float(readback_data,8));if(length(actual-position)>.001){return failure("Particle readback","GPU integration differs from CPU Euler oracle")}
   };print("Particles: {alive} finite live states; Euler oracle PASS.\n")
  };return sdl_ok()
 }}
}
