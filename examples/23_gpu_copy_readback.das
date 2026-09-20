options gen2
require dassdl3/sdl3_gpu_transfer_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            var source, zeros, result : array<uint8>
            resize(source,256)
            resize(zeros,256)
            resize(result,256)
            for (i in 0 .. 256) { source[i] = uint8((i*37+11)%256) }
            let scope_ok_1 = device |> with_gpu_buffer(source,SDL_GPU_BUFFERUSAGE_VERTEX) $(a : uint64) {
                let scope_ok_2 = device |> with_gpu_buffer(zeros,SDL_GPU_BUFFERUSAGE_VERTEX) $(b : uint64) {
                    var operation_result_1 <- device |> gpu_copy_buffer(a,0u,b,0u,256u)
                    if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                    let scope_ok_3 = device |> with_gpu_readback(b,0u,256u) $(ticket : uint64) {
                        // Other CPU work can run here; no mapped GPU pointer escapes.
                        let state = device |> gpu_poll_readback(ticket)
                        if (is_err(state)) { return err(unwrap_err(state),type<SdlUnit>) }
                        let already_ready = unwrap(state)
                        var operation_result_2 <- device |> gpu_wait_readback(ticket)
                        if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                        var operation_result_3 <- device |> gpu_readback_bytes(ticket,result)
                        if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
                        for (i in 0 .. 256) { verify(result[i] == source[i]) }
                        print("GPU copy/readback: 256 bytes match; ready at first poll: {already_ready}\n")

                        return sdl_ok()
                    }
                    if (is_err(scope_ok_3)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_3).message}\n") ; return err(unwrap_err(scope_ok_3),type<SdlUnit>) }

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
