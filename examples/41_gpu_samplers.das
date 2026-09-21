options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_gpu_sampler_boost

// Samplers are independent resources. Binding them to a general render pass
// is a later API stage; this example exercises creation and scoped ownership.

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var info = gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR,SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT)
    info.enable_anisotropy = true
    info.max_anisotropy = 4.0
    return device |> with_gpu_sampler(info) $(sampler : GpuSamplerHandle) {
        let description = gpu_sampler_descriptor(device,sampler) |> sdl_try
        print("Scoped sampler {sampler}: linear, repeat, anisotropy={description.max_anisotropy}\n")
        return device |> with_gpu_sampler() $(nearest : GpuSamplerHandle) {
            verify(nearest != sampler)
            var query_result_2 : SDL_GPUSamplerCreateInfo
            gpu_sampler_descriptor(device,nearest,query_result_2) |> sdl_try
            verify(query_result_2.min_filter == SDL_GPUFilter.FILTER_NEAREST)
            print("Independent nearest/clamp sampler {nearest}\n")

            return sdl_ok()
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
