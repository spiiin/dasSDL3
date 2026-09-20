options gen2
require dassdl3/sdl3_gpu_native_boost
require daslib/defer

def compute_values(device : SDL_GPUDevice?) : bool {
    let spirv=(SDL_GetGPUShaderFormats(device)&SDL_GPU_SHADERFORMAT_SPIRV)!=0u
    let ext=spirv ? "spv" : "dxil"
    var info : SDL_GPUComputePipelineCreateInfo
    info.format=spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    info.num_readwrite_storage_buffers=1u; info.num_uniform_buffers=1u
    info.threadcount_x=4u; info.threadcount_y=1u; info.threadcount_z=1u
    let pipeline=SDL_LoadGPUComputePipelineFile(device,info,"{SDL_GetBasePath()}assets/shaders/native.comp.{ext}","main")
    if (pipeline==null) { return false }
    {
        defer() { SDL_ReleaseGPUComputePipeline(device,pipeline) }
        var buffer_info : SDL_GPUBufferCreateInfo; buffer_info.usage=SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE; buffer_info.size=32u
        var output=SDL_CreateGPUBufferRef(device,buffer_info)
        if (output==null) { return false }
        {
            defer() { SDL_ReleaseGPUBuffer(device,output) }
            var transfer_info : SDL_GPUTransferBufferCreateInfo; transfer_info.usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD; transfer_info.size=32u
            var download=SDL_CreateGPUTransferBufferRef(device,transfer_info)
            if (download==null) { return false }
            {
                defer() { SDL_ReleaseGPUTransferBuffer(device,download) }
                var finished=false
                let acquired=with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
                    var textures : array<SDL_GPUStorageTextureReadWriteBinding>
                    var buffers : array<SDL_GPUStorageBufferReadWriteBinding>; resize(buffers,1); buffers[0].buffer=output
                    var uniforms : array<uint8>; resize(uniforms,16); uniforms[0]=uint8(10)
                    if (!SDL_PushGPUComputeUniformDataArray(command,0u,uniforms)) {return err(sdl_error("49_gpu_native_compute"),type<SdlUnit>)}
                    let begun=with_native_gpu_compute_pass(command,textures,buffers) $(compute_pass : SDL_GPUComputePass?) {
                        SDL_BindGPUComputePipeline(compute_pass,pipeline)
                        SDL_DispatchGPUCompute(compute_pass,2u,1u,1u)

                        return sdl_ok()
                    }
                    if (is_err(begun)) { return err(unwrap_err(begun),type<SdlUnit>) }
                    let copied=with_native_gpu_copy_pass(command) $(copy_pass : SDL_GPUCopyPass?) {
                        var source : SDL_GPUBufferRegion; source.buffer=output; source.size=32u
                        var destination : SDL_GPUTransferBufferLocation; destination.transfer_buffer=download
                        SDL_DownloadFromGPUBufferRef(copy_pass,source,destination)

                        return sdl_ok()
                    }
                    if (is_err(copied)) { return err(unwrap_err(copied),type<SdlUnit>) }
                    var submitted <- native_gpu_submit_fence(command)
                    if(is_err(submitted)){return err(unwrap_err(submitted),type<SdlUnit>)}
                    var fence=move_unwrap(submitted)
                    if (fence==null) {return err(sdl_error("49_gpu_native_compute"),type<SdlUnit>)}
                    var fences : array<SDL_GPUFence?>; resize(fences,1); fences[0]=fence
                    if (!SDL_WaitForGPUFencesArray(device,true,fences)) {return err(sdl_error("49_gpu_native_compute"),type<SdlUnit>)}
                    SDL_ReleaseGPUFence(device,fence)
                    var bytes : array<uint8>; resize(bytes,32)
                    if (!SDL_ReadGPUTransferBufferBytes(device,download,32u,0u,bytes)) {return err(sdl_error("49_gpu_native_compute"),type<SdlUnit>)}
                    finished=true
                    for (i in 0..8) {
                        let n=uint(bytes[4*i])|(uint(bytes[4*i+1])<<8u)|(uint(bytes[4*i+2])<<16u)|(uint(bytes[4*i+3])<<24u)
                        if (n!=uint(10+3*i)) { finished=false }
                        print("{n} ")
                    }
                    print("\n")

                    return sdl_ok()
                }
                return is_ok(acquired) && finished
            }
        }
    }
}

[export]
def main(smoke : bool) : int {
    var success=false
    let initialized=with_sdl() {
        let created=with_native_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) { success=compute_values(device)
            return sdl_ok()
        }
        if (is_err(created)) { print("GPU device: {unwrap_err(created).message}\n") ; return err(unwrap_err(created),type<SdlUnit>) }

        return sdl_ok()
    }
    if (!is_ok(initialized) || !success) { print("Native compute: {is_err(initialized) ? unwrap_err(initialized).message : SDL_GetErrorCopy()}\n"); return 1 }
    print("Native compute PASS\n"); return 0
}
