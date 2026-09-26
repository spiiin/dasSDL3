options gen2
require daslib/defer
module sdl3_gpu_native_boost shared public
require dassdl3/sdl3_gpu_shader_boost public

// Only non-optional creation/acquisition uses this null-as-error conversion.
// Swapchain texture absence retains its separate Result<Option<...>> contract.
def private native_gpu_pointer_result(var handle : auto(T); operation : string) {
    var value = handle
    if (value == null) { return err(sdl_error(operation),type<T -const>) }
    return <- move_ok(value,type<SdlError>)
}
def public create_native_gpu_device(formats : uint; debug : bool; driver : string = "") {
    return <- native_gpu_pointer_result(SDL_CreateGPUDeviceDefault(formats,debug,driver),"SDL_CreateGPUDeviceDefault")
}
def public create_native_gpu_buffer(device : SDL_GPUDevice?; info : SDL_GPUBufferCreateInfo) {
    return <- native_gpu_pointer_result(SDL_CreateGPUBufferRef(device,info),"SDL_CreateGPUBufferRef")
}
def public create_native_gpu_transfer_buffer(device : SDL_GPUDevice?; info : SDL_GPUTransferBufferCreateInfo) {
    return <- native_gpu_pointer_result(SDL_CreateGPUTransferBufferRef(device,info),"SDL_CreateGPUTransferBufferRef")
}
def public load_native_gpu_shader(device : SDL_GPUDevice?; info : SDL_GPUShaderCreateInfo; path : string; entrypoint : string = "main") {
    return <- native_gpu_pointer_result(SDL_LoadGPUShaderFile(device,info,path,entrypoint),"SDL_LoadGPUShaderFile")
}
def public load_native_gpu_compute_pipeline(device : SDL_GPUDevice?; info : SDL_GPUComputePipelineCreateInfo; path : string; entrypoint : string = "main") {
    return <- native_gpu_pointer_result(SDL_LoadGPUComputePipelineFile(device,info,path,entrypoint),"SDL_LoadGPUComputePipelineFile")
}
def public create_native_gpu_graphics_pipeline(device : SDL_GPUDevice?; info : SDL_GPUGraphicsPipelineCreateInfo;
        buffers : array<SDL_GPUVertexBufferDescription>; attributes : array<SDL_GPUVertexAttribute>; colors : array<SDL_GPUColorTargetDescription>) {
    return <- native_gpu_pointer_result(SDL_CreateGPUGraphicsPipelineArrays(device,info,buffers,attributes,colors),"SDL_CreateGPUGraphicsPipelineArrays")
}
def public acquire_native_gpu_command_buffer(device : SDL_GPUDevice?) {
    return <- native_gpu_pointer_result(SDL_AcquireGPUCommandBuffer(device),"SDL_AcquireGPUCommandBuffer")
}

