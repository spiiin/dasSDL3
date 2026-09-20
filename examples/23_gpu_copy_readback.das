options gen2
require dassdl3/sdl3_gpu_transfer_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var source, zeros, result : array<uint8>
    resize(source,256)
    resize(zeros,256)
    resize(result,256)
    for (i in 0 .. 256) { source[i] = uint8((i*37+11)%256) }
    return device |> with_gpu_buffer(source,SDL_GPU_BUFFERUSAGE_VERTEX) $(a : uint64) {
        return device |> with_gpu_buffer(zeros,SDL_GPU_BUFFERUSAGE_VERTEX) $(b : uint64) {
            var gpu_copy_buffer_result <- device |> gpu_copy_buffer(a,0u,b,0u,256u)
            if (is_err(gpu_copy_buffer_result)) { return gpu_copy_buffer_result }
            return device |> with_gpu_readback(b,0u,256u) $(ticket : uint64) {
                // Other CPU work can run here; no mapped GPU pointer escapes.
                let state = device |> gpu_poll_readback(ticket)
                if (is_err(state)) { return err(unwrap_err(state),type<SdlUnit>) }
                let already_ready = unwrap(state)
                var gpu_wait_readback_result <- device |> gpu_wait_readback(ticket)
                if (is_err(gpu_wait_readback_result)) { return gpu_wait_readback_result }
                var gpu_readback_bytes_result <- device |> gpu_readback_bytes(ticket,result)
                if (is_err(gpu_readback_bytes_result)) { return gpu_readback_bytes_result }
                for (i in 0 .. 256) { verify(result[i] == source[i]) }
                print("GPU copy/readback: 256 bytes match; ready at first poll: {already_ready}\n")

                return sdl_ok()
            }
        }
    }
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl() {
        return with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            return run_gpu_example(device, smoke)
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
