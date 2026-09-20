options gen2
require daslib/defer
module sdl3_gpu_buffers_boost shared public
require dassdl3/sdl3_gpu_image_boost public

// Copied float32 vertex data. Other layouts can use with_gpu_buffer(bytes, VERTEX).
def public with_gpu_vertex_buffer(device : SDL_GPUDevice?; values : array<float>;
        blk : block<(buffer : uint64) : void>) {
    let id = SDL_CreateGPUFloatVertexBuffer(device,values)
    if (id == 0ul) { return false }
    {
        defer() { SDL_ReleaseGPUDataBuffer(device,id) }
        blk(id)
        return true
    }
}

// Immutable indices retain a CPU copy for draw-time range validation.
def public with_gpu_index_buffer(device : SDL_GPUDevice?; values : array<uint>;
        element : SDL_GPUIndexElementSize; blk : block<(buffer : uint64) : void>) {
    let id = SDL_CreateGPUCheckedIndexBuffer(device,values,element)
    if (id == 0ul) { return false }
    {
        defer() { SDL_ReleaseGPUCheckedIndexBuffer(device,id) }
        blk(id)
        return true
    }
}

// Viewport and scissor use top-left pixel coordinates; SDL handles backend Y.
def public gpu_viewport(width, height : float) : SDL_GPUViewport {
    var value : SDL_GPUViewport
    value.w = width; value.h = height; value.max_depth = 1.0
    return value
}