// Native-pointer scopes: SDL ownership, not checked IDs. No resource may escape
// its owner/device scope. Ordinary returns run defer; application panic may not.
def public with_native_gpu_device(formats : uint; debug : bool; driver : string;
        blk : block<(device : SDL_GPUDevice?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let device=SDL_CreateGPUDeviceDefault(formats,debug,driver)
    if (device==null) { return err(sdl_error("with_native_gpu_device"), type<TT>) }
    { defer() { SDL_DestroyGPUDevice(device) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(device) } else { scope_result <- blk(device) } }

    return <- scope_result
}

def public with_native_gpu_buffer(device : SDL_GPUDevice?; info : SDL_GPUBufferCreateInfo;
        blk : block<(var resource : SDL_GPUBuffer?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var resource=SDL_CreateGPUBufferRef(device,info)
    if (resource==null) { return err(sdl_error("with_native_gpu_buffer"), type<TT>) }
    { defer() { SDL_ReleaseGPUBuffer(device,resource) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(resource) } else { scope_result <- blk(resource) } }

    return <- scope_result
}

def public with_native_gpu_texture(device : SDL_GPUDevice?; info : SDL_GPUTextureCreateInfo;
        blk : block<(var resource : SDL_GPUTexture?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var resource=SDL_CreateGPUTextureRef(device,info)
    if (resource==null) { return err(sdl_error("with_native_gpu_texture"), type<TT>) }
    { defer() { SDL_ReleaseGPUTexture(device,resource) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(resource) } else { scope_result <- blk(resource) } }

    return <- scope_result
}

def public with_native_gpu_transfer_buffer(device : SDL_GPUDevice?; info : SDL_GPUTransferBufferCreateInfo;
        blk : block<(var resource : SDL_GPUTransferBuffer?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var resource=SDL_CreateGPUTransferBufferRef(device,info)
    if (resource==null) { return err(sdl_error("with_native_gpu_transfer_buffer"), type<TT>) }
    { defer() { SDL_ReleaseGPUTransferBuffer(device,resource) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(resource) } else { scope_result <- blk(resource) } }

    return <- scope_result
}

def public with_native_gpu_sampler(device : SDL_GPUDevice?; info : SDL_GPUSamplerCreateInfo;
        blk : block<(var resource : SDL_GPUSampler?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var resource=SDL_CreateGPUSamplerRef(device,info)
    if (resource==null) { return err(sdl_error("with_native_gpu_sampler"), type<TT>) }
    { defer() { SDL_ReleaseGPUSampler(device,resource) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(resource) } else { scope_result <- blk(resource) } }

    return <- scope_result
}

def public with_native_gpu_shader_bytes(device : SDL_GPUDevice?; info : SDL_GPUShaderCreateInfo;
        bytes : array<uint8>; entrypoint : string; blk : block<(var resource : SDL_GPUShader?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var resource=SDL_CreateGPUShaderBytes(device,info,bytes,entrypoint)
    if (resource==null) { return err(sdl_error("with_native_gpu_shader_bytes"), type<TT>) }
    { defer() { SDL_ReleaseGPUShader(device,resource) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(resource) } else { scope_result <- blk(resource) } }

    return <- scope_result
}

def public with_native_gpu_shader_file(device : SDL_GPUDevice?; info : SDL_GPUShaderCreateInfo;
        path : string; entrypoint : string; blk : block<(var resource : SDL_GPUShader?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var resource=SDL_LoadGPUShaderFile(device,info,path,entrypoint)
    if (resource==null) { return err(sdl_error("with_native_gpu_shader_file"), type<TT>) }
    { defer() { SDL_ReleaseGPUShader(device,resource) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(resource) } else { scope_result <- blk(resource) } }

    return <- scope_result
}

def public with_native_gpu_compute_pipeline_bytes(device : SDL_GPUDevice?; info : SDL_GPUComputePipelineCreateInfo;
        bytes : array<uint8>; entrypoint : string; blk : block<(var resource : SDL_GPUComputePipeline?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var resource=SDL_CreateGPUComputePipelineBytes(device,info,bytes,entrypoint)
    if (resource==null) { return err(sdl_error("with_native_gpu_compute_pipeline_bytes"), type<TT>) }
    { defer() { SDL_ReleaseGPUComputePipeline(device,resource) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(resource) } else { scope_result <- blk(resource) } }

    return <- scope_result
}

def public with_native_gpu_compute_pipeline_file(device : SDL_GPUDevice?; info : SDL_GPUComputePipelineCreateInfo;
        path : string; entrypoint : string; blk : block<(var resource : SDL_GPUComputePipeline?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var resource=SDL_LoadGPUComputePipelineFile(device,info,path,entrypoint)
    if (resource==null) { return err(sdl_error("with_native_gpu_compute_pipeline_file"), type<TT>) }
    { defer() { SDL_ReleaseGPUComputePipeline(device,resource) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(resource) } else { scope_result <- blk(resource) } }

    return <- scope_result
}

def public with_native_gpu_graphics_pipeline(device : SDL_GPUDevice?; info : SDL_GPUGraphicsPipelineCreateInfo;
        buffers : array<SDL_GPUVertexBufferDescription>; attributes : array<SDL_GPUVertexAttribute>;
        colors : array<SDL_GPUColorTargetDescription>; blk : block<(pipeline : SDL_GPUGraphicsPipeline?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let pipeline=SDL_CreateGPUGraphicsPipelineArrays(device,info,buffers,attributes,colors)
    if (pipeline==null) { return err(sdl_error("with_native_gpu_graphics_pipeline"), type<TT>) }
    { defer() { SDL_ReleaseGPUGraphicsPipeline(device,pipeline) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(pipeline) } else { scope_result <- blk(pipeline) } }

    return <- scope_result
}

def public native_gpu_submit(var command : SDL_GPUCommandBuffer?&) {
    if(command==null) { return err(SdlError(operation="native_gpu_submit",message="Command already consumed"),type<SdlUnit>) }
    let result=SDL_SubmitGPUCommandBuffer(command)
    command=null
    return sdl_status(result, "native_gpu_submit")
}
def public native_gpu_cancel(var command : SDL_GPUCommandBuffer?&) {
    if(command==null) { return err(SdlError(operation="native_gpu_cancel",message="Command already consumed"),type<SdlUnit>) }
    let result=SDL_CancelGPUCommandBuffer(command)
    command=null
    return sdl_status(result, "native_gpu_cancel")
}
def public native_gpu_submit_fence(var command : SDL_GPUCommandBuffer?&) {
    if(command==null) { return err(SdlError(operation="native_gpu_submit_fence",message="Command already consumed"),type<SDL_GPUFence?>) }
    var fence=SDL_SubmitGPUCommandBufferAndAcquireFence(command)
    command=null
    var value = fence
    if (value == null) { return err(sdl_error("native_gpu_submit_fence"), type<SDL_GPUFence?>) }
    return <- move_ok(value,type<SdlError>)
}
// Offscreen only. Consume commands using the reference helpers above; end passes
// before returning. For swapchain acquisition use the separate owner below.
def public with_native_gpu_commands(device : SDL_GPUDevice?;
        blk : block<(var command : SDL_GPUCommandBuffer?&) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var command=SDL_AcquireGPUCommandBuffer(device)
    if (command==null) { return err(sdl_error("with_native_gpu_commands"),type<TT>) }
    { defer() { if (command!=null) { if (!SDL_CancelGPUCommandBuffer(command) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_CancelGPUCommandBuffer"),type<TT>) } } }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(command) } else { scope_result <- blk(command) } }

    return <- scope_result
}
def public with_native_gpu_copy_pass(command : SDL_GPUCommandBuffer?;
        blk : block<(var copy_pass : SDL_GPUCopyPass?&) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var copy_pass=SDL_BeginGPUCopyPass(command)
    if (copy_pass==null) { return err(sdl_error("with_native_gpu_copy_pass"), type<TT>) }
    { defer() { if(copy_pass!=null) { SDL_EndGPUCopyPass(copy_pass) } }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(copy_pass) } else { scope_result <- blk(copy_pass) } }

    return <- scope_result
}
def public with_native_gpu_render_pass(command : SDL_GPUCommandBuffer?; colors : array<SDL_GPUColorTargetInfo>;
        blk : block<(var render_pass : SDL_GPURenderPass?&) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var render_pass=SDL_BeginGPURenderPassArray(command,colors,null)
    if (render_pass==null) { return err(sdl_error("with_native_gpu_render_pass"), type<TT>) }
    { defer() { if(render_pass!=null) { SDL_EndGPURenderPass(render_pass) } }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(render_pass) } else { scope_result <- blk(render_pass) } }

    return <- scope_result
}
def public with_native_gpu_render_pass(command : SDL_GPUCommandBuffer?; colors : array<SDL_GPUColorTargetInfo>;
        depth : SDL_GPUDepthStencilTargetInfo; blk : block<(var render_pass : SDL_GPURenderPass?&) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var render_pass=SDL_BeginGPURenderPassDepthArray(command,colors,depth)
    if (render_pass==null) { return err(sdl_error("with_native_gpu_render_pass"), type<TT>) }
    { defer() { if(render_pass!=null) { SDL_EndGPURenderPass(render_pass) } }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(render_pass) } else { scope_result <- blk(render_pass) } }

    return <- scope_result
}
def public with_native_gpu_compute_pass(command : SDL_GPUCommandBuffer?;
        textures : array<SDL_GPUStorageTextureReadWriteBinding>; buffers : array<SDL_GPUStorageBufferReadWriteBinding>;
        blk : block<(var compute_pass : SDL_GPUComputePass?&) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var compute_pass=SDL_BeginGPUComputePassArray(command,textures,buffers)
    if (compute_pass==null) { return err(sdl_error("with_native_gpu_compute_pass"), type<TT>) }
    { defer() { if(compute_pass!=null) { SDL_EndGPUComputePass(compute_pass) } }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(compute_pass) } else { scope_result <- blk(compute_pass) } }

    return <- scope_result
}
// Swapchain pointers are borrowed until their command is consumed.
struct SdlSwapchainTexture {
    texture : SDL_GPUTexture?
    size : uint2
}
def public native_gpu_swapchain(command : SDL_GPUCommandBuffer?; window : SDL_Window?; wait : bool = true) {
    var texture : SDL_GPUTexture?
    var width, height : uint
    let acquired = wait ? SDL_WaitAndAcquireGPUSwapchainTextureRef(command,window,texture,width,height) : SDL_AcquireGPUSwapchainTextureRef(command,window,texture,width,height)
    if (!acquired) { return err(sdl_error(wait ? "SDL_WaitAndAcquireGPUSwapchainTexture" : "SDL_AcquireGPUSwapchainTexture"),type<$Option<SdlSwapchainTexture> >) }
    if (texture==null) {
        var absent = none(type<SdlSwapchainTexture>)
        return <- move_ok(absent,type<SdlError>)
    }
    var image = SdlSwapchainTexture(texture=texture,size=uint2(width,height))
    var present <- move_some(image)
    return <- move_ok(present,type<SdlError>)
}
// None skips the body. Any acquired texture must be submitted, even on body failure.
// SDL forbids cancelling a command after acquiring a swapchain texture; primary errors win.
def public with_native_gpu_swapchain(device : SDL_GPUDevice?; window : SDL_Window?;
        blk : block<(command : SDL_GPUCommandBuffer?; var texture : SDL_GPUTexture?; width, height : uint) : $Result<auto(TT); SdlError> >) {
    var command=SDL_AcquireGPUCommandBuffer(device)
    if (command==null) {return err(sdl_error("SDL_AcquireGPUCommandBuffer"),type<$Option<TT> >)}
    var outcome : $Result<$Option<TT>; SdlError>
    {
        defer() {
            if (command!=null) {
                if (!SDL_CancelGPUCommandBuffer(command) && is_ok(outcome)) {
                    outcome <- err(sdl_error("SDL_CancelGPUCommandBuffer"),type<$Option<TT> >)
                }
            }
        }
        var acquired <- native_gpu_swapchain(command,window)
        if (is_err(acquired)) { outcome <- err(unwrap_err(acquired),type<$Option<TT> >) }
        else {
            var optional_image <- move_unwrap(acquired)
            if (is_none(optional_image)) {
                var absent = none(type<TT>)
                outcome <- move_ok(absent,type<SdlError>)
            } else {
                var image <- move_unwrap(optional_image)
                var body_result : $Result<TT; SdlError>
                static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) {
                    body_result=blk(command,image.texture,image.size.x,image.size.y)
                } else {
                    body_result <- blk(command,image.texture,image.size.x,image.size.y)
                }
                let submitted=native_gpu_submit(command)
                if (is_err(body_result)) { outcome <- err(unwrap_err(body_result),type<$Option<TT> >) }
                elif (is_err(submitted)) {outcome <- err(unwrap_err(submitted),type<$Option<TT> >)}
                else {
                    var value : TT
                    static_if (typeinfo can_copy(value)) {value=move_unwrap(body_result)}
                    else {value <- move_unwrap(body_result)}
                    var present <- move_some(value)
                    outcome <- move_ok(present,type<SdlError>)
                }
            }
        }
    }
    return <- outcome
}

// Consumes this variable; aliases still obey SDL's manual lifetime preconditions.
def public native_gpu_end_copy_pass(var value : SDL_GPUCopyPass?&) {
    if(value==null) { return err(SdlError(operation="native_gpu_end_copy_pass",message="Pass already ended"),type<SdlUnit>) }
    SDL_EndGPUCopyPass(value)
    value=null
    return sdl_ok()
}

// Consumes this variable; aliases still obey SDL's manual lifetime preconditions.
def public native_gpu_end_render_pass(var value : SDL_GPURenderPass?&) {
    if(value==null) { return err(SdlError(operation="native_gpu_end_render_pass",message="Pass already ended"),type<SdlUnit>) }
    SDL_EndGPURenderPass(value)
    value=null
    return sdl_ok()
}

// Consumes this variable; aliases still obey SDL's manual lifetime preconditions.
def public native_gpu_end_compute_pass(var value : SDL_GPUComputePass?&) {
    if(value==null) { return err(SdlError(operation="native_gpu_end_compute_pass",message="Pass already ended"),type<SdlUnit>) }
    SDL_EndGPUComputePass(value)
    value=null
    return sdl_ok()
}

// Capacity is the actual transfer-buffer allocation size, in bytes.
def public write_native_gpu_transfer_floats(device : SDL_GPUDevice?; transfer : SDL_GPUTransferBuffer?;
        capacity, offset : uint; values : array<float>; cycle : bool = true) {
    return sdl_status(SDL_WriteGPUTransferBufferFloats(device,transfer,capacity,offset,values,cycle),"SDL_WriteGPUTransferBufferFloats")
}

def public push_native_gpu_vertex_uniforms(command : SDL_GPUCommandBuffer?; slot : uint; values : array<float>) {
    return sdl_status(SDL_PushGPUVertexUniformFloats(command,slot,values),"SDL_PushGPUVertexUniformFloats")
}

// Native descriptor builder. Creation and validation stay with SDL.
def public gpu_texture(width, height : uint; format : SDL_GPUTextureFormat; usage : uint) : SDL_GPUTextureCreateInfo {
    return SDL_GPUTextureCreateInfo(texture_type=SDL_GPUTextureType.TEXTURETYPE_2D,
        format=format,usage=usage,width=width,height=height,layer_count_or_depth=1u,
        num_levels=1u,sample_count=SDL_GPUSampleCount.SAMPLECOUNT_1)
}
def public texture_shape(var settings : SDL_GPUTextureCreateInfo; kind : SDL_GPUTextureType; layers_or_depth : uint) {
    settings.texture_type = kind
    settings.layer_count_or_depth = layers_or_depth
}
def public mip_levels(var settings : SDL_GPUTextureCreateInfo; count : uint) { settings.num_levels = count }
def public sample_count(var settings : SDL_GPUTextureCreateInfo; count : SDL_GPUSampleCount) { settings.sample_count = count }
def public texture_usage(var settings : SDL_GPUTextureCreateInfo; flags : uint) { settings.usage = flags }

// Counts and threadgroup dimensions must match the trusted compiled shader.
def public gpu_compute_pipeline(format : uint) : SDL_GPUComputePipelineCreateInfo {
    return SDL_GPUComputePipelineCreateInfo(format=format,threadcount_x=1u,threadcount_y=1u,threadcount_z=1u)
}
def public threadgroup(var settings : SDL_GPUComputePipelineCreateInfo; x, y, z : uint) {
    settings.threadcount_x = x
    settings.threadcount_y = y
    settings.threadcount_z = z
}
def public samplers(var settings : SDL_GPUComputePipelineCreateInfo; count : uint) { settings.num_samplers = count }
def public uniform_buffers(var settings : SDL_GPUComputePipelineCreateInfo; count : uint) { settings.num_uniform_buffers = count }
def public readonly_storage_textures(var settings : SDL_GPUComputePipelineCreateInfo; count : uint) { settings.num_readonly_storage_textures = count }
def public readonly_storage_buffers(var settings : SDL_GPUComputePipelineCreateInfo; count : uint) { settings.num_readonly_storage_buffers = count }
def public readwrite_storage_textures(var settings : SDL_GPUComputePipelineCreateInfo; count : uint) { settings.num_readwrite_storage_textures = count }
def public readwrite_storage_buffers(var settings : SDL_GPUComputePipelineCreateInfo; count : uint) { settings.num_readwrite_storage_buffers = count }

// The same owned path/entrypoint options work with checked and native shaders.
def public load_native_gpu_shader(device : SDL_GPUDevice?; settings : GpuShaderOptions) {
    return <- load_native_gpu_shader(device,settings.info,settings.path,settings.entrypoint)
}
def public with_native_gpu_shader_file(device : SDL_GPUDevice?; settings : GpuShaderOptions;
        blk : block<(var resource : SDL_GPUShader?) : $Result<auto(TT);SdlError>>) {
    return <- with_native_gpu_shader_file(device,settings.info,settings.path,settings.entrypoint,blk)
}
def public with_native_gpu_shader_bytes(device : SDL_GPUDevice?; bytes : array<uint8>; settings : GpuShaderOptions;
        blk : block<(var resource : SDL_GPUShader?) : $Result<auto(TT);SdlError>>) {
    return <- with_native_gpu_shader_bytes(device,settings.info,bytes,settings.entrypoint,blk)
}
