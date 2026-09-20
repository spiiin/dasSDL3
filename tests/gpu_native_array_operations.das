options gen2
require sdl3

// Same independent pixel/byte oracles as the raw ABI test, now exercising
// array, output-reference and record-reference conversion entry points.

def uniform_bytes(compute : bool; base : uint) : array<uint8> {
    var bytes : array<uint8>; resize(bytes,16)
    if (compute) { bytes[0]=uint8(base) }
    else { for (i in 0..4) { bytes[4*i+2]=uint8(128); bytes[4*i+3]=uint8(63) } }
    return <- bytes
}
def begin_color(command : SDL_GPUCommandBuffer?; color : SDL_GPUColorTargetInfo) : SDL_GPURenderPass? {
    var colors : array<SDL_GPUColorTargetInfo>; resize(colors,1); colors[0]=color
    var result=SDL_BeginGPURenderPassArray(command,colors,null)
    return result
}
def begin_compute(command : SDL_GPUCommandBuffer?; texture : SDL_GPUStorageTextureReadWriteBinding;
                  buffer : SDL_GPUStorageBufferReadWriteBinding) : SDL_GPUComputePass? {
    var textures : array<SDL_GPUStorageTextureReadWriteBinding>; resize(textures,1); textures[0]=texture
    var buffers : array<SDL_GPUStorageBufferReadWriteBinding>; resize(buffers,1); buffers[0]=buffer
    var result=SDL_BeginGPUComputePassArray(command,textures,buffers)
    return result
}
def wait_native(device : SDL_GPUDevice?; var fence : SDL_GPUFence?) : bool {
    var fences : array<SDL_GPUFence?>; resize(fences,1); fences[0]=fence
    return SDL_WaitForGPUFencesArray(device,true,fences)
}

