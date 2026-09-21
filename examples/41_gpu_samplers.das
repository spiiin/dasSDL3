options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_sampler_boost

// Samplers are independent resources. Binding them to a general render pass
// is a later API stage; this example exercises creation and scoped ownership.

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var info = gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR,SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT)
    info.enable_anisotropy = true
    info.max_anisotropy = 4.0
    return sdl_scope() {
        let sampler : GpuSamplerHandle = device |> with_gpu_sampler(info) |> sdl_use
        let description = gpu_sampler_descriptor(device,sampler) |> sdl_try
        print("Scoped sampler {sampler}: linear, repeat, anisotropy={description.max_anisotropy}\n")
        let nearest : GpuSamplerHandle = device |> with_gpu_sampler() |> sdl_use
        verify(nearest != sampler)
        var query_result_2 : SDL_GPUSamplerCreateInfo
        gpu_sampler_descriptor(device,nearest,query_result_2) |> sdl_try
        verify(query_result_2.min_filter == SDL_GPUFilter.FILTER_NEAREST)
        print("Independent nearest/clamp sampler {nearest}\n")

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
