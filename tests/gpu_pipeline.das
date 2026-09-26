options gen2
require dassdl3/sdl3_gpu_pipeline_boost
require dassdl3/sdl3_gpu_sampler_boost
require daslib/rtti
require strings

def check_triangle(device : SDL_GPUDevice?; vertex, fragment : string; format : uint) {
    let vi = gpu_shader_info(format, SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    let fi = gpu_shader_info(format, SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    let vs = SDL_LoadGPUCheckedShader(device, vertex, vi, "main")
    let fs = SDL_LoadGPUCheckedShader(device, fragment, fi, "main")
    verify(*vs != 0ul && *fs != 0ul)
    var buffers : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    var colors : array<SDL_GPUColorTargetDescription>
    resize(colors, 1); colors[0] = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
    var info = gpu_graphics_pipeline_info()
    verify(*SDL_CreateGPUCheckedGraphicsPipeline(device, fs, vs, info, buffers, attributes, colors) == 0ul)
    verify(*SDL_CreateGPUCheckedGraphicsPipeline(device, vs, vs, info, buffers, attributes, colors) == 0ul)
    var ids : array<GpuPipelineHandle>
    for (mode in 0 .. 3) {
        colors[0] = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
        if (mode == 1) {
            var blend = colors[0].blend_state
            blend.enable_blend = true
            blend.src_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_SRC_COLOR
            colors[0] <- colors[0] |> blending(blend)
        }
        if (mode == 2) {
            colors[0] <- colors[0] |> color_write_mask(uint8(1))
        }
        let id = SDL_CreateGPUCheckedGraphicsPipeline(device, vs, fs, info, buffers, attributes, colors)
        verify(*id != 0ul); push(ids, id)
    }
    verify(SDL_ReleaseGPUCheckedShader(device, vs) && SDL_ReleaseGPUCheckedShader(device, fs))
    clear(colors)
    info.rasterizer_state.cull_mode = SDL_GPUCullMode.CULLMODE_FRONT
    for (mode in 0 .. 3) {
        let id = ids[mode]
        var query_result_1 : SDL_GPUGraphicsPipelineCreateInfo
        verify(is_ok(gpu_graphics_pipeline_descriptor(device, id, query_result_1)))
        verify(query_result_1.rasterizer_state.cull_mode == SDL_GPUCullMode.CULLMODE_NONE)
        if (!SDLTest_graphics_pipeline_triangle(device, *id, uint(mode))) { panic("Pipeline pixels: {SDL_GetError()}") }
        verify(SDL_ReleaseGPUCheckedGraphicsPipeline(device, id))
        verify(!SDL_ReleaseGPUCheckedGraphicsPipeline(device, id))
        verify(!SDL_GetGPUCheckedGraphicsPipelineInfo(device, id, info) && SDLTest_graphics_pipeline_hidden(info))
    }
}
def check_vertex_layout(device : SDL_GPUDevice?; vertex, fragment : string; format : uint) {
    var vi = gpu_shader_info(format, SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    var fi = gpu_shader_info(format, SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT); fi.num_samplers = 1u
    let vs = SDL_LoadGPUCheckedShader(device, vertex, vi, "main")
    let fs = SDL_LoadGPUCheckedShader(device, fragment, fi, "main")
    verify(*vs != 0ul && *fs != 0ul)
    var buffers : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    var colors : array<SDL_GPUColorTargetDescription>
    resize(buffers, 1); resize(attributes, 2); resize(colors, 1)
    buffers[0].pitch = 16u
    buffers[0].input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX
    attributes[0].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
    attributes[1].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
    attributes[1].location = 1u; attributes[1].offset = 8u
    colors[0] = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
    let info = gpu_graphics_pipeline_info()
    // D3D12 indexes buffer descriptions by slot: normalize reordered inputs.
    resize(buffers, 2)
    buffers[0].slot = 1u; buffers[0].pitch = 8u; buffers[0].input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE
    buffers[1].slot = 0u; buffers[1].pitch = 8u; buffers[1].input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX
    attributes[1].buffer_slot = 1u; attributes[1].offset = 0u
    var description <- gpu_pipeline(vs, fs)
    description <- description |> vertex_buffer(1u, 8u, SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE)
    description <- description |> vertex_buffer(0u, 8u)
    description <- description |> vertex_attribute(0u, 0u, SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2, 0u)
    description <- description |> vertex_attribute(1u, 1u, SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2, 0u)
    description <- description |> color_target(colors[0])
    description <- description |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT)
    description <- description |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS)
    description <- description |> depth_write(true)
    let scope_ok_0 = device |> with_gpu_graphics_pipeline(description) $(sorted : GpuPipelineHandle) {
        let queried = gpu_graphics_pipeline_descriptor(device, sorted)
        verify(is_ok(queried))
        let actual = unwrap(queried)
        verify(actual.target_info.has_depth_stencil_target)
        verify(actual.target_info.depth_stencil_format == SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT)
        verify(actual.depth_stencil_state.enable_depth_test && actual.depth_stencil_state.enable_depth_write)
        verify(actual.depth_stencil_state.compare_op == SDL_GPUCompareOp.COMPAREOP_LESS)
        verify(SDLTest_graphics_pipeline_sorted(device, *sorted))

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
    resize(buffers, 1)
    buffers[0].slot = 0u; buffers[0].pitch = 16u; buffers[0].input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX
    attributes[1].buffer_slot = 0u; attributes[1].offset = 8u
    let pipeline = SDL_CreateGPUCheckedGraphicsPipeline(device, vs, fs, info, buffers, attributes, colors)
    verify(*pipeline != 0ul)
    verify(SDL_ReleaseGPUCheckedShader(device, vs) && SDL_ReleaseGPUCheckedShader(device, fs))
    buffers[0].pitch = 2048u; attributes[1].offset = 0u
    colors[0].format = SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT
    clear(buffers); clear(attributes); clear(colors)
    var query_result_2 : SDL_GPUGraphicsPipelineCreateInfo
    verify(is_ok(gpu_graphics_pipeline_descriptor(device, pipeline, query_result_2)))
    verify(SDLTest_graphics_pipeline_hidden(query_result_2))
    verify(SDL_ReleaseGPUCheckedGraphicsPipeline(device, pipeline))
}
def check_states(device : SDL_GPUDevice?; vs : GpuShaderHandle; fs : GpuShaderHandle) {
    var buffers : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    var colors : array<SDL_GPUColorTargetDescription>
    resize(colors, 1); colors[0] = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
    var info = gpu_graphics_pipeline_info()
    var samples, depths = 0
    for (sample in array<SDL_GPUSampleCount>(SDL_GPUSampleCount.SAMPLECOUNT_1, SDL_GPUSampleCount.SAMPLECOUNT_2, SDL_GPUSampleCount.SAMPLECOUNT_4, SDL_GPUSampleCount.SAMPLECOUNT_8)) {
        info <- info |> multisampling(SDL_GPUMultisampleState(sample_count = sample))
        if (SDL_GPUTextureSupportsSampleCount(device, colors[0].format, sample)) {
            let scope_ok_1 = device |> with_gpu_graphics_pipeline(vs, fs, info, buffers, attributes, colors) $(id : GpuPipelineHandle) {
                var query_result_3 : SDL_GPUGraphicsPipelineCreateInfo
                verify(is_ok(gpu_graphics_pipeline_descriptor(device, id, query_result_3)))
                verify(query_result_3.multisample_state.sample_count == sample)
                samples++

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_1)
        } else { verify(*SDL_CreateGPUCheckedGraphicsPipeline(device, vs, fs, info, buffers, attributes, colors) == 0ul) }
    }
    info <- info |> sample_count(SDL_GPUSampleCount.SAMPLECOUNT_1)
    for (format in array<SDL_GPUTextureFormat>(SDL_GPUTextureFormat.TEXTUREFORMAT_D16_UNORM, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM_S8_UINT, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT_S8_UINT)) {
        if (SDL_GPUTextureSupportsFormat(device, format, SDL_GPUTextureType.TEXTURETYPE_2D, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) {
            info <- info |> depth_target(format)
            info <- info |> depth_stencil(SDL_GPUDepthStencilState())
            info <- info |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS)
            info <- info |> depth_write(true)
            info <- info |> stencil_test(format == SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM_S8_UINT || format == SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT_S8_UINT)
            let face = SDL_GPUStencilOpState(fail_op = SDL_GPUStencilOp.STENCILOP_KEEP,
                pass_op = SDL_GPUStencilOp.STENCILOP_REPLACE, depth_fail_op = SDL_GPUStencilOp.STENCILOP_KEEP,
                compare_op = SDL_GPUCompareOp.COMPAREOP_ALWAYS)
            info <- info |> stencil_faces(face)
            info <- info |> stencil_masks(uint8(255), uint8(255))
            let scope_ok_2 = device |> with_gpu_graphics_pipeline(vs, fs, info, buffers, attributes, colors) $(id : GpuPipelineHandle) {
                var query_result_4 : SDL_GPUGraphicsPipelineCreateInfo
                verify(is_ok(gpu_graphics_pipeline_descriptor(device, id, query_result_4)))
                let copy = query_result_4
                verify(copy.target_info.has_depth_stencil_target && copy.target_info.depth_stencil_format == format)
                verify(copy.depth_stencil_state.compare_op == SDL_GPUCompareOp.COMPAREOP_LESS && copy.depth_stencil_state.enable_depth_write)
                verify(copy.depth_stencil_state.enable_stencil_test == info.depth_stencil_state.enable_stencil_test)
                if (copy.depth_stencil_state.enable_stencil_test) {
                    verify(copy.depth_stencil_state.front_stencil_state.pass_op == SDL_GPUStencilOp.STENCILOP_REPLACE)
                    verify(copy.depth_stencil_state.back_stencil_state.pass_op == SDL_GPUStencilOp.STENCILOP_REPLACE)
                    verify(copy.depth_stencil_state.compare_mask == uint8(255) && copy.depth_stencil_state.write_mask == uint8(255))
                }
                verify(SDLTest_graphics_pipeline_hidden(copy))
                depths++

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_2)
        }
    }
    info = gpu_graphics_pipeline_info(); info.multisample_state.enable_mask = true
    var caught, invoked = false
    { let operation_ok = device |> with_gpu_graphics_pipeline(vs, fs, info, buffers, attributes, colors) $(id : GpuPipelineHandle) { invoked = true
        return sdl_ok()
    } |> is_ok
caught = !operation_ok }
    verify(caught && !invoked)
    info = gpu_graphics_pipeline_info()
    for (count in 2 .. 5) {
        resize(colors, count)
        for (i in 0 .. count) { colors[i] = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) }
        let scope_ok_3 = device |> with_gpu_graphics_pipeline(vs, fs, info, buffers, attributes, colors) $(id : GpuPipelineHandle) {
            verify(*id != 0ul)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_3)
    }
    resize(colors, 5)
    verify(*SDL_CreateGPUCheckedGraphicsPipeline(device, vs, fs, info, buffers, attributes, colors) == 0ul)
    clear(colors)
    verify(*SDL_CreateGPUCheckedGraphicsPipeline(device, vs, fs, info, buffers, attributes, colors) == 0ul)
    print("Pipeline creation capabilities: {samples} sample counts, {depths} depth/stencil formats (no depth/MSAA pixel test here)\n")
}
def check_lifetime(device : SDL_GPUDevice?; vertex, fragment : string; format : uint) {
    let vi = gpu_shader_info(format, SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    let fi = gpu_shader_info(format, SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    let scope_ok_4 = device |> with_gpu_shader_file(vertex, vi) $(vs : GpuShaderHandle) {
        let scope_ok_5 = device |> with_gpu_shader_file(fragment, fi) $(fs : GpuShaderHandle) {
            check_states(device, vs, fs)
            var stale : GpuPipelineHandle
            let scope_ok_6 = device |> with_gpu_graphics_pipeline(vs, fs, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(outer : GpuPipelineHandle) {
                verify(SDLTest_graphics_pipeline_thread(device, *outer))
                var caught = false
                {
                    let scope_ok_7 = device |> with_gpu_graphics_pipeline(vs, fs, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(inner : GpuPipelineHandle) {
                        stale = inner; caught = !is_ok(set_title(null, "expected SDL failure")); return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_7)
                }
                verify(caught && !SDLTest_graphics_pipeline_exists(*stale))
                verify(SDLTest_graphics_pipeline_triangle(device, *outer, 0u))
                let other = with_gpu_device(GPU_SHADER_FORMATS, true, "") $(second : SDL_GPUDevice?) {
                    verify(!SDL_ReleaseGPUCheckedGraphicsPipeline(second, outer))
                    let scope_ok_8 = second |> with_gpu_shader_file(vertex, vi) $(sv : GpuShaderHandle) {
                        let scope_ok_9 = second |> with_gpu_shader_file(fragment, fi) $(sf : GpuShaderHandle) {
                            var b : array<SDL_GPUVertexBufferDescription>
                            var a : array<SDL_GPUVertexAttribute>
                            var c : array<SDL_GPUColorTargetDescription>
                            resize(c, 1); c[0] = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
                            verify(*SDL_CreateGPUCheckedGraphicsPipeline(device, sv, fs, gpu_graphics_pipeline_info(), b, a, c) == 0ul)
                            stale = SDL_CreateGPUCheckedGraphicsPipeline(second, sv, sf, gpu_graphics_pipeline_info(), b, a, c)
                            verify(*stale != 0ul)

                            return sdl_ok()
                        } |> is_ok
                        verify(scope_ok_9)

                        return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_8)

                    return sdl_ok()
                } |> is_ok
                verify(other && !SDLTest_graphics_pipeline_exists(*stale))
                verify(SDLTest_graphics_pipeline_triangle(device, *outer, 0u))
                let scope_ok_10 = device |> with_gpu_sampler() $(sampler : GpuSamplerHandle) {
                    verify(!SDL_ReleaseGPUCheckedGraphicsPipeline(device, GpuPipelineHandle(*sampler)))
                    verify(!SDL_ReleaseGPUCheckedSampler(device, GpuSamplerHandle(*outer)))

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_10)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_6)
            let scope_ok_11 = device |> with_gpu_graphics_pipeline(vs, fs, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(id : GpuPipelineHandle) { stale = id; return sdl_ok()
            } |> is_ok
            verify(scope_ok_11)
            verify(!SDLTest_graphics_pipeline_exists(*stale))

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_5)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_4)
    verify(SDLTest_graphics_pipeline_count(device) == 0u)
}
[export]
def main(smoke : bool) : int {
    verify(SDLTest_graphics_pipeline_validation())
    var available = false
    let scope_ok_12 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS, true, "") $(device : SDL_GPUDevice?) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let base = "{SDL_GetBasePath()}assets/shaders"
            check_triangle(device, "{base}/triangle.vert.{extension}", "{base}/triangle.frag.{extension}", format)
            check_vertex_layout(device, "{base}/mesh.vert.{extension}", "{base}/mesh.frag.{extension}", format)
            check_lifetime(device, "{base}/triangle.vert.{extension}", "{base}/triangle.frag.{extension}", format)
            print("General graphics pipeline layouts, blend/mask pixels and ownership PASS: {SDL_GetGPUDeviceDriver(device)}\n")

            return sdl_ok()
        } |> is_ok
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_12)
    return available ? 0 : 77
}
