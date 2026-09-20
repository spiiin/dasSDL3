options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_gpu_native_boost
require daslib/defer

def compute_values(device : SDL_GPUDevice?) : $Result<SdlUnit; SdlError> {
    let spirv=(SDL_GetGPUShaderFormats(device)&SDL_GPU_SHADERFORMAT_SPIRV)!=0u
    let ext=spirv ? "spv" : "dxil"
    var info : SDL_GPUComputePipelineCreateInfo
    info.format=spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    info.num_readwrite_storage_buffers=1u; info.num_uniform_buffers=1u
    info.threadcount_x=4u; info.threadcount_y=1u; info.threadcount_z=1u
    let pipeline=SDL_LoadGPUComputePipelineFile(device,info,"{SDL_GetBasePath()}assets/shaders/native.comp.{ext}","main")
    if (pipeline==null) { return err(sdl_error("compute_values"),type<SdlUnit>) }
    {
        defer() { SDL_ReleaseGPUComputePipeline(device,pipeline) }
        var buffer_info : SDL_GPUBufferCreateInfo; buffer_info.usage=SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE; buffer_info.size=32u
        var output=SDL_CreateGPUBufferRef(device,buffer_info)
        if (output==null) { return err(sdl_error("compute_values"),type<SdlUnit>) }
        {
            defer() { SDL_ReleaseGPUBuffer(device,output) }
            return read_compute_output(device, pipeline, output)
        }
    }
}

def dispatch_and_check(device : SDL_GPUDevice?; pipeline : SDL_GPUComputePipeline?; var output : SDL_GPUBuffer?; var download : SDL_GPUTransferBuffer?) : $Result<SdlUnit; SdlError> {
    var finished=false
    with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
        var textures : array<SDL_GPUStorageTextureReadWriteBinding>
        var buffers : array<SDL_GPUStorageBufferReadWriteBinding>; resize(buffers,1); buffers[0].buffer=output
        var uniforms : array<uint8>; resize(uniforms,16); uniforms[0]=uint8(10)
        if (!SDL_PushGPUComputeUniformDataArray(command,0u,uniforms)) {return err(sdl_error("49_gpu_native_compute"),type<SdlUnit>)}
        with_native_gpu_compute_pass(command,textures,buffers) $(compute_pass : SDL_GPUComputePass?) {
            SDL_BindGPUComputePipeline(compute_pass,pipeline)
            SDL_DispatchGPUCompute(compute_pass,2u,1u,1u)

            return sdl_ok()
        } |> sdl_try
        with_native_gpu_copy_pass(command) $(copy_pass : SDL_GPUCopyPass?) {
            var source : SDL_GPUBufferRegion; source.buffer=output; source.size=32u
            var destination : SDL_GPUTransferBufferLocation; destination.transfer_buffer=download
            SDL_DownloadFromGPUBufferRef(copy_pass,source,destination)

            return sdl_ok()
        } |> sdl_try
        var fence = native_gpu_submit_fence(command) |> sdl_try
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
    } |> sdl_try
    if(!finished) {return err(SdlError(operation="compute_values",message="Readback differs from expected values"),type<SdlUnit>)}
    return sdl_ok()
}

def read_compute_output(device : SDL_GPUDevice?; pipeline : SDL_GPUComputePipeline?; var output : SDL_GPUBuffer?) : $Result<SdlUnit; SdlError> {
    var transfer_info : SDL_GPUTransferBufferCreateInfo; transfer_info.usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD; transfer_info.size=32u
    var download=SDL_CreateGPUTransferBufferRef(device,transfer_info)
    if (download==null) { return err(sdl_error("compute_values"),type<SdlUnit>) }
    {
        defer() { SDL_ReleaseGPUTransferBuffer(device,download) }
        return dispatch_and_check(device, pipeline, output, download)
    }
}

[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        return with_native_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) { return compute_values(device)
        }
    }
    if (is_err(initialized)) { print("Native compute: {unwrap_err(initialized).message}\n"); return 1 }
    print("Native compute PASS\n"); return 0
}
