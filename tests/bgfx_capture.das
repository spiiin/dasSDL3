options gen2
module bgfx_capture shared public
require dassdl3/sdl3_scope public
require dassdl3/sdl3_gpu_native_boost public
require dassdl3/sdl3_iostream_boost
require dassdl3/sdl3_init_boost
require daslib/defer

def read_image(device : SDL_GPUDevice?; var color : SDL_GPUTexture?; width, height : uint; name : string; bytes_per_pixel : uint = 4u) {
    return sdl_scope() {
        let size = width * height * bytes_per_pixel
        var download : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(
            SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD, size = size)) |> sdl_use
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        with_native_gpu_copy_pass(command) $(var copy_pass) {
            let source = SDL_GPUTextureRegion(texture = color, w = width, h = height, d = 1u)
            let target = SDL_GPUTextureTransferInfo(transfer_buffer = download, pixels_per_row = width, rows_per_layer = height)
            SDL_DownloadFromGPUTextureRef(copy_pass, source, target)
            return sdl_ok()
        } |> sdl_try
        var fence = native_gpu_submit_fence(command) |> sdl_try
        {
            defer() { SDL_ReleaseGPUFence(device, fence) }
            let fences <- array(fence)
            sdl_status(SDL_WaitForGPUFencesArray(device, true, fences), "SDL_WaitForGPUFencesArray") |> sdl_try
        }
        var bytes : array<uint8>; resize(bytes, int(size))
        sdl_status(SDL_ReadGPUTransferBufferBytes(device, download, size, 0u, bytes), "SDL_ReadGPUTransferBufferBytes") |> sdl_try
        let folder = hint_string("DASSDL3_BGFX_CAPTURE") |> unwrap_or("")
        let extension = bytes_per_pixel == 4u ? "rgba" : "rgba16f"
        if (folder != "") { save_file("{folder}/{name}.{extension}", bytes) |> sdl_try }
        return <- move_ok(bytes, type<SdlError>)
    }
}

def image_hash(bytes : array<uint8>) {
    var hash = 2166136261u
    for (byte in bytes) { hash = (hash ^ uint(byte)) * 16777619u }
    return hash
}

