options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_native_boost
require daslib/defer

def compute_values(device : SDL_GPUDevice?) : $Result<SdlUnit; SdlError> {
    let spirv=(SDL_GetGPUShaderFormats(device)&SDL_GPU_SHADERFORMAT_SPIRV)!=0u
    let ext=spirv ? "spv" : "dxil"
    var info = SDL_GPUComputePipelineCreateInfo(
        format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL,
        num_readwrite_storage_buffers = 1u,
        num_uniform_buffers = 1u,
        threadcount_x = 4u,
        threadcount_y = 1u,
        threadcount_z = 1u
    )
    let pipeline = device |> load_native_gpu_compute_pipeline(info,"{SDL_GetBasePath()}assets/shaders/native.comp.{ext}","main") |> sdl_try
    {
        defer() { SDL_ReleaseGPUComputePipeline(device,pipeline) }
        var buffer_info = SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE, size = 32u)
        var output = device |> create_native_gpu_buffer(buffer_info) |> sdl_try
        {
            defer() { SDL_ReleaseGPUBuffer(device,output) }
            return read_compute_output(device, pipeline, output)
        }
    }
}

def dispatch_and_check(device : SDL_GPUDevice?; pipeline : SDL_GPUComputePipeline?; var output : SDL_GPUBuffer?; var download : SDL_GPUTransferBuffer?) : $Result<SdlUnit; SdlError> {
    var finished=false
    sdl_scope() {
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        var textures : array<SDL_GPUStorageTextureReadWriteBinding>
        var buffers : array<SDL_GPUStorageBufferReadWriteBinding>; resize(buffers,1); buffers[0].buffer=output
        var uniforms : array<uint8>; resize(uniforms,16); uniforms[0]=uint8(10)
        if (!SDL_PushGPUComputeUniformDataArray(command,0u,uniforms)) {return err(sdl_error("49_gpu_native_compute"),type<SdlUnit>)}
        sdl_scope() {
            var compute_pass : SDL_GPUComputePass?& = with_native_gpu_compute_pass(command,textures,buffers) |> sdl_use
            SDL_BindGPUComputePipeline(compute_pass,pipeline)
            SDL_DispatchGPUCompute(compute_pass,2u,1u,1u)

            return sdl_ok()
        } |> sdl_try
        sdl_scope() {
            var copy_pass : SDL_GPUCopyPass?& = with_native_gpu_copy_pass(command) |> sdl_use
            var source = SDL_GPUBufferRegion(buffer = output, size = 32u)
            var destination = SDL_GPUTransferBufferLocation(transfer_buffer = download)
            SDL_DownloadFromGPUBufferRef(copy_pass,source,destination)

            return sdl_ok()
        } |> sdl_try
        var fence = native_gpu_submit_fence(command) |> sdl_try
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
    var transfer_info = SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD, size = 32u)
    var download = device |> create_native_gpu_transfer_buffer(transfer_info) |> sdl_try
    {
        defer() { SDL_ReleaseGPUTransferBuffer(device,download) }
        return dispatch_and_check(device, pipeline, output, download)
    }
}

[export]
def main(smoke : bool) : int {
    let initialized=sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(GPU_SHADER_FORMATS,true,"") |> sdl_use
        return compute_values(device)
    }
    if (is_err(initialized)) { print("Native compute: {unwrap_err(initialized).message}\n"); return 1 }
    print("Native compute PASS\n"); return 0
}
