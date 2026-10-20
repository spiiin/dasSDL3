options gen2
module advanced_app shared public
// Application code for Forge lessons 15-20. Not part of the public SDL module.
require forge_support public
require advanced_assets public
require advanced_shaders as ash
require advanced_lines public
require dassdl3/sdl3_window_boost
require daslib/defer
require daslib/match

struct AdvancedPart { spec : PartSpec; mesh : MeshBuffers; diffuse,normal : SDL_GPUTexture?; material : int }
struct AdvancedScene {
    parts : array<AdvancedPart>
    grid : MeshBuffers
    solid,blend,grid_pipeline,shadow_pipeline,preview,world_lines,overlay_lines : SDL_GPUGraphicsPipeline?
    sampler,shadow_sampler : SDL_GPUSampler?
    depth : SDL_GPUTexture?
    shadows : array<SDL_GPUTexture?>
    lines : SDL_GPUBuffer?
    size : uint2
    lesson : int
}
struct AdvancedSettings {
    eye,target : float3
    effect : bool = true
    normal_mode : float = 2.0
    fog_mode : float = 0.0
    preview : int = -1
    paused : bool = false
}
def advanced_defaults(lesson : int) : AdvancedSettings {
    var eye=float3(0,2,12);var yaw=0.0;var pitch=0.0
    if(lesson==15){eye=float3(-6.1,7,4.4);yaw=-50.0;pitch=-50.0}
    elif(lesson==16){eye=float3(0,2.1,5.5)}
    elif(lesson==17){eye=float3(0,1.5,3.5)}
    elif(lesson==19){eye=float3(0,4,12)}
    elif(lesson==20){eye=float3(-6,5,6);yaw=-40.0;pitch=-25.0}
    yaw*=0.01745329252;pitch*=0.01745329252
    return AdvancedSettings(eye=eye,target=eye+float3(-sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))*10.0)
}
def advanced_vp(width,height : uint; settings : AdvancedSettings; lesson : int) : float4x4 {
    if(lesson!=19){return camera_matrix(width,height,settings.eye,settings.target)}
    var p : float4x4;p[0].x=1.7320508*float(height)/float(width);p[1].y=1.7320508
    p[2]=float4(0,0,-200.0/199.9,-1);p[3].z=-20.0/199.9
    return p*look_at_rh(settings.eye,settings.target,float3(0,1,0))
}
def cascade_splits : float3 {
    var splits : float3
    for(i in 0..3){let p=float(i+1)/3.0;splits[i]=0.5*(0.1*pow(1000.0,p)+0.1+99.9*p)}
    return splits
}
def cascade_matrix(settings : AdvancedSettings; aspect,near_,far_ : float) : float4x4 {
    let f=normalize(settings.target-settings.eye);let r=normalize(cross(f,float3(0,1,0)));let u=cross(r,f)
    var corners : float3[8];var center=float3(0)
    for(z in 0..2){for(y in 0..2){for(x in 0..2){
        let d=z==0 ? near_ : far_
        let c=settings.eye+f*d+r*(float(x*2-1)*d*aspect/1.7320508)+u*(float(y*2-1)*d/1.7320508)
        corners[z*4+y*2+x]=c;center+=c/8.0
    }}}
    let view=look_at_rh(center+normalize(float3(1,1,0.5))*50.0,center,float3(0,1,0))
    var lo=float3(1e30);var hi=float3(-1e30)
    for(c in corners){let lp=view*float4(c,1.0);lo=min(lo,lp.xyz);hi=max(hi,lp.xyz)}
    lo.z-=50.0
    let n=-hi.z;let f_=-lo.z
    var p : float4x4
    p[0].x=2.0/(hi.x-lo.x);p[1].y=2.0/(hi.y-lo.y);p[2].z=-1.0/(f_-n)
    p[3]=float4(-(hi.x+lo.x)/(hi.x-lo.x),-(hi.y+lo.y)/(hi.y-lo.y),-n/(f_-n),1.0)
    return p*view
}
def advanced_pipeline(device : SDL_GPUDevice?; vs,vr,fs,fr : array<uint>; format : SDL_GPUTextureFormat; stride : uint=32u; blend : bool=false; shadow : bool=false; lines : bool=false; overlay : bool=false; cull : bool=false) {
    return sdl_scope(){
        var vertex : SDL_GPUShader? = device |> with_dsl_example_shader(vs,vr) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(fs,fr) |> sdl_use
        var info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,primitive_type=lines ? SDL_GPUPrimitiveType.PRIMITIVETYPE_LINELIST : SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST,rasterizer_state=SDL_GPURasterizerState(enable_depth_clip=true,front_face=SDL_GPUFrontFace.FRONTFACE_COUNTER_CLOCKWISE))
        info <- info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL) |> depth_write(!blend)
        if(overlay){info.depth_stencil_state.enable_depth_test=false;info.depth_stencil_state.enable_depth_write=false}
        if(cull){info.rasterizer_state.cull_mode=SDL_GPUCullMode.CULLMODE_BACK}
        if(shadow){info.rasterizer_state.cull_mode=SDL_GPUCullMode.CULLMODE_FRONT;info.rasterizer_state.depth_bias_constant_factor=1.0;info.rasterizer_state.depth_bias_slope_factor=1.5}
        var buffers : array<SDL_GPUVertexBufferDescription>;var attributes : array<SDL_GPUVertexAttribute>
        if(stride!=0u){
            buffers <- array(SDL_GPUVertexBufferDescription(pitch=stride))
            attributes <- array(SDL_GPUVertexAttribute(format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3))
            if(lines){push(attributes,SDL_GPUVertexAttribute(location=1u,offset=12u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4))}
            elif(!shadow){
                push(attributes,SDL_GPUVertexAttribute(location=1u,offset=12u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3))
                push(attributes,SDL_GPUVertexAttribute(location=2u,offset=24u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2))
                if(stride==48u){push(attributes,SDL_GPUVertexAttribute(location=3u,offset=32u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4))}
            }
        }
        var colors : array<SDL_GPUColorTargetDescription>
        if(!shadow){
            var target=gpu_color_target(format)
            if(blend){target.blend_state=SDL_GPUColorTargetBlendState(enable_blend=true,src_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA,dst_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,color_blend_op=SDL_GPUBlendOp.BLENDOP_ADD,src_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,dst_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,alpha_blend_op=SDL_GPUBlendOp.BLENDOP_ADD)}
            push(colors,target)
        }
        return <- device |> create_native_gpu_graphics_pipeline(info,buffers,attributes,colors)
    }
}
def release(device : SDL_GPUDevice?; var scene : AdvancedScene) {
    for(part in scene.parts){release(device,part.mesh);if(part.diffuse!=null){SDL_ReleaseGPUTexture(device,part.diffuse)};if(part.normal!=null){SDL_ReleaseGPUTexture(device,part.normal)}}
    release(device,scene.grid)
    for(p in fixed_array(scene.solid,scene.blend,scene.grid_pipeline,scene.shadow_pipeline,scene.preview,scene.world_lines,scene.overlay_lines)){if(p!=null){SDL_ReleaseGPUGraphicsPipeline(device,p)}}
    for(t in scene.shadows){if(t!=null){SDL_ReleaseGPUTexture(device,t)}}
    if(scene.depth!=null){SDL_ReleaseGPUTexture(device,scene.depth)}
    if(scene.sampler!=null){SDL_ReleaseGPUSampler(device,scene.sampler)}
    if(scene.shadow_sampler!=null){SDL_ReleaseGPUSampler(device,scene.shadow_sampler)}
    if(scene.lines!=null){SDL_ReleaseGPUBuffer(device,scene.lines)}
}
def add_parts(var dst : array<AdvancedPart>; specs : array<PartSpec>; placement : float4x4; material : int=0) {
    for(spec in specs){var p=AdvancedPart(spec=spec,material=material);p.spec.model=placement*spec.model;push(dst,p)}
}
def with_advanced(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; lesson : int; body : block<(var scene : AdvancedScene) : SdlStatus>) : SdlStatus {
    var scene=AdvancedScene(lesson=lesson)
    defer(){release(device,scene)}
    if(lesson==16){let specs <- blending_parts();add_parts(scene.parts,specs,identity_matrix())}
    elif(lesson==17){let specs <- normal_parts();add_parts(scene.parts,specs,identity_matrix())}
    elif(lesson==18){let specs <- suzanne_parts();for(i in 0..5){add_parts(scene.parts,specs,model_matrix(float3(float(i-2)*3.5,1.3,0),float3(1)),i)}}
    elif(lesson!=19){
        let truck <- truck_parts();add_parts(scene.parts,truck,identity_matrix())
        let boxes <- box_parts()
        for(i in 0..12){
            let base=i<8 ? i : (i-8)*2;let angle=float(base)*6.283185307/8.0
            let pos=float3(cos(angle)*5.0,i<8 ? 0.5 : 1.5,sin(angle)*5.0)
            add_parts(scene.parts,boxes,model_matrix(pos,float3(1),-(angle+0.3*float(base)+(i<8 ? 0.0 : 0.5))))
        }
    }
    for(part in scene.parts){
        var mesh=load_mesh(device,part.spec.mesh) |> sdl_try;part.mesh=mesh
        var diffuse=load_texture(device,part.spec.diffuse=="" ? "advanced_white" : part.spec.diffuse,false,lesson!=16 && lesson!=17) |> sdl_try;part.diffuse=diffuse
        if(lesson==17){var normal=load_texture(device,part.spec.normal=="" ? "advanced_flat" : part.spec.normal,false,false) |> sdl_try;part.normal=normal}
    }
    var sampler=SDL_CreateGPUSamplerRef(device,gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR,SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT))
    if(sampler==null){return err(sdl_error("Create Forge sampler"),type<SdlUnit>)};scene.sampler=sampler
    var grid=load_mesh(device,"advanced_plane") |> sdl_try;scene.grid=grid
    if(lesson==19){
        var p=advanced_pipeline(device,ash::debug_line_vertex,ash::debug_line_vertex_reflect,ash::debug_line_fragment,ash::debug_line_fragment_reflect,format,28u,false,false,true) |> sdl_try;scene.world_lines=p
        // Overlay still attaches the same depth target, but disables its tests/writes.
        p=advanced_pipeline(device,ash::debug_line_vertex,ash::debug_line_vertex_reflect,ash::debug_line_fragment,ash::debug_line_fragment_reflect,format,28u,false,false,true,true) |> sdl_try;scene.overlay_lines=p
        var vb=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_VERTEX,size=65536u*28u)) |> sdl_try;scene.lines=vb
    }else{
        var p=advanced_pipeline(device,lesson==15 ? ash::cascade_vertex : (lesson==17 ? ash::normal_vertex : ash::advanced_vertex),lesson==15 ? ash::cascade_vertex_reflect : (lesson==17 ? ash::normal_vertex_reflect : ash::advanced_vertex_reflect),lesson==15 ? ash::cascade_fragment : (lesson==17 ? ash::normal_fragment : (lesson==18 ? ash::material_fragment : (lesson==20 ? ash::fog_fragment : ash::blend_fragment))),lesson==15 ? ash::cascade_fragment_reflect : (lesson==17 ? ash::normal_fragment_reflect : (lesson==18 ? ash::material_fragment_reflect : (lesson==20 ? ash::fog_fragment_reflect : ash::blend_fragment_reflect))),format,lesson==17 ? 48u : 32u,false,false,false,false,lesson==15 || lesson==18 || lesson==20) |> sdl_try;scene.solid=p
        if(lesson==16){p=advanced_pipeline(device,ash::advanced_vertex,ash::advanced_vertex_reflect,ash::blend_fragment,ash::blend_fragment_reflect,format,32u,true) |> sdl_try;scene.blend=p}
        p=advanced_pipeline(device,lesson==15 ? ash::cascade_vertex : (lesson==20 ? ash::advanced_vertex : ash::advanced_grid_vertex),lesson==15 ? ash::cascade_vertex_reflect : (lesson==20 ? ash::advanced_vertex_reflect : ash::advanced_grid_vertex_reflect),lesson==15 ? ash::cascade_fragment : (lesson==20 ? ash::fog_fragment : ash::advanced_grid_fragment),lesson==15 ? ash::cascade_fragment_reflect : (lesson==20 ? ash::fog_fragment_reflect : ash::advanced_grid_fragment_reflect),format) |> sdl_try;scene.grid_pipeline=p
    }
    if(lesson==15){
        var p=advanced_pipeline(device,ash::shadow_vertex,ash::shadow_vertex_reflect,ash::shadow_fragment,ash::shadow_fragment_reflect,format,32u,false,true) |> sdl_try;scene.shadow_pipeline=p
        p=advanced_pipeline(device,ash::depth_preview_vertex,ash::depth_preview_vertex_reflect,ash::depth_preview_fragment,ash::depth_preview_fragment_reflect,format,0u,false,false,false,true) |> sdl_try;scene.preview=p
        var sampler_=SDL_CreateGPUSamplerRef(device,gpu_sampler_info(SDL_GPUFilter.FILTER_NEAREST))
        if(sampler_==null){return err(sdl_error("Create shadow sampler"),type<SdlUnit>)};scene.shadow_sampler=sampler_
        resize(scene.shadows,3)
        for(t in scene.shadows){var tex=device |> create_advanced_texture(gpu_texture(2048u,2048u,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_try;t=tex}
    }
    return body(scene)
}

def material(index : int; var f : ash::AdvancedFragment) {
    if(index==0){f.ambient=float4(0.24725,0.1995,0.0745,0);f.diffuse=float4(0.75164,0.60648,0.22648,0);f.specular=float4(0.628281,0.555802,0.366065,51.2)}
    elif(index==1){f.ambient=float4(0);f.diffuse=float4(0.5,0,0,0);f.specular=float4(0.7,0.6,0.6,32)}
    elif(index==2){f.ambient=float4(0.135,0.2225,0.1575,0);f.diffuse=float4(0.54,0.89,0.63,0);f.specular=float4(0.316228,0.316228,0.316228,12.8)}
    elif(index==3){f.ambient=float4(0.25,0.20725,0.20725,0);f.diffuse=float4(1,0.829,0.829,0);f.specular=float4(0.296648,0.296648,0.296648,11.264)}
    else{f.ambient=float4(0.25);f.diffuse=float4(0.4);f.specular=float4(0.774597,0.774597,0.774597,76.8)}
}
def fragment_defaults(lesson : int; settings : AdvancedSettings) : ash::AdvancedFragment {
    let light=lesson==15 ? float3(1,1,0.5) : ((lesson==16 || lesson==17) ? float3(0.3,0.8,0.5) : float3(0.5,1,0.5))
    return ash::AdvancedFragment(base=float4(1),light=float4(light,0.0),eye=float4(settings.eye,1.0),ambient=float4(0.15),diffuse=float4(1),specular=float4(0.4,0.4,0.4,32),fog_color=float4(0.5,0.5,0.5,1),fog=float4(2,18,settings.fog_mode>1.5 ? 0.08 : 0.12,settings.effect ? settings.fog_mode : -1.0),controls=float4(0,0,settings.normal_mode,0),splits=float4(cascade_splits(),0.0),shadow=float4(1.0/2048.0,0.0005,settings.effect ? 1.0 : 0.0,0.5))
}
def shadow_bindings(var scene : AdvancedScene; var image : SDL_GPUTexture?) {
    return <- array(SDL_GPUTextureSamplerBinding(texture=image,sampler=scene.sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[0],sampler=scene.shadow_sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[1],sampler=scene.shadow_sampler),SDL_GPUTextureSamplerBinding(texture=scene.shadows[2],sampler=scene.shadow_sampler))
}
def nearest_distance(spec : PartSpec; eye : float3) : float {
    let delta=eye-clamp(eye,spec.minimum,spec.maximum);return dot(delta,delta)
}
def draw_order(parts : array<AdvancedPart>; eye : float3; sorted : bool=true) {
    var order : array<int>
    for(mode in 0..3){
        let start=length(order)
        for(i in 0..length(parts)){if(parts[i].spec.mode==mode){push(order,i)}}
        if(mode==2 && sorted){for(i in start+1..length(order)){
            let index=order[i];let distance=nearest_distance(parts[index].spec,eye);var j=i
            while(j>start && nearest_distance(parts[order[j-1]].spec,eye)<distance){order[j]=order[j-1];j--}
            order[j]=index
        }}
    }
    return <- order
}
def render_advanced(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var scene : AdvancedScene; var target : SDL_GPUTexture?; width,height : uint; time : float; settings : AdvancedSettings) : SdlStatus {
    if(scene.size!=uint2(width,height)){
        if(scene.depth!=null){SDL_ReleaseGPUTexture(device,scene.depth);scene.depth=null}
        var depth=device |> create_advanced_texture(gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_try;scene.depth=depth;scene.size=uint2(width,height)
    }
    var vertex=ash::AdvancedVertex(model=identity_matrix(),vp=advanced_vp(width,height,settings,scene.lesson))
    if(scene.lesson==15){
        let splits=cascade_splits();vertex.light0=cascade_matrix(settings,float(width)/float(height),0.1,splits.x);vertex.light1=cascade_matrix(settings,float(width)/float(height),splits.x,splits.y);vertex.light2=cascade_matrix(settings,float(width)/float(height),splits.y,splits.z)
        let matrices=fixed_array(vertex.light0,vertex.light1,vertex.light2)
        for(i in 0..3){
            let depth=SDL_GPUDepthStencilTargetInfo(texture=scene.shadows[i],clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE,stencil_load_op=SDL_GPULoadOp.LOADOP_DONT_CARE,stencil_store_op=SDL_GPUStoreOp.STOREOP_DONT_CARE)
            let colors : array<SDL_GPUColorTargetInfo>
            with_native_gpu_render_pass(command,colors,depth) $(var pass_){
                SDL_BindGPUGraphicsPipeline(pass_,scene.shadow_pipeline)
                for(part in scene.parts){push_gpu_dsl_vertex_uniform(command,0u,ash::AdvancedVertex(model=part.spec.model,vp=matrices[i])) |> sdl_try;draw_mesh(pass_,part.mesh) |> sdl_try}
                return sdl_ok()
            } |> sdl_try
        }
    }
    var world,overlay : array<DebugLineVertex>
    if(scene.lesson==19){
        make_debug_lines(world,overlay,time)
        var bytes : array<uint8>
        // Debug vertices are tightly packed at 28 bytes, not std430 struct stride.
        bytes <- line_bytes(world,overlay)
        upload_bytes(device,scene.lines,bytes) |> sdl_try
    }
    let clear=scene.lesson==20 ? float4(0.5,0.5,0.5,1) : (scene.lesson==19 ? float4(0.05,0.05,0.07,1) : float4(0.0099,0.0099,0.0267,1))
    let colors <- array(attachment(target,false,clear))
    let depth=SDL_GPUDepthStencilTargetInfo(texture=scene.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE,stencil_load_op=SDL_GPULoadOp.LOADOP_DONT_CARE,stencil_store_op=SDL_GPUStoreOp.STOREOP_DONT_CARE)
    return with_native_gpu_render_pass(command,colors,depth) $(var pass_){
        if(scene.lesson==19){
            push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try
            let buffers <- array(SDL_GPUBufferBinding(buffer=scene.lines));sdl_status(SDL_BindGPUVertexBuffersArray(pass_,0u,buffers),"Bind debug lines") |> sdl_try
            SDL_BindGPUGraphicsPipeline(pass_,scene.world_lines);SDL_DrawGPUPrimitives(pass_,uint(length(world)),1u,0u,0u)
            if(settings.effect){SDL_BindGPUGraphicsPipeline(pass_,scene.overlay_lines);SDL_DrawGPUPrimitives(pass_,uint(length(overlay)),1u,uint(length(world)),0u)}
            return sdl_ok()
        }
        var frag=fragment_defaults(scene.lesson,settings)
        frag.controls.w=float(scene.lesson);frag.base=float4(0.068,0.534,0.932,1);frag.diffuse=float4(0.014,0.014,0.045,1)
        frag.ambient=float4(scene.lesson==15 ? 0.3 : 0.15);frag.specular=scene.lesson==15 ? float4(0.2,0.2,0.2,32) : float4(0.4,0.4,0.4,32)
        if(scene.lesson==20){frag.base=float4(0.35,0.35,0.35,1);frag.diffuse=float4(0.2);frag.specular=float4(0.3,0.3,0.3,32)}
        SDL_BindGPUGraphicsPipeline(pass_,scene.grid_pipeline)
        push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,frag) |> sdl_try
        if(scene.lesson==15){let images <- shadow_bindings(scene,scene.parts[0].diffuse);sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind grid shadows") |> sdl_try}
        if(scene.lesson==20){var images <- array(scene.parts[0].diffuse);bind_images(pass_,images,scene.sampler) |> sdl_try}
        draw_mesh(pass_,scene.grid) |> sdl_try
        let order <- draw_order(scene.parts,settings.eye)
        for(index in order){
            var part=scene.parts[index]
            SDL_BindGPUGraphicsPipeline(pass_,scene.lesson==16 && part.spec.mode==2 && settings.effect ? scene.blend : scene.solid)
            vertex.model=part.spec.model;frag=fragment_defaults(scene.lesson,settings)
            frag.base=part.spec.base;frag.controls.x=part.spec.diffuse!="" ? 1.0 : 0.0;frag.controls.y=float(part.spec.mode);frag.shadow.w=part.spec.cutoff
            if(scene.lesson==17){frag.shadow.z=part.spec.normal!="" ? 1.0 : 0.0}
            if(scene.lesson==15){frag.specular=float4(0.5,0.5,0.5,64)}
            if(scene.lesson==18){material(part.material,frag);frag.controls.x=0.0;if(!settings.effect){frag.specular=float4(0,0,0,32)}}
            if(scene.lesson==20){frag.diffuse=part.spec.base;frag.ambient=part.spec.base*0.2;frag.specular=float4(0.3,0.3,0.3,32)}
            push_gpu_dsl_vertex_uniform(command,0u,vertex) |> sdl_try;push_gpu_dsl_fragment_uniform(command,0u,frag) |> sdl_try
            if(scene.lesson==15){let images <- shadow_bindings(scene,part.diffuse);sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Bind cascade maps") |> sdl_try}
            else{var images <- array(part.diffuse);if(scene.lesson==17){push(images,part.normal)};bind_images(pass_,images,scene.sampler) |> sdl_try}
            draw_mesh(pass_,part.mesh) |> sdl_try
        }
        if(scene.lesson==15 && settings.preview>=0){
            SDL_BindGPUGraphicsPipeline(pass_,scene.preview)
            let images <- array(SDL_GPUTextureSamplerBinding(texture=scene.shadows[settings.preview],sampler=scene.shadow_sampler));sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,images),"Preview cascade") |> sdl_try
            SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u)
        }
        return sdl_ok()
    }
}

