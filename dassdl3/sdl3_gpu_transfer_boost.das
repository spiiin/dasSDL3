options gen2
module sdl3_gpu_transfer_boost shared public
require dassdl3/sdl3_gpu_boost public

// Inputs are copied before returning; buffers have fixed capacity in bytes.
def public with_gpu_buffer(device : SDL_GPUDevice?; bytes : array<uint8>; usage : uint;
        blk : block<(buffer : uint64) : void>) {
    let id = SDL_CreateGPUDataBuffer(device,bytes,usage)
    if (id == 0ul) { panic("GPU buffer: {SDL_GetError()}") }
    SDL_ScopeReleaseGPUDataBuffer(device,id,blk)
}

// Partial updates preserve the rest of the buffer. Cycling requires a full update.
def public gpu_update_buffer(device : SDL_GPUDevice?; buffer : uint64; offset : uint;
        bytes : array<uint8>; cycle : bool = false) {
    if (!SDL_UpdateGPUDataBuffer(device,buffer,offset,bytes,cycle)) { panic("GPU upload: {SDL_GetError()}") }
}

def public gpu_copy_buffer(device : SDL_GPUDevice?; source : uint64; source_offset : uint;
        destination : uint64; destination_offset, size : uint) {
    if (!SDL_CopyGPUDataBuffer(device,source,source_offset,destination,destination_offset,size)) {
        panic("GPU copy: {SDL_GetError()}")
    }
}

// Requests and submits a snapshot, then invokes script. This is not a recording
// scope. Closing it discards the ticket; pending GPU work remains submitted.
def public with_gpu_readback(device : SDL_GPUDevice?; buffer : uint64; offset, size : uint;
        blk : block<(readback : uint64) : void>) {
    let id = SDL_RequestGPUBufferReadback(device,buffer,offset,size)
    if (id == 0ul) { panic("GPU readback request: {SDL_GetError()}") }
    SDL_ScopeReleaseGPUReadback(device,id,blk)
}

def public gpu_readback_ready(device : SDL_GPUDevice?; ticket : uint64) : bool {
    let state = SDL_PollGPUReadback(device,ticket)
    if (state < 0) { panic("GPU readback poll: {SDL_GetError()}") }
    return state == 1
}

def public gpu_wait_readback(device : SDL_GPUDevice?; ticket : uint64) {
    if (!SDL_WaitGPUReadback(device,ticket)) { panic("GPU readback wait: {SDL_GetError()}") }
}

// Does not resize or retain output. It must match the requested byte count.
def public gpu_readback_bytes(device : SDL_GPUDevice?; ticket : uint64; var bytes : array<uint8>) {
    if (!SDL_ReadGPUReadback(device,ticket,bytes)) { panic("GPU readback bytes: {SDL_GetError()}") }
}
