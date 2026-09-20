options gen2
require dassdl3/sdl3_gpu_sampler_boost

// Samplers are independent resources. Binding them to a general render pass
// is a later API stage; this example exercises creation and scoped ownership.

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var info = gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR,SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT)
    info.enable_anisotropy = true
    info.max_anisotropy = 4.0
    return device |> with_gpu_sampler(info) $(sampler : uint64) {
        var query_result_1 : SDL_GPUSamplerCreateInfo
        var gpu_sampler_descriptor_result <- gpu_sampler_descriptor(device,sampler,query_result_1)
        if (is_err(gpu_sampler_descriptor_result)) { return err(unwrap_err(gpu_sampler_descriptor_result),type<SdlUnit>) }
        let description = query_result_1
        print("Scoped sampler {sampler}: linear, repeat, anisotropy={description.max_anisotropy}\n")
        return device |> with_gpu_sampler() $(nearest : uint64) {
            verify(nearest != sampler)
            var query_result_2 : SDL_GPUSamplerCreateInfo
            var gpu_sampler_descriptor_result_2 <- gpu_sampler_descriptor(device,nearest,query_result_2)
            if (is_err(gpu_sampler_descriptor_result_2)) { return err(unwrap_err(gpu_sampler_descriptor_result_2),type<SdlUnit>) }
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
