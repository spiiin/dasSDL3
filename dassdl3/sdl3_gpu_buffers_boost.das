options gen2
require daslib/defer
module sdl3_gpu_buffers_boost shared public
require dassdl3/sdl3_gpu_image_boost public

// Copied float32 vertex data. Other layouts can use with_gpu_buffer(bytes, VERTEX).
def public with_gpu_vertex_buffer(device : SDL_GPUDevice?; values : array<float>;
        blk : block<(buffer : uint64) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let id = SDL_CreateGPUFloatVertexBuffer(device,values)
    if (id == 0ul) { return err(sdl_error("with_gpu_vertex_buffer"), type<TT>) }
    {
        defer() { if (!SDL_ReleaseGPUDataBuffer(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUDataBuffer"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}

// Immutable indices retain a CPU copy for draw-time range validation.
def public with_gpu_index_buffer(device : SDL_GPUDevice?; values : array<uint>;
        element : SDL_GPUIndexElementSize; blk : block<(buffer : uint64) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let id = SDL_CreateGPUCheckedIndexBuffer(device,values,element)
    if (id == 0ul) { return err(sdl_error("with_gpu_index_buffer"), type<TT>) }
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

