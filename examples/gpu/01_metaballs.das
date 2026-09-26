options gen2
// Port of bgfx examples/02-metaballs; BSD-2-Clause (LICENSE-bgfx.txt).
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_window_boost
require dassdl3/sdl3_iostream_boost
require daslib/match
require daslib/defer
require metaballs_field
require math
require dassdl3/sdl3_init_boost

let WIDTH = 640u
let HEIGHT = 480u
// Worst case: five triangles per cube, 9 floats per vertex. No silent truncation.
let CAPACITY = uint(31*31*31*15*9*4)

struct Controls {
    iso : float = 0.75
    dimensions : int = 32
    paused : bool
    running : bool = true
}

def input(window : SDL_Window?; var controls : Controls) {
    for (event in poll_events()) {
        if (should_close(event,window)) { controls.running=false; break }
        match (event) {
            if (SdlEvent(key_down=$v(key))) {
                if (key.window_id != SDL_GetWindowID(window)) { continue }
                if (key.keycode==SDLK_UP) { controls.iso=min(4.0,controls.iso+0.05) }
                elif (key.keycode==SDLK_DOWN) { controls.iso=max(0.1,controls.iso-0.05) }
                elif (key.keycode==SDLK_RIGHT) { controls.dimensions=min(32,controls.dimensions+2) }
                elif (key.keycode==SDLK_LEFT) { controls.dimensions=max(8,controls.dimensions-2) }
                elif (key.keycode==SDLK_SPACE && !key.repeat) { controls.paused=!controls.paused }
                elif (key.keycode==SDLK_R) { controls=Controls() }
            }
            if (_) { }
        }
    }
}

def draw(command : SDL_GPUCommandBuffer?; pipeline : SDL_GPUGraphicsPipeline?;
        var buffer : SDL_GPUBuffer?; var color, depth : SDL_GPUTexture?; count : uint; time : float) {
    let f = 1.7320508 // cot(60 degrees / 2)
    let uniforms <- array<float>(sin(time*0.67),cos(time*0.67),sin(time),cos(time),
        f*float(HEIGHT)/float(WIDTH),f,100.0/99.9,-10.0/99.9)
    command |> push_native_gpu_vertex_uniforms(0u,uniforms) |> sdl_try
    let targets <- array(SDL_GPUColorTargetInfo(texture=color,
        load_op=SDL_GPULoadOp.LOADOP_CLEAR, store_op=SDL_GPUStoreOp.STOREOP_STORE,
        clear_color=SDL_FColor(r=0.03,g=0.03,b=0.04,a=1.0)))
    let depth_target = SDL_GPUDepthStencilTargetInfo(texture=depth,clear_depth=1.0,
        load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_DONT_CARE,
        stencil_load_op=SDL_GPULoadOp.LOADOP_DONT_CARE,stencil_store_op=SDL_GPUStoreOp.STOREOP_DONT_CARE)
    return sdl_scope() {
        var render_pass : SDL_GPURenderPass?& = with_native_gpu_render_pass(command,targets,depth_target) |> sdl_use
        SDL_BindGPUGraphicsPipeline(render_pass,pipeline)
        let bindings <- array(SDL_GPUBufferBinding(buffer=buffer))
        sdl_status(SDL_BindGPUVertexBuffersArray(render_pass,0u,bindings),"SDL_BindGPUVertexBuffersArray") |> sdl_try
        if (count>0u) { SDL_DrawGPUPrimitives(render_pass,count,1u,0u,0u) }
        return sdl_ok()
    }
}

