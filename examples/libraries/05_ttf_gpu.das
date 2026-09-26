options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_ttf_boost
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_pixels_boost
require daslib/defer

let WIDTH = 640u
let HEIGHT = 256u
let CAPACITY = 262144u
let TEXT = "SDL_ttf GPU: ffi café"

def draw_text_sequence(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?;
        pipeline : SDL_GPUGraphicsPipeline?; var sampler : SDL_GPUSampler?;
        var vertices,indices : SDL_GPUBuffer?; var upload : SDL_GPUTransferBuffer?;
        var target : SDL_GPUTexture?; var sequence : TtfGpuDrawSequence) {
    if (sequence.image_type != TTF_ImageType.IMAGE_ALPHA || sequence.atlas_texture == null) {
        return err(SdlError(operation="GPU text example",message="This shader handles alpha glyphs only"),type<SdlUnit>)
    }
    var packed : array<float>
    resize(packed,length(sequence.xy)*4)
    for (i in 0 .. length(sequence.xy)) {
        packed[4*i] = sequence.xy[i].x; packed[4*i+1] = sequence.xy[i].y
        packed[4*i+2] = sequence.uv[i].x; packed[4*i+3] = sequence.uv[i].y
    }
    // Native uint32 indices serialized to little-endian bytes for the upload helper.
    var index_bytes : array<uint8>
    resize(index_bytes,length(sequence.indices)*4)
    for (i in 0 .. length(sequence.indices)) {
        let value = uint(sequence.indices[i])
        for (b in 0 .. 4) { index_bytes[4*i+b] = uint8(value >> uint(b*8)) }
    }
    let vertex_size = uint(length(packed))*4u
    let index_size = uint(length(index_bytes))
    if (vertex_size+index_size > CAPACITY) {
        return err(SdlError(operation="GPU text example",message="Sequence exceeds example upload capacity"),type<SdlUnit>)
    }
    device |> write_native_gpu_transfer_floats(upload,CAPACITY,0u,packed,true) |> sdl_try
    sdl_status(SDL_WriteGPUTransferBufferBytes(device,upload,CAPACITY,vertex_size,index_bytes,false),"SDL_WriteGPUTransferBufferBytes") |> sdl_try
    sdl_scope() {
        var copy_pass : SDL_GPUCopyPass?& = with_native_gpu_copy_pass(command) |> sdl_use
        let from_vertex = SDL_GPUTransferBufferLocation(transfer_buffer=upload)
        let from_index = SDL_GPUTransferBufferLocation(transfer_buffer=upload,offset=vertex_size)
        let to_vertex = SDL_GPUBufferRegion(buffer=vertices,size=vertex_size)
        let to_index = SDL_GPUBufferRegion(buffer=indices,size=index_size)
        SDL_UploadToGPUBufferRef(copy_pass,from_vertex,to_vertex,true)
        SDL_UploadToGPUBufferRef(copy_pass,from_index,to_index,true)
        return sdl_ok()
    } |> sdl_try
    let uniforms <- array<float>(float(WIDTH),float(HEIGHT),16.0,16.0)
    command |> push_native_gpu_vertex_uniforms(0u,uniforms) |> sdl_try
    let targets <- array(SDL_GPUColorTargetInfo(texture=target,load_op=SDL_GPULoadOp.LOADOP_LOAD,store_op=SDL_GPUStoreOp.STOREOP_STORE))
    return sdl_scope() {
        var render_pass : SDL_GPURenderPass?& = with_native_gpu_render_pass(command,targets) |> sdl_use
        SDL_BindGPUGraphicsPipeline(render_pass,pipeline)
        let vb <- array(SDL_GPUBufferBinding(buffer=vertices))
        let ib = SDL_GPUBufferBinding(buffer=indices)
        let bindings <- array(SDL_GPUTextureSamplerBinding(texture=sequence.atlas_texture,sampler=sampler))
        sdl_status(SDL_BindGPUVertexBuffersArray(render_pass,0u,vb),"SDL_BindGPUVertexBuffersArray") |> sdl_try
        SDL_BindGPUIndexBufferRef(render_pass,ib,SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
        sdl_status(SDL_BindGPUFragmentSamplersArray(render_pass,0u,bindings),"SDL_BindGPUFragmentSamplersArray") |> sdl_try
        SDL_DrawGPUIndexedPrimitives(render_pass,uint(length(sequence.indices)),1u,0u,0,0u)
        return sdl_ok()
    }
}

def compare_pixels(device : SDL_GPUDevice?; var target : SDL_GPUTexture?; font : TTF_Font?) {
    return sdl_scope() {
        var download : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(
            usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD,size=WIDTH*HEIGHT*4u)) |> sdl_use
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        sdl_scope() {
            var copy_pass : SDL_GPUCopyPass?& = with_native_gpu_copy_pass(command) |> sdl_use
            let region = SDL_GPUTextureRegion(texture=target,w=WIDTH,h=HEIGHT,d=1u)
            let destination = SDL_GPUTextureTransferInfo(transfer_buffer=download,pixels_per_row=WIDTH,rows_per_layer=HEIGHT)
            SDL_DownloadFromGPUTextureRef(copy_pass,region,destination)
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
        return font |> with_text_surface(TEXT,SDL_Color(r=255u8,g=255u8,b=255u8,a=255u8)) $(surface : SDL_Surface?) {
            let size = surface_size(surface) |> sdl_try
            var cpu : array<uint8>
            resize(cpu,size.x*size.y*4)
            copy_surface_rgba8(surface,cpu,size.x*4) |> sdl_try
            var ink = 0
            var mismatches = 0
            for (y in 0 .. int(HEIGHT)) {
                for (x in 0 .. int(WIDTH)) {
                    let sx=x-16; let sy=y-16
                    let expected = sx>=0 && sy>=0 && sx<size.x && sy<size.y ? int(cpu[4*(sy*size.x+sx)+3]) : 0
                    let actual = int(pixels[4*(y*int(WIDTH)+x)+2])
                    if (actual>20) { ink++ }
                    if (actual-expected>3 || expected-actual>3) { mismatches++ }
                }
            }
            print("GPU text readback: {ink} ink pixels, {mismatches} differing pixels.\n")
            if (ink<500 || mismatches>100) {
                return err(SdlError(operation="GPU text readback",message="GPU glyph mask differs from CPU reference"),type<SdlUnit>)
            }
            return sdl_ok()
        }
    }
}

def frames(device : SDL_GPUDevice?; window : SDL_Window?; font : TTF_Font?; text : TTF_Text?;
        pipeline : SDL_GPUGraphicsPipeline?; var sampler : SDL_GPUSampler?;
        var vertices,indices : SDL_GPUBuffer?; var upload : SDL_GPUTransferBuffer?;
        var target : SDL_GPUTexture?; smoke : bool) {
    var frame = 0
    var running = true
    var event = SDL_MakeEvent()
    while (running) {
        while (is_some(poll_event(event))) { if (should_close(event)) { running=false } }
        if (!running) { break }
        // Update between submitted frames. Do not retain atlas snapshots across changes.
        if (frame==1) { text |> set_text("GPU text updated") |> sdl_try }
        if (frame==2) { text |> set_text(TEXT) |> sdl_try }
        var sequences <- text |> gpu_text_draw_data() |> sdl_try
        with_native_gpu_swapchain(device,window) $(command; var swapchain; width,height) {
            let clear_targets <- array(SDL_GPUColorTargetInfo(texture=target,
                load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE,clear_color=SDL_FColor(a=1.0)))
            with_native_gpu_render_pass(command,clear_targets) $(var render_pass) { return sdl_ok() } |> sdl_try
            for (sequence in sequences) {
                draw_text_sequence(device,command,pipeline,sampler,vertices,indices,upload,target,sequence) |> sdl_try
            }
            let blit = SDL_GPUBlitInfo(source=SDL_GPUBlitRegion(texture=target,w=WIDTH,h=HEIGHT),
                destination=SDL_GPUBlitRegion(texture=swapchain,w=width,h=height),
                load_op=SDL_GPULoadOp.LOADOP_DONT_CARE,filter=SDL_GPUFilter.FILTER_LINEAR)
            SDL_BlitGPUTextureRef(command,blit)
            return sdl_ok()
        } |> sdl_try
        frame++
        if (smoke && frame==3) { break }
        SDL_Delay(16u)
    }
    if (smoke) { compare_pixels(device,target,font) |> sdl_try }
    return sdl_status(SDL_WaitForGPUIdle(device),"SDL_WaitForGPUIdle")
}

def resources(device : SDL_GPUDevice?; window : SDL_Window?; font : TTF_Font?; text : TTF_Text?;
        var vertex,fragment : SDL_GPUShader?; smoke : bool) {
    let layout <- array(SDL_GPUVertexBufferDescription(slot=0u,pitch=16u,input_rate=SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX))
    let attributes <- array(SDL_GPUVertexAttribute(location=0u,buffer_slot=0u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2),
        SDL_GPUVertexAttribute(location=1u,buffer_slot=0u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2,offset=8u))
    let colors <- array(SDL_GPUColorTargetDescription(format=SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,
        blend_state=SDL_GPUColorTargetBlendState(enable_blend=true,
            src_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA,dst_color_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
            color_blend_op=SDL_GPUBlendOp.BLENDOP_ADD,src_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE,
            dst_alpha_blendfactor=SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA,alpha_blend_op=SDL_GPUBlendOp.BLENDOP_ADD)))
    let info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,
        primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST,
        rasterizer_state=SDL_GPURasterizerState(enable_depth_clip=true,cull_mode=SDL_GPUCullMode.CULLMODE_NONE))
    return sdl_scope() {
        let pipeline : SDL_GPUGraphicsPipeline? = device |> with_native_gpu_graphics_pipeline(info,layout,attributes,colors) |> sdl_use
        var vertices : SDL_GPUBuffer? = device |> with_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_VERTEX,size=CAPACITY)) |> sdl_use
        var indices : SDL_GPUBuffer? = device |> with_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_INDEX,size=CAPACITY)) |> sdl_use
        var upload : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD,size=CAPACITY)) |> sdl_use
        var sampler : SDL_GPUSampler? = device |> with_native_gpu_sampler(SDL_GPUSamplerCreateInfo(
            min_filter=SDL_GPUFilter.FILTER_LINEAR,mag_filter=SDL_GPUFilter.FILTER_LINEAR,
            address_mode_u=SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
            address_mode_v=SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE)) |> sdl_use
        var target : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH,HEIGHT,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_use
        return frames(device,window,font,text,pipeline,sampler,vertices,indices,upload,target,smoke)
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) {
    let spirv = (SDL_GetGPUShaderFormats(device)&SDL_GPU_SHADERFORMAT_SPIRV)!=0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let ext = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/libraries/shaders/ttf"
    return sdl_scope() {
        let font : TTF_Font? = with_font("{SDL_GetBasePath()}assets/libraries/Amiri-Regular.ttf",48.0) |> sdl_use
        let engine : TTF_TextEngine? = device |> with_gpu_text_engine() |> sdl_use
        let text : TTF_Text? = engine |> with_text(font,TEXT) |> sdl_use
        var vertex : SDL_GPUShader? = device |> with_native_gpu_shader_file(SDL_GPUShaderCreateInfo(
            format=format,stage=SDL_GPUShaderStage.SHADERSTAGE_VERTEX,num_uniform_buffers=1u),"{base}.vert.{ext}","main") |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_native_gpu_shader_file(SDL_GPUShaderCreateInfo(
            format=format,stage=SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,num_samplers=1u),"{base}.frag.{ext}","main") |> sdl_use
        return resources(device,window,font,text,vertex,fragment,smoke)
    }
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        with_ttf() |> sdl_use
        let window : SDL_Window? = with_window("SDL_ttf GPU atlas - Escape to exit",int(WIDTH),int(HEIGHT),0ul) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(GPU_SHADER_FORMATS,true,"") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device,window),"SDL_ClaimWindowForGPUDevice") |> sdl_try
        { defer() { SDL_ReleaseWindowFromGPUDevice(device,window) }; return run(device,window,smoke) }
    }
    if (is_err(result)) { let error=unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1 }
    print("SDL_ttf GPU text: PASS\n")
    return 0
}
