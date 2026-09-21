options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_transfer_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var source, zeros, result : array<uint8>
    resize(source,256)
    resize(zeros,256)
    resize(result,256)
    for (i in 0 .. 256) { source[i] = uint8((i*37+11)%256) }
    return sdl_scope() {
        let a : GpuBufferHandle = device |> with_gpu_buffer(source,SDL_GPU_BUFFERUSAGE_VERTEX) |> sdl_use
        let b : GpuBufferHandle = device |> with_gpu_buffer(zeros,SDL_GPU_BUFFERUSAGE_VERTEX) |> sdl_use
        device |> gpu_copy_buffer(a,0u,b,0u,256u) |> sdl_try
        let ticket : GpuReadbackHandle = device |> with_gpu_readback(b,0u,256u) |> sdl_use
        // Other CPU work can run here; no mapped GPU pointer escapes.
        let already_ready = device |> gpu_poll_readback(ticket) |> sdl_try
        device |> gpu_wait_readback(ticket) |> sdl_try
        device |> gpu_readback_bytes(ticket,result) |> sdl_try
        for (i in 0 .. 256) { verify(result[i] == source[i]) }
        print("GPU copy/readback: 256 bytes match; ready at first poll: {already_ready}\n")

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_gpu_device(GPU_SHADER_FORMATS,true,"") |> sdl_use
        return run_gpu_example(device, smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