def frame(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : SDL_GPUGraphicsPipeline?;
        var buffer : SDL_GPUBuffer?; var upload : SDL_GPUTransferBuffer?; var color, depth : SDL_GPUTexture?;
        vertices : array<float>; time : float) {
    device |> write_native_gpu_transfer_floats(upload,CAPACITY,0u,vertices) |> sdl_try
    with_native_gpu_swapchain(device,window) $(command; var swapchain; width,height) {
        sdl_scope() {
            var copy_pass : SDL_GPUCopyPass?& = with_native_gpu_copy_pass(command) |> sdl_use
            let from = SDL_GPUTransferBufferLocation(transfer_buffer=upload)
            let to = SDL_GPUBufferRegion(buffer=buffer,size=uint(length(vertices))*4u)
            if (to.size>0u) { SDL_UploadToGPUBufferRef(copy_pass,from,to,true) }
            return sdl_ok()
        } |> sdl_try
        draw(command,pipeline,buffer,color,depth,uint(length(vertices)/9),time) |> sdl_try
        // Fixed internal resolution; scaling on presentation also handles window resizing.
        let blit = SDL_GPUBlitInfo(
            source=SDL_GPUBlitRegion(texture=color,w=WIDTH,h=HEIGHT),
            destination=SDL_GPUBlitRegion(texture=swapchain,w=width,h=height),
            load_op=SDL_GPULoadOp.LOADOP_DONT_CARE,filter=SDL_GPUFilter.FILTER_LINEAR)
        SDL_BlitGPUTextureRef(command,blit)
        return sdl_ok()
    } |> sdl_try
    return sdl_ok()
}

// Smoke mode verifies actual rendered pixels, not just successful API calls.
def check_image(device : SDL_GPUDevice?; var color : SDL_GPUTexture?) {
    return sdl_scope() {
        var download : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(
            SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD,size=WIDTH*HEIGHT*4u)) |> sdl_use
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        sdl_scope() {
            var copy_pass : SDL_GPUCopyPass?& = with_native_gpu_copy_pass(command) |> sdl_use
            let from = SDL_GPUTextureRegion(texture=color,w=WIDTH,h=HEIGHT,d=1u)
            let to = SDL_GPUTextureTransferInfo(transfer_buffer=download,pixels_per_row=WIDTH,rows_per_layer=HEIGHT)
            SDL_DownloadFromGPUTextureRef(copy_pass,from,to)
            return sdl_ok()
        } |> sdl_try
        var fence = native_gpu_submit_fence(command) |> sdl_try
        {
            defer() { SDL_ReleaseGPUFence(device,fence) }
            let fences <- array(fence)
            sdl_status(SDL_WaitForGPUFencesArray(device,true,fences),"SDL_WaitForGPUFencesArray") |> sdl_try
        }
        var pixels : array<uint8>
        resize(pixels,int(WIDTH*HEIGHT*4u))
        sdl_status(SDL_ReadGPUTransferBufferBytes(device,download,WIDTH*HEIGHT*4u,0u,pixels),"SDL_ReadGPUTransferBufferBytes") |> sdl_try
        var bright=0
        for (i in 0 .. int(WIDTH*HEIGHT)) {
            if (int(pixels[i*4])>30 || int(pixels[i*4+1])>30 || int(pixels[i*4+2])>30) { bright++ }
        }
        if (bright<500 || bright>int(WIDTH*HEIGHT)*3/4) {
            return err(SdlError(operation="metaballs readback",message="Unexpected foreground coverage: {bright}"),type<SdlUnit>)
        }
        let capture_path = hint_string("DASSDL3_METABALLS_CAPTURE") |> unwrap_or("")
        if (capture_path!="") { save_file(capture_path,pixels) |> sdl_try }
        print("Readback: {bright} foreground pixels.\n")
        return sdl_ok()
    }
}

