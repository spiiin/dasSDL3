options gen2
require dassdl3/sdl3_gpu_native_boost
require daslib/defer
require daslib/fio

def put32(var bytes : array<uint8>; offset : int; value : uint) {
    for (i in 0..4) { bytes[offset+i]=uint8((value>>uint(i*8))&255u) }
}

def exercise(device : SDL_GPUDevice?) : bool {
    let spirv=(SDL_GetGPUShaderFormats(device)&SDL_GPU_SHADERFORMAT_SPIRV)!=0u
    let ext=spirv ? "spv" : "dxil"
    let base="{SDL_GetBasePath()}assets/shaders/attachments"
    var shaders : array<SDL_GPUShader?>; resize(shaders,2)
    var pipelines : array<SDL_GPUGraphicsPipeline?>; resize(pipelines,2)
    var textures : array<SDL_GPUTexture?>; resize(textures,5)
    var buffers : array<SDL_GPUBuffer?>; resize(buffers,3)
    var transfers : array<SDL_GPUTransferBuffer?>; resize(transfers,2)
    {
        defer() {
            SDL_WaitForGPUIdle(device)
            for (p in pipelines) { if (p!=null) { SDL_ReleaseGPUGraphicsPipeline(device,p) } }
            for (s in shaders) { if (s!=null) { SDL_ReleaseGPUShader(device,s) } }
            for (t in textures) { if (t!=null) { SDL_ReleaseGPUTexture(device,t) } }
            for (b in buffers) { if (b!=null) { SDL_ReleaseGPUBuffer(device,b) } }
            for (t in transfers) { if (t!=null) { SDL_ReleaseGPUTransferBuffer(device,t) } }
        }
        var shader = SDL_GPUShaderCreateInfo(
            format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL,
            stage = SDL_GPUShaderStage.SHADERSTAGE_VERTEX,
            num_uniform_buffers = 1u
        )
        var empty : array<uint8>
        verify(SDL_CreateGPUShaderBytes(device,shader,empty,"main")==null)
        var called=false
        let scope_ok_0=with_native_gpu_shader_file(device,shader,"missing-native-shader.bin","main") $(var s : SDL_GPUShader?) { called=true
            return sdl_ok()
        } |> is_ok; verify(!scope_ok_0)
        verify(!called && SDL_GetError()!="")
        let file=fopen("{base}.vert.{ext}","rb"); verify(file!=null)
        {
            defer() { fclose(file) }
            fload(file,int64(fstat(file).size)) $(bytes) {
                let scoped=with_native_gpu_shader_bytes(device,shader,bytes,"main") $(var s : SDL_GPUShader?) { verify(s!=null); return sdl_ok()
                } |> is_ok
                verify(scoped)
                shaders[0]=SDL_CreateGPUShaderBytes(device,shader,bytes,"main")
            }
        }
        shader.stage=SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT; shader.num_uniform_buffers=0u
        shaders[1]=SDL_LoadGPUShaderFile(device,shader,"{base}.frag.{ext}","main")
        verify(shaders[0]!=null && shaders[1]!=null)
        var compute_info = SDL_GPUComputePipelineCreateInfo(
            format = shader.format,
            num_readwrite_storage_buffers = 1u,
            num_uniform_buffers = 1u,
            threadcount_x = 4u,
            threadcount_y = 1u,
            threadcount_z = 1u
        )
        verify(SDL_CreateGPUComputePipelineBytes(device,compute_info,empty,"main")==null)
        let compute_path="{SDL_GetBasePath()}assets/shaders/native.comp.{ext}"
        let compute_file=fopen(compute_path,"rb"); verify(compute_file!=null)
        {
            defer() { fclose(compute_file) }
            fload(compute_file,int64(fstat(compute_file).size)) $(bytes) {
                let scoped=with_native_gpu_compute_pipeline_bytes(device,compute_info,bytes,"main") $(var p : SDL_GPUComputePipeline?) { verify(p!=null); return sdl_ok()
                } |> is_ok
                verify(scoped)
            }
        }
        let compute_scoped=with_native_gpu_compute_pipeline_file(device,compute_info,compute_path,"main") $(var p : SDL_GPUComputePipeline?) { verify(p!=null); return sdl_ok()
        } |> is_ok
        verify(compute_scoped)
        // The temporary byte array is gone before any GPU draw consumes the shader.
        var tex = SDL_GPUTextureCreateInfo(
            texture_type = SDL_GPUTextureType.TEXTURETYPE_2D,
            width = 8u,
            height = 8u,
            layer_count_or_depth = 1u,
            num_levels = 1u,
            format = SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,
            usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET
        )
        verify(SDL_GPUTextureSupportsSampleCount(device,tex.format,SDL_GPUSampleCount.SAMPLECOUNT_4))
        tex.sample_count=SDL_GPUSampleCount.SAMPLECOUNT_4
        textures[0]=SDL_CreateGPUTextureRef(device,tex); textures[1]=SDL_CreateGPUTextureRef(device,tex)
        tex.sample_count=SDL_GPUSampleCount.SAMPLECOUNT_1
        textures[2]=SDL_CreateGPUTextureRef(device,tex); textures[3]=SDL_CreateGPUTextureRef(device,tex)
        tex.format=SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM_S8_UINT; tex.usage=SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET; tex.sample_count=SDL_GPUSampleCount.SAMPLECOUNT_4
        if (!SDL_GPUTextureSupportsFormat(device,tex.format,tex.texture_type,tex.usage)) { tex.format=SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT_S8_UINT }
        verify(SDL_GPUTextureSupportsFormat(device,tex.format,tex.texture_type,tex.usage))
        // SDL 3.2.18 D3D12 queries the SRV format for depth MSAA, not the DSV
        // format. Validate actual creation and rendered pixels with debug on.
        let depth_format=tex.format
        textures[4]=SDL_CreateGPUTextureRef(device,tex)
        for (t in textures) { verify(t!=null) }
        let texture_scoped=with_native_gpu_texture(device,tex) $(var t : SDL_GPUTexture?) { verify(t!=null); return sdl_ok()
        } |> is_ok
        verify(texture_scoped)
        var sampler_info : SDL_GPUSamplerCreateInfo
        let sampler_scoped=with_native_gpu_sampler(device,sampler_info) $(var s : SDL_GPUSampler?) { verify(s!=null); return sdl_ok()
        } |> is_ok
        verify(sampler_scoped)
        var bi = SDL_GPUBufferCreateInfo(size = 128u, usage = SDL_GPU_BUFFERUSAGE_VERTEX)
        buffers[0]=SDL_CreateGPUBufferRef(device,bi); buffers[1]=SDL_CreateGPUBufferRef(device,bi)
        bi.usage=SDL_GPU_BUFFERUSAGE_INDEX; buffers[2]=SDL_CreateGPUBufferRef(device,bi)
        for (b in buffers) { verify(b!=null) }
        let buffer_scoped=with_native_gpu_buffer(device,bi) $(var b : SDL_GPUBuffer?) { verify(b!=null); return sdl_ok()
        } |> is_ok
        verify(buffer_scoped)
        var ti = SDL_GPUTransferBufferCreateInfo(size = 1024u, usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD)
        transfers[0]=SDL_CreateGPUTransferBufferRef(device,ti)
        ti.usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD; transfers[1]=SDL_CreateGPUTransferBufferRef(device,ti)
        verify(transfers[0]!=null && transfers[1]!=null)
        let transfer_scoped=with_native_gpu_transfer_buffer(device,ti) $(var t : SDL_GPUTransferBuffer?) { verify(t!=null); return sdl_ok()
        } |> is_ok
        verify(transfer_scoped)
        var bytes : array<uint8>; resize(bytes,320)
        // Vertex binding starts at byte16, first vertex/index base is three.
        put32(bytes,40,0xbf800000u); put32(bytes,44,0xbf800000u)
        put32(bytes,48,0x40400000u); put32(bytes,52,0xbf800000u)
        put32(bytes,56,0xbf800000u); put32(bytes,60,0x40400000u)
        put32(bytes,144,0x3f800000u); put32(bytes,156,0x3f800000u)
        put32(bytes,164,0x3f800000u); put32(bytes,172,0x3f800000u)
        put32(bytes,184,0x3f800000u); put32(bytes,188,0x3f800000u)
        put32(bytes,264,0u); put32(bytes,268,1u); put32(bytes,272,2u)
        verify(!SDL_WriteGPUTransferBufferBytes(device,transfers[0],1024u,1000u,bytes,false))
        verify(!SDL_WriteGPUTransferBufferBytes(device,transfers[0],1024u,0xffffffffu,bytes,false))
        verify(SDL_WriteGPUTransferBufferBytes(device,transfers[0],1024u,1024u,empty,true))
        verify(SDL_WriteGPUTransferBufferBytes(device,transfers[0],1024u,0u,bytes,true))
        // Out-of-order dense slots are normalized; caller arrays remain unchanged.
        var layouts : array<SDL_GPUVertexBufferDescription>; resize(layouts,3)
        layouts[0].slot=2u; layouts[0].pitch=16u; layouts[0].input_rate=SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE
        layouts[1].slot=0u; layouts[1].pitch=8u
        layouts[2].slot=1u; layouts[2].pitch=8u
        var attrs : array<SDL_GPUVertexAttribute>; resize(attrs,2)
        attrs[0].location=0u; attrs[0].buffer_slot=1u; attrs[0].format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
        attrs[1].location=1u; attrs[1].buffer_slot=2u; attrs[1].format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4
        var formats : array<SDL_GPUColorTargetDescription>; resize(formats,2)
        formats[0].format=SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM; formats[1].format=formats[0].format
        var pi = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = shaders[0], fragment_shader = shaders[1], primitive_type = SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST); pi.rasterizer_state.enable_depth_clip=true
        pi.multisample_state.sample_count=SDL_GPUSampleCount.SAMPLECOUNT_4
        pi.target_info.has_depth_stencil_target=true; pi.target_info.depth_stencil_format=depth_format
        pi.depth_stencil_state.enable_depth_test=true; pi.depth_stencil_state.enable_depth_write=true; pi.depth_stencil_state.compare_op=SDL_GPUCompareOp.COMPAREOP_LESS
        pi.depth_stencil_state.enable_stencil_test=true; pi.depth_stencil_state.compare_mask=uint8(255); pi.depth_stencil_state.write_mask=uint8(255)
        pi.depth_stencil_state.front_stencil_state.compare_op=SDL_GPUCompareOp.COMPAREOP_ALWAYS
        pi.depth_stencil_state.front_stencil_state.pass_op=SDL_GPUStencilOp.STENCILOP_REPLACE
        pi.depth_stencil_state.front_stencil_state.fail_op=SDL_GPUStencilOp.STENCILOP_KEEP; pi.depth_stencil_state.front_stencil_state.depth_fail_op=SDL_GPUStencilOp.STENCILOP_KEEP
        pi.depth_stencil_state.back_stencil_state=pi.depth_stencil_state.front_stencil_state
        layouts[0].slot=5u; verify(SDL_CreateGPUGraphicsPipelineArrays(device,pi,layouts,attrs,formats)==null); layouts[0].slot=2u
        pipelines[0]=SDL_CreateGPUGraphicsPipelineArrays(device,pi,layouts,attrs,formats)
        verify(layouts[0].slot==2u && pipelines[0]!=null)
        pi.depth_stencil_state.compare_op=SDL_GPUCompareOp.COMPAREOP_ALWAYS; pi.depth_stencil_state.enable_depth_write=false
        pi.depth_stencil_state.front_stencil_state.compare_op=SDL_GPUCompareOp.COMPAREOP_EQUAL
        pi.depth_stencil_state.front_stencil_state.pass_op=SDL_GPUStencilOp.STENCILOP_KEEP
        pi.depth_stencil_state.back_stencil_state=pi.depth_stencil_state.front_stencil_state
        pipelines[1]=SDL_CreateGPUGraphicsPipelineArrays(device,pi,layouts,attrs,formats); verify(pipelines[1]!=null)
        let pipeline_scoped=with_native_gpu_graphics_pipeline(device,pi,layouts,attrs,formats) $(p : SDL_GPUGraphicsPipeline?) { verify(p!=null); return sdl_ok()
        } |> is_ok
        verify(pipeline_scoped)
        var targets : array<SDL_GPUColorTargetInfo>; resize(targets,2)
        for (i in 0..2) {
            targets[i].texture=textures[i]; targets[i].resolve_texture=textures[i+2]
            targets[i].load_op=SDL_GPULoadOp.LOADOP_CLEAR; targets[i].store_op=SDL_GPUStoreOp.STOREOP_RESOLVE_AND_STORE
            targets[i].cycle=true; targets[i].cycle_resolve_texture=true
        }
        var depth = SDL_GPUDepthStencilTargetInfo(
            texture = textures[4],
            clear_depth = 1.0,
            load_op = SDL_GPULoadOp.LOADOP_CLEAR,
            store_op = SDL_GPUStoreOp.STOREOP_STORE,
            stencil_load_op = SDL_GPULoadOp.LOADOP_CLEAR,
            stencil_store_op = SDL_GPUStoreOp.STOREOP_STORE,
            cycle = true
        )
        var bindings : array<SDL_GPUBufferBinding>; resize(bindings,2)
        bindings[0].buffer=buffers[0]; bindings[0].offset=16u; bindings[1].buffer=buffers[1]; bindings[1].offset=16u
        verify(!SDL_BindGPUVertexBuffersArray(null,0xffffffffu,bindings))
        var dummy : array<SDL_GPUBufferBinding>; resize(dummy,1); dummy[0].buffer=buffers[0]
        var index = SDL_GPUBufferBinding(buffer = buffers[2], offset = 4u)
        var uniform : array<uint8>; resize(uniform,16); put32(uniform,0,0x3f000000u)
        var completed=false
        let scope_ok_1=with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
            let scope_ok_2=with_native_gpu_copy_pass(command) $(var copy_pass : SDL_GPUCopyPass?&) {
                var source = SDL_GPUTransferBufferLocation(transfer_buffer = transfers[0])
                var destination = SDL_GPUBufferRegion(size = 64u)
                for (i in 0..3) {
                    source.offset=uint(i*128); destination.buffer=buffers[i]
                    SDL_UploadToGPUBufferRef(copy_pass,source,destination,true)
                }

                return sdl_ok()
            } |> is_ok; verify(scope_ok_2)
            verify(SDL_PushGPUVertexUniformDataArray(command,0u,uniform))
            let scope_ok_3=with_native_gpu_render_pass(command,targets,depth) $(var render_pass : SDL_GPURenderPass?&) {
                SDL_BindGPUGraphicsPipeline(render_pass,pipelines[0])
                verify(SDL_BindGPUVertexBuffersArray(render_pass,0u,dummy)); verify(SDL_BindGPUVertexBuffersArray(render_pass,1u,bindings))
                SDL_SetGPUStencilReference(render_pass,7u)
                SDL_DrawGPUPrimitives(render_pass,3u,1u,3u,1u)
                put32(uniform,0,0x3f400000u); verify(SDL_PushGPUVertexUniformDataArray(command,0u,uniform))
                SDL_DrawGPUPrimitives(render_pass,3u,1u,3u,2u) // Far blue fails LESS.

                verify(is_ok(native_gpu_end_render_pass(render_pass)) && render_pass==null)
                verify(is_err(native_gpu_end_render_pass(render_pass)))
                return sdl_ok()
            } |> is_ok; verify(scope_ok_3)
            for (i in 0..2) { targets[i].load_op=SDL_GPULoadOp.LOADOP_LOAD; targets[i].cycle=false; targets[i].cycle_resolve_texture=false }
            depth.load_op=SDL_GPULoadOp.LOADOP_LOAD; depth.stencil_load_op=SDL_GPULoadOp.LOADOP_LOAD; depth.cycle=false
            let scope_ok_4=with_native_gpu_render_pass(command,targets,depth) $(var render_pass : SDL_GPURenderPass?&) {
                SDL_BindGPUGraphicsPipeline(render_pass,pipelines[1]); verify(SDL_BindGPUVertexBuffersArray(render_pass,0u,dummy)); verify(SDL_BindGPUVertexBuffersArray(render_pass,1u,bindings))
                SDL_BindGPUIndexBufferRef(render_pass,index,SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
                SDL_SetGPUStencilReference(render_pass,8u)
                SDL_DrawGPUIndexedPrimitives(render_pass,3u,1u,1u,3,2u) // Wrong stencil fails.
                var scissor = SDL_Rect(x = 4, w = 4, h = 8)
                SDL_SetGPUScissorRef(render_pass,scissor); SDL_SetGPUStencilReference(render_pass,7u)
                SDL_DrawGPUIndexedPrimitives(render_pass,3u,1u,1u,3,2u)

                return sdl_ok()
            } |> is_ok; verify(scope_ok_4)
            let scope_ok_5=with_native_gpu_copy_pass(command) $(var copy_pass : SDL_GPUCopyPass?&) {
                var source = SDL_GPUTextureRegion(w = 8u, h = 8u, d = 1u)
                var destination = SDL_GPUTextureTransferInfo(transfer_buffer = transfers[1], pixels_per_row = 8u, rows_per_layer = 8u)
                source.texture=textures[2]; destination.offset=64u; SDL_DownloadFromGPUTextureRef(copy_pass,source,destination)
                source.texture=textures[3]; destination.offset=512u; SDL_DownloadFromGPUTextureRef(copy_pass,source,destination)

                return sdl_ok()
            } |> is_ok; verify(scope_ok_5)
            var fence=move_unwrap(native_gpu_submit_fence(command)); verify(command==null && fence!=null)
            verify(is_err(native_gpu_submit(command)) && is_err(native_gpu_cancel(command)) && is_err(native_gpu_submit_fence(command)))
            var fences : array<SDL_GPUFence?>; resize(fences,1); fences[0]=fence
            verify(SDL_WaitForGPUFencesArray(device,true,fences)); SDL_ReleaseGPUFence(device,fence)
            var pixels : array<uint8>; resize(pixels,256)
            verify(!SDL_ReadGPUTransferBufferBytes(device,transfers[1],1024u,1000u,pixels))
            verify(SDL_ReadGPUTransferBufferBytes(device,transfers[1],1024u,64u,pixels))
            for (i in 0..64) {
                let right=(i%8)>=4
                verify(pixels[i*4]==uint8(0) && pixels[i*4+1]==uint8(right ? 0 : 255) && pixels[i*4+2]==uint8(right ? 255 : 0) && pixels[i*4+3]==uint8(255))
            }
            verify(SDL_ReadGPUTransferBufferBytes(device,transfers[1],1024u,512u,pixels))
            for (i in 0..64) {
                let right=(i%8)>=4
                verify(pixels[i*4]==uint8(255) && pixels[i*4+1]==uint8(right ? 255 : 0) && pixels[i*4+2]==uint8(right ? 0 : 255) && pixels[i*4+3]==uint8(255))
            }
            completed=true

            return sdl_ok()
        } |> is_ok; verify(scope_ok_1)
        verify(completed)
        // Normal early return closes the copy pass, then cancels the command.
        let scope_ok_6=with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
            let scope_ok_7=with_native_gpu_copy_pass(command) $(var copy_pass : SDL_GPUCopyPass?&) {
                verify(is_ok(native_gpu_end_copy_pass(copy_pass)) && copy_pass==null)
                verify(is_err(native_gpu_end_copy_pass(copy_pass)))
                return sdl_ok()
            } |> is_ok; verify(scope_ok_7)
            let scope_ok_8=with_native_gpu_copy_pass(command) $(var copy_pass : SDL_GPUCopyPass?&) { return sdl_ok()
            } |> is_ok; verify(scope_ok_8)
            var writable_textures : array<SDL_GPUStorageTextureReadWriteBinding>
            var writable_buffers : array<SDL_GPUStorageBufferReadWriteBinding>
            let ended=with_native_gpu_compute_pass(command,writable_textures,writable_buffers) $(var compute : SDL_GPUComputePass?&) {
                verify(is_ok(native_gpu_end_compute_pass(compute)) && compute==null)
                verify(is_err(native_gpu_end_compute_pass(compute)))
                return sdl_ok()
            }
            verify(is_ok(ended))
            return sdl_ok()
        } |> is_ok; verify(scope_ok_6)
        return true
    }
}

[export]
def main(smoke : bool) : int {
    var success=false
    let scope_ok_9=with_sdl() {
        let scope_ok_10=with_native_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) { success=exercise(device)
            return sdl_ok()
        } |> is_ok; verify(scope_ok_10)

        return sdl_ok()
    } |> is_ok; verify(scope_ok_9)
    verify(success)
    print("Native adapters: shader bytes, MRT/MSAA resolve, depth/stencil, offsets, first-instance, deferred cleanup PASS\n")
    return 0
}
