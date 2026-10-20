options gen2
module lesson_host shared public
// Shared application loop for Forge ports; deliberately example-local.
require forge_support public
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_window_boost
require daslib/match
require daslib/defer
struct LessonState {
 eye : float3=float3(-6.1,7,4.4)
 target : float3=float3(0,0,0)
 mode : int=2
 exposure : float=1.0
 strength : float=0.04
 threshold : float=1.0
 effect : bool=true
 paused : bool=false
 time : float=0.0
}
def lesson_camera(eye : float3; yaw,pitch : float) : LessonState {
 return LessonState(eye=eye,target=eye+float3(-sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))*10.0)
}
// Offscreen capture is an example test hook. Normal execution presents to the window.
def lesson_capture(device : SDL_GPUDevice?;window : SDL_Window?;var state : LessonState;path : string;draw : block<(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint) : SdlStatus>) : SdlStatus {
 let capture_variant=hint_string("DASSDL3_FORGE_VARIANT") |> unwrap_or("")
 if(capture_variant=="changed"){state.effect=false;state.mode=0;state.exposure=.5;state.time=1.5}
 if(capture_variant=="time"){state.time=1.5}
 for(mode in 0..9){if(capture_variant=="mode{mode}"){state.mode=mode}}
 return sdl_scope(){
  let format=SDL_GetGPUSwapchainTextureFormat(device,window)
  var target : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(1280u,720u,format,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
  for(frame in 0..3){with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){draw(command,target,1280u,720u) |> sdl_try;return native_gpu_submit(command)} |> sdl_try}
  var bytes <- read_image(device,target,1280u,720u) |> sdl_try
  if(format==SDL_GPUTextureFormat.TEXTUREFORMAT_B8G8R8A8_UNORM || format==SDL_GPUTextureFormat.TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB){for(i in 0..1280*720){let r=bytes[i*4];bytes[i*4]=bytes[i*4+2];bytes[i*4+2]=r}}
  return save_file(path,bytes)
 }
}

def lesson_loop(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool; var state : LessonState; draw : block<(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint) : SdlStatus>) : SdlStatus {
 let capture_path=hint_string("DASSDL3_FORGE_CAPTURE") |> unwrap_or("");if(capture_path!=""){return lesson_capture(device,window,state,capture_path,draw)}
 var running=true;var frames=0;var last=SDL_GetTicks()
 while(running){
  for(event in poll_events()){
   if(should_close(event,window)){running=false}
   match(event){if(SdlEvent(key_down=$v(k))){
    if(k.keycode>=SDLK_1 && k.keycode<=SDLK_9){state.mode=int(k.keycode-SDLK_1)}
    elif(k.keycode==SDLK_SPACE && !k.repeat){state.paused=!state.paused}
    elif(k.keycode==SDLK_E && !k.repeat){state.effect=!state.effect}
    elif(k.keycode==SDLK_EQUALS){state.exposure=min(10.0,state.exposure+0.1)}
    elif(k.keycode==SDLK_MINUS){state.exposure=max(0.1,state.exposure-0.1)}
    elif(k.keycode==SDLK_UP){state.strength=min(0.5,state.strength+0.005)}
    elif(k.keycode==SDLK_DOWN){state.strength=max(0.0,state.strength-0.005)}
    elif(k.keycode==SDLK_RIGHT){state.threshold=min(10.0,state.threshold+0.1)}
    elif(k.keycode==SDLK_LEFT){state.threshold=max(0.0,state.threshold-0.1)}
    elif(k.keycode==SDLK_W || k.keycode==SDLK_S){let delta=normalize(state.target-state.eye)*(k.keycode==SDLK_W ? 0.5 : -0.5);state.eye+=delta;state.target+=delta}
   }if(SdlEvent(mouse_motion=$v(mouse))){if((mouse.buttons&SDL_BUTTON_RMASK)!=0u){
    let offset=state.eye-state.target;let radius=length(offset);let yaw=atan2(offset.x,offset.z)-mouse.delta.x*0.005;let pitch=clamp(asin(offset.y/radius)+mouse.delta.y*0.005,-1.4,1.4)
    state.eye=state.target+float3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*radius
   }}if(SdlEvent(mouse_wheel=$v(wheel))){state.eye=state.target+(state.eye-state.target)*exp(-wheel.delta.y*0.1)}if(_){} }
  }
  if(!running){break}
  let now=SDL_GetTicks();if(!state.paused && !smoke){state.time+=min(0.1,float(now-last)*0.001)};last=now
  with_native_gpu_swapchain(device,window,draw) |> sdl_try
  frames++;if(smoke && frames>=3){break};SDL_Delay(16u)
 }
 return sdl_status(SDL_WaitForGPUIdle(device),"Wait Forge lesson GPU")
}
def with_lesson_window(number : int; body : block<(device : SDL_GPUDevice?;window : SDL_Window?) : SdlStatus>) : int {
 let result=sdl_scope(){
  with_sdl() |> sdl_use
  let window : SDL_Window? = with_window("Forge GPU {number} | SDL + daScript DSL",1280,720,SDL_WINDOW_RESIZABLE) |> sdl_use
  let device : SDL_GPUDevice? = with_native_gpu_device(dsl_example_formats(),true,"") |> sdl_use
  sdl_status(SDL_ClaimWindowForGPUDevice(device,window),"Claim Forge window") |> sdl_try
  {defer(){SDL_ReleaseWindowFromGPUDevice(device,window)}
   configure_forge_swapchain(device,window) |> sdl_try
   return body(device,window)
  }
 }
 if(is_err(result)){let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
 print("Forge {number}: rendered; resources released.\n");return 0
}
