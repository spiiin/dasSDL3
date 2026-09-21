options gen2
require dassdl3/sdl3_gpu_recording_boost
require daslib/rtti

def render_quad(device : SDL_GPUDevice?; pipeline : GpuPipelineHandle; target : GpuTextureHandle; vb : GpuBufferHandle; ib : GpuIndexBufferHandle; vertex_texture : GpuTextureHandle; texture : GpuTextureHandle; sampler : GpuSamplerHandle; linear : bool) {
    // Explicit cross-kind constructors below deliberately test native rejection.
    // Ordinary accidental mixing is covered by test_gpu_handle_errors.py.
    var black : SDL_FColor
    black.a = 1.0
    var buffers <- array<GpuBufferHandle>(vb)
    var offsets <- array<uint>(0u)
    var vertex_images <- array<GpuTextureHandle>(vertex_texture)
    var fragment_images <- array<GpuTextureHandle>(texture)
    var samplers <- array<GpuSamplerHandle>(sampler)
    var transform <- array<float4>(float4(0.75,0.0,0.0,0.125),float4(0.0,0.75,0.0,-0.125))
    var tint <- array<float4>(float4(1.0,0.5,1.0,1.0))
    let before = SDLTestGPURecordings()
    var saved_command : GpuCommandBufferHandle
    var saved_pass : GpuRenderPassHandle
    let scope_ok_0 = device |> with_gpu_command_buffer() $(command : GpuCommandBufferHandle) {
        saved_command = command
        verify(!SDL_EndGPURenderPassChecked(device,GpuRenderPassHandle(*command)))
        verify(SDLTestGPURecordingValues(device,*command))
        is_ok(device |> gpu_push_uniform(command,SDL_GPUShaderStage.SHADERSTAGE_VERTEX,0u,transform))
        // SDL copies uniforms immediately; later script mutation must not change them.
        transform[0] = float4(0.0)
        let render_pass = unwrap_or(device |> gpu_begin_render_pass(command,target,uint2(0u),SDL_GPULoadOp.LOADOP_CLEAR,black), GpuRenderPassHandle(0ul))
        saved_pass = render_pass
        verify(*SDL_BeginGPURenderPassChecked(device,command,target,uint2(0u),SDL_GPULoadOp.LOADOP_CLEAR,black) == 0ul)
        verify(!SDL_SubmitGPUCommandBufferChecked(device,command))
        verify(!SDL_CancelGPUCommandBufferChecked(device,command))
        verify(!SDL_DrawGPUIndexedPrimitivesChecked(device,render_pass,6u,1u,0u,0))
        is_ok(device |> gpu_bind_pipeline(render_pass,pipeline))
        is_ok(device |> gpu_bind_vertex_buffers(render_pass,0u,buffers,offsets))
        is_ok(device |> gpu_bind_index_buffer(render_pass,ib))
        is_ok(device |> gpu_bind_samplers(render_pass,SDL_GPUShaderStage.SHADERSTAGE_VERTEX,vertex_images,samplers))
        is_ok(device |> gpu_bind_samplers(render_pass,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,fragment_images,samplers))
        var feedback <- array<GpuTextureHandle>(target)
        verify(!SDL_BindGPUSamplersChecked(device,render_pass,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,feedback,samplers))
        verify(!SDL_DrawGPUIndexedPrimitivesChecked(device,render_pass,6u,1u,0u,0)) // Missing fragment uniform.
        is_ok(device |> gpu_push_uniform(command,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,0u,tint))
        buffers[0] = GpuBufferHandle(0ul); vertex_images[0] = GpuTextureHandle(0ul); fragment_images[0] = GpuTextureHandle(0ul); samplers[0] = GpuSamplerHandle(0ul)
        verify(!SDL_BindGPUVertexBuffersChecked(device,render_pass,0u,buffers,offsets))
        verify(!SDL_BindGPUSamplersChecked(device,render_pass,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,fragment_images,samplers))
        verify(!SDL_BindGPUIndexBufferChecked(device,render_pass,GpuIndexBufferHandle(*vb)))
        verify(!SDL_DrawGPUIndexedPrimitivesChecked(device,render_pass,7u,1u,0u,0))
        verify(!SDL_DrawGPUIndexedPrimitivesChecked(device,render_pass,6u,1u,0u,-1))
        verify(!SDL_DrawGPUPrimitivesChecked(device,render_pass,6u,1u,0u))
        verify(!SDL_SetGPUScissorChecked(device,render_pass,uint4(0u,0u,65u,64u)))
        is_ok(device |> gpu_set_viewport(render_pass,gpu_viewport(64.0,64.0)))
        is_ok(device |> gpu_set_blend_constants(render_pass,black))
        is_ok(device |> gpu_set_scissor(render_pass,uint4(0u,0u,32u,64u)))
        is_ok(device |> gpu_draw_indexed_primitives(render_pass,6u))
        tint[0].x = 0.5
        is_ok(device |> gpu_push_uniform(command,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,0u,tint))
        tint[0] = float4(0.0)
        is_ok(device |> gpu_set_scissor(render_pass,uint4(32u,0u,32u,64u)))
        is_ok(device |> gpu_draw_indexed_primitives(render_pass,6u))
        fragment_images[0] = texture
        let scope_ok_1 = device |> with_gpu_sampler(gpu_sampler_info()) $(temporary : GpuSamplerHandle) {
            samplers[0] = temporary
            is_ok(device |> gpu_bind_samplers(render_pass,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,fragment_images,samplers))

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_1)
        verify(!SDL_DrawGPUIndexedPrimitivesChecked(device,render_pass,6u,1u,0u,0))
        samplers[0] = sampler
        is_ok(device |> gpu_bind_samplers(render_pass,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,fragment_images,samplers))
        let scope_ok_2 = device |> with_gpu_rgba_texture(1u,1u) $(temporary : GpuTextureHandle) {
            fragment_images[0] = temporary
            is_ok(device |> gpu_bind_samplers(render_pass,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,fragment_images,samplers))

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_2)
        verify(!SDL_DrawGPUIndexedPrimitivesChecked(device,render_pass,6u,1u,0u,0))
        is_ok(device |> gpu_end_render_pass(render_pass))
        verify(!SDL_EndGPURenderPassChecked(device,render_pass))
        verify(!SDL_DrawGPUIndexedPrimitivesChecked(device,render_pass,6u,1u,0u,0))
        let next_pass = unwrap_or(device |> gpu_begin_render_pass(command,target,uint2(0u),SDL_GPULoadOp.LOADOP_LOAD,black), GpuRenderPassHandle(0ul))
        verify(!SDL_DrawGPUIndexedPrimitivesChecked(device,next_pass,6u,1u,0u,0))
        is_ok(device |> gpu_end_render_pass(next_pass))
        is_ok(device |> gpu_submit_command_buffer(command))
        verify(!SDL_SubmitGPUCommandBufferChecked(device,command))
        verify(!SDL_CancelGPUCommandBufferChecked(device,command))

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
    verify(SDLTestGPURecordings() == before)
    verify(SDLTestGPURecordingFailure(device,*target))
    verify(SDLTestGPURecordingDevices(device,*target))
    verify(!is_ok(gpu_set_scissor(device,saved_pass,uint4(0u,0u,64u,64u))))
    verify(!is_ok(gpu_push_uniform(device,saved_command,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,0u,tint)))
    var recovered = false
    {
        let scope_ok_3 = device |> with_gpu_command_buffer() $(command : GpuCommandBufferHandle) {
            let render_pass = unwrap_or(device |> gpu_begin_render_pass(command,target,uint2(0u),SDL_GPULoadOp.LOADOP_CLEAR,black), GpuRenderPassHandle(0ul))
            recovered = !is_ok(set_title(null,"expected SDL failure")); return sdl_ok()
        } |> is_ok
        verify(scope_ok_3)
    }
    verify(recovered && SDLTestGPURecordings() == before)
    // Early return also closes and cancels the live render_pass. The preceding pixels survive.
    let scope_ok_4 = device |> with_gpu_command_buffer() $(command : GpuCommandBufferHandle) {
        let render_pass = unwrap_or(device |> gpu_begin_render_pass(command,target,uint2(0u),SDL_GPULoadOp.LOADOP_CLEAR,black), GpuRenderPassHandle(0ul))
        return sdl_ok()
    } |> is_ok
    verify(scope_ok_4)
    let scope_ok_5 = device |> with_gpu_command_buffer() $(command : GpuCommandBufferHandle) {
        is_ok(device |> gpu_cancel_command_buffer(command))

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_5)
    verify(SDLTestGPURecordings() == before)
    var bytes : array<uint8>
    resize(bytes,64*64*4)
    let scope_ok_6 = device |> with_gpu_texture_readback(target,uint2(0u),uint4(0u,0u,64u,64u)) $(ticket : GpuReadbackHandle) {
        is_ok(device |> gpu_wait_readback(ticket))
        is_ok(device |> gpu_readback_bytes(ticket,bytes))

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_6)
    if (!SDLTestGPURecordingPixels(bytes,linear)) { panic("{SDL_GetError()}") }

}

def run(device : SDL_GPUDevice?; linear : bool) {
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let extension = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/bindings"
    var vi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    var fi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    vi.num_samplers = 1u; vi.num_uniform_buffers = 1u
    fi.num_samplers = 1u; fi.num_uniform_buffers = 1u
    let scope_ok_7 = device |> with_gpu_shader_file("{base}.vert.{extension}",vi) $(vertex : GpuShaderHandle) {
        let scope_ok_8 = device |> with_gpu_shader_file("{base}.frag.{extension}",fi) $(fragment : GpuShaderHandle) {
            var layouts : array<SDL_GPUVertexBufferDescription>
            resize(layouts,1); layouts[0].pitch = 16u
            var attributes : array<SDL_GPUVertexAttribute>
            resize(attributes,2)
            attributes[0].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
            attributes[1].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
            attributes[1].location = 1u; attributes[1].offset = 8u
            var colors : array<SDL_GPUColorTargetDescription>
            push(colors,gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
            let scope_ok_9 = device |> with_gpu_graphics_pipeline(vertex,fragment,gpu_graphics_pipeline_info(),layouts,attributes,colors) $(pipeline : GpuPipelineHandle) {
                var vertices <- array<float>(-0.75,0.75,0.0,0.0, 0.75,0.75,1.0,0.0, 0.75,-0.75,1.0,1.0, -0.75,-0.75,0.0,1.0)
                var indices <- array<uint>(0u,1u,2u,0u,2u,3u)
                let scope_ok_10 = device |> with_gpu_vertex_buffer(vertices) $(vb : GpuBufferHandle) {
                    let scope_ok_11 = device |> with_gpu_index_buffer(indices,SDL_GPUIndexElementSize.INDEXELEMENTSIZE_16BIT) $(ib : GpuIndexBufferHandle) {
                        let scope_ok_12 = device |> with_gpu_rgba_texture(1u,1u) $(vertex_texture : GpuTextureHandle) {
                            var vertex_color <- array<uint8>(uint8(128),uint8(255),uint8(128),uint8(255))
                            is_ok(device |> gpu_upload_texture(vertex_texture,uint2(0u),uint4(0u,0u,1u,1u),vertex_color,4u))
                            let scope_ok_13 = device |> with_gpu_rgba_texture(2u,2u) $(texture : GpuTextureHandle) {
                                var image <- array<uint8>(uint8(255),uint8(0),uint8(0),uint8(255), uint8(0),uint8(255),uint8(0),uint8(255),
                                    uint8(0),uint8(0),uint8(255),uint8(255), uint8(255),uint8(255),uint8(255),uint8(255))
                                is_ok(device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,2u,2u),image,8u))
                                let filter_mode = linear ? SDL_GPUFilter.FILTER_LINEAR : SDL_GPUFilter.FILTER_NEAREST
                                let scope_ok_14 = device |> with_gpu_sampler(gpu_sampler_info(filter_mode)) $(sampler : GpuSamplerHandle) {
                                    let scope_ok_15 = device |> with_gpu_color_target_texture(64u,64u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(target : GpuTextureHandle) {
                                        render_quad(device,pipeline,target,vb,ib,vertex_texture,texture,sampler,linear)

                                        return sdl_ok()
                                    } |> is_ok
                                    verify(scope_ok_15)

                                    return sdl_ok()
                                } |> is_ok
                                verify(scope_ok_14)

                                return sdl_ok()
                            } |> is_ok
                            verify(scope_ok_13)

                            return sdl_ok()
                        } |> is_ok
                        verify(scope_ok_12)

                        return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_11)

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_10)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_9)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_8)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_7)
}

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_16 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            run(device,false)
            run(device,true)
            print("Texture/sampler and uniform bindings: {SDL_GetGPUDeviceDriver(device)}\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_16)
    return available ? 0 : 77
}
