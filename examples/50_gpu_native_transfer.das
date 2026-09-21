options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_gpu_native_boost
require daslib/defer

def transfer_roundtrip(device : SDL_GPUDevice?) : $Result<SdlUnit; SdlError> {
    var info : SDL_GPUTransferBufferCreateInfo
    info.usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD; info.size=256u
    var upload = device |> create_native_gpu_transfer_buffer(info) |> sdl_try
    {
        defer() { SDL_ReleaseGPUTransferBuffer(device,upload) }
        info.usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD
        var download = device |> create_native_gpu_transfer_buffer(info) |> sdl_try
        {
            defer() { SDL_ReleaseGPUTransferBuffer(device,download) }
            return copy_buffers(device, upload, download)
        }
    }
}

def copy_and_check(device : SDL_GPUDevice?; var source, destination : SDL_GPUBuffer?; var upload, download : SDL_GPUTransferBuffer?) : $Result<SdlUnit; SdlError> {
        var bytes : array<uint8>; resize(bytes,100)
        for (i in 0..100) { bytes[i]=uint8((i*7+3)%256) }
        if (!SDL_WriteGPUTransferBufferBytes(device,upload,256u,32u,bytes,true)) { return err(sdl_error("transfer_roundtrip"),type<SdlUnit>) }
        var completed=false
        with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
            with_native_gpu_copy_pass(command) $(copy_pass : SDL_GPUCopyPass?) {
                var location : SDL_GPUTransferBufferLocation; location.transfer_buffer=upload; location.offset=32u
                var region : SDL_GPUBufferRegion; region.buffer=source; region.offset=16u; region.size=100u
                SDL_UploadToGPUBufferRef(copy_pass,location,region,true)
                var from : SDL_GPUBufferLocation; from.buffer=source; from.offset=16u
                var to : SDL_GPUBufferLocation; to.buffer=destination; to.offset=48u
                SDL_CopyGPUBufferToBufferRef(copy_pass,from,to,100u,true)
                region.buffer=destination; region.offset=48u
                location.transfer_buffer=download; location.offset=24u
                SDL_DownloadFromGPUBufferRef(copy_pass,region,location)

                return sdl_ok()
            } |> sdl_try
            var fence = native_gpu_submit_fence(command) |> sdl_try
            var fences : array<SDL_GPUFence?>; resize(fences,1); fences[0]=fence
            if (!SDL_WaitForGPUFencesArray(device,true,fences)) {return err(sdl_error("50_gpu_native_transfer"),type<SdlUnit>)}
            SDL_ReleaseGPUFence(device,fence)
            var result : array<uint8>; resize(result,100)
            if (!SDL_ReadGPUTransferBufferBytes(device,download,256u,24u,result)) {return err(sdl_error("50_gpu_native_transfer"),type<SdlUnit>)}
            completed=true
            for (i in 0..100) { if (result[i]!=bytes[i]) { completed=false } }

            return sdl_ok()
        } |> sdl_try
    if(!completed) {return err(SdlError(operation="transfer_roundtrip",message="Readback differs from expected values"),type<SdlUnit>)}
    return sdl_ok()
}

def copy_to_destination(device : SDL_GPUDevice?; buffer_info : SDL_GPUBufferCreateInfo; var source : SDL_GPUBuffer?; var upload, download : SDL_GPUTransferBuffer?) : $Result<SdlUnit; SdlError> {
    var destination = device |> create_native_gpu_buffer(buffer_info) |> sdl_try
    {
        defer() { SDL_ReleaseGPUBuffer(device,destination) }
        return copy_and_check(device, source, destination, upload, download)
    }
}

def copy_buffers(device : SDL_GPUDevice?; var upload, download : SDL_GPUTransferBuffer?) : $Result<SdlUnit; SdlError> {
    var buffer_info : SDL_GPUBufferCreateInfo
    buffer_info.usage=SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ; buffer_info.size=256u
    var source = device |> create_native_gpu_buffer(buffer_info) |> sdl_try
    {
        defer() { SDL_ReleaseGPUBuffer(device,source) }
        return copy_to_destination(device, buffer_info, source, upload, download)
    }
}

[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        return with_native_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) { return transfer_roundtrip(device)
        }
    }
    if (is_err(initialized)) { print("Native transfer: {unwrap_err(initialized).message}\n"); return 1 }
    print("Native transfer: 100 bytes, nonzero offsets, cycling PASS\n"); return 0
}
