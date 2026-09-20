options gen2
require daslib/defer
module sdl3_gpu_native_boost shared public
require dassdl3/sdl3_gpu_boost public

// Native-pointer scopes: SDL ownership, not checked IDs. No resource may escape
// its owner/device scope. Ordinary returns run defer; application panic may not.
def public with_native_gpu_device(formats : uint; debug : bool; driver : string;
        blk : block<(device : SDL_GPUDevice?) : void>) : bool {
    let device=SDL_CreateGPUDeviceDefault(formats,debug,driver)
    if (device==null) { return false }
    { defer() { SDL_DestroyGPUDevice(device) }; blk(device); return true }
}

def public with_native_gpu_buffer(device : SDL_GPUDevice?; info : SDL_GPUBufferCreateInfo;
        blk : block<(var resource : SDL_GPUBuffer?) : void>) : bool {
    var resource=SDL_CreateGPUBufferRef(device,info)
    if (resource==null) { return false }
    { defer() { SDL_ReleaseGPUBuffer(device,resource) }; blk(resource); return true }
}

def public with_native_gpu_texture(device : SDL_GPUDevice?; info : SDL_GPUTextureCreateInfo;
        blk : block<(var resource : SDL_GPUTexture?) : void>) : bool {
    var resource=SDL_CreateGPUTextureRef(device,info)
    if (resource==null) { return false }
    { defer() { SDL_ReleaseGPUTexture(device,resource) }; blk(resource); return true }
}

def public with_native_gpu_transfer_buffer(device : SDL_GPUDevice?; info : SDL_GPUTransferBufferCreateInfo;
        blk : block<(var resource : SDL_GPUTransferBuffer?) : void>) : bool {
    var resource=SDL_CreateGPUTransferBufferRef(device,info)
    if (resource==null) { return false }
    { defer() { SDL_ReleaseGPUTransferBuffer(device,resource) }; blk(resource); return true }
}

def public with_native_gpu_sampler(device : SDL_GPUDevice?; info : SDL_GPUSamplerCreateInfo;
        blk : block<(var resource : SDL_GPUSampler?) : void>) : bool {
    var resource=SDL_CreateGPUSamplerRef(device,info)
    if (resource==null) { return false }
    { defer() { SDL_ReleaseGPUSampler(device,resource) }; blk(resource); return true }
}

def public with_native_gpu_shader_bytes(device : SDL_GPUDevice?; info : SDL_GPUShaderCreateInfo;
        bytes : array<uint8>; entrypoint : string; blk : block<(var resource : SDL_GPUShader?) : void>) : bool {
    var resource=SDL_CreateGPUShaderBytes(device,info,bytes,entrypoint)
    if (resource==null) { return false }
    { defer() { SDL_ReleaseGPUShader(device,resource) }; blk(resource); return true }
}

def public with_native_gpu_shader_file(device : SDL_GPUDevice?; info : SDL_GPUShaderCreateInfo;
        path : string; entrypoint : string; blk : block<(var resource : SDL_GPUShader?) : void>) : bool {
    var resource=SDL_LoadGPUShaderFile(device,info,path,entrypoint)
    if (resource==null) { return false }
    { defer() { SDL_ReleaseGPUShader(device,resource) }; blk(resource); return true }
}

def public with_native_gpu_compute_pipeline_bytes(device : SDL_GPUDevice?; info : SDL_GPUComputePipelineCreateInfo;
        bytes : array<uint8>; entrypoint : string; blk : block<(var resource : SDL_GPUComputePipeline?) : void>) : bool {
    var resource=SDL_CreateGPUComputePipelineBytes(device,info,bytes,entrypoint)
    if (resource==null) { return false }
    { defer() { SDL_ReleaseGPUComputePipeline(device,resource) }; blk(resource); return true }
}

def public with_native_gpu_compute_pipeline_file(device : SDL_GPUDevice?; info : SDL_GPUComputePipelineCreateInfo;
        path : string; entrypoint : string; blk : block<(var resource : SDL_GPUComputePipeline?) : void>) : bool {
    var resource=SDL_LoadGPUComputePipelineFile(device,info,path,entrypoint)
    if (resource==null) { return false }
    { defer() { SDL_ReleaseGPUComputePipeline(device,resource) }; blk(resource); return true }
}

