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
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
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
            device |> with_gpu_buffer(initial,SDL_GPU_BUFFERUSAGE_VERTEX) $(a) {
                dead_buffer = a
                device |> with_gpu_buffer(changed,SDL_GPU_BUFFERUSAGE_VERTEX) $(b) {
                    verify(!SDL_CopyGPUDataBuffer(device,a,0u,a,0u,16u))
                    verify(!SDL_CopyGPUDataBuffer(device,a,0u,b,252u,8u))
                    verify(!SDL_CopyGPUDataBuffer(device,a,0xfffffffcu,b,0u,16u))
                    verify(!SDL_UpdateGPUDataBuffer(device,a,1u,part,false))
                    verify(!SDL_UpdateGPUDataBuffer(device,a,0u,part,true))
                    verify(!SDL_UpdateGPUDataBuffer(device,a,0u,empty,false))
                    verify(SDL_RequestGPUBufferReadback(device,a,0u,0u) == 0ul)
                    verify(SDL_RequestGPUBufferReadback(device,a,252u,8u) == 0ul)
                    device |> gpu_copy_buffer(a,32u,b,64u,128u)
                    device |> with_gpu_readback(b,0u,256u) $(ticket) {
                        dead_ticket = ticket
                        verify(SDL_PollGPUReadback(device,ticket) >= 0)
                        verify(!SDL_ReleaseGPUDataBuffer(device,ticket))
                        verify(SDL_PollGPUReadback(device,a) == -1)
                        verify(!SDL_ReadGPUReadback(device,ticket,part))
                        // Queue a later update before waiting: the ticket owns an earlier snapshot.
                        device |> gpu_update_buffer(b,0u,initial,true)
                        device |> gpu_wait_readback(ticket)
                        verify(device |> gpu_readback_ready(ticket))
                        device |> gpu_readback_bytes(ticket,result)
                        for (i in 0 .. 256) {
                            verify(result[i] == ((i >= 64 && i < 192) ? initial[i-32] : changed[i]))
                        }
                        device |> gpu_readback_bytes(ticket,result)
                    }
                    verify(SDL_PollGPUReadback(device,dead_ticket) == -1)
                    verify(!SDL_ReleaseGPUReadback(device,dead_ticket))
                    device |> gpu_update_buffer(b,128u,part)
                    device |> with_gpu_readback(b,0u,256u) $(ticket) {
                        device |> gpu_wait_readback(ticket)
                        device |> gpu_readback_bytes(ticket,result)
                        for (i in 0 .. 256) { verify(result[i] == ((i >= 128 && i < 144) ? uint8(7) : initial[i])) }
                    }
                    // The source can be released immediately after requesting download.
                    let transient = SDL_CreateGPUDataBuffer(device,changed,SDL_GPU_BUFFERUSAGE_VERTEX)
                    verify(transient != 0ul)
                    device |> with_gpu_readback(transient,0u,256u) $(ticket) {
                        check(SDL_ReleaseGPUDataBuffer(device,transient))
                        device |> gpu_wait_readback(ticket)
                        device |> gpu_readback_bytes(ticket,result)
                        equal(changed,result)
                    }
                    let other_available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(other) {
                        verify(SDL_RequestGPUBufferReadback(other,a,0u,256u) == 0ul)
                        verify(!SDL_ReleaseGPUDataBuffer(other,a))
                        // Intentionally leave pending resources to the device cleanup.
                        let other_buffer = SDL_CreateGPUDataBuffer(other,initial,SDL_GPU_BUFFERUSAGE_VERTEX)
                        verify(other_buffer != 0ul)
                        let other_ticket = SDL_RequestGPUBufferReadback(other,other_buffer,0u,256u)
                        verify(other_ticket != 0ul && SDL_PollGPUReadback(device,other_ticket) == -1)
                        verify(!SDL_WaitGPUReadback(device,other_ticket))
                    }
                    verify(other_available)
                    device |> with_gpu_readback(a,0u,256u) $(ticket) {
                        device |> gpu_wait_readback(ticket)
                        device |> gpu_readback_bytes(ticket,result)
                        equal(initial,result)
                    }
                }
            }
            // Stress immediate discard followed by another acquire: a pending
            // Vulkan fence must not be returned to the pool and reset in use.
            device |> with_gpu_buffer(initial,SDL_GPU_BUFFERUSAGE_VERTEX) $(a) {
                for (i in 0 .. 128) {
                    device |> with_gpu_readback(a,0u,256u) $(ticket) { dead_ticket = ticket }
                    verify(SDL_PollGPUReadback(device,dead_ticket) == -1)
                }
                device |> with_gpu_readback(a,0u,256u) $(ticket) {
                    device |> gpu_wait_readback(ticket)
                    device |> gpu_readback_bytes(ticket,result)
                    equal(initial,result)
                }
            }
            verify(SDL_RequestGPUBufferReadback(device,dead_buffer,0u,256u) == 0ul)
            var caught = false
            try {
                device |> with_gpu_buffer(initial,SDL_GPU_BUFFERUSAGE_VERTEX) $(a) {
                    dead_buffer = a
                    device |> with_gpu_readback(a,0u,256u) $(ticket) {
                        dead_ticket = ticket
                        panic("GPU transfer scope sentinel")
                    }
                }
            } recover { caught = rtrim(this_context().last_exception) == "GPU transfer scope sentinel" }
            verify(caught && SDL_PollGPUReadback(device,dead_ticket) == -1)
            verify(!SDL_ReleaseGPUDataBuffer(device,dead_buffer))
            device |> with_gpu_buffer(initial,SDL_GPU_BUFFERUSAGE_VERTEX) $(a) {
                device |> with_gpu_readback(a,0u,256u) $(ticket) { dead_ticket = ticket; return }
                verify(SDL_PollGPUReadback(device,dead_ticket) == -1)
            }
            print("GPU buffer ranges, queued snapshots, copy, fences and cleanup PASS: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    return available ? 0 : 77
}
