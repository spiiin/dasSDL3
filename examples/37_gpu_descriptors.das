options gen2
require sdl3

// Generated value types only. This example does not create a graphics pipeline.
[export]
def main(smoke : bool) : int {
    var texture : SDL_GPUTextureCreateInfo
    texture.texture_type = SDL_GPUTextureType.TEXTURETYPE_2D
    texture.format = SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM
    texture.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET
    texture.width = 256u; texture.height = 128u
    texture.layer_count_or_depth = 1u; texture.num_levels = 1u
    texture.sample_count = SDL_GPUSampleCount.SAMPLECOUNT_1
    verify(texture.props == 0u)
    let bytes = SDL_CalculateGPUTextureFormatSize(texture.format,texture.width,texture.height,texture.layer_count_or_depth)
    verify(bytes == 131072u)

    var vertex : SDL_GPUVertexBufferDescription
    vertex.slot = 0u; vertex.pitch = 12u
    vertex.input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX
    verify(vertex.instance_step_rate == 0u) // Reserved by SDL 3.2.18.
    var position : SDL_GPUVertexAttribute
    position.location = 0u; position.buffer_slot = vertex.slot
    position.format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3
    position.offset = 0u

    var raster : SDL_GPURasterizerState
    raster.fill_mode = SDL_GPUFillMode.FILLMODE_FILL
    raster.cull_mode = SDL_GPUCullMode.CULLMODE_BACK
    raster.front_face = SDL_GPUFrontFace.FRONTFACE_COUNTER_CLOCKWISE
    raster.enable_depth_clip = true
    var samples : SDL_GPUMultisampleState
    samples.sample_count = SDL_GPUSampleCount.SAMPLECOUNT_1
    verify(samples.sample_mask == 0u && !samples.enable_mask)

    var viewport : SDL_GPUViewport
    viewport.w = float(texture.width); viewport.h = float(texture.height)
    viewport.max_depth = 1.0
    var draw : SDL_GPUIndirectDrawCommand
    draw.num_vertices = 3u; draw.num_instances = 1u
    var indexed : SDL_GPUIndexedIndirectDrawCommand
    indexed.num_indices = 6u; indexed.num_instances = 1u
    indexed.vertex_offset = -2
    var compute : SDL_GPUIndirectDispatchCommand
    compute.groupcount_x = 4u; compute.groupcount_y = 1u; compute.groupcount_z = 1u
    var buffer : SDL_GPUBufferCreateInfo
    buffer.usage = SDL_GPU_BUFFERUSAGE_INDIRECT; buffer.size = 16u
    print("GPU descriptors: {int(texture.width)}x{int(texture.height)}, {int(bytes)} bytes; typed layouts and draw parameters ready\n")
    return 0
}
