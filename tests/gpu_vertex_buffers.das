options gen2
require dassdl3/sdl3_gpu_recording_boost
require daslib/rtti

def pixels(device : SDL_GPUDevice?; target : GpuTextureHandle; solid : bool) {
    var bytes : array<uint8>
    resize(bytes, 64 * 64 * 4)
    let scope_ok_0 = device |> with_gpu_texture_readback(target, uint2(0u), uint4(0u, 0u, 64u, 64u)) $(ticket : GpuReadbackHandle) {
        is_ok(device |> gpu_wait_readback(ticket))
        is_ok(device |> gpu_readback_bytes(ticket, bytes))

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
    if (!SDLTestGPUVertexPixels(bytes, solid)) { panic("Vertex pixels: {SDL_GetError()}") }
}

// Test-local fixture, not a public rendering helper.
def record(device : SDL_GPUDevice?; pipeline : GpuPipelineHandle; target : GpuTextureHandle; var buffers : array<GpuBufferHandle>;
           var offsets : array<uint>; instances : uint; index : GpuIndexBufferHandle; count, first : uint; base : int) {
    var black = SDL_FColor(a = 1.0)
    let scope_ok_1 = device |> with_gpu_command_buffer() $(command : GpuCommandBufferHandle) {
        let render_pass = unwrap_or(device |> gpu_begin_render_pass(command, target, uint2(0u), SDL_GPULoadOp.LOADOP_CLEAR, black), GpuRenderPassHandle(0ul))
        is_ok(device |> gpu_bind_pipeline(render_pass, pipeline))
        let original_offset = offsets[0]
        offsets[0] = 1u
        verify(!SDL_BindGPUVertexBuffersChecked(device, render_pass, 0u, buffers, offsets))
        offsets[0] = original_offset
        is_ok(device |> gpu_bind_vertex_buffers(render_pass, 0u, buffers, offsets))
        let original_buffer = buffers[0]
        buffers[0] = GpuBufferHandle(0ul)
        verify(!SDL_BindGPUVertexBuffersChecked(device, render_pass, 0u, buffers, offsets))
        if (*index == 0ul) {
            verify(!SDL_DrawGPUPrimitivesChecked(device, render_pass, 4u, instances, 0u))
            if (instances == 2u) { verify(!SDL_DrawGPUPrimitivesChecked(device, render_pass, 3u, 3u, 0u)) }
            is_ok(device |> gpu_draw_primitives(render_pass, 3u, instances))
        } else {
            verify(!SDL_BindGPUIndexBufferChecked(device, render_pass, GpuIndexBufferHandle(*original_buffer)))
            is_ok(device |> gpu_bind_index_buffer(render_pass, index))
            verify(!SDL_DrawGPUIndexedPrimitivesChecked(device, render_pass, 7u, instances, 1u, 0))
            if (base == -1) {
                verify(!SDL_DrawGPUIndexedPrimitivesChecked(device, render_pass, 3u, instances, 0u, 0))
                verify(!SDL_DrawGPUIndexedPrimitivesChecked(device, render_pass, 3u, instances, 1u, -2))
            }
            is_ok(device |> gpu_draw_indexed_primitives(render_pass, count, instances, first, base))
        }
        buffers[0] = original_buffer
        is_ok(device |> gpu_end_render_pass(render_pass))
        is_ok(device |> gpu_submit_command_buffer(command))

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_1)
}

def draws(device : SDL_GPUDevice?; pipeline : GpuPipelineHandle; target : GpuTextureHandle; var buffers : array<GpuBufferHandle>;
          var offsets : array<uint>; mode : int) {
    let instances = mode == 2 ? 2u : 1u
    record(device, pipeline, target, buffers, offsets, instances, GpuIndexBufferHandle(0ul), 3u, 0u, 0)
    pixels(device, target, mode == 2)
    for (element in 0 .. 2) {
        let format = element == 0 ? SDL_GPUIndexElementSize.INDEXELEMENTSIZE_16BIT : SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT
        var indices <- array<uint>(99u, 1u, 2u, 3u, 1u, 2u, 3u)
        let scope_ok_2 = device |> with_gpu_index_buffer(indices, format) $(ib : GpuIndexBufferHandle) {
            clear(indices)
            record(device, pipeline, target, buffers, offsets, instances, ib, 3u, 1u, -1)
            pixels(device, target, mode == 2)
            record(device, pipeline, target, buffers, offsets, instances, ib, 6u, 1u, -1)
            pixels(device, target, mode == 2)
            var zero : array<uint8>
            resize(zero, 4)
            verify(!SDL_UpdateGPUDataBuffer(device, GpuBufferHandle(*ib), 0u, zero, false))
            verify(!SDL_ReleaseGPUDataBuffer(device, GpuBufferHandle(*ib)))
            let scope_ok_3 = with_gpu_device() $(other : SDL_GPUDevice?) { verify(!SDL_ReleaseGPUCheckedIndexBuffer(other, ib))
                return sdl_ok()
            } |> is_ok
            verify(scope_ok_3)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_2)
    }
    if (mode != 2) {
        var indices <- array<uint>(0u, 1u, 2u)
        let scope_ok_4 = device |> with_gpu_index_buffer(indices, SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT) $(ib : GpuIndexBufferHandle) {
            var starts : array<uint>
            resize(starts, length(offsets))
            record(device, pipeline, target, buffers, starts, 1u, ib, 3u, 0u, 1)
            pixels(device, target, false)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_4)
    }
}

def check(device : SDL_GPUDevice?; vertex : GpuShaderHandle; fragment : GpuShaderHandle) {
    verify(SDLTestGPUIndexBadArrays(device))
    var layouts : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    var colors : array<SDL_GPUColorTargetDescription>
    push(colors, gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
    resize(attributes, 2)
    attributes[0].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
    attributes[1].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3
    attributes[1].location = 1u
    for (mode in 0 .. 3) {
        resize(layouts, mode == 0 ? 1 : 2)
        layouts[0].slot = 0u; layouts[0].pitch = mode == 0 ? 20u : 8u
        layouts[0].input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX
        attributes[1].buffer_slot = mode == 0 ? 0u : 1u
        attributes[1].offset = mode == 0 ? 8u : 0u
        if (mode != 0) {
            layouts[1].slot = 1u; layouts[1].pitch = 12u
            layouts[1].input_rate = mode == 2 ? SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE : SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX
            let saved = layouts[0]; layouts[0] = layouts[1]; layouts[1] = saved
        }
        let scope_ok_5 = device |> with_gpu_graphics_pipeline(vertex, fragment, gpu_graphics_pipeline_info(), layouts, attributes, colors) $(pipeline : GpuPipelineHandle) {
            let scope_ok_6 = device |> with_gpu_color_target_texture(64u, 64u, 1u, 1u, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(target : GpuTextureHandle) {
                var data <- array<float>(0.0, 0.0, 0.0, 0.0, 0.0, -0.75, -0.75, 1.0, 0.0, 0.0, 0.0, 0.75, 0.0, 1.0, 0.0, 0.75, -0.75, 0.0, 0.0, 1.0)
                if (mode != 0) { data <- array<float>(0.0, 0.0, -0.75, -0.75, 0.0, 0.75, 0.75, -0.75) }
                let scope_ok_7 = device |> with_gpu_vertex_buffer(data) $(vb : GpuBufferHandle) {
                    var buffers <- array<GpuBufferHandle>(vb)
                    var offsets <- array<uint>(mode == 0 ? 20u : 8u)
                    clear(data)
                    if (mode == 0) { draws(device, pipeline, target, buffers, offsets, mode) }
                    else {
                        var rgb <- array<float>(0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0)
                        if (mode == 2) { rgb <- array<float>(0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0) }
                        let scope_ok_8 = device |> with_gpu_vertex_buffer(rgb) $(color_buffer : GpuBufferHandle) {
                            push(buffers, color_buffer); push(offsets, 12u)
                            draws(device, pipeline, target, buffers, offsets, mode)

                            return sdl_ok()
                        } |> is_ok
                        verify(scope_ok_8)
                    }

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_7)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_6)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_5)
    }
    var caught = false
    var indices <- array<uint>(0u, 1u, 2u)
    {
        let scope_ok_9 = device |> with_gpu_index_buffer(indices, SDL_GPUIndexElementSize.INDEXELEMENTSIZE_16BIT) $(ib : GpuIndexBufferHandle) { caught = !is_ok(set_title(null, "expected SDL failure")); return sdl_ok()
        } |> is_ok
        verify(scope_ok_9)
    }
    verify(caught && SDLTestGPUIndexBuffers() == 0)
}

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_10 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS, true, "") $(device : SDL_GPUDevice?) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let base = "{SDL_GetBasePath()}assets/shaders/vertex_color"
            let vi = gpu_shader_info(format, SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
            let fi = gpu_shader_info(format, SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
            let scope_ok_11 = device |> with_gpu_shader_file("{base}.vert.{extension}", vi) $(vertex : GpuShaderHandle) {
                let scope_ok_12 = device |> with_gpu_shader_file("{base}.frag.{extension}", fi) $(fragment : GpuShaderHandle) { check(device, vertex, fragment)
                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_12)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_11)

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_10)
    return available ? 0 : 77
}
