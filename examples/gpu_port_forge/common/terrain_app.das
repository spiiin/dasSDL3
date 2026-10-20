options gen2
module terrain_app shared public
require animation_app public
require ui_app public
require terrain_shaders as ts
require hdr_shaders as hs
require dassdl3/sdl3_shader_storage
require raw_bytes
require daslib/math_bits
require daslib/defer

def terrain_hash(seed : uint) : uint {var s=(seed^61u)^(seed>>16u);s*=9u;s=s^(s>>4u);s*=0x27d4eb2du;return s^(s>>15u)}

struct TerrainRender {
 height,depth,shadow,atlas,bake_depth : SDL_GPUTexture?
 sampler_ : SDL_GPUSampler?
 terrain_pipeline,terrain_wire,terrain_shadow,plant_pipeline,plant_wire,plant_shadow,billboard,grass_pipeline,grass_wire : SDL_GPUGraphicsPipeline?
 grids,blades : array<MeshBuffers>
 trunk,crown,cross,billboard_mesh : MeshBuffers
 heights : array<float>
 trees : array<ts::PlantInstance>
 near_buffer,far_buffer : SDL_GPUBuffer?
 grass_buffers : array<SDL_GPUBuffer?>
 near_count,far_count : uint
 grass_counts : uint[4]
 size : uint2
 half_extent : float=20.0
 height_scale : float=8.0
}

def terrain_pipeline(device : SDL_GPUDevice?;format : SDL_GPUTextureFormat;vs,vr,access,fs,fr : array<uint>;shadow : bool=false;wire : bool=false) {
 return sdl_scope(){
  var vertex : SDL_GPUShader? = device |> with_deformation_shader(vs,vr,access) |> sdl_use
  var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(fs,fr) |> sdl_use
  var info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST,rasterizer_state=SDL_GPURasterizerState(enable_depth_clip=true,fill_mode=wire ? SDL_GPUFillMode.FILLMODE_LINE : SDL_GPUFillMode.FILLMODE_FILL))
  info <- info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL) |> depth_write(true)
  if(shadow){info.rasterizer_state.depth_bias_constant_factor=1.0;info.rasterizer_state.depth_bias_slope_factor=1.5}
  let buffers <- array(SDL_GPUVertexBufferDescription(pitch=32u));let attributes <- array(SDL_GPUVertexAttribute(format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),SDL_GPUVertexAttribute(location=1u,offset=12u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),SDL_GPUVertexAttribute(location=2u,offset=24u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2))
  var colors : array<SDL_GPUColorTargetDescription>;if(!shadow){push(colors,gpu_color_target(format))}
  return <- device |> create_native_gpu_graphics_pipeline(info,buffers,attributes,colors)
 }
}

def release_terrain(device : SDL_GPUDevice?;var r : TerrainRender){
 for(p in fixed_array(r.terrain_pipeline,r.terrain_wire,r.terrain_shadow,r.plant_pipeline,r.plant_wire,r.plant_shadow,r.billboard,r.grass_pipeline,r.grass_wire)){if(p!=null){SDL_ReleaseGPUGraphicsPipeline(device,p)}}
 for(t in fixed_array(r.height,r.depth,r.shadow,r.atlas,r.bake_depth)){if(t!=null){SDL_ReleaseGPUTexture(device,t)}}
 for(b in fixed_array(r.near_buffer,r.far_buffer)){if(b!=null){SDL_ReleaseGPUBuffer(device,b)}};for(b in r.grass_buffers){SDL_ReleaseGPUBuffer(device,b)}
 for(mesh in r.grids){release(device,mesh)};for(mesh in r.blades){release(device,mesh)};release(device,r.trunk);release(device,r.crown);release(device,r.cross);release(device,r.billboard_mesh)
 if(r.sampler_!=null){SDL_ReleaseGPUSampler(device,r.sampler_)}
}

