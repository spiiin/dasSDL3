options gen2
require dassdl3/sdl3_gpu_sampler_boost

// Samplers are independent resources. Binding them to a general render pass
// is a later API stage; this example exercises creation and scoped ownership.
var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            var info = gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR,SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT)
            info.enable_anisotropy = true
            info.max_anisotropy = 4.0
            let scope_ok_1 = device |> with_gpu_sampler(info) $(sampler) {
                var query_result_1 : SDL_GPUSamplerCreateInfo
                if (!gpu_sampler_descriptor(device,sampler,query_result_1)) { example_failed = true; print("SDL query: {SDL_GetError()}\n"); return }
                let description = query_result_1
                print("Scoped sampler {sampler}: linear, repeat, anisotropy={description.max_anisotropy}\n")
                let scope_ok_2 = device |> with_gpu_sampler() $(nearest) {
                    verify(nearest != sampler)
                    var query_result_2 : SDL_GPUSamplerCreateInfo
                    if (!gpu_sampler_descriptor(device,nearest,query_result_2)) { example_failed = true; print("SDL query: {SDL_GetError()}\n"); return }
                    verify(query_result_2.min_filter == SDL_GPUFilter.FILTER_NEAREST)
                    print("Independent nearest/clamp sampler {nearest}\n")
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
