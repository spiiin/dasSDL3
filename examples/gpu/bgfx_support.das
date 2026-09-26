options gen2
module bgfx_support shared public
// Small application-local SDL operations shared by the bgfx ports.
require dassdl3/sdl3_scope public
require dassdl3/sdl3_gpu_native_boost public
require dassdl3/sdl3_gpu_pipeline_boost public
require dassdl3/sdl3_iostream_boost public
require daslib/defer

def texture(device : SDL_GPUDevice?; width, height : uint; format : SDL_GPUTextureFormat; usage : uint; cube : bool = false) {
    var info = gpu_texture(width, height, format, usage)
    if (cube) { info |> texture_shape(SDL_GPUTextureType.TEXTURETYPE_CUBE, 6u) }
    var result = SDL_CreateGPUTextureRef(device, info)
    if (result == null) { return err(sdl_error("SDL_CreateGPUTexture"), type<SDL_GPUTexture?>) }
    return <- move_ok(result, type<SdlError>)
}

def pipeline(device : SDL_GPUDevice?; vertex_name, fragment_name : string; format : SDL_GPUTextureFormat;
             depth : bool; sampler_count : uint; buffers : array<SDL_GPUVertexBufferDescription>; attributes : array<SDL_GPUVertexAttribute>; cull : bool = false) {
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let shader_format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let extension = spirv ? "spv" : "dxil"
    let path = "{SDL_GetBasePath()}assets/shaders/"
    var vs = gpu_shader("{path}{vertex_name}.vert.{extension}", shader_format, SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    vs |> uniform_buffers(1u)
    var fs = gpu_shader("{path}{fragment_name}.frag.{extension}", shader_format, SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    fs |> samplers(sampler_count)
    return sdl_scope() {
        var vertex : SDL_GPUShader? = device |> with_native_gpu_shader_file(vs) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_native_gpu_shader_file(fs) |> sdl_use
        var info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vertex, fragment_shader = fragment)
        info |> topology(SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
        info |> rasterizer(SDL_GPURasterizerState(enable_depth_clip = true))
        if (cull) { info.rasterizer_state.cull_mode = SDL_GPUCullMode.CULLMODE_BACK; info.rasterizer_state.front_face = SDL_GPUFrontFace.FRONTFACE_CLOCKWISE }
        if (depth) {
            info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT)
            info |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS)
            info |> depth_write(true)
        }
        let colors <- array(gpu_color_target(format))
        return <- create_native_gpu_graphics_pipeline(device, info, buffers, attributes, colors)
    }
}

def upload_floats(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var buffer : SDL_GPUBuffer?;
                  var transfer : SDL_GPUTransferBuffer?; capacity : uint; values : array<float>) {
    device |> write_native_gpu_transfer_floats(transfer, capacity, 0u, values, true) |> sdl_try
    return with_native_gpu_copy_pass(command) $(var copy_pass) {
        let source = SDL_GPUTransferBufferLocation(transfer_buffer = transfer)
        let destination = SDL_GPUBufferRegion(buffer = buffer, size = uint(length(values)) * 4u)
        SDL_UploadToGPUBufferRef(copy_pass, source, destination, true)
        return sdl_ok()
    }
}

def upload_texture(device : SDL_GPUDevice?; var target : SDL_GPUTexture?; filename : string; width, height, bytes_per_pixel, layers : uint) {
    let bytes <- load_file("{SDL_GetBasePath()}assets/bgfx/{filename}") |> sdl_try
    let face_size = width * height * bytes_per_pixel
    if (uint(length(bytes)) != face_size * layers) { return err(SdlError(operation = filename, message = "Unexpected texture payload size"), type<SdlUnit>) }
    return sdl_scope() {
        var transfer : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(
            SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = uint(length(bytes)))) |> sdl_use
        sdl_status(SDL_WriteGPUTransferBufferBytes(device, transfer, uint(length(bytes)), 0u, bytes, false), "SDL_WriteGPUTransferBufferBytes") |> sdl_try
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        with_native_gpu_copy_pass(command) $(var copy_pass) {
            for (layer in 0u .. layers) {
                let source = SDL_GPUTextureTransferInfo(transfer_buffer = transfer, offset = face_size * layer, pixels_per_row = width, rows_per_layer = height)
                let destination = SDL_GPUTextureRegion(texture = target, layer = layer, w = width, h = height, d = 1u)
                SDL_UploadToGPUTextureRef(copy_pass, source, destination, false)
            }
            return sdl_ok()
        } |> sdl_try
        return native_gpu_submit(command)
    }
}

def upload_bytes(device : SDL_GPUDevice?; var buffer : SDL_GPUBuffer?; bytes : array<uint8>) {
    let size = uint(length(bytes))
    return sdl_scope() {
        var transfer : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(
            SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = size)) |> sdl_use
        sdl_status(SDL_WriteGPUTransferBufferBytes(device, transfer, size, 0u, bytes, false), "SDL_WriteGPUTransferBufferBytes") |> sdl_try
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        with_native_gpu_copy_pass(command) $(var copy_pass) {
            let source = SDL_GPUTransferBufferLocation(transfer_buffer = transfer)
            let destination = SDL_GPUBufferRegion(buffer = buffer, size = size)
            SDL_UploadToGPUBufferRef(copy_pass, source, destination, false)
            return sdl_ok()
        } |> sdl_try
        return native_gpu_submit(command)
    }
}

def depth_attachment(var target : SDL_GPUTexture?) {
    return SDL_GPUDepthStencilTargetInfo(texture = target, clear_depth = 1.0, load_op = SDL_GPULoadOp.LOADOP_CLEAR,
        store_op = SDL_GPUStoreOp.STOREOP_DONT_CARE, stencil_load_op = SDL_GPULoadOp.LOADOP_DONT_CARE, stencil_store_op = SDL_GPUStoreOp.STOREOP_DONT_CARE)
}

def replace_depth(device : SDL_GPUDevice?; var target : SDL_GPUTexture?&; var size : uint2&; width, height : uint) {
    if (size.x != width || size.y != height) {
        var replacement = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try
        if (target != null) { SDL_ReleaseGPUTexture(device, target) }
        target = replacement; size = uint2(width, height)
    }
    return sdl_ok()
}