[export]
def main(smoke : bool) : int {
    unsafe {
        verify(SDL_Init(SDL_INIT_VIDEO))
        verify(SDL_GetNumGPUDrivers() > 0)
        let driver = SDL_GetGPUDriver(0)
        let formats = SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL
        verify(SDL_GPUSupportsShaderFormats(formats,driver))
        let props = SDLTest_raw_properties()
        verify(props != 0u && SDL_GPUSupportsProperties(props))
        var device = SDL_CreateGPUDeviceWithProperties(props)
        SDLTest_raw_destroy_properties(props)
        verify(device != null)
        let dxil = SDL_GetGPUDeviceDriver(device) == "direct3d12"
        verify(SDL_GetGPUShaderFormats(device) != 0u)
        verify(SDL_GPUTextureFormatTexelBlockSize(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) == 4u)
        verify(SDL_CalculateGPUTextureFormatSize(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,4u,4u,1u) == 64u)
        verify(SDL_GPUTextureSupportsFormat(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPUTextureType.TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_SAMPLER))
        verify(SDL_GPUTextureSupportsSampleCount(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPUSampleCount.SAMPLECOUNT_1))

        var ti : SDL_GPUTransferBufferCreateInfo
        ti.usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD; ti.size=1024u
        var upload=SDL_CreateGPUTransferBufferRef(device,ti); verify(upload!=null)
        ti.usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD; ti.size=2048u
        var download=SDL_CreateGPUTransferBufferRef(device,ti); verify(download!=null)
        let mapped=SDL_MapGPUTransferBuffer(device,upload,false); verify(SDLTest_raw_fill_upload(mapped))
        SDL_UnmapGPUTransferBuffer(device,upload)
        var bi : SDL_GPUBufferCreateInfo
        bi.size=1024u; bi.usage=SDL_GPU_BUFFERUSAGE_VERTEX
        var geometry=SDL_CreateGPUBufferRef(device,bi); verify(geometry!=null)
        bi.usage=SDL_GPU_BUFFERUSAGE_INDEX
        var indices=SDL_CreateGPUBufferRef(device,bi); verify(indices!=null)
        bi.usage=SDL_GPU_BUFFERUSAGE_INDIRECT
        var indirect=SDL_CreateGPUBufferRef(device,bi); verify(indirect!=null)
        bi.size=32u; bi.usage=SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ|SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ
        var readonly=SDL_CreateGPUBufferRef(device,bi); verify(readonly!=null)
        var copied=SDL_CreateGPUBufferRef(device,bi); verify(copied!=null)
        bi.usage=SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE
        var output=SDL_CreateGPUBufferRef(device,bi); verify(output!=null)
        SDL_SetGPUBufferName(device,geometry,"raw geometry and indirect commands")
        var texture_info : SDL_GPUTextureCreateInfo
        texture_info.texture_type=SDL_GPUTextureType.TEXTURETYPE_2D; texture_info.format=SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM
        texture_info.width=4u; texture_info.height=4u; texture_info.layer_count_or_depth=1u; texture_info.num_levels=1u
        texture_info.usage=SDL_GPU_TEXTUREUSAGE_SAMPLER
        var image=SDL_CreateGPUTextureRef(device,texture_info); verify(image!=null)
        texture_info.usage=SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ|SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ
        var image_copy=SDL_CreateGPUTextureRef(device,texture_info); verify(image_copy!=null)
        texture_info.width=8u; texture_info.height=8u; texture_info.num_levels=4u
        texture_info.usage=SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER
        var target=SDL_CreateGPUTextureRef(device,texture_info); verify(target!=null)
        var blitted=SDL_CreateGPUTextureRef(device,texture_info); verify(blitted!=null)
        texture_info.height=1u; texture_info.num_levels=1u; texture_info.usage=SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE
        var compute_image=SDL_CreateGPUTextureRef(device,texture_info); verify(compute_image!=null)
        SDL_SetGPUTextureName(device,target,"raw rendered target")
        var sampler_info : SDL_GPUSamplerCreateInfo
        var sampler=SDL_CreateGPUSamplerRef(device,sampler_info); verify(sampler!=null)

        var command=SDL_AcquireGPUCommandBuffer(device); verify(command!=null)
        SDL_InsertGPUDebugLabel(command,"raw transfer/render/compute")
        if (!dxil) {
            SDL_PushGPUDebugGroup(command,"raw group")
            SDL_PopGPUDebugGroup(command)
        } else {
            print("RAW_UNSUPPORTED SDL_PushGPUDebugGroup SDL_PopGPUDebugGroup pinned SDL 3.2.18 D3D12 metadata defect\n")
        }
        var copy_pass=SDL_BeginGPUCopyPass(command); verify(copy_pass!=null)
        var transfer : SDL_GPUTransferBufferLocation; transfer.transfer_buffer=upload
        var region : SDL_GPUBufferRegion; region.buffer=geometry; region.size=192u
        SDL_UploadToGPUBufferRef(copy_pass,transfer,region,false)
        region.buffer=indices
        SDL_UploadToGPUBufferRef(copy_pass,transfer,region,false)
        region.buffer=indirect
        SDL_UploadToGPUBufferRef(copy_pass,transfer,region,false)
        transfer.offset=64u; region.buffer=readonly; region.size=16u
        SDL_UploadToGPUBufferRef(copy_pass,transfer,region,false)
        var source : SDL_GPUBufferLocation; source.buffer=readonly
        var dest : SDL_GPUBufferLocation; dest.buffer=copied
        SDL_CopyGPUBufferToBufferRef(copy_pass,source,dest,16u,false)
        var tex_transfer : SDL_GPUTextureTransferInfo; tex_transfer.transfer_buffer=upload; tex_transfer.offset=256u; tex_transfer.pixels_per_row=4u; tex_transfer.rows_per_layer=4u
        var tex_region : SDL_GPUTextureRegion; tex_region.texture=image; tex_region.w=4u; tex_region.h=4u; tex_region.d=1u
        SDL_UploadToGPUTextureRef(copy_pass,tex_transfer,tex_region,false)
        var tex_source : SDL_GPUTextureLocation; tex_source.texture=image
        var tex_dest : SDL_GPUTextureLocation; tex_dest.texture=image_copy
        SDL_CopyGPUTextureToTextureRef(copy_pass,tex_source,tex_dest,4u,4u,1u,false)
        SDL_EndGPUCopyPass(copy_pass)

        var shader_info : SDL_GPUShaderCreateInfo
        verify(SDLTest_raw_shader_info(dxil,0,shader_info))
        var vs=SDL_CreateGPUShader(device,addr(shader_info)); verify(vs!=null)
        verify(SDLTest_raw_shader_info(dxil,1,shader_info))
        var fs=SDL_CreateGPUShader(device,addr(shader_info)); verify(fs!=null)
        var pipeline_info : SDL_GPUGraphicsPipelineCreateInfo
        SDLTest_raw_pipeline_info(pipeline_info,vs,fs)
        var pipeline=SDL_CreateGPUGraphicsPipeline(device,addr(pipeline_info)); verify(pipeline!=null)
        var compute_info : SDL_GPUComputePipelineCreateInfo
        verify(SDLTest_raw_compute_info(dxil,compute_info))
        var compute=SDL_CreateGPUComputePipeline(device,addr(compute_info)); verify(compute!=null)
        var color : SDL_GPUColorTargetInfo; color.texture=target; color.load_op=SDL_GPULoadOp.LOADOP_CLEAR; color.store_op=SDL_GPUStoreOp.STOREOP_STORE
        var render_pass=begin_color(command,color); verify(render_pass!=null)
        SDL_BindGPUGraphicsPipeline(render_pass,pipeline)
        var blend : SDL_FColor; blend.r=0.25; blend.g=0.5; blend.b=0.75; blend.a=1.0
        SDL_SetGPUBlendConstants(render_pass,blend)
        SDL_SetGPUStencilReference(render_pass,7u)
        var binding : SDL_GPUBufferBinding; binding.buffer=geometry
        var vertex_bindings : array<SDL_GPUBufferBinding>; resize(vertex_bindings,1); vertex_bindings[0]=binding
        verify(SDL_BindGPUVertexBuffersArray(render_pass,0u,vertex_bindings))
        binding.buffer=indices; binding.offset=32u
        SDL_BindGPUIndexBufferRef(render_pass,binding,SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
        var sampled : SDL_GPUTextureSamplerBinding; sampled.texture=image; sampled.sampler=sampler
        var samples : array<SDL_GPUTextureSamplerBinding>; resize(samples,1); samples[0]=sampled
        var images : array<SDL_GPUTexture?>; resize(images,1); images[0]=image_copy
        var storage : array<SDL_GPUBuffer?>; resize(storage,1); storage[0]=copied
        verify(SDL_BindGPUVertexSamplersArray(render_pass,0u,samples))
        verify(SDL_BindGPUFragmentSamplersArray(render_pass,0u,samples))
        verify(SDL_BindGPUVertexStorageTexturesArray(render_pass,0u,images))
        verify(SDL_BindGPUFragmentStorageTexturesArray(render_pass,0u,images))
        verify(SDL_BindGPUVertexStorageBuffersArray(render_pass,0u,storage))
        verify(SDL_BindGPUFragmentStorageBuffersArray(render_pass,0u,storage))
        verify(SDL_PushGPUVertexUniformDataArray(command,0u,uniform_bytes(false,0u)))
        verify(SDL_PushGPUFragmentUniformDataArray(command,0u,uniform_bytes(false,0u)))
        var viewport : SDL_GPUViewport; viewport.w=8.0; viewport.h=8.0; viewport.max_depth=1.0
        SDL_SetGPUViewportRef(render_pass,viewport)
        var scissor : SDL_Rect; scissor.w=4; scissor.h=4
        SDL_SetGPUScissorRef(render_pass,scissor)
        SDL_DrawGPUPrimitives(render_pass,3u,1u,0u,0u)
        scissor.x=4; SDL_SetGPUScissorRef(render_pass,scissor)
        SDL_DrawGPUIndexedPrimitives(render_pass,3u,1u,0u,0,0u)
        scissor.x=0; scissor.y=4; SDL_SetGPUScissorRef(render_pass,scissor)
        SDL_DrawGPUPrimitivesIndirect(render_pass,indirect,96u,1u)
        scissor.x=4; SDL_SetGPUScissorRef(render_pass,scissor)
        SDL_DrawGPUIndexedPrimitivesIndirect(render_pass,indirect,128u,1u)
        SDL_EndGPURenderPass(render_pass)
        SDL_GenerateMipmapsForGPUTexture(command,target)
        var blit : SDL_GPUBlitInfo
        blit.source.texture=target; blit.source.w=8u; blit.source.h=8u
        blit.destination.texture=blitted; blit.destination.w=8u; blit.destination.h=8u
        blit.load_op=SDL_GPULoadOp.LOADOP_DONT_CARE
        SDL_BlitGPUTextureRef(command,blit)

        var rwtex : SDL_GPUStorageTextureReadWriteBinding; rwtex.texture=compute_image
        var rwbuf : SDL_GPUStorageBufferReadWriteBinding; rwbuf.buffer=output
        var compute_pass=begin_compute(command,rwtex,rwbuf); verify(compute_pass!=null)
        SDL_BindGPUComputePipeline(compute_pass,compute)
        verify(SDL_BindGPUComputeSamplersArray(compute_pass,0u,samples))
        verify(SDL_BindGPUComputeStorageTexturesArray(compute_pass,0u,images))
        verify(SDL_BindGPUComputeStorageBuffersArray(compute_pass,0u,storage))
        verify(SDL_PushGPUComputeUniformDataArray(command,0u,uniform_bytes(true,11u)))
        SDL_DispatchGPUCompute(compute_pass,2u,1u,1u)
        SDL_EndGPUComputePass(compute_pass)
        // Snapshot the first dispatch before the second overwrites the output.
        copy_pass=SDL_BeginGPUCopyPass(command)
        region.buffer=output; region.size=32u; transfer.transfer_buffer=download; transfer.offset=64u
        SDL_DownloadFromGPUBufferRef(copy_pass,region,transfer)
        SDL_EndGPUCopyPass(copy_pass)
        compute_pass=begin_compute(command,rwtex,rwbuf)
        SDL_BindGPUComputePipeline(compute_pass,compute)
        verify(SDL_BindGPUComputeSamplersArray(compute_pass,0u,samples))
        verify(SDL_BindGPUComputeStorageTexturesArray(compute_pass,0u,images))
        verify(SDL_BindGPUComputeStorageBuffersArray(compute_pass,0u,storage))
        verify(SDL_PushGPUComputeUniformDataArray(command,0u,uniform_bytes(true,21u)))
        SDL_DispatchGPUComputeIndirect(compute_pass,indirect,160u)
        SDL_EndGPUComputePass(compute_pass)
        copy_pass=SDL_BeginGPUCopyPass(command)
        region.buffer=copied; region.size=16u; transfer.offset=0u
        SDL_DownloadFromGPUBufferRef(copy_pass,region,transfer)
        region.buffer=output; region.size=32u; transfer.offset=128u
        SDL_DownloadFromGPUBufferRef(copy_pass,region,transfer)
        tex_transfer.transfer_buffer=download; tex_transfer.offset=256u; tex_transfer.pixels_per_row=8u; tex_transfer.rows_per_layer=8u
        tex_region.texture=blitted; tex_region.w=8u; tex_region.h=8u
        SDL_DownloadFromGPUTextureRef(copy_pass,tex_region,tex_transfer)
        tex_transfer.offset=512u; tex_transfer.rows_per_layer=1u; tex_region.texture=compute_image; tex_region.h=1u
        SDL_DownloadFromGPUTextureRef(copy_pass,tex_region,tex_transfer)
        tex_transfer.offset=768u; tex_transfer.pixels_per_row=1u; tex_transfer.rows_per_layer=1u; tex_region.texture=target; tex_region.mip_level=3u; tex_region.w=1u
        SDL_DownloadFromGPUTextureRef(copy_pass,tex_region,tex_transfer)
        SDL_EndGPUCopyPass(copy_pass)
        var fence=SDL_SubmitGPUCommandBufferAndAcquireFence(command); verify(fence!=null)
        verify(wait_native(device,fence))
        verify(SDL_QueryGPUFence(device,fence))
        let result=SDL_MapGPUTransferBuffer(device,download,false); verify(result!=null)
        verify(SDLTest_raw_check_copy(result))
        verify(SDLTest_raw_check_words(result,64u,14u))
        verify(SDLTest_raw_check_words(result,128u,24u))
        verify(SDLTest_raw_check_pixels(result,256u,64u))
        verify(SDLTest_raw_check_pixels(result,512u,8u))
        verify(SDLTest_raw_check_pixels(result,768u,1u))
        SDL_UnmapGPUTransferBuffer(device,download)
        SDL_ReleaseGPUFence(device,fence)

        var window=SDL_CreateWindow("Raw GPU execution test",64,64,0ul); verify(window!=null)
        verify(SDL_ClaimWindowForGPUDevice(device,window))
        verify(SDL_WindowSupportsGPUSwapchainComposition(device,window,SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR))
        verify(SDL_WindowSupportsGPUPresentMode(device,window,SDL_GPUPresentMode.PRESENTMODE_VSYNC))
        verify(SDL_SetGPUSwapchainParameters(device,window,SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR,SDL_GPUPresentMode.PRESENTMODE_VSYNC))
        verify(SDL_SetGPUAllowedFramesInFlight(device,1u))
        verify(SDL_GetGPUSwapchainTextureFormat(device,window)!=SDL_GPUTextureFormat.TEXTUREFORMAT_INVALID)
        verify(SDL_WaitForGPUSwapchain(device,window))
        command=SDL_AcquireGPUCommandBuffer(device)
        var swap : SDL_GPUTexture?; var width=0u; var height=0u
        verify(SDL_AcquireGPUSwapchainTextureRef(command,window,swap,width,height))
        verify(swap!=null && width>0u && height>0u)
        color.texture=swap; color.clear_color=blend
        render_pass=begin_color(command,color); verify(render_pass!=null)
        SDL_EndGPURenderPass(render_pass)
        verify(SDL_SubmitGPUCommandBuffer(command))
        command=SDL_AcquireGPUCommandBuffer(device)
        verify(SDL_WaitAndAcquireGPUSwapchainTextureRef(command,window,swap,width,height))
        verify(swap!=null)
        color.texture=swap; render_pass=begin_color(command,color); verify(render_pass!=null)
        SDL_EndGPURenderPass(render_pass)
        verify(SDL_SubmitGPUCommandBuffer(command))
        command=SDL_AcquireGPUCommandBuffer(device); verify(SDL_CancelGPUCommandBuffer(command))
        verify(SDL_WaitForGPUIdle(device))
        SDL_ReleaseWindowFromGPUDevice(device,window)
        SDL_DestroyWindow(window)
        SDL_ReleaseGPUGraphicsPipeline(device,pipeline)
        SDL_ReleaseGPUComputePipeline(device,compute)
        SDL_ReleaseGPUShader(device,vs); SDL_ReleaseGPUShader(device,fs)
        SDL_ReleaseGPUSampler(device,sampler)
        SDL_ReleaseGPUBuffer(device,geometry); SDL_ReleaseGPUBuffer(device,readonly); SDL_ReleaseGPUBuffer(device,copied); SDL_ReleaseGPUBuffer(device,output)
        SDL_ReleaseGPUBuffer(device,indices); SDL_ReleaseGPUBuffer(device,indirect)
        SDL_ReleaseGPUTexture(device,image); SDL_ReleaseGPUTexture(device,image_copy); SDL_ReleaseGPUTexture(device,target); SDL_ReleaseGPUTexture(device,blitted); SDL_ReleaseGPUTexture(device,compute_image)
        SDL_ReleaseGPUTransferBuffer(device,upload); SDL_ReleaseGPUTransferBuffer(device,download)
        SDL_DestroyGPUDevice(device)
        device=SDL_CreateGPUDevice(formats,true,driver); verify(device!=null)
        SDL_DestroyGPUDevice(device)
        SDL_Quit()
        print("Native array/ref GPU operations and independent data oracles PASS\n")
        return 0
    }
}
