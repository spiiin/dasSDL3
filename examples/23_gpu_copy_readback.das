options gen2
require dassdl3/sdl3_gpu_transfer_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            var source, zeros, result : array<uint8>
            resize(source,256)
            resize(zeros,256)
            resize(result,256)
            for (i in 0 .. 256) { source[i] = uint8((i*37+11)%256) }
            let scope_ok_1 = device |> with_gpu_buffer(source,SDL_GPU_BUFFERUSAGE_VERTEX) $(a) {
                let scope_ok_2 = device |> with_gpu_buffer(zeros,SDL_GPU_BUFFERUSAGE_VERTEX) $(b) {
                    if (!(device |> gpu_copy_buffer(a,0u,b,0u,256u))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    let scope_ok_3 = device |> with_gpu_readback(b,0u,256u) $(ticket) {
                        // Other CPU work can run here; no mapped GPU pointer escapes.
                        let state = device |> gpu_poll_readback(ticket)
                        if (state < 0) { example_failed = true; print("GPU poll: {SDL_GetError()}\n"); return }
                        let already_ready = state == 1
                        if (!(device |> gpu_wait_readback(ticket))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(device |> gpu_readback_bytes(ticket,result))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        for (i in 0 .. 256) { verify(result[i] == source[i]) }
                        print("GPU copy/readback: 256 bytes match; ready at first poll: {already_ready}\n")
                    }
                    if (!scope_ok_3) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
