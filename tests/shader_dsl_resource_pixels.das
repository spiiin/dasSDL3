options gen2
module shader_dsl_resource_pixels shared public
require shader_dsl_resource_shaders
require dassdl3/sdl3_shader_compute public
require dassdl3/sdl3_shader_storage
require dassdl3/sdl3_scope
require ../examples/gpu_dsl/texture_support.das
require math
require daslib/defer

def private checker(x, y : int) : float3 {
    return float3(x == y ? 1.0 : 0.0, x == 1 ? 1.0 : 0.0, y == 1 ? 1.0 : 0.0)
}
def private expected_compute(x, y : int) : float3 {
    return checker(x / 4, y / 4) * 0.5 + checker(x % 2, y % 2) * 0.25 + float3(0.125, 0.0625, 0.03125)
}
def private quantized(v : float3) : float3 {return floor(v * 255.0 + float3(0.5)) / 255.0}

def public check_resources(device : SDL_GPUDevice?; compute, rmw : SDL_GPUComputePipeline?; var vertex, fragment : SDL_GPUShader?) : SdlStatus {
    var items : array<StorageItem>; resize(items, 64)
    for (i in 0 .. 64) {items[i] = StorageItem(rgb = float3(0.25, 0.125, 0.0625), scale = 0.5); items[i].extras[0] = uint(i); items[i].extras[1] = uint(i * 2)}
    var packed <- gpu_dsl_storage_bytes(items) |> sdl_try
    verify(length(packed) == 2048)
    var pipeline_info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vertex, fragment_shader = fragment, primitive_type = SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
    pipeline_info.rasterizer_state.enable_depth_clip = true
    var layouts : array<SDL_GPUVertexBufferDescription>; var attributes : array<SDL_GPUVertexAttribute>
    var colors <- array(SDL_GPUColorTargetDescription(format = SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
    return sdl_scope() {
        let pipeline : SDL_GPUGraphicsPipeline? = with_native_gpu_graphics_pipeline(device, pipeline_info, layouts, attributes, colors) |> sdl_use
        var input : SDL_GPUBuffer? = with_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ, size = 2048u)) |> sdl_use
        var output : SDL_GPUBuffer? = with_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE | SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ, size = 2048u)) |> sdl_use
        var source : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(2u, 2u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_use
        var readonly_image : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(2u, 2u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ)) |> sdl_use
        var image : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(8u, 8u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE | SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ)) |> sdl_use
        var target : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(8u, 8u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        var sampler : SDL_GPUSampler? = with_native_gpu_sampler(device, checker_sampler()) |> sdl_use
        var upload : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = 2048u)) |> sdl_use
        var download : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD, size = 2560u)) |> sdl_use
        upload_checker(device, source) |> sdl_try
        upload_checker(device, readonly_image) |> sdl_try
        sdl_status(SDL_WriteGPUTransferBufferBytes(device, upload, 2048u, 0u, packed, false), "SDL_WriteGPUTransferBufferBytes") |> sdl_try
        with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
            with_native_gpu_copy_pass(command) $(var gpu_pass : SDL_GPUCopyPass?&) {
                let from = SDL_GPUTransferBufferLocation(transfer_buffer = upload)
                let to = SDL_GPUBufferRegion(buffer = input, size = 2048u)
                SDL_UploadToGPUBufferRef(gpu_pass, from, to, false)
                return sdl_ok()
            } |> sdl_try
            var rw_textures <- array(SDL_GPUStorageTextureReadWriteBinding(texture = image))
            var rw_buffers <- array(SDL_GPUStorageBufferReadWriteBinding(buffer = output))
            with_native_gpu_compute_pass(command, rw_textures, rw_buffers) $(var gpu_pass : SDL_GPUComputePass?&) {
                SDL_BindGPUComputePipeline(gpu_pass, compute)
                var samplers <- array(SDL_GPUTextureSamplerBinding(texture = source, sampler = sampler))
                var textures <- array(readonly_image); var buffers <- array(input)
                sdl_status(SDL_BindGPUComputeSamplersArray(gpu_pass, 0u, samplers), "SDL_BindGPUComputeSamplersArray") |> sdl_try
                sdl_status(SDL_BindGPUComputeStorageTexturesArray(gpu_pass, 0u, textures), "SDL_BindGPUComputeStorageTexturesArray") |> sdl_try
                sdl_status(SDL_BindGPUComputeStorageBuffersArray(gpu_pass, 0u, buffers), "SDL_BindGPUComputeStorageBuffersArray") |> sdl_try
                SDL_DispatchGPUCompute(gpu_pass, 2u, 2u, 1u)
                return sdl_ok()
            } |> sdl_try
            var image_only_buffers : array<SDL_GPUStorageBufferReadWriteBinding>
            with_native_gpu_compute_pass(command, rw_textures, image_only_buffers) $(var gpu_pass : SDL_GPUComputePass?&) {
                SDL_BindGPUComputePipeline(gpu_pass, rmw)
                SDL_DispatchGPUCompute(gpu_pass, 2u, 2u, 1u)
                return sdl_ok()
            } |> sdl_try
            var targets <- array(SDL_GPUColorTargetInfo(texture = target, load_op = SDL_GPULoadOp.LOADOP_CLEAR, store_op = SDL_GPUStoreOp.STOREOP_STORE))
            with_native_gpu_render_pass(command, targets) $(var gpu_pass : SDL_GPURenderPass?&) {
                SDL_BindGPUGraphicsPipeline(gpu_pass, pipeline)
                var samplers <- array(SDL_GPUTextureSamplerBinding(texture = source, sampler = sampler))
                var textures <- array(image); var buffers <- array(output)
                sdl_status(SDL_BindGPUVertexSamplersArray(gpu_pass, 0u, samplers), "SDL_BindGPUVertexSamplersArray") |> sdl_try
                sdl_status(SDL_BindGPUVertexStorageTexturesArray(gpu_pass, 0u, textures), "SDL_BindGPUVertexStorageTexturesArray") |> sdl_try
                sdl_status(SDL_BindGPUVertexStorageBuffersArray(gpu_pass, 0u, buffers), "SDL_BindGPUVertexStorageBuffersArray") |> sdl_try
                sdl_status(SDL_BindGPUFragmentSamplersArray(gpu_pass, 0u, samplers), "SDL_BindGPUFragmentSamplersArray") |> sdl_try
                sdl_status(SDL_BindGPUFragmentStorageTexturesArray(gpu_pass, 0u, textures), "SDL_BindGPUFragmentStorageTexturesArray") |> sdl_try
                sdl_status(SDL_BindGPUFragmentStorageBuffersArray(gpu_pass, 0u, buffers), "SDL_BindGPUFragmentStorageBuffersArray") |> sdl_try
                SDL_DrawGPUPrimitives(gpu_pass, 3u, 1u, 0u, 0u)
                return sdl_ok()
            } |> sdl_try
            with_native_gpu_copy_pass(command) $(var gpu_pass : SDL_GPUCopyPass?&) {
                let from_image = SDL_GPUTextureRegion(texture = image, w = 8u, h = 8u, d = 1u)
                let from_target = SDL_GPUTextureRegion(texture = target, w = 8u, h = 8u, d = 1u)
                let image_to = SDL_GPUTextureTransferInfo(transfer_buffer = download, pixels_per_row = 8u, rows_per_layer = 8u)
                let target_to = SDL_GPUTextureTransferInfo(transfer_buffer = download, offset = 256u, pixels_per_row = 8u, rows_per_layer = 8u)
                SDL_DownloadFromGPUTextureRef(gpu_pass, from_image, image_to)
                SDL_DownloadFromGPUTextureRef(gpu_pass, from_target, target_to)
                let from_buffer = SDL_GPUBufferRegion(buffer = output, size = 2048u)
                let buffer_to = SDL_GPUTransferBufferLocation(transfer_buffer = download, offset = 512u)
                SDL_DownloadFromGPUBufferRef(gpu_pass, from_buffer, buffer_to)
                return sdl_ok()
            } |> sdl_try
            var fence = native_gpu_submit_fence(command) |> sdl_try
            {
                defer() {SDL_ReleaseGPUFence(device, fence)}
                var fences <- array(fence)
                return sdl_status(SDL_WaitForGPUFencesArray(device, true, fences), "SDL_WaitForGPUFencesArray")
            }
        } |> sdl_try
        var pixels : array<uint8>; resize(pixels, 512)
        sdl_status(SDL_ReadGPUTransferBufferBytes(device, download, 2560u, 0u, pixels), "SDL_ReadGPUTransferBufferBytes") |> sdl_try
        sdl_status(SDL_ReadGPUTransferBufferBytes(device, download, 2560u, 512u, packed), "SDL_ReadGPUTransferBufferBytes") |> sdl_try
        unpack_gpu_dsl_storage(packed, items) |> sdl_try
        let vertex_color = checker(0, 0) * 0.125 + quantized(expected_compute(0, 0).zyx) * 0.25 + expected_compute(0, 0) * 0.125
        for (y in 0 .. 8) {for (x in 0 .. 8) {
            let i = y * 8 + x; let compute_color = expected_compute(x, y)
            let render_color = vertex_color * 0.25 + checker(x / 4, y / 4) * 0.125 + quantized(compute_color.zyx) * 0.25 + compute_color * 0.25
            for (c in 0 .. 3) {
                verify(abs(float(pixels[i * 4 + c]) - floor(compute_color[2 - c] * 255.0 + 0.5)) <= 1.0)
                verify(abs(float(pixels[256 + i * 4 + c]) - floor(render_color[c] * 255.0 + 0.5)) <= 1.0)
                verify(abs(items[i].rgb[c] - compute_color[c]) < 0.00001)
            }
            verify(pixels[i * 4 + 3] == uint8(255) && pixels[256 + i * 4 + 3] == uint8(255))
            verify(items[i].scale == 1.0 && items[i].extras[0] == uint(i + 3) && items[i].extras[1] == uint(i * 2 + 7))
        }}
        return sdl_ok()
    }
}
