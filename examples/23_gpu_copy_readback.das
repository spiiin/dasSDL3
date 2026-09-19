options gen2
require dassdl3/sdl3_gpu_transfer_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            var source, zeros, result : array<uint8>
            resize(source,256)
            resize(zeros,256)
            resize(result,256)
            for (i in 0 .. 256) { source[i] = uint8((i*37+11)%256) }
            device |> with_gpu_buffer(source,SDL_GPU_BUFFERUSAGE_VERTEX) $(a) {
                device |> with_gpu_buffer(zeros,SDL_GPU_BUFFERUSAGE_VERTEX) $(b) {
                    device |> gpu_copy_buffer(a,0u,b,0u,256u)
                    device |> with_gpu_readback(b,0u,256u) $(ticket) {
                        // Other CPU work can run here; no mapped GPU pointer escapes.
                        let already_ready = device |> gpu_readback_ready(ticket)
                        device |> gpu_wait_readback(ticket)
                        device |> gpu_readback_bytes(ticket,result)
                        for (i in 0 .. 256) { verify(result[i] == source[i]) }
                        print("GPU copy/readback: 256 bytes match; ready at first poll: {already_ready}\n")
                    }
                }
            }
        }
    }
    return available ? 0 : 77
}
