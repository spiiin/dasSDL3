options gen2
module ui_app shared public
// CPU immediate UI geometry, one indexed SDL draw, R8 atlas and DSL shaders.
require lesson_host public
require ui_font public
require ui_shaders as us
require dassdl3/sdl3_shader_storage
require strings
require dassdl3/sdl3_init_boost
require daslib/defer
require daslib/match
struct UiBatch {
 vertices : array<float>; indices : array<uint>; glyphs : array<UiGlyph>
 vb,ib : SDL_GPUBuffer?; atlas : SDL_GPUTexture?;sampler : SDL_GPUSampler?;pipeline_ : SDL_GPUGraphicsPipeline?
 vertex_capacity,index_capacity : uint
 mouse,delta : float2;down,pressed,released : bool;active : int=-1;focus : bool=false
 counter : int;checked : bool=true;slider : float=0.5;health : float=75.0;mana : float=50.0
 text : string="Hello"; radio : int;dropdown : bool;choice : int
 color : float3=float3(.3,.7,.5)
 windows : float2[4]
}
def hit(ui : UiBatch;rect : float4) : bool {return ui.mouse.x>=rect.x && ui.mouse.y>=rect.y && ui.mouse.x<rect.x+rect.z && ui.mouse.y<rect.y+rect.w}
def ui_quad(var ui : UiBatch;rect,uv,color : float4){
 let index=uint(length(ui.vertices)/8)
 let pos=fixed_array(float2(rect.x,rect.y),float2(rect.x+rect.z,rect.y),float2(rect.x+rect.z,rect.y+rect.w),float2(rect.x,rect.y+rect.w))
 let tex=fixed_array(uv.xy,float2(uv.x+uv.z,uv.y),uv.xy+uv.zw,float2(uv.x,uv.y+uv.w))
 for(i in 0..4){for(v in fixed_array(pos[i].x,pos[i].y,tex[i].x,tex[i].y,color.x,color.y,color.z,color.w)){push(ui.vertices,v)}}
 for(i in fixed_array(0u,1u,2u,0u,2u,3u)){push(ui.indices,index+i)}
}
def ui_rect(var ui : UiBatch;rect,color : float4){ui_quad(ui,rect,float4(255.5/256.0,127.5/128.0,0.0,0.0),color)}
def ui_text(var ui : UiBatch;position : float2;text : string;color : float4=float4(0.9,0.92,0.95,1)){
 var x=position.x
 for(ch in text){if(ch>=32 && ch<=126){let g=ui.glyphs[ch-32];ui_quad(ui,float4(x,position.y,g.size.x,g.size.y),g.uv,color);x+=g.advance}}
}
def ui_button(var ui : UiBatch;rect : float4;text : string) : bool {
 let over=hit(ui,rect);ui_rect(ui,rect,over ? float4(0.24,0.42,0.6,1) : float4(0.18,0.25,0.34,1));ui_text(ui,rect.xy+float2(8,8),text)
 return over && ui.released
}
def ui_slider(var ui : UiBatch;rect : float4;var value : float&;lo,hi : float){
 if(ui.down && hit(ui,rect)){value=lo+(hi-lo)*clamp((ui.mouse.x-rect.x)/rect.z,0.0,1.0)}
 ui_rect(ui,rect,float4(0.1,0.13,0.19,1));ui_rect(ui,float4(rect.x,rect.y,rect.z*(value-lo)/(hi-lo),rect.w),float4(0.1,0.55,0.85,1))
}
def ui_window(var ui : UiBatch;index : int;size : float2;title : string) : float2 {
 let rect=float4(ui.windows[index],size.x,28.0)
 if(ui.pressed && hit(ui,rect)){ui.active=index}
 if(ui.down && ui.active==index){ui.windows[index]+=ui.delta}
 if(ui.released){ui.active=-1}
 let p=ui.windows[index];ui_rect(ui,float4(p,size),float4(0.08,0.1,0.15,0.96));ui_rect(ui,float4(p,size.x,28.0),float4(0.13,0.19,0.28,1));ui_text(ui,p+float2(10,7),title)
 return p+float2(12,40)
}
def make_ui(var ui : UiBatch;time : float){
 clear(ui.vertices);clear(ui.indices)
 let p=ui_window(ui,0,float2(300,680),"Controls")
 ui_text(ui,p,"Hello, GPU UI!",float4(0.1,0.65,1,1))
 if(ui_button(ui,float4(p.x,p.y+30,270.0,36.0),"Click me")){ui.counter++}
 ui_text(ui,p+float2(0,78),"Clicks: {ui.counter}")
 if(ui_button(ui,float4(p.x,p.y+108,270.0,30.0),ui.checked ? "[x] Toggle option" : "[ ] Toggle option")){ui.checked=!ui.checked}
 ui_slider(ui,float4(p.x,p.y+154,270.0,20.0),ui.slider,0.0,1.0);ui_text(ui,p+float2(0,185),"Value: {ui.slider:0.2f}")
 ui_text(ui,p+float2(0,224),"Health");ui_slider(ui,float4(p.x,p.y+248,270.0,20.0),ui.health,0.0,100.0)
 ui_text(ui,p+float2(0,284),"Mana");ui_slider(ui,float4(p.x,p.y+308,270.0,20.0),ui.mana,0.0,100.0)
 if(ui_button(ui,float4(p.x,p.y+352,270.0,32.0),ui.text)){ui.focus=true}
 ui_text(ui,p+float2(0,397),"Radio selection")
 for(i in 0..3){let prefix=ui.radio==i ? "(o)" : "( )";if(ui_button(ui,float4(p.x,p.y+422+float(i)*30.0,270.0,26.0),"{prefix} Option {i+1}")){ui.radio=i}}
 if(ui_button(ui,float4(p.x,p.y+526,270.0,30.0),"Choice: {ui.choice}  [v]")){ui.dropdown=!ui.dropdown}
 if(ui.dropdown){for(i in 0..5){if(ui_button(ui,float4(p.x,p.y+366+float(i)*30.0,270.0,28.0),"Select {i}")){ui.choice=i;ui.dropdown=false}}}
 let q=ui_window(ui,1,float2(340,680),"Inspector")
 ui_text(ui,q,"Widget values");ui_text(ui,q+float2(0,32),"Counter: {ui.counter}");ui_text(ui,q+float2(0,64),"Text: {ui.text}");ui_text(ui,q+float2(0,96),"Mouse: {ui.mouse.x:0.0f}, {ui.mouse.y:0.0f}")
 ui_text(ui,q+float2(0,144),"Color picker")
 for(y in 0..16){for(x in 0..28){ui_rect(ui,float4(q.x+float(x)*11.0,q.y+180.0+float(y)*10.0,11.0,10.0),float4(float(x)/27.0,1.0-float(y)/15.0,ui.slider,1.0))}}
 let picker=float4(q.x,q.y+180,308.0,160.0)
 if(ui.down && hit(ui,picker)){ui.color=float3(clamp((ui.mouse.x-q.x)/308.0,0.0,1.0),1.0-clamp((ui.mouse.y-q.y-180.0)/160.0,0.0,1.0),ui.slider)}
 ui_rect(ui,float4(q.x,q.y+360,80.0,40.0),float4(ui.color,1.0));ui_text(ui,q+float2(0,416),"RGB: {ui.color.x:0.2f} {ui.color.y:0.2f} {ui.color.z:0.2f}")
 let r=ui_window(ui,2,float2(280,420),"Performance")
 ui_text(ui,r,"One indexed draw / frame");ui_text(ui,r+float2(0,32),"32-byte vertices, uint32 indices");ui_text(ui,r+float2(0,72),"R8 font atlas: 256 x 128");ui_text(ui,r+float2(0,112),"Dynamic power-of-two buffers")
 let s=ui_window(ui,3,float2(560,240),"Signal graph")
 for(i in 0..120){let phase=time+float(i)*0.08;let v=sin(phase)*0.35+sin(phase*2.3)*0.2+sin(phase*5.7)*0.15+sin(phase*11.1)*0.08+0.5
  ui_rect(ui,float4(s.x+float(i)*4.4,s.y+90.0-v*80.0,3.0,3.0),float4(0.1,0.8,0.5,1))}
}
def ui_pipeline(device : SDL_GPUDevice?;format : SDL_GPUTextureFormat){
 return sdl_scope(){
  var vertex : SDL_GPUShader? = device |> with_dsl_example_shader(us::forge_ui_vertex,us::forge_ui_vertex_reflect) |> sdl_use
  var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(us::forge_ui_fragment,us::forge_ui_fragment_reflect) |> sdl_use
  let info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
  let buffers <- array(SDL_GPUVertexBufferDescription(pitch=32u));var attributes : array<SDL_GPUVertexAttribute>;for(i in 0u..4u){push(attributes,SDL_GPUVertexAttribute(location=i,offset=i*8u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2))}
  var color=gpu_color_target(format);color.blend_state=SDL_GPUColorTargetBlendState(enable_blend=true,src_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA,dst_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,color_blend_op=SDL_GPUBlendOp.BLENDOP_ADD,src_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,dst_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,alpha_blend_op=SDL_GPUBlendOp.BLENDOP_ADD)
  let colors <- array(color);return <- device |> create_native_gpu_graphics_pipeline(info,buffers,attributes,colors)
 }
}
def float_bytes(values : array<float>) {
 var bytes : array<uint8>;for(value in values){let bits=uint(float_bits_to_int(value));for(i in 0u..4u){push(bytes,uint8(bits>>(i*8u)))}};return <- bytes
}
def uint_bytes(values : array<uint>) {
 var bytes : array<uint8>;for(value in values){for(i in 0u..4u){push(bytes,uint8(value>>(i*8u)))}};return <- bytes
}
def draw_ui_batch(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var ui : UiBatch;var output : SDL_GPUTexture?;width,height : uint;time : float;overlay : bool=false) : SdlStatus {
 let vb <- float_bytes(ui.vertices);let ib <- uint_bytes(ui.indices)
 if(ui.vertex_capacity<uint(length(vb))){if(ui.vb!=null){SDL_ReleaseGPUBuffer(device,ui.vb);ui.vb=null};ui.vertex_capacity=65536u;while(ui.vertex_capacity<uint(length(vb))){ui.vertex_capacity*=2u};var b=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_VERTEX,size=ui.vertex_capacity)) |> sdl_try;ui.vb=b}
 if(ui.index_capacity<uint(length(ib))){if(ui.ib!=null){SDL_ReleaseGPUBuffer(device,ui.ib);ui.ib=null};ui.index_capacity=65536u;while(ui.index_capacity<uint(length(ib))){ui.index_capacity*=2u};var b=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_INDEX,size=ui.index_capacity)) |> sdl_try;ui.ib=b}
 upload_bytes(device,ui.vb,vb) |> sdl_try;upload_bytes(device,ui.ib,ib) |> sdl_try
 var projection : float4x4;projection[0].x=2.0/float(width);projection[1].y=-2.0/float(height);projection[2].z=1.0;projection[3]=float4(-1,1,0,1)
 push_gpu_dsl_vertex_uniform(command,0u,us::UiProjection(matrix=projection)) |> sdl_try
 let targets <- array(attachment(output,overlay,float4(0.02,0.02,0.03,1)))
 return with_native_gpu_render_pass(command,targets) $(var pass_){SDL_BindGPUGraphicsPipeline(pass_,ui.pipeline_);let buffers <- array(SDL_GPUBufferBinding(buffer=ui.vb));sdl_status(SDL_BindGPUVertexBuffersArray(pass_,0u,buffers),"Bind UI vertices") |> sdl_try;SDL_BindGPUIndexBufferRef(pass_,SDL_GPUBufferBinding(buffer=ui.ib),SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT);var images <- array(ui.atlas);bind_images(pass_,images,ui.sampler) |> sdl_try;SDL_DrawGPUIndexedPrimitives(pass_,uint(length(ui.indices)),1u,0u,0,0u);return sdl_ok()}
}
def draw_ui(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var ui : UiBatch;var output : SDL_GPUTexture?;width,height : uint;time : float) : SdlStatus {make_ui(ui,time);return draw_ui_batch(device,command,ui,output,width,height,time)}

