options gen2
module atmosphere_app shared public
require ../common/hdr_app.das public
require ./atmosphere_shaders.das public
require daslib/defer
def with_atmosphere_compute(device : SDL_GPUDevice?;words,reflection,access : array<uint>;body : block<(var p : SDL_GPUComputePipeline?) : SdlStatus>) : SdlStatus {
 if((SDL_GetGPUShaderFormats(device)&SDL_GPU_SHADERFORMAT_SPIRV)!=0u){return with_gpu_dsl_compute_pipeline(device,words,reflection,access,body)}
 static_if(typeinfo module_exists(sdl3_shader_dsl_cross)){return with_shadercross(){return with_gpu_dsl_compute_pipeline_cross(device,words,reflection,access,body)}}else{return failure("Atmosphere","Backend requires shadercross")}
}
def atmosphere_luts(command : SDL_GPUCommandBuffer?;trans,ms : SDL_GPUComputePipeline?;var trans_tex,ms_tex : SDL_GPUTexture?;var sampler : SDL_GPUSampler?) : SdlStatus {
 let buffers : array<SDL_GPUStorageBufferReadWriteBinding>
 let trans_out <- array(SDL_GPUStorageTextureReadWriteBinding(texture=trans_tex))
 with_native_gpu_compute_pass(command,trans_out,buffers) $(var pass_){SDL_BindGPUComputePipeline(pass_,trans);SDL_DispatchGPUCompute(pass_,32u,8u,1u);return sdl_ok()} |> sdl_try
 let ms_out <- array(SDL_GPUStorageTextureReadWriteBinding(texture=ms_tex))
 return with_native_gpu_compute_pass(command,ms_out,buffers) $(var pass_){SDL_BindGPUComputePipeline(pass_,ms);let images <- array(SDL_GPUTextureSamplerBinding(texture=trans_tex,sampler=sampler));sdl_status(SDL_BindGPUComputeSamplersArray(pass_,0u,images),"Atmosphere transmittance LUT") |> sdl_try;SDL_DispatchGPUCompute(pass_,4u,4u,1u);return sdl_ok()}
}
def render_atmosphere(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var post : HdrPasses;pipeline_ : SDL_GPUGraphicsPipeline?;var trans,ms,target : SDL_GPUTexture?;var sampler : SDL_GPUSampler?;width,height : uint;state : LessonState) : SdlStatus {
 hdr_targets(device,post,width,height,true) |> sdl_try
 let vp=camera_matrix(width,height,float3(0),state.target-state.eye);let inv=inverse(vp)
 push_gpu_dsl_vertex_uniform(command,0u,AtmosphereView(inverse=inv)) |> sdl_try
 let elevation=state.threshold;let azimuth=3.08+state.time*0.01
 push_gpu_dsl_fragment_uniform(command,0u,AtmosphereParams(camera=float4(state.eye,20.0),sun=float4(cos(elevation)*sin(azimuth),sin(elevation),cos(elevation)*cos(azimuth),32.0),resolution=float4(float(width),float(height),0.0,0.0))) |> sdl_try
 let targets <- array(attachment(post.hdr))
 with_native_gpu_render_pass(command,targets) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,pipeline_);var images <- array(trans,ms);bind_images(pass_,images,sampler) |> sdl_try;SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()} |> sdl_try
 return bloom_and_tone(command,post,target,sampler,state,true)
}
def run_atmosphere(smoke : bool) : int {
 return with_lesson_window(26) $(device,window){
  return with_atmosphere_compute(device,forge_transmittance_compute,forge_transmittance_compute_reflect,forge_transmittance_compute_access) $(var trans_compute){
   return with_atmosphere_compute(device,forge_multiscatter_compute,forge_multiscatter_compute_reflect,forge_multiscatter_compute_access) $(var ms_compute){
    return sdl_scope(){
     var trans : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(256u,64u,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_use
     var ms : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(32u,32u,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_use
     var sampler : SDL_GPUSampler? = device |> with_native_gpu_sampler(gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR)) |> sdl_use
     with_native_gpu_commands(device) $(var cmd : SDL_GPUCommandBuffer?&){atmosphere_luts(cmd,trans_compute,ms_compute,trans,ms,sampler) |> sdl_try;return native_gpu_submit(cmd)} |> sdl_try
     var p=device |> pipeline(forge_atmosphere_vertex,forge_atmosphere_vertex_reflect,forge_atmosphere_fragment,forge_atmosphere_fragment_reflect,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,false,false,false) |> sdl_try
     {defer(){SDL_ReleaseGPUGraphicsPipeline(device,p)}
      return with_hdr_passes(device,SDL_GetGPUSwapchainTextureFormat(device,window),true) $(var post){
       var state=lesson_camera(float3(0,6360.001,0),1.63,0.0);state.threshold=smoke ? 0.04 : 0.5
       return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_atmosphere(device,command,post,p,trans,ms,target,sampler,width,height,state)}
      }
     }
    }
   }
  }
 }
}
