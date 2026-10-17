options gen2
module bgfx_buffer_checks shared public
require bgfx_capture public
require daslib/defer
require daslib/math_bits public

def word(bytes : array<uint8>; at : int) : uint {
    return uint(bytes[at]) | (uint(bytes[at + 1]) << 8u) | (uint(bytes[at + 2]) << 16u) | (uint(bytes[at + 3]) << 24u)
}
def vector3(bytes : array<uint8>; at : int) : float3 {
    return float3(uint_bits_to_float(word(bytes, at)), uint_bits_to_float(word(bytes, at + 4)), uint_bits_to_float(word(bytes, at + 8)))
}
def read_buffer(device : SDL_GPUDevice?; var buffer : SDL_GPUBuffer?; size : uint) {
    return sdl_scope() {
        var download : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD, size = size)) |> sdl_use
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        with_native_gpu_copy_pass(command) $(var pass_ : SDL_GPUCopyPass?&) {
            SDL_DownloadFromGPUBufferRef(pass_, SDL_GPUBufferRegion(buffer = buffer, size = size), SDL_GPUTransferBufferLocation(transfer_buffer = download)); return sdl_ok()
        } |> sdl_try
        var fence = native_gpu_submit_fence(command) |> sdl_try
        {
            defer() { SDL_ReleaseGPUFence(device, fence) }
            let fences <- array(fence)
            sdl_status(SDL_WaitForGPUFencesArray(device, true, fences), "Wait test readback") |> sdl_try
        }
        var bytes : array<uint8>; resize(bytes, int(size))
        sdl_status(SDL_ReadGPUTransferBufferBytes(device, download, size, 0u, bytes), "Test buffer readback") |> sdl_try
        return <- move_ok(bytes, type<SdlError>)
    }
}
