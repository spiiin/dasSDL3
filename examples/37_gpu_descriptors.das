options gen2
require dassdl3/sdl3_gpu_native_boost

// Native descriptors and their builder. No GPU resources are created here.
[export]
def main(smoke : bool) : int {
    var texture = gpu_texture(256u, 128u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,
        SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)
    verify(texture.props == 0u)
    let bytes = SDL_CalculateGPUTextureFormatSize(texture.format, texture.width, texture.height, texture.layer_count_or_depth)
    verify(bytes == 131072u)

    var vertex = SDL_GPUVertexBufferDescription(slot = 0u, pitch = 12u, input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX)
    verify(vertex.instance_step_rate == 0u) // Reserved by SDL 3.2.18.
    var position = SDL_GPUVertexAttribute(
        location = 0u,
        buffer_slot = vertex.slot,
        format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3,
        offset = 0u
    )

    var raster = SDL_GPURasterizerState(
        fill_mode = SDL_GPUFillMode.FILLMODE_FILL,
        cull_mode = SDL_GPUCullMode.CULLMODE_BACK,
        front_face = SDL_GPUFrontFace.FRONTFACE_COUNTER_CLOCKWISE,
        enable_depth_clip = true
    )
    var samples = SDL_GPUMultisampleState(sample_count = SDL_GPUSampleCount.SAMPLECOUNT_1)
    verify(samples.sample_mask == 0u && !samples.enable_mask)

    var viewport = SDL_GPUViewport(w = float(texture.width), h = float(texture.height), max_depth = 1.0)
    var draw = SDL_GPUIndirectDrawCommand(num_vertices = 3u, num_instances = 1u)
    var indexed = SDL_GPUIndexedIndirectDrawCommand(num_indices = 6u, num_instances = 1u, vertex_offset = -2)
    var compute = SDL_GPUIndirectDispatchCommand(groupcount_x = 4u, groupcount_y = 1u, groupcount_z = 1u)
    var buffer = SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_INDIRECT, size = 16u)
    print("GPU descriptors: {int(texture.width)}x{int(texture.height)}, {int(bytes)} bytes; typed layouts and draw parameters ready\n")
    return 0
}
