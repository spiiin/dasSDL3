options gen2
require dassdl3/sdl3_gpu_native_boost
require daslib/defer

def transfer_roundtrip(device : SDL_GPUDevice?) : bool {
    var info : SDL_GPUTransferBufferCreateInfo
    info.usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD; info.size=256u
    var upload=SDL_CreateGPUTransferBufferRef(device,info)
    if (upload==null) { return false }
    {
        defer() { SDL_ReleaseGPUTransferBuffer(device,upload) }
        info.usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD
        var download=SDL_CreateGPUTransferBufferRef(device,info)
        if (download==null) { return false }
        {
            defer() { SDL_ReleaseGPUTransferBuffer(device,download) }
            var buffer_info : SDL_GPUBufferCreateInfo
            buffer_info.usage=SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ; buffer_info.size=256u
            var source=SDL_CreateGPUBufferRef(device,buffer_info)
            if (source==null) { return false }
            {
                defer() { SDL_ReleaseGPUBuffer(device,source) }
                var destination=SDL_CreateGPUBufferRef(device,buffer_info)
                if (destination==null) { return false }
                {
                    defer() { SDL_ReleaseGPUBuffer(device,destination) }
                    var bytes : array<uint8>; resize(bytes,100)
                    for (i in 0..100) { bytes[i]=uint8((i*7+3)%256) }
                    if (!SDL_WriteGPUTransferBufferBytes(device,upload,256u,32u,bytes,true)) { return false }
                    var completed=false
                    let acquired=with_native_gpu_commands(device) $(var command) {
                        let copied=with_native_gpu_copy_pass(command) $(copy_pass) {
                            var location : SDL_GPUTransferBufferLocation; location.transfer_buffer=upload; location.offset=32u
                            var region : SDL_GPUBufferRegion; region.buffer=source; region.offset=16u; region.size=100u
                            SDL_UploadToGPUBufferRef(copy_pass,location,region,true)
                            var from : SDL_GPUBufferLocation; from.buffer=source; from.offset=16u
                            var to : SDL_GPUBufferLocation; to.buffer=destination; to.offset=48u
                            SDL_CopyGPUBufferToBufferRef(copy_pass,from,to,100u,true)
                            region.buffer=destination; region.offset=48u
                            location.transfer_buffer=download; location.offset=24u
                            SDL_DownloadFromGPUBufferRef(copy_pass,region,location)
                        }
                        if (!copied) { return }
                        var fence=native_gpu_submit_fence(command)
                        if (fence==null) { return }
                        var fences : array<SDL_GPUFence?>; resize(fences,1); fences[0]=fence
                        if (!SDL_WaitForGPUFencesArray(device,true,fences)) { return }
                        SDL_ReleaseGPUFence(device,fence)
                        var result : array<uint8>; resize(result,100)
                        if (!SDL_ReadGPUTransferBufferBytes(device,download,256u,24u,result)) { return }
                        completed=true
                        for (i in 0..100) { if (result[i]!=bytes[i]) { completed=false } }
                    }
                    return acquired && completed
                }
            }
        }
    }
}

[export]
def main(smoke : bool) : int {
    var success=false
    let initialized=with_sdl() {
        let created=with_native_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) { success=transfer_roundtrip(device) }
        if (!created) { print("GPU device: {SDL_GetError()}\n") }
    }
    if (!initialized || !success) { print("Native transfer: {SDL_GetError()}\n"); return 1 }
    print("Native transfer: 100 bytes, nonzero offsets, cycling PASS\n"); return 0
}