def height_at(r : TerrainRender;x,z : float) : float {
 let uv=clamp(float2(x,z)/(r.half_extent*2.0)+float2(.5),float2(0),float2(1))*255.0
 let ix=min(254,int(uv.x));let iz=min(254,int(uv.y));let f=uv-float2(float(ix),float(iz))
 return ((r.heights[iz*256+ix]*(1.0-f.x)+r.heights[iz*256+ix+1]*f.x)*(1.0-f.y)+(r.heights[(iz+1)*256+ix]*(1.0-f.x)+r.heights[(iz+1)*256+ix+1]*f.x)*f.y)*r.height_scale
}
def slope_at(r : TerrainRender;x,z : float) : float {let d=2.0*r.half_extent/255.0;let dx=(height_at(r,x+d,z)-height_at(r,x-d,z))/(2.0*d);let dz=(height_at(r,x,z+d)-height_at(r,x,z-d))/(2.0*d);return sqrt(dx*dx+dz*dz)}
def tree_instances(r : TerrainRender;lesson : int){
 var result : array<ts::PlantInstance>
 for(zi in 1..51){for(xi in 1..51){let z=zi*5;let x=xi*5;
  let hash=terrain_hash(uint(z*256+x))
  let fx=float(x)+(float(hash&255u)/255.0-.5)*5.0;let fz=float(z)+(float((hash>>8u)&255u)/255.0-.5)*5.0
  let px=fx/255.0*(2.0*r.half_extent)-r.half_extent;let pz=fz/255.0*(2.0*r.half_extent)-r.half_extent
  if(slope_at(r,px,pz)>.4 || length(result)>=2000){continue}
  let green=.5+float((hash>>16u)&255u)/255.0*.3;let color=lesson==49 ? float4(.5+green*.4,.25+green*.4,.12,1.0) : float4(.2,green,.15,1.0)
  push(result,ts::PlantInstance(position=float4(px,height_at(r,px,pz),pz,.8+float(hash&255u)/255.0*.4),color=color))
 }};return <- result
}

def upload_height(device : SDL_GPUDevice?;var r : TerrainRender;lesson : int) : SdlStatus {
 let bytes <- load_file(asset("terrain_{lesson}.f32")) |> sdl_try;if(length(bytes)!=256*256*4){return failure("Terrain heightmap","Expected 256x256 R32_FLOAT")}
 resize(r.heights,256*256);for(i in 0..length(r.heights)){r.heights[i]=read_float(bytes,i*4)}
 var image=device |> create_advanced_texture(gpu_texture(256u,256u,SDL_GPUTextureFormat.TEXTUREFORMAT_R32_FLOAT,SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_try;r.height=image
 return sdl_scope(){
  var transfer : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD,size=256u*256u*4u)) |> sdl_use
  sdl_status(SDL_WriteGPUTransferBufferBytes(device,transfer,256u*256u*4u,0u,bytes,false),"Heightmap transfer") |> sdl_try
  return with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){with_native_gpu_copy_pass(command) $(var pass_ : SDL_GPUCopyPass?&){SDL_UploadToGPUTextureRef(pass_,SDL_GPUTextureTransferInfo(transfer_buffer=transfer,pixels_per_row=256u,rows_per_layer=256u),SDL_GPUTextureRegion(texture=r.height,w=256u,h=256u,d=1u),false);return sdl_ok()} |> sdl_try;return native_gpu_submit(command)}
 }
}

def terrain_light_matrix(r : TerrainRender) : float4x4 {
 let size=r.half_extent*1.6;var p : float4x4;p[0].x=1.0/size;p[1].y=1.0/size;p[2].z=-1.0/160.0;p[3]=float4(0.0,0.0,0.0,1.0)
 return p*look_at_rh(normalize(float3(.5,.8,.3))*80.0,float3(0),float3(0,1,0))
}
def plant_draw(command : SDL_GPUCommandBuffer?;pass_ : SDL_GPURenderPass?;pipeline_ : SDL_GPUGraphicsPipeline?;var mesh : MeshBuffers;var instances : SDL_GPUBuffer?;count : uint;vp,light : float4x4;eye : float3;mode,time,wind : float;color : float4) : SdlStatus {
 if(count==0u){return sdl_ok()};SDL_BindGPUGraphicsPipeline(pass_,pipeline_)
 push_gpu_dsl_vertex_uniform(command,0u,ts::PlantView(vp=vp,light=light,eye=float4(eye,1.0),mode=float4(mode,0.0,0.0,0.0),wind=float4(time,wind,0.0,0.0))) |> sdl_try
 push_gpu_dsl_fragment_uniform(command,0u,ts::PlantColor(value=color)) |> sdl_try
 let storage <- array(instances);sdl_status(SDL_BindGPUVertexStorageBuffersArray(pass_,0u,storage),"Bind plant instances") |> sdl_try
 return draw_mesh(pass_,mesh,count)
}

