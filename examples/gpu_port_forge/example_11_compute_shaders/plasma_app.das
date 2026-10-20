options gen2
module plasma_app shared public
require ../common/forge_support.das public
require ../common/scene_shaders.das as shaders
require ./plasma_shaders.das public
require dassdl3/sdl3_shader_compute public
require daslib/defer
require daslib/match

def with_plasma_pipeline(device : SDL_GPUDevice?; body : block<(var p : SDL_GPUComputePipeline?) : SdlStatus>) : SdlStatus {
    if((SDL_GetGPUShaderFormats(device)&SDL_GPU_SHADERFORMAT_SPIRV)!=0u){return with_gpu_dsl_compute_pipeline(device,plasma_compute,plasma_compute_reflect,plasma_compute_access,body)}
    static_if(typeinfo module_exists(sdl3_shader_dsl_cross)){
        return with_shadercross(){return with_gpu_dsl_compute_pipeline_cross(device,plasma_compute,plasma_compute_reflect,plasma_compute_access,body)}
    }else{return failure("Plasma","D3D12 needs the libraries runner with shadercross")}
}
def dispatch_plasma(command : SDL_GPUCommandBuffer?; pipeline : SDL_GPUComputePipeline?; var image : SDL_GPUTexture?; width,height : uint; time : float) : SdlStatus {
    push_gpu_dsl_compute_uniform(command,0u,PlasmaParams(time=time,width=width,height=height)) |> sdl_try
    let textures <- array(SDL_GPUStorageTextureReadWriteBinding(texture=image,cycle=false))
    var buffers : array<SDL_GPUStorageBufferReadWriteBinding>
    return with_native_gpu_compute_pass(command,textures,buffers) $(var compute_pass) {
        SDL_BindGPUComputePipeline(compute_pass,pipeline)
        SDL_DispatchGPUCompute(compute_pass,(width+7u)/8u,(height+7u)/8u,1u)
        return sdl_ok()
    }
}
def render_plasma(command : SDL_GPUCommandBuffer?; compute : SDL_GPUComputePipeline?; display : SDL_GPUGraphicsPipeline?; var image,target : SDL_GPUTexture?; var sampler : SDL_GPUSampler?; time : float) : SdlStatus {
    dispatch_plasma(command,compute,image,512u,512u,time) |> sdl_try
    let targets <- array(attachment(target))
    return with_native_gpu_render_pass(command,targets) $(var pass_) {
        SDL_BindGPUGraphicsPipeline(pass_,display)
        var images <- array(image);bind_images(pass_,images,sampler) |> sdl_try
        SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()
    }
}
def run_plasma(smoke : bool) : int {
    let result=sdl_scope(){
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("Forge GPU 11 | Compute plasma | Space: pause",960,720,SDL_WINDOW_RESIZABLE) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(dsl_example_formats(),true,"") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device,window),"SDL_ClaimWindowForGPUDevice") |> sdl_try
        {defer(){SDL_ReleaseWindowFromGPUDevice(device,window)}
        configure_forge_swapchain(device,window) |> sdl_try
        return with_plasma_pipeline(device) $(var compute) {
            var display=device |> pipeline(shaders::fullscreen_vertex,shaders::fullscreen_vertex_reflect,shaders::fullscreen_fragment,shaders::fullscreen_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),false,false,false) |> sdl_try
            {defer(){SDL_ReleaseGPUGraphicsPipeline(device,display)}
            return sdl_scope(){
                var image : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(512u,512u,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_use
                var sampler : SDL_GPUSampler? = device |> with_native_gpu_sampler(gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR)) |> sdl_use
                var running=true;var frames=0;var paused=false;var time=0.0;var last=SDL_GetTicks()
                while(running){
                    for(event in poll_events()){
                        if(should_close(event,window)){running=false}
                        match(event){if(SdlEvent(key_down=$v(key))){if(key.keycode==SDLK_SPACE && !key.repeat){paused = !paused}}if(_){} }
                    }
                    if(!running){break}
                    let now=SDL_GetTicks();if(!paused && !smoke){time+=float(now-last)*0.001};last=now
                    with_native_gpu_swapchain(device,window) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_plasma(command,compute,display,image,target,sampler,time)} |> sdl_try
                    frames++;if(smoke && frames>=3){break};SDL_Delay(16u)
                }
                return sdl_status(SDL_WaitForGPUIdle(device),"SDL_WaitForGPUIdle")
            }}
        }}
    }
    if(is_err(result)){let error=unwrap_err(result);print("{error.operation}: {error.message}\n");return 1}
    print("Forge 11: compute plasma rendered; resources released.\n");return 0
}