def run_ui(smoke : bool) : int {
 return with_lesson_window(28) $(device,window){
  var ui=UiBatch(glyphs=ui_glyphs());ui.windows[0]=float2(20,20);ui.windows[1]=float2(340,20);ui.windows[2]=float2(700,20);ui.windows[3]=float2(700,460)
  defer(){if(ui.vb!=null){SDL_ReleaseGPUBuffer(device,ui.vb)};if(ui.ib!=null){SDL_ReleaseGPUBuffer(device,ui.ib)};if(ui.atlas!=null){SDL_ReleaseGPUTexture(device,ui.atlas)};if(ui.sampler!=null){SDL_ReleaseGPUSampler(device,ui.sampler)};if(ui.pipeline_!=null){SDL_ReleaseGPUGraphicsPipeline(device,ui.pipeline_)}}
  var p=ui_pipeline(device,SDL_GetGPUSwapchainTextureFormat(device,window)) |> sdl_try;ui.pipeline_=p
  var atlas=SDL_CreateGPUTextureRef(device,gpu_texture(256u,128u,SDL_GPUTextureFormat.TEXTUREFORMAT_R8_UNORM,SDL_GPU_TEXTUREUSAGE_SAMPLER));if(atlas==null){return err(sdl_error("Create UI atlas"),type<SdlUnit>)};ui.atlas=atlas
  var sampler=SDL_CreateGPUSamplerRef(device,gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR));if(sampler==null){return err(sdl_error("UI font sampler"),type<SdlUnit>)};ui.sampler=sampler
  let bytes <- load_file(asset("extended_font.r8")) |> sdl_try
  sdl_scope(){
   var transfer : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD,size=32768u)) |> sdl_use
   sdl_status(SDL_WriteGPUTransferBufferBytes(device,transfer,32768u,0u,bytes,false),"UI R8 atlas bytes") |> sdl_try
   return with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){with_native_gpu_copy_pass(command) $(var pass_){SDL_UploadToGPUTextureRef(pass_,SDL_GPUTextureTransferInfo(transfer_buffer=transfer,pixels_per_row=256u,rows_per_layer=128u),SDL_GPUTextureRegion(texture=atlas,w=256u,h=128u,d=1u),false);return sdl_ok()} |> sdl_try;return native_gpu_submit(command)}
  } |> sdl_try
  sdl_status(SDL_StartTextInput(window),"Start UI text input") |> sdl_try
  {defer(){SDL_StopTextInput(window)}
   var running=true;var frames=0;let start=SDL_GetTicks()
   let capture_path=hint_string("DASSDL3_FORGE_CAPTURE") |> unwrap_or("")
   if(capture_path!=""){var state=LessonState();return lesson_capture(device,window,state,capture_path) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){if(!state.effect){ui.counter=7;ui.slider=.8;ui.checked=false};return draw_ui(device,command,ui,target,width,height,state.time)}}
   while(running){ui.pressed=false;ui.released=false;ui.delta=float2(0)
    for(event in poll_events()){
     if(should_close(event,window)){running=false}
     match(event){if(SdlEvent(mouse_motion=$v(m))){ui.mouse=m.position;ui.delta+=m.delta}
      if(SdlEvent(mouse_button_down=$v(m))){if(m.button==uint8(SDL_BUTTON_LEFT)){ui.down=true;ui.pressed=true;ui.mouse=m.position}}
      if(SdlEvent(mouse_button_up=$v(m))){if(m.button==uint8(SDL_BUTTON_LEFT)){ui.down=false;ui.released=true;ui.mouse=m.position}}
      if(SdlEvent(text_input=$v(t))){if(ui.focus && length(ui.text)<120){ui.text+="{t.text}"}}
      if(SdlEvent(key_down=$v(k))){if(ui.focus && k.keycode==SDLK_BACKSPACE && length(ui.text)>0){ui.text=slice(ui.text,0,length(ui.text)-1)}}
      if(_){} }
    }
    if(!running){break}
    let time=smoke ? 0.0 : float(SDL_GetTicks()-start)*0.001
    with_native_gpu_swapchain(device,window) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return draw_ui(device,command,ui,target,width,height,time)} |> sdl_try
    frames++;if(smoke && frames>=3){break};SDL_Delay(16u)
   }
   return sdl_status(SDL_WaitForGPUIdle(device),"Wait UI GPU")
  }
 }
}