def bake_imposters(device : SDL_GPUDevice?;var r : TerrainRender) : SdlStatus {
 var instance <- array(ts::PlantInstance(position=float4(0,0,0,1),color=float4(1)))
 let bytes <- gpu_dsl_storage_bytes(instance) |> sdl_try;upload_bytes(device,r.near_buffer,bytes) |> sdl_try
 return with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){
  let colors <- array(attachment(r.atlas,false,float4(0)));let depth=SDL_GPUDepthStencilTargetInfo(texture=r.bake_depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
  with_native_gpu_render_pass(command,colors,depth) $(var pass_ : SDL_GPURenderPass?&){
   for(frame in 0..8){let angle=float(frame)*6.283185307/8.0;let eye=float3(sin(angle)*5.0,.65,cos(angle)*5.0)
    var p : float4x4;p[0].x=1.0/.55;p[1].y=1.0/.70;p[2].z=-1.0/10.0;p[3].w=1.0;let vp=p*look_at_rh(eye,float3(0,.65,0),float3(0,1,0))
    SDL_SetGPUViewportRef(pass_,SDL_GPUViewport(x=float(frame%4*256),y=float(frame/4*256),w=256.0,h=256.0,max_depth=1.0))
    plant_draw(command,pass_,r.plant_pipeline,r.trunk,r.near_buffer,1u,vp,vp,eye,0.0,0.0,0.0,float4(.55,.40,.25,1.0)) |> sdl_try
    plant_draw(command,pass_,r.plant_pipeline,r.crown,r.near_buffer,1u,vp,vp,eye,0.0,0.0,0.0,float4(.85,.85,.85,1.0)) |> sdl_try
   };return sdl_ok()
  } |> sdl_try;return native_gpu_submit(command)
 }
}

def update_trees(device : SDL_GPUDevice?;var r : TerrainRender;state : LessonState;lesson : int) : SdlStatus {
 var near_,far_ : array<ts::PlantInstance>
 for(tree in r.trees){var instance=tree
  if(lesson==49){let distance=length(tree.position.xyz-state.eye);let alpha=state.effect ? clamp((distance-13.0)/6.0,0.0,1.0) : 0.0
   if(alpha>0.0){var billboard=tree;billboard.color.a=alpha;let d=state.eye-tree.position.xyz;var angle=atan2(d.x,d.z);if(angle<0.0){angle+=6.283185307};billboard.extra.y=float(int(floor(angle/6.283185307*8.0+.5))%8);push(far_,billboard)}
   instance.color.a=1.0-alpha;if(alpha>=1.0){continue}
  };push(near_,instance)
 };r.near_count=uint(length(near_));r.far_count=uint(length(far_))
 if(r.near_count>0u){let bytes <- gpu_dsl_storage_bytes(near_) |> sdl_try;upload_bytes(device,r.near_buffer,bytes) |> sdl_try}
 if(r.far_count>0u){let bytes <- gpu_dsl_storage_bytes(far_) |> sdl_try;upload_bytes(device,r.far_buffer,bytes) |> sdl_try};return sdl_ok()
}

def grass_instances(r : TerrainRender;state : LessonState;ring : int;vp : float4x4) {
 let mins=fixed_array(0.0,10.0,25.0,50.0);let maxs=fixed_array(10.0,25.0,50.0,80.0);let steps=fixed_array(.25,.5,1.0,2.0);let step=steps[ring];let radius=maxs[ring]
 var instances : array<ts::PlantInstance>;let low=int2(floor((state.eye.xz-float2(radius))/step));let high=int2(ceil((state.eye.xz+float2(radius))/step))
 for(z in range(low.y,high.y)){for(x in range(low.x,high.x)){
  let hash=terrain_hash(uint(x)*1973u+uint(z)*9277u+42u);let px=float(x)*step;let pz=float(z)*step
  if(abs(px)>r.half_extent || abs(pz)>r.half_extent || length(instances)>=16384){continue};let distance=length(float2(px,pz)-state.eye.xz)
  if(distance<mins[ring] || distance>=maxs[ring] || slope_at(r,px,pz)>.35){continue}
  let py=height_at(r,px,pz);let clip=vp*float4(px,py+.3,pz,1.0);if(clip.w<0.0 || abs(clip.x)>clip.w*1.2 || abs(clip.y)>clip.w*1.2 || clip.z < -0.5 || clip.z>clip.w+1.0){continue}
  let fade=clamp((maxs[ring]-distance)/3.0,0.0,1.0);let tint=float(hash&255u)/255.0
  push(instances,ts::PlantInstance(position=float4(px,py,pz,1.0),color=float4(.15+tint*.1,.3+tint*.25,.06,fade),extra=float4(float(hash%6283u)*.001,0.0,.35+tint*.2,0.0)))
 }};return <- instances
}

