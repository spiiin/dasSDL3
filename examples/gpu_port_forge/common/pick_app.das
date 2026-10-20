options gen2
module pick_app shared public
require stencil_app public
require hdr_shaders as hs
require daslib/defer
require daslib/match
require dassdl3/sdl3_init_boost
struct PickState {ids : SDL_GPUTexture?;readback : SDL_GPUTransferBuffer?;fence : SDL_GPUFence?;size : uint2;selected : int=-1;pixel : int2;pending,stencil : bool}
def pick_parts {
 var parts : array<AdvancedPart>
 let p=fixed_array(float4(-3,0.5,-2,1),float4(2,0.5,-1,0.8),float4(0,0.75,-4,1.5),float4(-1.5,0.5,-5,0.7),float4(3,0.6,-3,0.6),float4(-2,0.4,-3.5,0.4),float4(1,1,-2.5,0.6),float4(-0.5,0.5,-1.5,0.5),float4(2.5,0.4,-5,0.8),float4(-3,0.6,-4.5,0.6))
 let c=fixed_array(float4(0.85,0.2,0.15,1),float4(0.15,0.4,0.85,1),float4(0.2,0.75,0.25,1),float4(0.85,0.8,0.15,1),float4(0.6,0.25,0.75,1),float4(0.9,0.5,0.15,1),float4(0.15,0.8,0.8,1),float4(0.9,0.4,0.6,1),float4(0.85,0.85,0.85,1),float4(0.2,0.7,0.65,1))
 for(i in 0..10){push(parts,AdvancedPart(spec=PartSpec(mesh=i==4 || i==5 || i==7 || i==9 ? "remaining_sphere" : "advanced_box_0_0",model=model_matrix(p[i].xyz,float3(p[i].w)),base=c[i])))};return <- parts
}
def is_pick_sphere(index : int) : bool {return index==4 || index==5 || index==7 || index==9}
def poll_pick_result(device : SDL_GPUDevice?;var p=PickState()) : SdlStatus {
 if(p.fence!=null && SDL_QueryGPUFence(device,p.fence)){
  var bytes : array<uint8>;resize(bytes,4);sdl_status(SDL_ReadGPUTransferBufferBytes(device,p.readback,256u,0u,bytes),"Read picked ID") |> sdl_try
  let id=int(bytes[0])|(int(bytes[1])<<8)|(int(bytes[2])<<16);p.selected=id>=1 && id<=10 ? id-1 : -1;SDL_ReleaseGPUFence(device,p.fence);p.fence=null
 };return sdl_ok()
}
def queue_pick(device : SDL_GPUDevice?;var p=PickState()) : SdlStatus {
 if(!p.pending || p.fence!=null || p.size.x==0u){return sdl_ok()};p.pending=false
 return with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){
  with_native_gpu_copy_pass(command) $(var pass_){SDL_DownloadFromGPUTextureRef(pass_,SDL_GPUTextureRegion(texture=p.ids,x=uint(clamp(p.pixel.x,0,int(p.size.x)-1)),y=uint(clamp(p.pixel.y,0,int(p.size.y)-1)),w=1u,h=1u,d=1u),SDL_GPUTextureTransferInfo(transfer_buffer=p.readback,pixels_per_row=64u,rows_per_layer=1u));return sdl_ok()} |> sdl_try
  var fence=native_gpu_submit_fence(command) |> sdl_try;p.fence=fence;return sdl_ok()
 }
}
def render_pick(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var scene : AdvancedScene;var r : StencilPasses;var p=PickState();var output : SDL_GPUTexture?;width,height : uint;state : LessonState) : SdlStatus {
 stencil_target(device,r,width,height) |> sdl_try
 if(p.size!=uint2(width,height)){if(p.ids!=null){SDL_ReleaseGPUTexture(device,p.ids);p.ids=null};var ids=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_try;p.ids=ids;p.size=uint2(width,height)}
 let no_colors : array<SDL_GPUColorTargetInfo>;let shadow=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[0],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,no_colors,shadow) $(var pass_){return sdl_ok()} |> sdl_try
 let vp=planar_projection(width,height)*look_at_rh(state.eye,state.target,float3(0,1,0))
 let colors <- array(attachment(output));let depth=SDL_GPUDepthStencilTargetInfo(texture=r.depth,clear_depth=1.0,clear_stencil=0u8,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE,stencil_load_op=SDL_GPULoadOp.LOADOP_CLEAR,stencil_store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,colors,depth) $(var pass_){
  stencil_object(command,pass_,scene,r,0,vp,model_matrix(float3(0,-0.05,0),float3(100,0.1,100)),float4(0.12,0.14,0.18,1),state.eye) |> sdl_try
  for(i in 0..10){SDL_SetGPUStencilReference(pass_,uint(i+1));stencil_object(command,pass_,scene,r,p.stencil ? 8 : 0,vp,scene.parts[i].spec.model,scene.parts[i].spec.base,state.eye,is_pick_sphere(i)) |> sdl_try}
  if(p.selected>=0){let i=p.selected;SDL_SetGPUStencilReference(pass_,128u);stencil_object(command,pass_,scene,r,4,vp,scene.parts[i].spec.model,float4(0),state.eye,is_pick_sphere(i)) |> sdl_try
   var model=scene.parts[i].spec.model;model[0]*=1.04;model[1]*=1.04;model[2]*=1.04;stencil_object(command,pass_,scene,r,3,vp,model,float4(1,0.85,0.1,1),state.eye,is_pick_sphere(i)) |> sdl_try
  };return sdl_ok()
 } |> sdl_try
 if(!p.pending || p.fence!=null){return sdl_ok()}
 let ids <- array(attachment(p.ids,false,float4(0,0,0,1)));var depth_ids=depth;depth_ids.stencil_load_op=SDL_GPULoadOp.LOADOP_LOAD
 depth_ids.load_op=p.stencil ? SDL_GPULoadOp.LOADOP_LOAD : SDL_GPULoadOp.LOADOP_CLEAR
 return with_native_gpu_render_pass(command,ids,depth_ids) $(var pass_){
  if(p.stencil){SDL_BindGPUGraphicsPipeline(pass_,r.pipelines[9]);for(i in 0..10){SDL_SetGPUStencilReference(pass_,uint(i+1));push_gpu_dsl_fragment_uniform(command,0u,hs::AdvancedFragment(controls=float4(float(i+1),0.0,0.0,0.0))) |> sdl_try;SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u)}}
  else{for(i in 0..10){stencil_object(command,pass_,scene,r,7,vp,scene.parts[i].spec.model,float4(0),state.eye,is_pick_sphere(i),i+1) |> sdl_try}}
  return sdl_ok()
 }
}
def run_pick(smoke : bool) : int {
 return with_lesson_window(37) $(device,window){return with_advanced(device,SDL_GetGPUSwapchainTextureFormat(device,window),15) $(var scene){return with_stencil(device,SDL_GetGPUSwapchainTextureFormat(device,window)) $(var r){
  let parts <- pick_parts();replace_parts(device,scene,parts) |> sdl_try
  for(mode in fixed_array(7,9)){var pipeline_=stencil_pipeline(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,r.format,mode) |> sdl_try;SDL_ReleaseGPUGraphicsPipeline(device,r.pipelines[mode]);r.pipelines[mode]=pipeline_}
  var p=PickState()
  defer(){if(p.fence!=null){SDL_ReleaseGPUFence(device,p.fence)};if(p.readback!=null){SDL_ReleaseGPUTransferBuffer(device,p.readback)};if(p.ids!=null){SDL_ReleaseGPUTexture(device,p.ids)}}
  var transfer=SDL_CreateGPUTransferBufferRef(device,SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD,size=256u));if(transfer==null){return err(sdl_error("Create pick readback"),type<SdlUnit>)};p.readback=transfer
  var state=lesson_camera(float3(0,2,3),-0.15,-0.15);var running=true;var frames=0
  let capture_path=hint_string("DASSDL3_FORGE_CAPTURE") |> unwrap_or("")
  if(capture_path!=""){
   let vp=planar_projection(1280u,720u)*look_at_rh(state.eye,state.target,float3(0,1,0));let clip=vp*float4(0.0,.75,-4.0,1.0)
   p.pixel=int2(int((clip.x/clip.w*.5+.5)*1280.0),int((.5-clip.y/clip.w*.5)*720.0))
   for(method in 0..2){p.stencil=method==1;p.pending=true
    lesson_capture(device,window,state,capture_path) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_pick(device,command,scene,r,p,target,width,height,state)} |> sdl_try
    queue_pick(device,p) |> sdl_try;sdl_status(SDL_WaitForGPUIdle(device),"Wait picking contract") |> sdl_try;poll_pick_result(device,p) |> sdl_try
    if(p.selected!=2){return failure("Picking contract","Expected object 3, got {p.selected+1}, method {method}")}
   }
   print("Picking: color and stencil identify the same object, including selection outline.\n");return sdl_ok()
  }

  while(running){
   for(event in poll_events()){
    if(should_close(event,window)){running=false}
    match(event){if(SdlEvent(mouse_button_down=$v(mouse))){if(mouse.button==uint8(SDL_BUTTON_LEFT)){p.pixel=int2(mouse.position);p.pending=true}}
     if(SdlEvent(key_down=$v(key))){if(key.keycode==SDLK_TAB && !key.repeat){p.stencil=!p.stencil}else{if(key.keycode==SDLK_W || key.keycode==SDLK_S){let delta=normalize(state.target-state.eye)*(key.keycode==SDLK_W ? 0.5 : -0.5);state.eye+=delta;state.target+=delta}}}
     if(SdlEvent(mouse_motion=$v(mouse))){if((mouse.buttons&SDL_BUTTON_RMASK)!=0u){state.target+=float3(-mouse.delta.x,mouse.delta.y,0.0)*0.01}}
     if(_){} }
   };if(!running){break}
   poll_pick_result(device,p) |> sdl_try
   if(smoke && frames==0){p.pixel=int2(640,360);p.pending=true}
   with_native_gpu_swapchain(device,window) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_pick(device,command,scene,r,p,target,width,height,state)} |> sdl_try
   queue_pick(device,p) |> sdl_try
   sdl_status(SDL_SetWindowTitle(window,"Forge 37 | {p.stencil ? 1 : 0}: stencil/color ID | selected {p.selected}"),"Set picking title") |> sdl_try
   frames++;if(smoke && frames>=3){break};SDL_Delay(16u)
  }
  return sdl_status(SDL_WaitForGPUIdle(device),"Wait picking GPU")
 }}}
}
