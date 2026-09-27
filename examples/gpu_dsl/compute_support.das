options gen2
module compute_support shared public
require dassdl3/sdl3_shader_compute public
require dassdl3/sdl3_shader_uniforms
require dassdl3/sdl3_scope
require daslib/defer
require compute_shaders

// Includes a tail beyond count to prove the shader's bound check under over-dispatch.
def public run_compute(device : SDL_GPUDevice?; pipeline : SDL_GPUComputePipeline?) : SdlStatus {
    let capacity = 192
    let count = 131u
    let nbytes = uint(capacity * 4)
    var initial : array<uint8>; resize(initial, int(nbytes))
    for (i in 0 .. capacity) {
        var word = uint(i * i + 17)
        for (b in 0 .. 4) {initial[i * 4 + b] = uint8(word % 256u); word /= 256u}
    }
    return sdl_scope() {
        var storage : SDL_GPUBuffer? = with_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE, size = nbytes)) |> sdl_use
        var upload : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device,
            SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = nbytes)) |> sdl_use
        var download : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device,
            SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD, size = nbytes)) |> sdl_use
        sdl_status(SDL_WriteGPUTransferBufferBytes(device, upload, nbytes, 0u, initial, false), "SDL_WriteGPUTransferBufferBytes") |> sdl_try
        with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
            with_native_gpu_copy_pass(command) $(var copy_pass : SDL_GPUCopyPass?&) {
                let source = SDL_GPUTransferBufferLocation(transfer_buffer = upload)
                let destination = SDL_GPUBufferRegion(buffer = storage, size = nbytes)
                SDL_UploadToGPUBufferRef(copy_pass, source, destination, false)
                return sdl_ok()
            } |> sdl_try
            // Separate passes establish ordering for two dependent read-modify-write dispatches.
            for (round in 0 .. 2) {
                let uniforms = ComputeParams(count = count, factor = round == 0 ? 3u : 2u, bias = round == 0 ? 7u : 11u)
                push_gpu_dsl_compute_uniform(command, 0u, uniforms) |> sdl_try
                var textures : array<SDL_GPUStorageTextureReadWriteBinding>
                var buffers <- array(SDL_GPUStorageBufferReadWriteBinding(buffer = storage, cycle = false))
                with_native_gpu_compute_pass(command, textures, buffers) $(var compute_pass : SDL_GPUComputePass?&) {
                    SDL_BindGPUComputePipeline(compute_pass, pipeline)
                    SDL_DispatchGPUCompute(compute_pass, (count + 63u) / 64u, 1u, 1u)
                    return sdl_ok()
                } |> sdl_try
            }
            with_native_gpu_copy_pass(command) $(var copy_pass : SDL_GPUCopyPass?&) {
                let source = SDL_GPUBufferRegion(buffer = storage, size = nbytes)
                let destination = SDL_GPUTransferBufferLocation(transfer_buffer = download)
                SDL_DownloadFromGPUBufferRef(copy_pass, source, destination)
                return sdl_ok()
            } |> sdl_try
            var fence = native_gpu_submit_fence(command) |> sdl_try
            {
                defer() {SDL_ReleaseGPUFence(device, fence)}
                var fences <- array(fence)
                return sdl_status(SDL_WaitForGPUFencesArray(device, true, fences), "SDL_WaitForGPUFencesArray")
            }
        } |> sdl_try
        var bytes : array<uint8>; resize(bytes, int(nbytes))
        sdl_status(SDL_ReadGPUTransferBufferBytes(device, download, nbytes, 0u, bytes), "SDL_ReadGPUTransferBufferBytes") |> sdl_try
        for (i in 0 .. capacity) {
            var actual = 0u
            for (b in 0 .. 4) {actual = actual * 256u + uint(bytes[i * 4 + 3 - b])}
            let input = uint(i * i + 17)
            let expected = uint(i) < count ? (input * 3u + 7u) * 2u + 11u : input
            if (actual != expected) {
                return err(SdlError(operation = "run_compute", message = "GPU result mismatch at {i}: {actual}, expected {expected}"), type<SdlUnit>)
            }
        }
        print("Compute: 131 values transformed twice; 61 tail values unchanged.\n")
        return sdl_ok()
    }
}
