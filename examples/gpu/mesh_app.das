options gen2
module mesh_app shared public
// Port of bgfx examples/04-mesh; BSD-2-Clause (LICENSE-bgfx.txt).
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_gpu_pipeline_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_window_boost
require daslib/match
require daslib/defer
require math
require mesh_data

def upload_buffer(device : SDL_GPUDevice?; var buffer : SDL_GPUBuffer?; bytes : array<uint8>) {
    let size=uint(length(bytes))
    return sdl_scope() {
        var transfer : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(
            SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD,size=size)) |> sdl_use
        sdl_status(SDL_WriteGPUTransferBufferBytes(device,transfer,size,0u,bytes,false),"SDL_WriteGPUTransferBufferBytes") |> sdl_try
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        sdl_scope() {
            var copy_pass : SDL_GPUCopyPass?& = with_native_gpu_copy_pass(command) |> sdl_use
            let from=SDL_GPUTransferBufferLocation(transfer_buffer=transfer)
            let to=SDL_GPUBufferRegion(buffer=buffer,size=size)
            SDL_UploadToGPUBufferRef(copy_pass,from,to,false)
            return sdl_ok()
        } |> sdl_try
        return native_gpu_submit(command)
    }
}

def draw(command : SDL_GPUCommandBuffer?; pipeline : SDL_GPUGraphicsPipeline?;
        var vb, ib : SDL_GPUBuffer?; count : uint; var color, depth : SDL_GPUTexture?;
        width,height : uint; time : float) {
    let uniforms <- array<float>(time,float(width)/float(height),0.1,100.0)
    command |> push_native_gpu_vertex_uniforms(0u,uniforms) |> sdl_try
    let targets <- array(SDL_GPUColorTargetInfo(texture=color,load_op=SDL_GPULoadOp.LOADOP_CLEAR,
        store_op=SDL_GPUStoreOp.STOREOP_STORE,clear_color=SDL_FColor(r=48.0/255.0,g=48.0/255.0,b=48.0/255.0,a=1.0)))
    let depth_target=SDL_GPUDepthStencilTargetInfo(texture=depth,clear_depth=1.0,
        load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_DONT_CARE,
        stencil_load_op=SDL_GPULoadOp.LOADOP_DONT_CARE,stencil_store_op=SDL_GPUStoreOp.STOREOP_DONT_CARE)
    return sdl_scope() {
        var render_pass : SDL_GPURenderPass?& = with_native_gpu_render_pass(command,targets,depth_target) |> sdl_use
        SDL_BindGPUGraphicsPipeline(render_pass,pipeline)
        let bindings <- array(SDL_GPUBufferBinding(buffer=vb))
        sdl_status(SDL_BindGPUVertexBuffersArray(render_pass,0u,bindings),"SDL_BindGPUVertexBuffersArray") |> sdl_try
        let indices=SDL_GPUBufferBinding(buffer=ib)
        SDL_BindGPUIndexBufferRef(render_pass,indices,SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
        SDL_DrawGPUIndexedPrimitives(render_pass,count,1u,0u,0,0u)
        return sdl_ok()
    }
}

def animate(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : SDL_GPUGraphicsPipeline?;
        var vb,ib : SDL_GPUBuffer?; count : uint) {
    var running=true; var paused=false; var time=0.0; var previous=SDL_GetTicks(); var frames=0
    var depth : SDL_GPUTexture?
    var depth_width=0u; var depth_height=0u
    defer() { if (depth!=null) { SDL_ReleaseGPUTexture(device,depth) } }
    while (running) {
        for (event in poll_events()) {
            if (should_close(event,window)) { running=false }
            match (event) {
                if (SdlEvent(key_down=$v(key))) {
                    if (key.window_id==SDL_GetWindowID(window) && !key.repeat) {
                        if (key.keycode==SDLK_SPACE) { paused=!paused }
                        elif (key.keycode==SDLK_R) { time=0.0 }
                    }
                }
                if (_) { }
            }
        }
        if (!running) { break }
        let now=SDL_GetTicks()
        if (!paused) { time+=min(0.1,float(now-previous)*0.001) }
        previous=now
        with_native_gpu_swapchain(device,window) $(command; var swapchain; width,height) {
            if (width!=depth_width || height!=depth_height) {
                let settings=gpu_texture(width,height,SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)
                var replacement=SDL_CreateGPUTextureRef(device,settings)
                if (replacement==null) { return err(sdl_error("SDL_CreateGPUTexture"),type<SdlUnit>) }
                if (depth!=null) { SDL_ReleaseGPUTexture(device,depth) }
                depth=replacement; depth_width=width; depth_height=height
                print("Mesh target: {int(width)}x{int(height)}.\n")
            }
            return draw(command,pipeline,vb,ib,count,swapchain,depth,width,height,time)
        } |> sdl_try
        frames++
        SDL_Delay(16u)
    }
    sdl_status(SDL_WaitForGPUIdle(device),"SDL_WaitForGPUIdle") |> sdl_try
    print("Mesh: {frames} frames, {SDL_GetGPUDeviceDriver(device)}.\n")
    return sdl_ok()
}

def resources(device : SDL_GPUDevice?; window : SDL_Window?; var vertex, fragment : SDL_GPUShader?) {
    let mesh <- load_mesh("{SDL_GetBasePath()}assets/meshes/bunny.msh") |> sdl_try
    print("Bunny: {int(mesh.vertex_count)} vertices, {int(mesh.index_count/3u)} triangles.\n")
    var info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment)
    info |> topology(SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
    info |> rasterizer(SDL_GPURasterizerState(enable_depth_clip=true,cull_mode=SDL_GPUCullMode.CULLMODE_BACK,
        front_face=SDL_GPUFrontFace.FRONTFACE_CLOCKWISE))
    info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT)
    info |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS)
    info |> depth_write(true)
    let buffers <- array(SDL_GPUVertexBufferDescription(pitch=24u))
    let attributes <- array(SDL_GPUVertexAttribute(location=0u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),
        SDL_GPUVertexAttribute(location=1u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3,offset=12u))
    return sdl_scope() {
        var vb : SDL_GPUBuffer? = device |> with_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_VERTEX,size=uint(length(mesh.vertices)))) |> sdl_use
        var ib : SDL_GPUBuffer? = device |> with_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_INDEX,size=uint(length(mesh.indices)))) |> sdl_use
        upload_buffer(device,vb,mesh.vertices) |> sdl_try
        upload_buffer(device,ib,mesh.indices) |> sdl_try
        let swapchain_colors <- array(gpu_color_target(SDL_GetGPUSwapchainTextureFormat(device,window)))
        let pipeline : SDL_GPUGraphicsPipeline? = device |> with_native_gpu_graphics_pipeline(info,buffers,attributes,swapchain_colors) |> sdl_use
        return animate(device,window,pipeline,vb,ib,mesh.index_count)
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?) {
    let spirv=(SDL_GetGPUShaderFormats(device)&SDL_GPU_SHADERFORMAT_SPIRV)!=0u
    let format=spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let ext=spirv ? "spv" : "dxil"
    let base="{SDL_GetBasePath()}assets/shaders/mesh"
    var vs=gpu_shader("{base}.vert.{ext}",format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    vs |> uniform_buffers(1u)
    let fs=gpu_shader("{base}.frag.{ext}",format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    return sdl_scope() {
        var vertex : SDL_GPUShader? = device |> with_native_gpu_shader_file(vs) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_native_gpu_shader_file(fs) |> sdl_use
        return resources(device,window,vertex,fragment)
    }
}