def run_advanced(lesson : int; smoke : bool) : int {
    let result=sdl_scope(){
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("Forge GPU {lesson} | SDL + daScript DSL",1280,720,SDL_WINDOW_RESIZABLE) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(dsl_example_formats(),true,"") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device,window),"Claim Forge window") |> sdl_try
        {defer(){SDL_ReleaseWindowFromGPUDevice(device,window)}
        configure_forge_swapchain(device,window) |> sdl_try
        return with_advanced(device,SDL_GetGPUSwapchainTextureFormat(device,window),lesson) $(var scene){
            var settings=advanced_defaults(lesson);var running=true;var frames=0;var time=0.0;var last=SDL_GetTicks()
            while(running){
                for(event in poll_events()){
                    if(should_close(event,window)){running=false}
                    match(event){if(SdlEvent(key_down=$v(key))){
                        if(key.keycode==SDLK_R){settings=advanced_defaults(lesson)}
                        elif(key.keycode==SDLK_SPACE && !key.repeat){settings.paused=!settings.paused}
                        elif(key.keycode==SDLK_E && !key.repeat){settings.effect=!settings.effect}
                        elif(key.keycode==SDLK_1){settings.normal_mode=0;settings.fog_mode=0;settings.preview=0}
                        elif(key.keycode==SDLK_2){settings.normal_mode=1;settings.fog_mode=1;settings.preview=1}
                        elif(key.keycode==SDLK_3){settings.normal_mode=2;settings.fog_mode=2;settings.preview=2}
                        elif(key.keycode==SDLK_0){settings.preview=-1}
                        elif(key.keycode==SDLK_W || key.keycode==SDLK_S){let delta=normalize(settings.target-settings.eye)*(key.keycode==SDLK_W ? 0.5 : -0.5);settings.eye+=delta;settings.target+=delta}
                    }if(SdlEvent(mouse_motion=$v(mouse))){if((mouse.buttons&SDL_BUTTON_RMASK)!=0u){
                        let offset=settings.eye-settings.target;let radius=length(offset);let yaw=atan2(offset.x,offset.z)-mouse.delta.x*0.005
                        let pitch=clamp(asin(offset.y/radius)+mouse.delta.y*0.005,-1.4,1.4);settings.eye=settings.target+float3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*radius
                    }}if(SdlEvent(mouse_wheel=$v(wheel))){settings.eye=settings.target+(settings.eye-settings.target)*exp(-wheel.delta.y*0.1)}if(_){} }
                }
                if(!running){break}
                let now=SDL_GetTicks();if(!settings.paused && !smoke){time+=min(0.1,float(now-last)*0.001)};last=now
                with_native_gpu_swapchain(device,window) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_advanced(device,command,scene,target,width,height,time,settings)} |> sdl_try
                frames++;if(smoke && frames>=3){break};SDL_Delay(16u)
            }
            return sdl_status(SDL_WaitForGPUIdle(device),"Wait Forge GPU")
        }}
    }
    if(is_err(result)){let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    print("Forge {lesson}: rendered; resources released.\n");return 0
}

def create_advanced_texture(device : SDL_GPUDevice?; info : SDL_GPUTextureCreateInfo) {
    var texture=SDL_CreateGPUTextureRef(device,info)
    if(texture==null){return err(sdl_error("SDL_CreateGPUTexture"),type<SDL_GPUTexture?>)}
    return <- move_ok(texture,type<SdlError>)
}
