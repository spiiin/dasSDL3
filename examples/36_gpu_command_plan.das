options gen2
require dassdl3/sdl3_gpu_commands_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            let groups = device |> gpu_plan_debug_groups_supported()
            if (!groups) { print("Debug groups unavailable on pinned SDL D3D12; labels remain enabled\n") }
            var data, zero, result : array<uint8>
            resize(data,32); resize(zero,32); resize(result,32)
            for (i in 0 .. 32) { data[i] = uint8(i*7) }
            device |> with_gpu_buffer(data,SDL_GPU_BUFFERUSAGE_VERTEX) $(a) {
                device |> with_gpu_buffer(zero,SDL_GPU_BUFFERUSAGE_VERTEX) $(b) {
                    device |> with_gpu_buffer(zero,SDL_GPU_BUFFERUSAGE_VERTEX) $(c) {
                        device |> with_gpu_command_plan() $(plan) {
                            if (groups) { device |> gpu_plan_push_group(plan,"Two dependent copies") }
                            device |> gpu_plan_copy_buffer(plan,a,0u,b,0u,32u)
                            device |> gpu_plan_label(plan,"A -> B complete")
                            device |> gpu_plan_copy_buffer(plan,b,0u,c,0u,32u)
                            if (groups) { device |> gpu_plan_pop_group(plan) }
                            device |> gpu_submit_plan(plan)
                        }
                        device |> with_gpu_readback(c,0u,32u) $(ticket) {
                            device |> gpu_wait_readback(ticket)
                            device |> gpu_readback_bytes(ticket,result)
                        }
                        for (i in 0 .. 32) { verify(result[i] == data[i]) }
                        print("A -> B -> C in one command buffer: byte reference PASS\n")
                    }
                }
            }
        }
    }
    return available ? 0 : 77
}
