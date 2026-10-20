options gen2
module noise_app shared public
require ../common/forge_support.das public
require ./noise_shaders.das public
require ../common/lesson_host.das
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_window_boost
require daslib/match
require daslib/defer

def render_noise(command : SDL_GPUCommandBuffer?; pipeline_ : SDL_GPUGraphicsPipeline?; var output : SDL_GPUTexture?; width,height : uint; settings : NoiseParams) : SdlStatus {
 var params=settings;params.resolution=float2(float(width),float(height))
 push_gpu_dsl_fragment_uniform(command,0u,params) |> sdl_try
 let targets <- array(attachment(output))
 return with_native_gpu_render_pass(command,targets) $(var pass_){
  SDL_BindGPUGraphicsPipeline(pass_,pipeline_);SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()
 }
}
def run_noise(smoke : bool) : int {
 let result=sdl_scope(){
  with_sdl() |> sdl_use
  let window : SDL_Window? = with_window("Forge 25 | Noise | 1-6 modes, D dither, +/- scale",1280,720,SDL_WINDOW_RESIZABLE) |> sdl_use
  let device : SDL_GPUDevice? = with_native_gpu_device(dsl_example_formats(),true,"") |> sdl_use
  sdl_status(SDL_ClaimWindowForGPUDevice(device,window),"Claim noise window") |> sdl_try
  {defer(){SDL_ReleaseWindowFromGPUDevice(device,window)}
   configure_forge_swapchain(device,window) |> sdl_try
   var p=device |> pipeline(forge_noise_vertex,forge_noise_vertex_reflect,forge_noise_fragment,forge_noise_fragment_reflect,SDL_GetGPUSwapchainTextureFormat(device,window),false,false,false) |> sdl_try
   {defer(){SDL_ReleaseGPUGraphicsPipeline(device,p)}
    var settings=NoiseParams(scale=8.0);var running=true;var frames=0;var paused=false;var last=SDL_GetTicks()
    let capture_path=hint_string("DASSDL3_FORGE_CAPTURE") |> unwrap_or("")
    if(capture_path!=""){var state=LessonState(mode=settings.mode);return lesson_capture(device,window,state,capture_path) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){var params=settings;params.mode=state.mode;params.time=state.time;if(!state.effect){params.scale=4.0;params.dither=1};return render_noise(command,p,target,width,height,params)}}
    while(running){
     for(event in poll_events()){
      if(should_close(event,window)){running=false}
      match(event){if(SdlEvent(key_down=$v(k))){
       if(k.keycode>=SDLK_1 && k.keycode<=SDLK_6){settings.mode=int(k.keycode-SDLK_1)}
       elif(k.keycode==SDLK_D && !k.repeat){settings.dither=1-settings.dither}
       elif(k.keycode==SDLK_SPACE && !k.repeat){paused=!paused}
       elif(k.keycode==SDLK_EQUALS){settings.scale=min(64.0,settings.scale+1.0)}
       elif(k.keycode==SDLK_MINUS){settings.scale=max(1.0,settings.scale-1.0)}
      }if(_){} }
     }
     if(!running){break}
     let now=SDL_GetTicks();if(!paused && !smoke){settings.time+=min(0.1,float(now-last)*0.001)};last=now
     with_native_gpu_swapchain(device,window) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_noise(command,p,target,width,height,settings)} |> sdl_try
     frames++;if(smoke && frames>=3){break};SDL_Delay(16u)
    }
    return sdl_status(SDL_WaitForGPUIdle(device),"Wait noise GPU")
   }
  }
 }
 if(is_err(result)){let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
 print("Forge 25: all resources released.\n");return 0
}
