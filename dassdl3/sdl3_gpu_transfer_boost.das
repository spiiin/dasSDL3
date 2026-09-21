options gen2
require daslib/defer
module sdl3_gpu_transfer_boost shared public
require dassdl3/sdl3_gpu_boost public

// Inputs are copied before returning; buffers have fixed capacity in bytes.
def public create_gpu_buffer(device : SDL_GPUDevice?; bytes : array<uint8>; usage : uint) {
    return checked_handle_result(SDL_CreateGPUDataBuffer(device,bytes,usage),"SDL_CreateGPUDataBuffer")
}

def public request_gpu_buffer_readback(device : SDL_GPUDevice?; buffer : GpuBufferHandle; offset, size : uint) {
    return checked_handle_result(SDL_RequestGPUBufferReadback(device,buffer,offset,size),"SDL_RequestGPUBufferReadback")
}

def public with_gpu_buffer(device : SDL_GPUDevice?; bytes : array<uint8>; usage : uint;
        blk : block<(buffer : GpuBufferHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let acquired = create_gpu_buffer(device,bytes,usage)
    if (is_err(acquired)) { return err(unwrap_err(acquired),type<TT>) }
    let id = unwrap(acquired)
    {
        defer() { if (!SDL_ReleaseGPUDataBuffer(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUDataBuffer"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}

// Partial updates preserve the rest of the buffer. Cycling requires a full update.
def public gpu_update_buffer(device : SDL_GPUDevice?; buffer : GpuBufferHandle; offset : uint;
        bytes : array<uint8>; cycle : bool = false) {
    return sdl_status(SDL_UpdateGPUDataBuffer(device,buffer,offset,bytes,cycle), "gpu_update_buffer")
}

def public gpu_copy_buffer(device : SDL_GPUDevice?; source : GpuBufferHandle; source_offset : uint;
        destination : GpuBufferHandle; destination_offset, size : uint) {
    return sdl_status(SDL_CopyGPUDataBuffer(device,source,source_offset,destination,destination_offset,size), "gpu_copy_buffer")
}

// Requests and submits a snapshot, then invokes script. This is not a recording
// scope. Closing it discards the ticket; pending GPU work remains submitted.
def public with_gpu_readback(device : SDL_GPUDevice?; buffer : GpuBufferHandle; offset, size : uint;
        blk : block<(readback : GpuReadbackHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let acquired = request_gpu_buffer_readback(device,buffer,offset,size)
    if (is_err(acquired)) { return err(unwrap_err(acquired),type<TT>) }
    let id = unwrap(acquired)
    {
        defer() { if (!SDL_ReleaseGPUReadback(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUReadback"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}

// -1 = error, 0 = pending, 1 = ready. A failure is not a pending readback.
def public gpu_poll_readback(device : SDL_GPUDevice?; ticket : GpuReadbackHandle) {
    let state = SDL_PollGPUReadback(device,ticket)
    if (state < 0) { return err(sdl_error("gpu_poll_readback"), type<bool>) }
    return ok(state == 1, type<SdlError>)
}

def public gpu_wait_readback(device : SDL_GPUDevice?; ticket : GpuReadbackHandle) {
    return sdl_status(SDL_WaitGPUReadback(device,ticket), "gpu_wait_readback")
}

// Does not resize or retain output. It must match the requested byte count.
def public gpu_readback_bytes(device : SDL_GPUDevice?; ticket : GpuReadbackHandle; var bytes : array<uint8>) {
    return sdl_status(SDL_ReadGPUReadback(device,ticket,bytes), "gpu_readback_bytes")
}
