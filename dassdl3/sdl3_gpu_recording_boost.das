options gen2
require daslib/defer
module sdl3_gpu_recording_boost shared public
require dassdl3/sdl3_gpu_buffers_boost public
require dassdl3/sdl3_gpu_pipeline_boost public
require dassdl3/sdl3_gpu_sampler_boost public

// Real SDL command buffer. Explicit submit; scope exit cancels unfinished work.
def public acquire_gpu_command_buffer(device : SDL_GPUDevice?) {
    return checked_handle_result(SDL_AcquireGPUCommandBufferChecked(device), "SDL_AcquireGPUCommandBufferChecked")
}

def public with_gpu_command_buffer(device : SDL_GPUDevice?; blk : block<(command : GpuCommandBufferHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let acquired = acquire_gpu_command_buffer(device)
    if (is_err(acquired)) { return err(unwrap_err(acquired), type<TT>) }
    let command = unwrap(acquired)
    {
        defer() { if (!SDL_GPURecordingDiscard(device, command) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_GPURecordingDiscard"), type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(command) } else { scope_result <- blk(command) }
    }

    return <- scope_result
}
def public gpu_begin_render_pass(device : SDL_GPUDevice?; command : GpuCommandBufferHandle; target : GpuTextureHandle; sub : uint2;
                                 load : SDL_GPULoadOp; clear : SDL_FColor) {
    return checked_handle_result(SDL_BeginGPURenderPassChecked(device, command, target, sub, load, clear), "SDL_BeginGPURenderPassChecked")
}
def public gpu_end_render_pass(device : SDL_GPUDevice?; render_pass : GpuRenderPassHandle) {
    return sdl_status(SDL_EndGPURenderPassChecked(device, render_pass), "gpu_end_render_pass")
}
def public gpu_submit_command_buffer(device : SDL_GPUDevice?; command : GpuCommandBufferHandle) {
    return sdl_status(SDL_SubmitGPUCommandBufferChecked(device, command), "gpu_submit_command_buffer")
}
def public gpu_cancel_command_buffer(device : SDL_GPUDevice?; command : GpuCommandBufferHandle) {
    return sdl_status(SDL_CancelGPUCommandBufferChecked(device, command), "gpu_cancel_command_buffer")
}
def public gpu_bind_pipeline(device : SDL_GPUDevice?; render_pass : GpuRenderPassHandle; pipeline : GpuPipelineHandle) {
    return sdl_status(SDL_BindGPUGraphicsPipelineChecked(device, render_pass, pipeline), "gpu_bind_pipeline")
}
def public gpu_set_viewport(device : SDL_GPUDevice?; render_pass : GpuRenderPassHandle; viewport : SDL_GPUViewport) {
    return sdl_status(SDL_SetGPUViewportChecked(device, render_pass, viewport), "gpu_set_viewport")
}
def public gpu_set_scissor(device : SDL_GPUDevice?; render_pass : GpuRenderPassHandle; rect : uint4) {
    return sdl_status(SDL_SetGPUScissorChecked(device, render_pass, rect), "gpu_set_scissor")
}
def public gpu_set_blend_constants(device : SDL_GPUDevice?; render_pass : GpuRenderPassHandle; color : SDL_FColor) {
    return sdl_status(SDL_SetGPUBlendConstantsChecked(device, render_pass, color), "gpu_set_blend_constants")
}
def public gpu_bind_vertex_buffers(device : SDL_GPUDevice?; render_pass : GpuRenderPassHandle; first : uint;
                                   buffers : array<GpuBufferHandle>; offsets : array<uint>) {
    return sdl_status(SDL_BindGPUVertexBuffersChecked(device, render_pass, first, buffers, offsets), "gpu_bind_vertex_buffers")
}
def public gpu_bind_index_buffer(device : SDL_GPUDevice?; render_pass : GpuRenderPassHandle; index : GpuIndexBufferHandle) {
    return sdl_status(SDL_BindGPUIndexBufferChecked(device, render_pass, index), "gpu_bind_index_buffer")
}
def public gpu_bind_samplers(device : SDL_GPUDevice?; render_pass : GpuRenderPassHandle; stage : SDL_GPUShaderStage;
                             textures : array<GpuTextureHandle>; samplers : array<GpuSamplerHandle>) {
    return sdl_status(SDL_BindGPUSamplersChecked(device, render_pass, stage, textures, samplers), "gpu_bind_samplers")
}
def public gpu_push_uniform(device : SDL_GPUDevice?; command : GpuCommandBufferHandle; stage : SDL_GPUShaderStage;
                            slot : uint; values : array<float4>) {
    return sdl_status(SDL_PushGPUUniformVectorsChecked(device, command, stage, slot, values), "gpu_push_uniform")
}
def public gpu_push_uniform_bytes(device : SDL_GPUDevice?; command : GpuCommandBufferHandle; stage : SDL_GPUShaderStage;
                                  slot : uint; bytes : array<uint8>) {
    return sdl_status(SDL_PushGPUUniformBytesChecked(device, command, stage, slot, bytes), "gpu_push_uniform_bytes")
}
def public gpu_draw_primitives(device : SDL_GPUDevice?; render_pass : GpuRenderPassHandle; vertices : uint;
                               instances : uint = 1u; first_vertex : uint = 0u) {
    return sdl_status(SDL_DrawGPUPrimitivesChecked(device, render_pass, vertices, instances, first_vertex), "gpu_draw_primitives")
}
def public gpu_draw_indexed_primitives(device : SDL_GPUDevice?; render_pass : GpuRenderPassHandle; indices : uint;
                                       instances : uint = 1u; first_index : uint = 0u; base_vertex : int = 0) {
    return sdl_status(SDL_DrawGPUIndexedPrimitivesChecked(device, render_pass, indices, instances, first_index, base_vertex), "gpu_draw_indexed_primitives")
}