def with_forge_ui(device : SDL_GPUDevice?;format : SDL_GPUTextureFormat;body : block<(var ui : UiBatch) : SdlStatus>) : SdlStatus {
  var ui=UiBatch(glyphs=ui_glyphs());ui.windows[0]=float2(20,20);ui.windows[1]=float2(340,20);ui.windows[2]=float2(700,20);ui.windows[3]=float2(700,460)
  defer(){if(ui.vb!=null){SDL_ReleaseGPUBuffer(device,ui.vb)};if(ui.ib!=null){SDL_ReleaseGPUBuffer(device,ui.ib)};if(ui.atlas!=null){SDL_ReleaseGPUTexture(device,ui.atlas)};if(ui.sampler!=null){SDL_ReleaseGPUSampler(device,ui.sampler)};if(ui.pipeline_!=null){SDL_ReleaseGPUGraphicsPipeline(device,ui.pipeline_)}}
  var p=ui_pipeline(device,format) |> sdl_try;ui.pipeline_=p
  var atlas=SDL_CreateGPUTextureRef(device,gpu_texture(256u,128u,SDL_GPUTextureFormat.TEXTUREFORMAT_R8_UNORM,SDL_GPU_TEXTUREUSAGE_SAMPLER));if(atlas==null){return err(sdl_error("Create UI atlas"),type<SdlUnit>)};ui.atlas=atlas
  var sampler=SDL_CreateGPUSamplerRef(device,gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR));if(sampler==null){return err(sdl_error("UI font sampler"),type<SdlUnit>)};ui.sampler=sampler
  let bytes <- load_file(asset("extended_font.r8")) |> sdl_try
  sdl_scope(){
   var transfer : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD,size=32768u)) |> sdl_use
   sdl_status(SDL_WriteGPUTransferBufferBytes(device,transfer,32768u,0u,bytes,false),"UI R8 atlas bytes") |> sdl_try
   return with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){with_native_gpu_copy_pass(command) $(var pass_){SDL_UploadToGPUTextureRef(pass_,SDL_GPUTextureTransferInfo(transfer_buffer=transfer,pixels_per_row=256u,rows_per_layer=128u),SDL_GPUTextureRegion(texture=atlas,w=256u,h=128u,d=1u),false);return sdl_ok()} |> sdl_try;return native_gpu_submit(command)}
  } |> sdl_try
 return body(ui)
}

def sample_ui_mouse(var ui : UiBatch) {
 var position : float2;let buttons=SDL_GetMouseStateRef(position.x,position.y);let down=(buttons&SDL_BUTTON_LMASK)!=0u
 ui.pressed=down && !ui.down;ui.released=!down && ui.down;ui.delta=position-ui.mouse;ui.mouse=position;ui.down=down
}
