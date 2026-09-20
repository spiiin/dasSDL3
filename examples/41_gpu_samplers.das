options gen2
require dassdl3/sdl3_gpu_sampler_boost

// Samplers are independent resources. Binding them to a general render pass
// is a later API stage; this example exercises creation and scoped ownership.
var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            var info = gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR,SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT)
            info.enable_anisotropy = true
            info.max_anisotropy = 4.0
            let scope_ok_1 = device |> with_gpu_sampler(info) $(sampler : uint64) {
                var query_result_1 : SDL_GPUSamplerCreateInfo
                var operation_result_1 <- gpu_sampler_descriptor(device,sampler,query_result_1)
                if (is_err(operation_result_1)) { example_failed = true; print("SDL query: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                let description = query_result_1
                print("Scoped sampler {sampler}: linear, repeat, anisotropy={description.max_anisotropy}\n")
                let scope_ok_2 = device |> with_gpu_sampler() $(nearest : uint64) {
                    verify(nearest != sampler)
                    var query_result_2 : SDL_GPUSamplerCreateInfo
                    var operation_result_2 <- gpu_sampler_descriptor(device,nearest,query_result_2)
                    if (is_err(operation_result_2)) { example_failed = true; print("SDL query: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                    verify(query_result_2.min_filter == SDL_GPUFilter.FILTER_NEAREST)
                    print("Independent nearest/clamp sampler {nearest}\n")

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
