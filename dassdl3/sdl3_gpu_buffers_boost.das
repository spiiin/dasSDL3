options gen2
require daslib/defer
module sdl3_gpu_buffers_boost shared public
require dassdl3/sdl3_gpu_image_boost public

// Copied float32 vertex data. Other layouts can use with_gpu_buffer(bytes, VERTEX).
def public create_gpu_vertex_buffer(device : SDL_GPUDevice?; values : array<float>) {
    return checked_handle_result(SDL_CreateGPUFloatVertexBuffer(device,values),"SDL_CreateGPUFloatVertexBuffer")
}

def public create_gpu_index_buffer(device : SDL_GPUDevice?; values : array<uint>;
        element : SDL_GPUIndexElementSize) {
    return checked_handle_result(SDL_CreateGPUCheckedIndexBuffer(device,values,element),"SDL_CreateGPUCheckedIndexBuffer")
}

def public with_gpu_vertex_buffer(device : SDL_GPUDevice?; values : array<float>;
        blk : block<(buffer : GpuBufferHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let acquired = create_gpu_vertex_buffer(device,values)
    if (is_err(acquired)) { return err(unwrap_err(acquired),type<TT>) }
    let id = unwrap(acquired)
    {
        defer() { if (!SDL_ReleaseGPUDataBuffer(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUDataBuffer"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}

// Immutable indices retain a CPU copy for draw-time range validation.
def public with_gpu_index_buffer(device : SDL_GPUDevice?; values : array<uint>;
        element : SDL_GPUIndexElementSize; blk : block<(buffer : GpuIndexBufferHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let acquired = create_gpu_index_buffer(device,values,element)
    if (is_err(acquired)) { return err(unwrap_err(acquired),type<TT>) }
    let id = unwrap(acquired)
    {
        defer() { if (!SDL_ReleaseGPUCheckedIndexBuffer(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUCheckedIndexBuffer"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}

// Viewport and scissor use top-left pixel coordinates; SDL handles backend Y.
def public gpu_viewport(width, height : float) : SDL_GPUViewport {
    var value : SDL_GPUViewport
    value.w = width; value.h = height; value.max_depth = 1.0
    return value
}

