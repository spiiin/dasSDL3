options gen2
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_gpu_pipeline_boost
require dassdl3/sdl3_gpu_sampler_boost
require dassdl3/sdl3_window_boost

def pipeline_options() {
    // Move the array-owning temporary out of the chain, including a function return.
    return <- (gpu_pipeline(GpuShaderHandle(0ul), GpuShaderHandle(0ul))
        |> vertex_buffer(0u, 16u)
        |> vertex_attribute(0u, 0u, SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2, 0u)
        |> color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
        |> topology(SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
        |> sample_count(SDL_GPUSampleCount.SAMPLECOUNT_1)
        |> rasterizer(SDL_GPURasterizerState(enable_depth_clip = true))
        |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT)
        |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS)
        |> depth_write(true))
}

[export]
def main(unused : bool) : int {
    for (iteration in 0 .. 100) {
        var p <- pipeline_options()
        verify(length(p.buffers) == 1 && p.buffers[0].pitch == 16u)
        verify(length(p.attributes) == 1 && length(p.colors) == 1)
        verify(p.info.depth_stencil_state.enable_depth_write && p.info.depth_stencil_state.enable_depth_test)
        // Reassignment receives the moved result; temporary chains own their arrays.
        p <- p |> vertex_buffer(1u, 80u, SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE)
        p <- p |> depth_write(false) |> depth_test(SDL_GPUCompareOp.COMPAREOP_ALWAYS, false)
        verify(length(p.buffers) == 2 && !p.info.depth_stencil_state.enable_depth_write)
        verify(!p.info.depth_stencil_state.enable_depth_test)
        var moved <- p |> color_target(gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT))
        verify(length(p.buffers) == 0 && length(moved.buffers) == 2 && length(moved.colors) == 2)
        moved <- moved |> stencil_test() |> stencil_faces(SDL_GPUStencilOpState()) |> stencil_masks(uint8(7), uint8(3))
        verify(moved.info.depth_stencil_state.enable_stencil_test && moved.info.depth_stencil_state.write_mask == uint8(3))
    }
    var shader = (gpu_shader("example.spv", SDL_GPU_SHADERFORMAT_SPIRV, SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
        |> entrypoint("entry") |> samplers(2u) |> uniform_buffers(1u) |> storage_buffers(3u) |> storage_textures(4u))
    verify(shader.entrypoint == "entry" && shader.info.num_samplers == 2u && shader.info.num_uniform_buffers == 1u)
    verify(shader.info.num_storage_buffers == 3u && shader.info.num_storage_textures == 4u)
    var texture = (gpu_texture(16u, 8u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER)
        |> texture_shape(SDL_GPUTextureType.TEXTURETYPE_2D_ARRAY, 3u) |> mip_levels(2u)
        |> sample_count(SDL_GPUSampleCount.SAMPLECOUNT_1) |> texture_usage(SDL_GPU_TEXTUREUSAGE_COLOR_TARGET))
    verify(texture.width == 16u && texture.layer_count_or_depth == 3u && texture.num_levels == 2u)
    verify(texture.usage == SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)
    var sampler = (gpu_sampler() |> filters(SDL_GPUFilter.FILTER_LINEAR)
        |> address_modes(SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE)
        |> mipmap_mode(SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR)
        |> lod_range(1.0, 4.0) |> lod_bias(0.5) |> anisotropy(4.0) |> comparison(SDL_GPUCompareOp.COMPAREOP_LESS))
    verify(sampler.min_filter == SDL_GPUFilter.FILTER_LINEAR && sampler.mag_filter == SDL_GPUFilter.FILTER_LINEAR)
    verify(sampler.min_lod == 1.0 && sampler.max_lod == 4.0 && sampler.mip_lod_bias == 0.5)
    verify(sampler.enable_anisotropy && sampler.enable_compare)
    var compute = (gpu_compute_pipeline(SDL_GPU_SHADERFORMAT_SPIRV) |> threadgroup(8u, 4u, 2u)
        |> samplers(1u) |> uniform_buffers(2u) |> readonly_storage_textures(3u) |> readonly_storage_buffers(4u)
        |> readwrite_storage_textures(5u) |> readwrite_storage_buffers(6u))
    verify(compute.threadcount_x == 8u && compute.threadcount_y == 4u && compute.threadcount_z == 2u)
    verify(compute.num_samplers == 1u && compute.num_uniform_buffers == 2u)
    verify(compute.num_readonly_storage_textures == 3u && compute.num_readonly_storage_buffers == 4u)
    verify(compute.num_readwrite_storage_textures == 5u && compute.num_readwrite_storage_buffers == 6u)
    var window = (window_options("chain", int2(800, 600)) |> window_flags(SDL_WINDOW_HIDDEN)
        |> window_flags(SDL_WINDOW_RESIZABLE, false) |> window_position(int2(10, 20)))
    verify(window.position == int2(10, 20) && (window.flags & SDL_WINDOW_HIDDEN) != 0ul)
    verify((window.flags & SDL_WINDOW_RESIZABLE) == 0ul)
    var native = (gpu_graphics_pipeline_info() |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM_S8_UINT)
        |> depth_stencil(SDL_GPUDepthStencilState()) |> depth_test(SDL_GPUCompareOp.COMPAREOP_GREATER)
        |> depth_write(true) |> stencil_test() |> stencil_faces(SDL_GPUStencilOpState(), SDL_GPUStencilOpState())
        |> stencil_masks(uint8(15), uint8(7)) |> multisampling(SDL_GPUMultisampleState()))
    verify(native.depth_stencil_state.enable_depth_test && native.depth_stencil_state.enable_depth_write)
    verify(native.depth_stencil_state.enable_stencil_test && native.depth_stencil_state.compare_mask == uint8(15))
    var color = (gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
        |> blending(SDL_GPUColorTargetBlendState(enable_blend = true)) |> color_write_mask(uint8(7)))
    verify(color.blend_state.enable_blend && color.blend_state.enable_color_write_mask && color.blend_state.color_write_mask == uint8(7))
    print("Fluent builders: temporary lifetime, move, mutation and descriptor fields PASS\n")
    return 0
}

