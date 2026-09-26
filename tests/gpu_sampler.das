options gen2
require dassdl3/sdl3_gpu_sampler_boost
require dassdl3/sdl3_gpu_texture_transfer_boost
require daslib/rtti
require strings

def check_descriptors(device : SDL_GPUDevice?) {
    verify(SDLTest_sampler_invalid_descriptors(device))
    for (mode in 0 .. 4) {
        var info = gpu_sampler()
        let filter = mode == 0 ? SDL_GPUFilter.FILTER_NEAREST : SDL_GPUFilter.FILTER_LINEAR
        info |> filters(filter, filter)
        info |> mipmap_mode(mode == 0 ? SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_NEAREST : SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR)
        info |> address_modes(SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
            SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT, SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_MIRRORED_REPEAT)
        info |> lod_range(1.0, 8.0)
        info |> lod_bias(mode == 0 ? -2.0 : 2.0)
        info |> comparison(SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL, mode == 2)
        info |> anisotropy(16.0, mode == 3)
        let scope_ok_0 = device |> with_gpu_sampler(info) $(id : GpuSamplerHandle) {
            info.max_lod = 0.0 // Creation copied the descriptor.
            var query_result_1 : SDL_GPUSamplerCreateInfo
            verify(is_ok(gpu_sampler_descriptor(device, id, query_result_1)))
            var copy = query_result_1
            verify(copy.min_lod == 1.0 && copy.max_lod == 8.0)
            verify(copy.min_filter == info.min_filter && copy.mag_filter == info.mag_filter)
            verify(copy.mipmap_mode == info.mipmap_mode && copy.mip_lod_bias == info.mip_lod_bias)
            verify(copy.address_mode_u == info.address_mode_u && copy.address_mode_v == info.address_mode_v && copy.address_mode_w == info.address_mode_w)
            verify(copy.enable_compare == info.enable_compare && copy.enable_anisotropy == info.enable_anisotropy)
            verify(copy.compare_op == (mode == 2 ? SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL : SDL_GPUCompareOp.COMPAREOP_ALWAYS))
            verify(copy.max_anisotropy == (mode == 3 ? 16.0 : 1.0) && copy.props == 0u)
            copy.max_lod = 3.0
            var query_result_2 : SDL_GPUSamplerCreateInfo
            verify(is_ok(gpu_sampler_descriptor(device, id, query_result_2)))
            verify(query_result_2.max_lod == 8.0)
            verify(SDLTest_sampler_wrong_thread(device, *id))

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_0)
    }
}
def check_lifetime(device : SDL_GPUDevice?) {
    var stale : GpuSamplerHandle
    let scope_ok_1 = device |> with_gpu_sampler() $(id : GpuSamplerHandle) { stale = id; return sdl_ok()
    } |> is_ok
    verify(scope_ok_1)
    verify(!SDLTest_sampler_exists(*stale))
    var out = gpu_sampler_info()
    verify(!SDL_GetGPUCheckedSamplerInfo(device, stale, out) && out.max_lod == 0.0)
    verify(!SDL_ReleaseGPUCheckedSampler(device, stale))
    var caught = false
    let scope_ok_2 = device |> with_gpu_sampler() $(outer : GpuSamplerHandle) {
        {
            let scope_ok_3 = device |> with_gpu_sampler() $(inner : GpuSamplerHandle) { stale = inner; caught = !is_ok(set_title(null, "expected SDL failure")); return sdl_ok()
            } |> is_ok
            verify(scope_ok_3)
        }
        verify(caught && !SDLTest_sampler_exists(*stale))
        var query_result_3 : SDL_GPUSamplerCreateInfo
        verify(is_ok(gpu_sampler_descriptor(device, outer, query_result_3)))
        verify(query_result_3.max_lod == 1000.0)
        var foreign : GpuSamplerHandle
        let second = with_gpu_device(GPU_SHADER_FORMATS, true, "") $(other : SDL_GPUDevice?) {
            verify(!SDL_ReleaseGPUCheckedSampler(other, outer))
            verify(!SDL_GetGPUCheckedSamplerInfo(other, outer, out))
            foreign = SDL_CreateGPUCheckedSampler(other, gpu_sampler_info())
            verify(*foreign != 0ul && foreign != outer)
            verify(!SDL_GetGPUCheckedSamplerInfo(device, foreign, out))
            // Deliberately left for device cleanup.

            return sdl_ok()
        } |> is_ok
        verify(second && !SDLTest_sampler_exists(*foreign))
        var query_result_4 : SDL_GPUSamplerCreateInfo
        verify(is_ok(gpu_sampler_descriptor(device, outer, query_result_4)))
        verify(query_result_4.max_lod == 1000.0)
        let scope_ok_4 = device |> with_gpu_rgba_texture(1u, 1u) $(texture : GpuTextureHandle) {
            verify(!SDL_ReleaseGPUCheckedSampler(device, GpuSamplerHandle(*texture)))
            verify(!SDL_GetGPUCheckedSamplerInfo(device, GpuSamplerHandle(*texture), out))
            verify(!SDL_ReleaseGPUTransferTexture(device, GpuTextureHandle(*outer)))

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_4)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_2)
    verify(SDLTest_sampler_count(device) == 0u)
    caught = false
    var invoked = false
    var bad = gpu_sampler_info()
    bad.max_lod = -1.0
    verify(*SDL_CreateGPUCheckedSampler(device, bad) == 0ul)
    let creation_error = SDL_GetError()
    { let operation_ok = device |> with_gpu_sampler(bad) $(id : GpuSamplerHandle) { invoked = true
        return sdl_ok()
    } |> is_ok
caught = !operation_ok }
    verify(caught && !invoked && SDLTest_sampler_count(device) == 0u)
    verify(SDL_GetError() == creation_error, "failed acquisition ran cleanup and replaced SDL error")
    caught = false
    {
        let scope_ok_5 = device |> with_gpu_sampler() $(outer : GpuSamplerHandle) {
            let scope_ok_6 = device |> with_gpu_sampler() $(inner : GpuSamplerHandle) { caught = !is_ok(set_title(null, "expected SDL failure")); return sdl_ok()
            } |> is_ok
            verify(scope_ok_6)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_5)
    }
    verify(caught && SDLTest_sampler_count(device) == 0u)
}
[export]
def main(smoke : bool) : int {
    verify(*SDL_CreateGPUCheckedSampler(null, gpu_sampler_info()) == 0ul)
    var available = false
    var abandoned : GpuSamplerHandle
    let scope_ok_7 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS, true, "") $(device : SDL_GPUDevice?) {
            check_descriptors(device)
            check_lifetime(device)
            abandoned = SDL_CreateGPUCheckedSampler(device, gpu_sampler_info())
            verify(*abandoned != 0ul)
            print("GPU sampler descriptor, validation, thread, scopes and two-device ownership PASS: {SDL_GetGPUDeviceDriver(device)}\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_7)
    verify(!SDLTest_sampler_exists(*abandoned))
    return available ? 0 : 77
}