def public with_native_gpu_graphics_pipeline(device : SDL_GPUDevice?; info : SDL_GPUGraphicsPipelineCreateInfo;
        buffers : array<SDL_GPUVertexBufferDescription>; attributes : array<SDL_GPUVertexAttribute>;
        colors : array<SDL_GPUColorTargetDescription>; blk : block<(pipeline : SDL_GPUGraphicsPipeline?) : void>) : bool {
    let pipeline=SDL_CreateGPUGraphicsPipelineArrays(device,info,buffers,attributes,colors)
    if (pipeline==null) { return false }
    { defer() { SDL_ReleaseGPUGraphicsPipeline(device,pipeline) }; blk(pipeline); return true }
}

def public native_gpu_submit(var command : SDL_GPUCommandBuffer?&) : bool {
    let result=SDL_SubmitGPUCommandBuffer(command)
    command=null
    return result
}
def public native_gpu_cancel(var command : SDL_GPUCommandBuffer?&) : bool {
    let result=SDL_CancelGPUCommandBuffer(command)
    command=null
    return result
}
def public native_gpu_submit_fence(var command : SDL_GPUCommandBuffer?&) : SDL_GPUFence? {
    var fence=SDL_SubmitGPUCommandBufferAndAcquireFence(command)
    command=null
    return fence
}
// Offscreen only. Consume commands using the reference helpers above; end passes
// before returning. For swapchain acquisition use the separate owner below.
def public with_native_gpu_commands(device : SDL_GPUDevice?;
        blk : block<(var command : SDL_GPUCommandBuffer?&) : void>) : bool {
    var command=SDL_AcquireGPUCommandBuffer(device)
    if (command==null) { return false }
    { defer() { if (command!=null) { SDL_CancelGPUCommandBuffer(command) } }; blk(command); return true }
}
def public with_native_gpu_copy_pass(command : SDL_GPUCommandBuffer?;
        blk : block<(copy_pass : SDL_GPUCopyPass?) : void>) : bool {
    let copy_pass=SDL_BeginGPUCopyPass(command)
    if (copy_pass==null) { return false }
    { defer() { SDL_EndGPUCopyPass(copy_pass) }; blk(copy_pass); return true }
}
def public with_native_gpu_render_pass(command : SDL_GPUCommandBuffer?; colors : array<SDL_GPUColorTargetInfo>;
        blk : block<(render_pass : SDL_GPURenderPass?) : void>) : bool {
    let render_pass=SDL_BeginGPURenderPassArray(command,colors,null)
    if (render_pass==null) { return false }
    { defer() { SDL_EndGPURenderPass(render_pass) }; blk(render_pass); return true }
}
def public with_native_gpu_render_pass(command : SDL_GPUCommandBuffer?; colors : array<SDL_GPUColorTargetInfo>;
        depth : SDL_GPUDepthStencilTargetInfo; blk : block<(render_pass : SDL_GPURenderPass?) : void>) : bool {
    let render_pass=SDL_BeginGPURenderPassDepthArray(command,colors,depth)
    if (render_pass==null) { return false }
    { defer() { SDL_EndGPURenderPass(render_pass) }; blk(render_pass); return true }
}
def public with_native_gpu_compute_pass(command : SDL_GPUCommandBuffer?;
        textures : array<SDL_GPUStorageTextureReadWriteBinding>; buffers : array<SDL_GPUStorageBufferReadWriteBinding>;
        blk : block<(compute_pass : SDL_GPUComputePass?) : void>) : bool {
    let compute_pass=SDL_BeginGPUComputePassArray(command,textures,buffers)
    if (compute_pass==null) { return false }
    { defer() { SDL_EndGPUComputePass(compute_pass) }; blk(compute_pass); return true }
}
// Acquisition+submission result. Minimized/null-texture success skips blk.
// blk borrows command/texture; it must not submit/cancel/release them itself.
def public with_native_gpu_swapchain(device : SDL_GPUDevice?; window : SDL_Window?;
        blk : block<(command : SDL_GPUCommandBuffer?; var texture : SDL_GPUTexture?; width, height : uint) : void>) : bool {
    var command=SDL_AcquireGPUCommandBuffer(device)
    if (command==null) { return false }
    {
        defer() { if (command!=null) { SDL_CancelGPUCommandBuffer(command) } }
        var texture : SDL_GPUTexture?
        var width=0u; var height=0u
        if (!SDL_WaitAndAcquireGPUSwapchainTextureRef(command,window,texture,width,height)) { return false }
        if (texture==null) { return true }
        var submitted=false
        { defer() { submitted=native_gpu_submit(command) }; blk(command,texture,width,height) }
        return submitted
    }
}
