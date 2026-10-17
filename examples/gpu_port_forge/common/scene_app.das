options gen2
module scene_app shared public
require ./forge_support.das public
require ./scene_shaders.das as shaders
require dassdl3/sdl3_shader_storage
require dassdl3/sdl3_window_boost
require daslib/defer
require daslib/match
struct Instance { model : float4x4 }
struct Scene { first,second : MeshBuffers; diffuse,other,environment,depth : SDL_GPUTexture?; sampler : SDL_GPUSampler?; mesh,grid,sky : SDL_GPUGraphicsPipeline?; boxes,ducks : SDL_GPUBuffer?; size : uint2; lesson : int }
struct Settings { eye : float3; target : float3; ambient : float = 0.15; specular : float = 0.5; shininess : float = 64.0; reflectivity : float = 0.6; spacing : float = 1.0; show_grid : bool = true; show_objects : bool = true; box_count : uint = 47u; duck_count : uint = 256u }

def release(device : SDL_GPUDevice?; var scene : Scene) {
    release(device,scene.first);release(device,scene.second)
    for(t in fixed_array(scene.diffuse,scene.other,scene.environment,scene.depth)){if(t!=null){SDL_ReleaseGPUTexture(device,t)}}
    for(p in fixed_array(scene.mesh,scene.grid,scene.sky)){if(p!=null){SDL_ReleaseGPUGraphicsPipeline(device,p)}}
    if(scene.sampler!=null){SDL_ReleaseGPUSampler(device,scene.sampler)}
    if(scene.boxes!=null){SDL_ReleaseGPUBuffer(device,scene.boxes)};if(scene.ducks!=null){SDL_ReleaseGPUBuffer(device,scene.ducks)}
}
def instance_matrices(ducks : bool) {
    var values : array<Instance>
    if(ducks){for(z in 0..16){for(x in 0..16){push(values,Instance(model=model_matrix(float3(float(x)*2.0-15.0,0.0,float(z)*2.0-15.0),float3(0.5),float(x+z)*0.15)))}}}
    else{
        for(z in 0..6){for(x in 0..6){push(values,Instance(model=model_matrix(float3(float(x)*3.0-7.5,0.5,float(z)*3.0-7.5),float3(1.0))))}}
        for(i in 0..11){let index=(i*7)%36;push(values,Instance(model=model_matrix(float3(float(index%6)*3.0-7.5,1.5,float(index/6)*3.0-7.5),float3(1.0),0.1)))}
    }
    return <- values
}
def with_scene(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; lesson : int; body : block<(var scene : Scene) : SdlStatus>) : SdlStatus {
    var scene=Scene(lesson=lesson);defer(){release(device,scene)}
    let model=lesson==10 ? "Suzanne" : (lesson==12 ? "CesiumMilkTruck" : (lesson==13 ? "BoxTextured" : "Shuttle"))
    var first=load_mesh(device,model) |> sdl_try;scene.first=first
    var diffuse=load_texture(device,model) |> sdl_try;scene.diffuse=diffuse
    var sampler=SDL_CreateGPUSamplerRef(device,gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR))
    if(sampler==null){return err(sdl_error("SDL_CreateGPUSampler"),type<SdlUnit>)};scene.sampler=sampler
    var p=device |> pipeline(lesson==13 ? shaders::instanced_vertex : shaders::lit_vertex,lesson==13 ? shaders::instanced_vertex_reflect : shaders::lit_vertex_reflect,
        lesson==14 ? shaders::environment_fragment : shaders::lit_fragment,lesson==14 ? shaders::environment_fragment_reflect : shaders::lit_fragment_reflect,format,true,lesson==13) |> sdl_try;scene.mesh=p
    if(lesson==12 || lesson==13){p=device |> pipeline(shaders::grid_vertex,shaders::grid_vertex_reflect,shaders::grid_fragment,shaders::grid_fragment_reflect,format,false,false,true) |> sdl_try;scene.grid=p}
    if(lesson==13){
        var second=load_mesh(device,"Duck") |> sdl_try;scene.second=second
        var other=load_texture(device,"Duck") |> sdl_try;scene.other=other
        let boxes <- instance_matrices(false);let ducks <- instance_matrices(true)
        let box_bytes <- gpu_dsl_storage_bytes(boxes) |> sdl_try;let duck_bytes <- gpu_dsl_storage_bytes(ducks) |> sdl_try
        var buffer=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_VERTEX,size=uint(length(box_bytes)))) |> sdl_try;scene.boxes=buffer
        upload_bytes(device,scene.boxes,box_bytes) |> sdl_try
        buffer=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_VERTEX,size=uint(length(duck_bytes)))) |> sdl_try;scene.ducks=buffer
        upload_bytes(device,scene.ducks,duck_bytes) |> sdl_try
    }
    if(lesson==14){
        var cube=load_texture(device,"sky",true) |> sdl_try;scene.environment=cube
        p=device |> pipeline(shaders::fullscreen_vertex,shaders::fullscreen_vertex_reflect,shaders::sky_fragment,shaders::sky_fragment_reflect,format,false,false,false) |> sdl_try;scene.sky=p
    }
    return body(scene)
}
def defaults(lesson : int) : Settings {
    if(lesson==10){return Settings(eye=float3(0.0,0.0,4.0),target=float3(0.0))}
    if(lesson==12){return Settings(eye=float3(10.0,6.0,10.0),target=float3(0.0,1.0,0.0),ambient=0.3)}
    if(lesson==13){return Settings(eye=float3(24.0,20.0,26.0),target=float3(0.0),ambient=0.3)}
    return Settings(eye=float3(-35.0,21.0,28.0),target=float3(0.0),ambient=0.08)
}
def render_scene(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var scene : Scene; var target : SDL_GPUTexture?; width,height : uint; time : float; settings : Settings) : SdlStatus {
    if(scene.size!=uint2(width,height)){
        if(scene.depth!=null){SDL_ReleaseGPUTexture(device,scene.depth);scene.depth=null}
        var depth=SDL_CreateGPUTextureRef(device,gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET))
        if(depth==null){return err(sdl_error("Create depth"),type<SdlUnit>)};scene.depth=depth;scene.size=uint2(width,height)
    }
    let vp=camera_matrix(width,height,settings.eye,settings.target)
    if(scene.lesson==14){
        let f=normalize(settings.target-settings.eye);let right=normalize(cross(float3(0.0,1.0,0.0),f));let up=cross(f,right)
        push_gpu_dsl_fragment_uniform(command,0u,shaders::SkyParams(right=float4(right*(float(width)/float(height)/1.7320508),0.0),up=float4(up/1.7320508,0.0),forward=float4(f,0.0))) |> sdl_try
        let targets <- array(attachment(target))
        with_native_gpu_render_pass(command,targets) $(var pass_) {
            SDL_BindGPUGraphicsPipeline(pass_,scene.sky)
            var images <- array(scene.environment);bind_images(pass_,images,scene.sampler) |> sdl_try
            SDL_DrawGPUPrimitives(pass_,3u,1u,0u,0u);return sdl_ok()
        } |> sdl_try
    }
    let targets <- array(attachment(target,scene.lesson==14))
    let depth=SDL_GPUDepthStencilTargetInfo(texture=scene.depth,clear_depth=1.0,load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE,stencil_load_op=SDL_GPULoadOp.LOADOP_DONT_CARE,stencil_store_op=SDL_GPUStoreOp.STOREOP_DONT_CARE)
    return with_native_gpu_render_pass(command,targets,depth) $(var pass_) {
        if(scene.grid!=null && settings.show_grid){
            SDL_BindGPUGraphicsPipeline(pass_,scene.grid)
            push_gpu_dsl_vertex_uniform(command,0u,shaders::Transform(model=identity_matrix(),vp=vp)) |> sdl_try
            push_gpu_dsl_fragment_uniform(command,0u,shaders::GridParams(line_color=float4(0.068,0.534,0.932,1.0),bg_color=float4(0.014,0.014,0.045,1.0),light_dir=float4(1.0,1.0,1.0,0.0),eye_pos=float4(settings.eye,1.0),spacing=settings.spacing,line_width=0.02,fade_distance=40.0,ambient=0.3,shininess=32.0,specular=0.2)) |> sdl_try
            SDL_DrawGPUPrimitives(pass_,6u,1u,0u,0u)
        }
        if(settings.show_objects){
            SDL_BindGPUGraphicsPipeline(pass_,scene.mesh)
            let model=scene.lesson==10 ? model_matrix(float3(0.0),float3(1.0,1.2,0.8),time*0.25) : identity_matrix()
            push_gpu_dsl_vertex_uniform(command,0u,shaders::Transform(model=model,vp=vp)) |> sdl_try
            push_gpu_dsl_fragment_uniform(command,0u,shaders::Lighting(base_color=float4(1.0),light_dir=float4(1.0,0.7,1.0,0.0),eye_pos=float4(settings.eye,1.0),has_texture=1u,shininess=settings.shininess,ambient=settings.ambient,specular=settings.specular,reflectivity=settings.reflectivity)) |> sdl_try
            var images <- array(scene.diffuse);if(scene.lesson==14){push(images,scene.environment)}
            bind_images(pass_,images,scene.sampler) |> sdl_try
            draw_mesh(pass_,scene.first,scene.lesson==13 ? settings.box_count : 1u,scene.boxes) |> sdl_try
            if(scene.lesson==13){
                images <- array(scene.other);bind_images(pass_,images,scene.sampler) |> sdl_try
                draw_mesh(pass_,scene.second,settings.duck_count,scene.ducks) |> sdl_try
            }
        }
        return sdl_ok()
    }
}
def run_scene(lesson : int; smoke : bool) : int {
    let result=sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("Forge GPU {lesson} | SDL + daScript DSL",960,720,SDL_WINDOW_RESIZABLE) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(dsl_example_formats(),true,"") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device,window),"SDL_ClaimWindowForGPUDevice") |> sdl_try
        {defer(){SDL_ReleaseWindowFromGPUDevice(device,window)}
        return with_scene(device,SDL_GetGPUSwapchainTextureFormat(device,window),lesson) $(var scene) {
            var settings=defaults(lesson);var running=true;var frames=0;let start=SDL_GetTicks()
            while(running){
                for(event in poll_events()){
                    if(should_close(event,window)){running=false}
                    match(event){if(SdlEvent(key_down=$v(key))){
                        if(key.keycode==SDLK_R){settings=defaults(lesson)}
                        elif(key.keycode==SDLK_G && !key.repeat){settings.show_grid = !settings.show_grid}
                        elif(key.keycode==SDLK_A){settings.ambient=max(0.0,settings.ambient-0.05)}
                        elif(key.keycode==SDLK_D){settings.ambient=min(1.0,settings.ambient+0.05)}
                        elif(key.keycode==SDLK_LEFT){settings.reflectivity=max(0.0,settings.reflectivity-0.1)}
                        elif(key.keycode==SDLK_RIGHT){settings.reflectivity=min(1.0,settings.reflectivity+0.1)}
                        elif(key.keycode==SDLK_UP){settings.spacing*=1.25}
                        elif(key.keycode==SDLK_DOWN){settings.spacing=max(0.1,settings.spacing/1.25)}
                        elif(key.keycode==SDLK_W || key.keycode==SDLK_S){let delta=normalize(settings.target-settings.eye)*(key.keycode==SDLK_W ? 0.5 : -0.5);settings.eye+=delta;settings.target+=delta}
                    }if(SdlEvent(mouse_motion=$v(mouse))){
                        if((mouse.buttons&SDL_BUTTON_RMASK)!=0u){
                            let offset=settings.eye-settings.target;let radius=length(offset)
                            let yaw=atan2(offset.x,offset.z)-mouse.delta.x*0.005
                            let pitch=clamp(asin(offset.y/radius)+mouse.delta.y*0.005,-1.4,1.4)
                            settings.eye=settings.target+float3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*radius
                        }
                    }if(SdlEvent(mouse_wheel=$v(wheel))){settings.eye=settings.target+(settings.eye-settings.target)*exp(-wheel.delta.y*0.1)}if(_){} }
                }
                if(!running){break}
                let time=smoke ? 0.0 : float(SDL_GetTicks()-start)*0.001
                with_native_gpu_swapchain(device,window) $(command : SDL_GPUCommandBuffer?;var target : SDL_GPUTexture?;width,height : uint){return render_scene(device,command,scene,target,width,height,time,settings)} |> sdl_try
                frames++;if(smoke && frames>=3){break};SDL_Delay(16u)
            }
            return sdl_status(SDL_WaitForGPUIdle(device),"SDL_WaitForGPUIdle")
        }}
    }
    if(is_err(result)){let error=unwrap_err(result);print("{error.operation}: {error.message}\n");return 1}
    print("Forge {lesson}: rendered; resources released.\n");return 0
}