def terrain_meshes(command : SDL_GPUCommandBuffer?;pass_ : SDL_GPURenderPass?;var r : TerrainRender;state : LessonState;vp,light : float4x4;lesson : int;shadow,wire : bool) : SdlStatus {
 SDL_BindGPUGraphicsPipeline(pass_,shadow ? r.terrain_shadow : (wire ? r.terrain_wire : r.terrain_pipeline))
 var image <- array(SDL_GPUTextureSamplerBinding(texture=r.height,sampler=r.sampler_));sdl_status(SDL_BindGPUVertexSamplersArray(pass_,0u,image),"Terrain height vertex") |> sdl_try
 let images <- array(SDL_GPUTextureSamplerBinding(texture=r.height,sampler=r.sampler_),SDL_GPUTextureSamplerBinding(texture=r.shadow,sampler=r.sampler_));if(!shadow){sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Terrain height / shadow") |> sdl_try}
 push_gpu_dsl_fragment_uniform(command,0u,ts::TerrainLight(eye=float4(state.eye,1.0),light=float4(.5,.8,.3,0.0),settings=float4(r.height_scale,r.half_extent,.7,0.0))) |> sdl_try
 if(lesson!=50){push_gpu_dsl_vertex_uniform(command,0u,ts::TerrainView(vp=vp,light=light,terrain=float4(r.half_extent,r.height_scale,0.0,0.0))) |> sdl_try;return draw_mesh(pass_,r.grids[0])}
 let distances=fixed_array(15.0,30.0,50.0,9999.0);let resolutions=fixed_array(64,32,16,8)
 for(z in 0..8){for(x in 0..8){let center=float2(float(x)*10.0-35.0,float(z)*10.0-35.0);let distance=length(center-state.eye.xz);var lod=0;for(i in 0..3){if(distance>distances[i]){lod=i+1}}
  let morph=lod<3 ? clamp((distance-distances[lod]*.8)/(distances[lod]*.2),0.0,1.0) : 0.0
  push_gpu_dsl_vertex_uniform(command,0u,ts::TerrainView(vp=vp,light=light,terrain=float4(r.half_extent,r.height_scale,0.0,0.0),tile=float4(center.x,center.y,10.0,1.0),morph=float4(morph,10.0/float(resolutions[lod]/2)/80.0,0.0,0.0))) |> sdl_try
  draw_mesh(pass_,r.grids[lod]) |> sdl_try
 }};return sdl_ok()
}

def terrain_plants(command : SDL_GPUCommandBuffer?;pass_ : SDL_GPURenderPass?;var r : TerrainRender;state : LessonState;vp,light : float4x4;lesson : int;shadow,wire : bool) : SdlStatus {
 if(lesson==50){for(ring in 0..(shadow ? 2 : 4)){plant_draw(command,pass_,shadow ? r.plant_shadow : (wire ? r.grass_wire : r.grass_pipeline),r.blades[ring],r.grass_buffers[ring],r.grass_counts[ring],vp,light,state.eye,2.0,state.time,state.effect ? .5 : 0.0,float4(1)) |> sdl_try};return sdl_ok()}
 if(lesson==49){
  plant_draw(command,pass_,shadow ? r.plant_shadow : (wire ? r.plant_wire : r.plant_pipeline),r.trunk,r.near_buffer,r.near_count,vp,light,state.eye,0.0,0.0,0.0,float4(.55,.4,.25,1)) |> sdl_try
  plant_draw(command,pass_,shadow ? r.plant_shadow : (wire ? r.plant_wire : r.plant_pipeline),r.crown,r.near_buffer,r.near_count,vp,light,state.eye,0.0,0.0,0.0,float4(.85,.85,.85,1)) |> sdl_try
  if(!shadow && r.far_count>0u){let images <- array(SDL_GPUTextureSamplerBinding(texture=r.atlas,sampler=r.sampler_));sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Imposter atlas") |> sdl_try;plant_draw(command,pass_,r.billboard,r.billboard_mesh,r.far_buffer,r.far_count,vp,light,state.eye,1.0,0.0,0.0,float4(1)) |> sdl_try}
 }else{if(!shadow){let images <- array(SDL_GPUTextureSamplerBinding(texture=r.atlas,sampler=r.sampler_));sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Tree alpha mask") |> sdl_try;plant_draw(command,pass_,r.billboard,r.cross,r.near_buffer,r.near_count,vp,light,state.eye,0.0,0.0,0.0,float4(1)) |> sdl_try}}
 return sdl_ok()
}

def render_terrain(device : SDL_GPUDevice?;command : SDL_GPUCommandBuffer?;var r : TerrainRender;var output : SDL_GPUTexture?;width,height : uint;state : LessonState;lesson : int) : SdlStatus {
 if(r.size!=uint2(width,height)){if(r.depth!=null){SDL_ReleaseGPUTexture(device,r.depth);r.depth=null};var image=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;r.depth=image;r.size=uint2(width,height)}
 let vp=camera_matrix(lesson==50 ? max(1u,width/2u) : width,height,state.eye,state.target);let light=terrain_light_matrix(r)
 if(lesson==50){for(ring in 0..4){let instances <- grass_instances(r,state,ring,vp);r.grass_counts[ring]=uint(length(instances));if(length(instances)>0){let bytes <- gpu_dsl_storage_bytes(instances) |> sdl_try;upload_bytes(device,r.grass_buffers[ring],bytes) |> sdl_try}}}else{update_trees(device,r,state,lesson) |> sdl_try}
 let empty : array<SDL_GPUColorTargetInfo>;let shadow_depth=SDL_GPUDepthStencilTargetInfo(texture=r.shadow,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 with_native_gpu_render_pass(command,empty,shadow_depth) $(var pass_ : SDL_GPURenderPass?&){terrain_meshes(command,pass_,r,state,light,light,lesson,true,false) |> sdl_try;return terrain_plants(command,pass_,r,state,light,light,lesson,true,false)} |> sdl_try
 let colors <- array(attachment(output,false,float4(.15,.2,.3,1)));let depth=SDL_GPUDepthStencilTargetInfo(texture=r.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)
 return with_native_gpu_render_pass(command,colors,depth) $(var pass_ : SDL_GPURenderPass?&){for(view in 0..(lesson==50 ? 2 : 1)){
  if(lesson==50){let half_=width/2u;SDL_SetGPUViewportRef(pass_,SDL_GPUViewport(x=float(uint(view)*half_),w=float(half_),h=float(height),max_depth=1.0));SDL_SetGPUScissorRef(pass_,SDL_Rect(x=view*int(half_),w=int(half_),h=int(height)))}
  terrain_meshes(command,pass_,r,state,vp,light,lesson,false,view==1) |> sdl_try;terrain_plants(command,pass_,r,state,vp,light,lesson,false,view==1) |> sdl_try
 };return sdl_ok()}
}

def run_terrain(lesson : int;smoke : bool) : int {
 return with_lesson_window(lesson) $(device,window){
  var r=TerrainRender();defer(){release_terrain(device,r)};if(lesson==50){r.half_extent=40.0;r.height_scale=4.0}
  upload_height(device,r,lesson) |> sdl_try
  var sampler_=SDL_CreateGPUSamplerRef(device,gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR));if(sampler_==null){return err(sdl_error("Terrain sampler"),type<SdlUnit>)};r.sampler_=sampler_
  var image=device |> create_advanced_texture(gpu_texture(2048u,2048u,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_try;r.shadow=image
  let names=lesson==50 ? fixed_array("terrain_grid_64","terrain_grid_32","terrain_grid_16","terrain_grid_8") : fixed_array("terrain_grid_128","terrain_grid_128","terrain_grid_128","terrain_grid_128")
  for(name in names){var mesh=load_mesh(device,name) |> sdl_try;push(r.grids,mesh)}
  for(segments in fixed_array(4,3,2,1)){var mesh=load_mesh(device,"terrain_blade_{segments}") |> sdl_try;push(r.blades,mesh)}
  var mesh=load_mesh(device,"terrain_trunk") |> sdl_try;r.trunk=mesh;mesh=load_mesh(device,"terrain_crown") |> sdl_try;r.crown=mesh;mesh=load_mesh(device,"terrain_cross") |> sdl_try;r.cross=mesh;mesh=load_mesh(device,"terrain_billboard") |> sdl_try;r.billboard_mesh=mesh
  var buffer=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,size=2000u*48u)) |> sdl_try;r.near_buffer=buffer
  buffer=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,size=2000u*48u)) |> sdl_try;r.far_buffer=buffer
  for(i in 0..4){buffer=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,size=16384u*48u)) |> sdl_try;push(r.grass_buffers,buffer)}
  let format=SDL_GetGPUSwapchainTextureFormat(device,window);let empty : array<uint>
  var p=terrain_pipeline(device,format,ts::forge_terrain_vertex,ts::forge_terrain_vertex_reflect,empty,ts::forge_terrain_fragment,ts::forge_terrain_fragment_reflect) |> sdl_try;r.terrain_pipeline=p
  p=terrain_pipeline(device,format,ts::forge_terrain_vertex,ts::forge_terrain_vertex_reflect,empty,ts::forge_terrain_fragment,ts::forge_terrain_fragment_reflect,false,true) |> sdl_try;r.terrain_wire=p
  p=terrain_pipeline(device,format,ts::forge_terrain_shadow_vertex,ts::forge_terrain_shadow_vertex_reflect,empty,hs::shadow_fragment,hs::shadow_fragment_reflect,true) |> sdl_try;r.terrain_shadow=p
  p=terrain_pipeline(device,lesson==49 ? SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB : format,ts::forge_plant_vertex,ts::forge_plant_vertex_reflect,ts::forge_plant_vertex_access,ts::forge_plant_fragment,ts::forge_plant_fragment_reflect) |> sdl_try;r.plant_pipeline=p
  p=terrain_pipeline(device,format,ts::forge_plant_vertex,ts::forge_plant_vertex_reflect,ts::forge_plant_vertex_access,ts::forge_plant_fragment,ts::forge_plant_fragment_reflect,false,true) |> sdl_try;r.plant_wire=p
  p=terrain_pipeline(device,format,ts::forge_plant_shadow_vertex,ts::forge_plant_shadow_vertex_reflect,ts::forge_plant_shadow_vertex_access,hs::shadow_fragment,hs::shadow_fragment_reflect,true) |> sdl_try;r.plant_shadow=p
  p=terrain_pipeline(device,format,ts::forge_billboard_vertex,ts::forge_billboard_vertex_reflect,ts::forge_billboard_vertex_access,ts::forge_tree_billboard_fragment,ts::forge_tree_billboard_fragment_reflect) |> sdl_try;r.billboard=p
  p=terrain_pipeline(device,format,ts::forge_grass_vertex,ts::forge_grass_vertex_reflect,ts::forge_grass_vertex_access,ts::forge_grass_fragment,ts::forge_grass_fragment_reflect) |> sdl_try;r.grass_pipeline=p
  p=terrain_pipeline(device,format,ts::forge_grass_vertex,ts::forge_grass_vertex_reflect,ts::forge_grass_vertex_access,ts::forge_grass_fragment,ts::forge_grass_fragment_reflect,false,true) |> sdl_try;r.grass_wire=p
  r.trees <- tree_instances(r,lesson)
  if(lesson==49){image=device |> create_advanced_texture(gpu_texture(1024u,512u,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_try;r.atlas=image
   image=device |> create_advanced_texture(gpu_texture(1024u,512u,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;r.bake_depth=image;bake_imposters(device,r) |> sdl_try
   // The bake target and the swapchain have independent format contracts.
   p=terrain_pipeline(device,format,ts::forge_plant_vertex,ts::forge_plant_vertex_reflect,ts::forge_plant_vertex_access,ts::forge_plant_fragment,ts::forge_plant_fragment_reflect) |> sdl_try;SDL_ReleaseGPUGraphicsPipeline(device,r.plant_pipeline);r.plant_pipeline=p
  }else{image=load_texture(device,"terrain_tree") |> sdl_try;r.atlas=image}
  var state=lesson_camera(lesson==50 ? float3(0,4,12) : float3(0,12,18),0.0,lesson==50 ? -.15 : -.45)
  print("Forge {lesson}: {length(r.trees)} slope-filtered trees.\n")
  return lesson_loop(device,window,smoke,state) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_terrain(device,command,r,target,width,height,state,lesson)}
 }
}
