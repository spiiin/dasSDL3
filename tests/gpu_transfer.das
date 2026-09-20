options gen2
require dassdl3/sdl3_gpu_transfer_boost
require daslib/rtti
require daslib/strings_boost

def check(ok : bool) { if (!ok) { panic("GPU transfer test: {SDL_GetError()}") } }
def equal(a,b : array<uint8>) {
    verify(length(a) == length(b))
    for (i in 0 .. length(a)) { verify(a[i] == b[i]) }
}
[export]
def main(smoke : bool) : int {
    verify(is_err(gpu_poll_readback(null,0ul)))
    verify(SDL_GetError() != "")
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            var initial, changed, result, part, empty : array<uint8>
            resize(initial,256)
            resize(changed,256)
            resize(result,256)
            resize(part,16)
            for (i in 0 .. 256) {
                initial[i] = uint8((i*37+11)%256)
                changed[i] = uint8((i*13+19)%256)
            }
            for (i in 0 .. 16) { part[i] = uint8(7) }
            verify(SDL_CreateGPUDataBuffer(null,initial,SDL_GPU_BUFFERUSAGE_VERTEX) == 0ul)
            verify(SDL_CreateGPUDataBuffer(device,empty,SDL_GPU_BUFFERUSAGE_VERTEX) == 0ul)
            verify(SDL_CreateGPUDataBuffer(device,initial,0u) == 0ul)
            verify(SDL_CreateGPUDataBuffer(device,initial,SDL_GPU_BUFFERUSAGE_VERTEX | SDL_GPU_BUFFERUSAGE_INDEX) == 0ul)
            var dead_buffer = 0ul
            var dead_ticket = 0ul
            let scope_ok_1 = device |> with_gpu_buffer(initial,SDL_GPU_BUFFERUSAGE_VERTEX) $(a : uint64) {
                dead_buffer = a
                let scope_ok_2 = device |> with_gpu_buffer(changed,SDL_GPU_BUFFERUSAGE_VERTEX) $(b : uint64) {
                    verify(!SDL_CopyGPUDataBuffer(device,a,0u,a,0u,16u))
                    verify(!SDL_CopyGPUDataBuffer(device,a,0u,b,252u,8u))
                    verify(!SDL_CopyGPUDataBuffer(device,a,0xfffffffcu,b,0u,16u))
                    verify(!SDL_UpdateGPUDataBuffer(device,a,1u,part,false))
                    verify(!SDL_UpdateGPUDataBuffer(device,a,0u,part,true))
                    verify(!SDL_UpdateGPUDataBuffer(device,a,0u,empty,false))
                    verify(SDL_RequestGPUBufferReadback(device,a,0u,0u) == 0ul)
                    verify(SDL_RequestGPUBufferReadback(device,a,252u,8u) == 0ul)
                    is_ok(device |> gpu_copy_buffer(a,32u,b,64u,128u))
                    let scope_ok_3 = device |> with_gpu_readback(b,0u,256u) $(ticket : uint64) {
                        dead_ticket = ticket
                        verify(SDL_PollGPUReadback(device,ticket) >= 0)
                        verify(!SDL_ReleaseGPUDataBuffer(device,ticket))
                        verify(SDL_PollGPUReadback(device,a) == -1)
                        verify(!SDL_ReadGPUReadback(device,ticket,part))
                        // Queue a later update before waiting: the ticket owns an earlier snapshot.
                        is_ok(device |> gpu_update_buffer(b,0u,initial,true))
                        is_ok(device |> gpu_wait_readback(ticket))
                        verify(unwrap(device |> gpu_poll_readback(ticket)))
                        is_ok(device |> gpu_readback_bytes(ticket,result))
                        for (i in 0 .. 256) {
                            verify(result[i] == ((i >= 64 && i < 192) ? initial[i-32] : changed[i]))
                        }
                        is_ok(device |> gpu_readback_bytes(ticket,result))

                        return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_3)
                    verify(SDL_PollGPUReadback(device,dead_ticket) == -1)
                    verify(!SDL_ReleaseGPUReadback(device,dead_ticket))
                    is_ok(device |> gpu_update_buffer(b,128u,part))
                    let scope_ok_4 = device |> with_gpu_readback(b,0u,256u) $(ticket : uint64) {
                        is_ok(device |> gpu_wait_readback(ticket))
                        is_ok(device |> gpu_readback_bytes(ticket,result))
                        for (i in 0 .. 256) { verify(result[i] == ((i >= 128 && i < 144) ? uint8(7) : initial[i])) }

                        return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_4)
                    // The source can be released immediately after requesting download.
                    let transient = SDL_CreateGPUDataBuffer(device,changed,SDL_GPU_BUFFERUSAGE_VERTEX)
                    verify(transient != 0ul)
                    let scope_ok_5 = device |> with_gpu_readback(transient,0u,256u) $(ticket : uint64) {
                        check(SDL_ReleaseGPUDataBuffer(device,transient))
                        is_ok(device |> gpu_wait_readback(ticket))
                        is_ok(device |> gpu_readback_bytes(ticket,result))
                        equal(changed,result)

                        return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_5)
                    let other_available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(other : SDL_GPUDevice?) {
                        verify(SDL_RequestGPUBufferReadback(other,a,0u,256u) == 0ul)
                        verify(!SDL_ReleaseGPUDataBuffer(other,a))
                        // Intentionally leave pending resources to the device cleanup.
                        let other_buffer = SDL_CreateGPUDataBuffer(other,initial,SDL_GPU_BUFFERUSAGE_VERTEX)
                        verify(other_buffer != 0ul)
                        let other_ticket = SDL_RequestGPUBufferReadback(other,other_buffer,0u,256u)
                        verify(other_ticket != 0ul && SDL_PollGPUReadback(device,other_ticket) == -1)
                        verify(!SDL_WaitGPUReadback(device,other_ticket))

                        return sdl_ok()
                    } |> is_ok
                    verify(other_available)
                    let scope_ok_6 = device |> with_gpu_readback(a,0u,256u) $(ticket : uint64) {
                        is_ok(device |> gpu_wait_readback(ticket))
                        is_ok(device |> gpu_readback_bytes(ticket,result))
                        equal(initial,result)

                        return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_6)

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_2)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_1)
            // Stress immediate discard followed by another acquire: a pending
            // Vulkan fence must not be returned to the pool and reset in use.
            let scope_ok_7 = device |> with_gpu_buffer(initial,SDL_GPU_BUFFERUSAGE_VERTEX) $(a : uint64) {
                for (i in 0 .. 128) {
                    let scope_ok_8 = device |> with_gpu_readback(a,0u,256u) $(ticket : uint64) { dead_ticket = ticket
                        return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_8)
                    verify(SDL_PollGPUReadback(device,dead_ticket) == -1)
                }
                let scope_ok_9 = device |> with_gpu_readback(a,0u,256u) $(ticket : uint64) {
                    is_ok(device |> gpu_wait_readback(ticket))
                    is_ok(device |> gpu_readback_bytes(ticket,result))
                    equal(initial,result)

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_9)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_7)
            verify(SDL_RequestGPUBufferReadback(device,dead_buffer,0u,256u) == 0ul)
            var caught = false
            {
                let scope_ok_10 = device |> with_gpu_buffer(initial,SDL_GPU_BUFFERUSAGE_VERTEX) $(a : uint64) {
                    dead_buffer = a
                    let scope_ok_11 = device |> with_gpu_readback(a,0u,256u) $(ticket : uint64) {
                        dead_ticket = ticket
                        caught = !is_ok(set_title(null,"expected SDL failure")); return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_11)

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_10)
            }
            verify(caught && SDL_PollGPUReadback(device,dead_ticket) == -1)
            verify(!SDL_ReleaseGPUDataBuffer(device,dead_buffer))
            let scope_ok_12 = device |> with_gpu_buffer(initial,SDL_GPU_BUFFERUSAGE_VERTEX) $(a : uint64) {
                let scope_ok_13 = device |> with_gpu_readback(a,0u,256u) $(ticket : uint64) { dead_ticket = ticket; return sdl_ok()
                } |> is_ok
                verify(scope_ok_13)
                verify(SDL_PollGPUReadback(device,dead_ticket) == -1)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_12)
            print("GPU buffer ranges, queued snapshots, copy, fences and cleanup PASS: {SDL_GetGPUDeviceDriver(device)}\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
    return available ? 0 : 77
}
