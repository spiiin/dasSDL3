options gen2
module rsm_gui shared public
require ./rsm_app.das public
require dassdl3/sdl3_imgui public

def settings_panel(var settings : Settings) {
    SetNextWindowPos(ImVec2(930.0,10.0),ImGuiCond.FirstUseEver)
    SetNextWindowSize(ImVec2(340.0,400.0),ImGuiCond.FirstUseEver)
    if(Begin("Settings")) {
        SliderFloat("RSM Amount",unsafe(addr(settings.bounce)),0.0,0.7)
        SliderFloat("VPL Radius",unsafe(addr(settings.radius)),0.25,20.0)
        SliderFloat("Light Azimuth",unsafe(addr(settings.azimuth)),0.0,360.0)
        SliderFloat("Light Elevation",unsafe(addr(settings.elevation)),35.0,90.0)
        let names=fixed_array("Direct + indirect","Direct only","Reflected flux")
        if(BeginCombo("Display",names[settings.mode])){for(i in 0..3){if(Selectable(names[i],settings.mode==i)){settings.mode=i}};EndCombo()}
        Text("Adapted: 64-sample gather, Cornell room")
        Checkbox("Paused",unsafe(addr(settings.paused)))
        if(Button("Reset")){settings=Settings()}
    }
    End()
}
def run_gui(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
 return with_imgui_gpu(window,device){
  DisableIniPersistence();StyleColorsDark()
  return with_resources(device,SDL_GetGPUSwapchainTextureFormat(device,window)) $(var r){
   var settings=Settings();var raw=SDL_MakeEvent();var running=true;var frames=0;var time=0.0;var last=SDL_GetTicks()
   while(running){
    while(is_some(poll_event(raw))){
     ImGui_SDL3_ProcessEvent(raw);let event=decode_event(raw)
     if(!(event is key_down) && should_close(event,window)){running=false}
     if(!ImGui_SDL3_WantCaptureKeyboard()){
      if(should_close(event,window)){running=false}
      match(event){if(SdlEvent(key_down=$v(k))){if(!k.repeat){
       if(k.keycode==SDLK_SPACE){settings.paused=!settings.paused}
       elif(k.keycode==SDLK_R){settings=Settings();time=0.0}
       elif(k.keycode==SDLK_M){settings.mode=(settings.mode+1)%3}
      }}if(_){} }
     }
    }
    if(!running){break}
    let now=SDL_GetTicks();let dt=float(now-last)*0.001;last=now
    if(!settings.paused && !smoke){time+=dt}
    ImGui_ImplSDLGPU3_NewFrame();ImGui_ImplSDL3_NewFrame();NewFrame()
    settings_panel(settings);Render()
    with_native_gpu_swapchain(device,window) $(command : SDL_GPUCommandBuffer?;var output : SDL_GPUTexture?;width,height : uint){
     draw(device,command,r,output,width,height,time,settings) |> sdl_try
     ImGui_SDL3_GPU_Prepare(command)
     let targets <- array(SDL_GPUColorTargetInfo(texture=output,load_op=SDL_GPULoadOp.LOADOP_LOAD,store_op=SDL_GPUStoreOp.STOREOP_STORE))
     return with_native_gpu_render_pass(command,targets) $(var pass_ : SDL_GPURenderPass?&){ImGui_SDL3_GPU_Render(command,pass_);return sdl_ok()}
    } |> sdl_try
    frames++;if(smoke && frames>=3){break}
   }
   if(smoke){print("rsm ImGui panel: {frames} frames rendered.\n")}
   return sdl_ok()
  }
 }
}