def animate(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : SDL_GPUGraphicsPipeline?;
        var buffer : SDL_GPUBuffer?; var upload : SDL_GPUTransferBuffer?; var color, depth : SDL_GPUTexture?; smoke : bool) {
    var controls = Controls()
    var grid : array<GridPoint>
    var vertices : array<float>
    reserve(vertices,65536*9)
    var time=0.0
    var previous=SDL_GetTicks()
    var frames=0
    while (controls.running) {
        input(window,controls)
        if (!controls.running) { break }
        let now=SDL_GetTicks()
        if (!controls.paused) { time += smoke ? 0.4 : min(0.1,float(now-previous)*0.001) }
        previous=now
        let start=SDL_GetPerformanceCounter()
        update_field(grid,controls.dimensions,time)
        triangulate(grid,controls.dimensions,controls.iso,vertices)
        let elapsed=1000.0*float(SDL_GetPerformanceCounter()-start)/float(SDL_GetPerformanceFrequency())
        if (uint(length(vertices))*4u>CAPACITY) { return err(SdlError(operation="metaballs",message="Vertex capacity exceeded"),type<SdlUnit>) }
        frame(device,window,pipeline,buffer,upload,color,depth,vertices,time) |> sdl_try
        set_title(window,"Metaballs | ISO {controls.iso} | grid {controls.dimensions} | {length(vertices)/9} vertices | CPU {elapsed} ms | arrows / Space / R / Esc") |> sdl_try
        frames++
        if (smoke && frames==3) { break }
    }
    if (smoke) {
        if (length(vertices)==0) { return err(SdlError(operation="metaballs",message="Empty generated surface"),type<SdlUnit>) }
        check_image(device,color) |> sdl_try
        print("Metaballs: {frames} frames, {length(vertices)/9} vertices, {SDL_GetGPUDeviceDriver(device)}.\n")
    }
    return sdl_ok()
}

def resources(device : SDL_GPUDevice?; window : SDL_Window?; var vertex, fragment : SDL_GPUShader?; smoke : bool) {
    let layout <- array(SDL_GPUVertexBufferDescription(pitch=36u))
    let attributes <- array(
        SDL_GPUVertexAttribute(location=0u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),
        SDL_GPUVertexAttribute(location=1u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3,offset=12u),
        SDL_GPUVertexAttribute(location=2u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3,offset=24u))
    let colors <- array(SDL_GPUColorTargetDescription(format=SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
    let info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,
        primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST,
        rasterizer_state=SDL_GPURasterizerState(enable_depth_clip=true,cull_mode=SDL_GPUCullMode.CULLMODE_NONE),
        depth_stencil_state=SDL_GPUDepthStencilState(enable_depth_test=true,enable_depth_write=true,compare_op=SDL_GPUCompareOp.COMPAREOP_LESS),
        target_info=SDL_GPUGraphicsPipelineTargetInfo(has_depth_stencil_target=true,depth_stencil_format=SDL_GPUTextureFormat.TEXTUREFORMAT_D16_UNORM))
    return sdl_scope() {
        let pipeline : SDL_GPUGraphicsPipeline? = device |> with_native_gpu_graphics_pipeline(info,layout,attributes,colors) |> sdl_use
        var buffer : SDL_GPUBuffer? = device |> with_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_VERTEX,size=CAPACITY)) |> sdl_use
        var upload : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD,size=CAPACITY)) |> sdl_use
        var color : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH,HEIGHT,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_use
        var depth : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH,HEIGHT,SDL_GPUTextureFormat.TEXTUREFORMAT_D16_UNORM,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_use
        return animate(device,window,pipeline,buffer,upload,color,depth,smoke)
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) {
    let spirv=(SDL_GetGPUShaderFormats(device)&SDL_GPU_SHADERFORMAT_SPIRV)!=0u
    let format=spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let ext=spirv ? "spv" : "dxil"
    let base="{SDL_GetBasePath()}assets/shaders/metaballs"
    return sdl_scope() {
        var vertex : SDL_GPUShader? = device |> with_native_gpu_shader_file(SDL_GPUShaderCreateInfo(format=format,stage=SDL_GPUShaderStage.SHADERSTAGE_VERTEX,num_uniform_buffers=1u),"{base}.vert.{ext}","main") |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_native_gpu_shader_file(SDL_GPUShaderCreateInfo(format=format,stage=SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT),"{base}.frag.{ext}","main") |> sdl_use
        return resources(device,window,vertex,fragment,smoke)
    }
}

[export]
def main(smoke : bool) : int {
    let result=sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window(WindowOptions(title="Metaballs",size=int2(960,720),flags=SDL_WINDOW_RESIZABLE)) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(GPU_SHADER_FORMATS,true,"") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device,window),"SDL_ClaimWindowForGPUDevice") |> sdl_try
        {
            defer() { SDL_ReleaseWindowFromGPUDevice(device,window) }
            return run(device,window,smoke)
        }
    }
    if (is_err(result)) { let error=unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1 }
    return 0
}
