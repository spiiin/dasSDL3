options gen2
require dassdl3/sdl3_gpu_commands_boost
require daslib/rtti
require daslib/strings_boost

def buffer_equals(device : SDL_GPUDevice?; buffer : uint64; expected : array<uint8>) {
    var actual : array<uint8>
    resize(actual,length(expected))
    device |> with_gpu_readback(buffer,0u,uint(length(expected))) $(ticket) {
        device |> gpu_wait_readback(ticket)
        device |> gpu_readback_bytes(ticket,actual)
    }
    for (i in 0 .. length(actual)) { verify(actual[i] == expected[i]) }
}
def texture_equals(device : SDL_GPUDevice?; texture : uint64; sub : uint2; width : uint; expected : array<uint8>) {
    var actual : array<uint8>
    resize(actual,length(expected))
    device |> with_gpu_texture_readback(texture,sub,uint4(0u,0u,width,width)) $(ticket) {
        device |> gpu_wait_readback(ticket)
        device |> gpu_readback_bytes(ticket,actual)
    }
    for (i in 0 .. length(actual)) { verify(actual[i] == expected[i]) }
}
def check_buffers(device : SDL_GPUDevice?) {
    let groups = device |> gpu_plan_debug_groups_supported()
    var data, zero : array<uint8>
    resize(data,32); resize(zero,32)
    for (i in 0 .. 32) { data[i] = uint8(i*7) }
    device |> with_gpu_buffer(data,SDL_GPU_BUFFERUSAGE_VERTEX) $(a) {
        device |> with_gpu_buffer(zero,SDL_GPU_BUFFERUSAGE_VERTEX) $(b) {
            device |> with_gpu_buffer(zero,SDL_GPU_BUFFERUSAGE_VERTEX) $(c) {
                var stale = 0ul
                device |> with_gpu_command_plan() $(plan) {
                    stale = plan
                    verify(!SDL_GPUPlanPopGroup(device,plan))
                    verify(!SDL_GPUPlanCopyBuffer(device,plan,a,1u,b,0u,4u))
                    verify(!SDL_GPUPlanCopyBuffer(device,plan,a,0u,a,0u,4u))
                    verify(!SDL_GPUPlanCopyBuffer(device,plan,a,0xFFFFFFFCu,b,0u,8u))
                    verify(!SDL_GPUPlanCopyBuffer(device,a,a,0u,b,0u,4u))
                    if (groups) { device |> gpu_plan_push_group(plan,"Upload → copy") }
                    if (groups) { verify(SDLTestGPUPlanNoAcquire(device,plan)) }
                    device |> gpu_plan_copy_buffer(plan,a,0u,b,0u,32u)
                    if (groups) { device |> gpu_plan_push_group(plan,"dependent copy") }
                    device |> gpu_plan_copy_buffer(plan,b,0u,c,0u,32u)
                    device |> gpu_plan_label(plan,"ready ✓")
                    verify(SDLTestGPUPlanTextCopy(device,plan))
                    if (groups) { device |> gpu_plan_pop_group(plan) }
                    if (groups) { device |> gpu_plan_pop_group(plan) }
                    // Building the plan did not touch the destination.
                    buffer_equals(device,c,zero)
                    device |> gpu_submit_plan(plan)
                    verify(!SDL_SubmitGPUCommandPlan(device,plan))
                    verify(!SDL_GPUPlanLabel(device,plan,"late"))
                }
                verify(!SDL_GPUPlanLabel(device,stale,"stale"))
                buffer_equals(device,b,data); buffer_equals(device,c,data)
                // A plan borrows resource IDs, not a snapshot of their contents.
                device |> with_gpu_command_plan() $(plan) {
                    device |> gpu_plan_copy_buffer(plan,a,0u,b,0u,32u)
                    device |> gpu_update_buffer(a,0u,zero)
                    device |> gpu_submit_plan(plan)
                }
                buffer_equals(device,b,zero)
                device |> gpu_update_buffer(a,0u,data)
                device |> gpu_update_buffer(b,0u,zero)
                // Invalid last item rejects the whole plan before acquisition.
                device |> with_gpu_command_plan() $(plan) {
                    device |> gpu_plan_copy_buffer(plan,a,0u,b,0u,32u)
                    device |> with_gpu_buffer(data,SDL_GPU_BUFFERUSAGE_VERTEX) $(temporary) {
                        device |> gpu_plan_copy_buffer(plan,temporary,0u,b,0u,4u)
                    }
                    verify(SDLTestGPUPlanNoAcquire(device,plan))
                    buffer_equals(device,b,zero)
                }
                // Panic discards a CPU plan, with no GPU work to cancel.
                var caught = false
                try {
                    device |> with_gpu_command_plan() $(plan) {
                        device |> gpu_plan_copy_buffer(plan,a,0u,b,0u,32u)
                        panic("discard this plan")
                    }
                } recover { caught = true }
                verify(caught && SDLTestGPUPlans() == 0)
                buffer_equals(device,b,zero)
                verify(SDLTestGPUPlanFaults(device,a,b))
                verify(SDL_RequestGPUBufferReadback(device,b,0u,32u) == 0ul)
                device |> gpu_update_buffer(b,0u,zero)
                buffer_equals(device,b,zero)
                with_gpu_device() $(other) {
                    device |> with_gpu_command_plan() $(plan) {
                        verify(!SDL_GPUPlanLabel(other,plan,"foreign"))
                        verify(!SDL_SubmitGPUCommandPlan(other,plan))
                        verify(!SDL_ReleaseGPUCommandPlan(other,plan))
                        device |> gpu_submit_plan(plan)
                    }
                }
            }
        }
    }
}
def check_textures(device : SDL_GPUDevice?) {
    var pixels, tiny : array<uint8>
    resize(pixels,64); resize(tiny,4)
    for (i in 0 .. 64) { pixels[i] = uint8(72) }
    for (i in 0 .. 4) { tiny[i] = uint8(72) }
    device |> with_gpu_rgba_texture(4u,4u) $(source) {
        device |> gpu_upload_texture(source,uint2(0u),uint4(0u,0u,4u,4u),pixels,16u)
        device |> with_gpu_color_target_texture(4u,4u,2u,3u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(image) {
            device |> with_gpu_color_target_texture(4u,4u,1u,3u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(dest) {
                device |> with_gpu_command_plan() $(plan) {
                    verify(!SDL_GPUPlanMipmaps(device,plan,source))
                    verify(!SDL_GPUPlanCopyTexture(device,plan,source,uint2(0u),uint4(0u,0u,4u,4u),image,uint2(0u),uint2(1u)))
                    verify(!SDL_GPUPlanBlit(device,plan,source,uint2(0u),uint4(0u,0u,4u,4u),image,uint2(0u),uint4(0u,0u,4u,4u),42u))
                    device |> gpu_plan_copy_texture(plan,source,uint2(0u),uint4(0u,0u,4u,4u),image,uint2(0u,1u),uint2(0u))
                    device |> gpu_plan_mipmaps(plan,image)
                    device |> gpu_plan_blit(plan,image,uint2(2u,1u),uint4(0u,0u,1u,1u),dest,uint2(0u),uint4(0u,0u,4u,4u))
                    device |> gpu_plan_mipmaps(plan,dest)
                    device |> gpu_submit_plan(plan)
                }
                texture_equals(device,image,uint2(2u,1u),1u,tiny)
                texture_equals(device,dest,uint2(0u),4u,pixels)
                texture_equals(device,dest,uint2(2u,0u),1u,tiny)
                device |> with_gpu_command_plan() $(plan) {
                    device |> gpu_plan_blit(plan,image,uint2(0u,1u),uint4(0u,0u,4u,4u),dest,uint2(0u),uint4(0u,0u,4u,4u))
                    device |> gpu_plan_mipmaps(plan,dest)
                    verify(SDLTestGPUPlanFailSubmit(device,plan))
                    verify(!SDL_SubmitGPUCommandPlan(device,plan))
                }
                verify(SDL_RequestGPUTextureReadback(device,dest,uint2(0u),uint4(0u,0u,4u,4u)) == 0ul)
                verify(SDL_RequestGPUTextureReadback(device,dest,uint2(2u,0u),uint4(0u,0u,1u,1u)) == 0ul)
                device |> gpu_upload_texture(dest,uint2(0u),uint4(0u,0u,4u,4u),pixels,16u)
                device |> gpu_generate_mipmaps(dest)
                texture_equals(device,dest,uint2(2u,0u),1u,tiny)
                for (i in 0 .. 64) { pixels[i] = uint8(0) }
                texture_equals(device,image,uint2(0u),4u,pixels)
            }
        }
    }
}
def check_bc_plan(device : SDL_GPUDevice?) {
    let format = SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM
    if (!(device |> gpu_supports_format(format,SDL_GPU_TEXTURETYPE_2D_ARRAY,SDL_GPU_TEXTUREUSAGE_SAMPLER))) {
        print("Optional BC1 plan test unsupported\n")
        return
    }
    var bytes : array<uint8>
    resize(bytes,8)
    for (i in 0 .. 8) { bytes[i] = uint8(i*9+3) }
    device |> with_gpu_transfer_texture(4u,4u,2u,3u,format,SDL_GPU_TEXTURETYPE_2D_ARRAY) $(a) {
        device |> with_gpu_transfer_texture(4u,4u,2u,3u,format,SDL_GPU_TEXTURETYPE_2D_ARRAY) $(b) {
            device |> gpu_upload_texture(a,uint2(2u,1u),uint4(0u,0u,1u,1u),bytes,8u)
            device |> with_gpu_command_plan() $(plan) {
                device |> gpu_plan_copy_texture(plan,a,uint2(2u,1u),uint4(0u,0u,1u,1u),b,uint2(2u,0u),uint2(0u))
                device |> gpu_submit_plan(plan)
            }
            texture_equals(device,b,uint2(2u,0u),1u,bytes)
        }
    }
}
def check_scope_errors(device : SDL_GPUDevice?) {
    // Deliberate ownership misuse tests both cleanup failure paths.
    for (mode in 0 .. 2) {
        let body_fails = mode == 1
        var caught = false
        var message = ""
        try {
            device |> with_gpu_command_plan() $(plan) {
                verify(SDL_ReleaseGPUCommandPlan(device,plan))
                if (body_fails) { panic("original body failure") }
            }
        } recover {
            caught = true
            message := rtrim(this_context().last_exception)
        }
        verify(caught && find(message,"SDL scope cleanup") >= 0)
        if (body_fails) { verify(find(message,"original body failure") >= 0) }
        verify(SDLTestGPUPlans() == 0)
    }
}
def check_limits(device : SDL_GPUDevice?) {
    let groups = device |> gpu_plan_debug_groups_supported()
    device |> with_gpu_command_plan() $(plan) {
        for (i in 0 .. (groups ? 64 : 0)) { device |> gpu_plan_push_group(plan,"") }
        verify(!SDL_GPUPlanPushGroup(device,plan,"overflow"))
        for (i in 0 .. (groups ? 64 : 0)) { device |> gpu_plan_pop_group(plan) }
        for (i in 0 .. (groups ? 3968 : 4096)) { device |> gpu_plan_label(plan,"") }
        verify(!SDL_GPUPlanLabel(device,plan,"overflow"))
        device |> gpu_submit_plan(plan)
    }
}
[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            check_buffers(device)
            check_textures(device)
            check_scope_errors(device)
            check_limits(device)
            check_bc_plan(device)
            let plan = SDL_CreateGPUCommandPlan(device)
            verify(plan != 0ul) // Device destruction owns abandoned plan cleanup.
        }
        verify(SDLTestGPUPlans() == 0)
    }
    return available ? 0 : 77
}
