options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_gpu_utilities_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var face, result : array<uint8>
    resize(face,64); resize(result,64)
    device |> with_gpu_transfer_texture(4u,4u,6u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTURETYPE_CUBE) $(cube : uint64) {
        for (layer in 0u .. 6u) {
            for (i in 0 .. 64) { face[i] = uint8(int(layer)*31+i) }
            device |> gpu_upload_texture(cube,uint2(0u,layer),uint4(0u,0u,4u,4u),face,16u) |> sdl_try
        }
        for (layer in 0u .. 6u) {
            device |> with_gpu_texture_readback(cube,uint2(0u,layer),uint4(0u,0u,4u,4u)) $(ticket : uint64) {
                device |> gpu_wait_readback(ticket) |> sdl_try
                device |> gpu_readback_bytes(ticket,result) |> sdl_try
                for (i in 0 .. 64) { verify(result[i] == uint8(int(layer)*31+i)) }

                return sdl_ok()
            } |> sdl_try
        }

        return sdl_ok()
    } |> sdl_try
    print("Six independent cubemap faces verified\n")

    return sdl_ok()
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
