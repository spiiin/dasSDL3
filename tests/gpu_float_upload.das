options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_native_boost
require daslib/defer

def check_upload(device : SDL_GPUDevice?) {
    let values <- array<float>(1.0,-2.0,0.5,0.0)
    return sdl_scope() {
        var upload : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD,size=32u)) |> sdl_use
        var download : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD,size=32u)) |> sdl_use
        var buffer : SDL_GPUBuffer? = device |> with_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_VERTEX,size=32u)) |> sdl_use
        verify(is_err(write_native_gpu_transfer_floats(device,upload,32u,20u,values)))
        verify(is_err(write_native_gpu_transfer_floats(device,upload,32u,0xffffffffu,values)))
        verify(is_err(write_native_gpu_transfer_floats(device,null,32u,0u,values)))
        device |> write_native_gpu_transfer_floats(upload,32u,8u,values) |> sdl_try
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        sdl_scope() {
            var copy_pass : SDL_GPUCopyPass?& = with_native_gpu_copy_pass(command) |> sdl_use
            let source=SDL_GPUTransferBufferLocation(transfer_buffer=upload,offset=8u)
            let region=SDL_GPUBufferRegion(buffer=buffer,offset=4u,size=16u)
            let destination=SDL_GPUTransferBufferLocation(transfer_buffer=download,offset=12u)
            SDL_UploadToGPUBufferRef(copy_pass,source,region,false)
            SDL_DownloadFromGPUBufferRef(copy_pass,region,destination)
            return sdl_ok()
        } |> sdl_try
        var fence=native_gpu_submit_fence(command) |> sdl_try
        {
            defer() { SDL_ReleaseGPUFence(device,fence) }
            let fences <- array(fence)
            sdl_status(SDL_WaitForGPUFencesArray(device,true,fences),"SDL_WaitForGPUFencesArray") |> sdl_try
        }
        var bytes : array<uint8>; resize(bytes,16)
        sdl_status(SDL_ReadGPUTransferBufferBytes(device,download,32u,12u,bytes),"SDL_ReadGPUTransferBufferBytes") |> sdl_try
        let expected <- array<uint>(0x3f800000u,0xc0000000u,0x3f000000u,0u)
        for (i in 0 .. 4) {
            for (j in 0 .. 4) { verify(uint(bytes[i*4+j])==((expected[i]>>uint(j*8))&255u)) }
        }
        verify(is_err(push_native_gpu_vertex_uniforms(null,0u,values)))
        return sdl_ok()
    }
}
[export]
def main(smoke : bool) : int {
    let result=sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(GPU_SHADER_FORMATS,true,"") |> sdl_use
        return check_upload(device)
    }
    if (is_err(result)) { print("{unwrap_err(result).message}\n"); return 1 }
    print("GPU float upload roundtrip and validation PASS\n")
    return 0
}
