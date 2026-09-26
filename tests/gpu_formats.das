options gen2
require dassdl3/sdl3_gpu_formats_boost

def check_format(device : SDL_GPUDevice?; format, bpp : uint; optional : bool = false) {
    verify(unwrap_or(gpu_format_block_bytes(format), 0u) == bpp)
    verify(unwrap_or(gpu_format_bytes(format, 5u, 3u, 2u), 0u) == 30u * bpp)
    if (!(unwrap_or(device |> gpu_supports_format(format, SDL_GPU_TEXTURETYPE_2D_ARRAY, SDL_GPU_TEXTUREUSAGE_SAMPLER), false))) {
        verify(optional)
        verify(*SDL_CreateGPUColorTransferTexture(device, 5u, 3u, 2u, 2u, format) == 0ul)
        print("Optional sampler format {format} unsupported by SDL backend; creation rejected\n")
        return
    }
    let row = int(5u * bpp)
    let pitch = row + 3
    var source, tight, actual, expected : array<uint8>
    resize(source, 2 * pitch + row); resize(tight, 3 * row); resize(actual, 3 * row); resize(expected, 3 * row)
    for (i in 0 .. 3 * row) {
        let y = i / row
        let x = i % row
        var value = uint8((y * 71 + x * 17 + 9) % 256)
        if (format == SDL_GPU_TEXTUREFORMAT_R32_FLOAT || format == SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT) {
            value = (x % 4 == 3) ? uint8(63 + (x / 4 + y) % 2) : ((x % 4 == 2) ? uint8(128) : uint8(0))
        }
        if (format == SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT) {
            value = (x % 2 == 0) ? uint8(0) : uint8(60 + 4 * ((x / 2 + y) % 2))
        }
        source[y * pitch + x] = value
        tight[i] = value
        expected[i] = uint8(0)
    }
    let scope_ok_0 = device |> with_gpu_color_texture(5u, 3u, 2u, 2u, format) $(a : GpuTextureHandle) {
        is_ok(device |> gpu_upload_texture(a, uint2(0u, 1u), uint4(0u, 0u, 5u, 3u), source, uint(pitch)))
        clear(source)
        let scope_ok_1 = device |> with_gpu_texture_readback(a, uint2(0u, 1u), uint4(0u, 0u, 5u, 3u)) $(ticket : GpuReadbackHandle) {
            is_ok(device |> gpu_wait_readback(ticket))
            is_ok(device |> gpu_readback_bytes(ticket, actual))
            for (i in 0 .. length(tight)) { verify(actual[i] == tight[i]) }

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_1)
        let scope_ok_2 = device |> with_gpu_color_texture(5u, 3u, 2u, 2u, format) $(b : GpuTextureHandle) {
            is_ok(device |> gpu_copy_texture(a, uint2(0u, 1u), uint4(1u, 1u, 3u, 2u), b, uint2(0u, 0u), uint2(0u)))
            for (i in 0 .. int(6u * bpp)) {
                let y = i / int(3u * bpp)
                let x = i % int(3u * bpp)
                expected[y * row + x] = tight[(y + 1) * row + int(bpp) + x]
            }
            let scope_ok_3 = device |> with_gpu_texture_readback(b, uint2(0u), uint4(0u, 0u, 5u, 3u)) $(ticket : GpuReadbackHandle) {
                is_ok(device |> gpu_wait_readback(ticket))
                is_ok(device |> gpu_readback_bytes(ticket, actual))
                for (i in 0 .. length(expected)) { verify(actual[i] == expected[i]) }

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_3)
            // Separate mip stays zero, with format-dependent tight size.
            resize(actual, int(2u * bpp))
            let scope_ok_4 = device |> with_gpu_texture_readback(b, uint2(1u, 1u), uint4(0u, 0u, 2u, 1u)) $(ticket : GpuReadbackHandle) {
                is_ok(device |> gpu_wait_readback(ticket))
                is_ok(device |> gpu_readback_bytes(ticket, actual))
                for (v in actual) { verify(v == uint8(0)) }

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_4)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_2)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
}
[export]
def main(smoke : bool) : int {
    verify(!unwrap_or(gpu_supports_texture_transfer(null, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTURETYPE_2D), false))
    verify(SDL_GetError() != "")
    verify(SDL_GPUFormatBlockSizeChecked(0u) == 0u)
    verify(SDL_GPUFormatBlockSizeChecked(0xffffffffu) == 0u)
    verify(SDL_GPUFormatSizeChecked(SDL_GPU_TEXTUREFORMAT_R8_UNORM, 0u, 1u, 1u) == 0u)
    verify(SDL_GPUFormatSizeChecked(SDL_GPU_TEXTUREFORMAT_R8_UNORM, 0xffffffffu, 1u, 1u) == 0u)
    verify(SDL_GPUFormatSizeChecked(SDL_GPU_TEXTUREFORMAT_R32G32B32A32_UINT, 8192u, 8192u, 5u) == 0u)
    verify(unwrap_or(gpu_format_bytes(SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM, 7u, 5u, 2u), 0u) == 64u)
    verify(unwrap_or(gpu_format_bytes(SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM, 7u, 5u), 0u) == 64u)
    verify(unwrap_or(gpu_format_bytes(SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM, 11u, 9u), 0u) == 144u)
    verify(unwrap_or(gpu_format_bytes(SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT, 13u, 13u), 0u) == 64u)
    verify(unwrap_or(gpu_format_bytes(SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT, 3u, 2u), 0u) == 30u)
    for (f in 1u .. SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT + 1u) {
        verify(unwrap_or(gpu_format_block_bytes(f), 0u) > 0u)
        verify(unwrap_or(gpu_format_bytes(f, 1u, 1u), 0u) == unwrap_or(gpu_format_block_bytes(f), 0u))
    }
    var available = false
    let scope_ok_5 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS, true, "") $(device : SDL_GPUDevice?) {
            verify(SDL_GPUFormatSupportedChecked(device, 0u, 0u, 1u) == -1)
            verify(SDL_GPUFormatSupportedChecked(device, SDL_GPU_TEXTUREFORMAT_R8_UNORM, 999u, 1u) == -1)
            verify(SDL_GPUFormatSupportedChecked(device, SDL_GPU_TEXTUREFORMAT_R8_UNORM, 0u, 0x80000000u) == -1)
            verify(SDL_GPUSampleCountSupportedChecked(device, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM, 999u) == -1)
            verify(unwrap_or(device |> gpu_supports_samples(SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_SAMPLECOUNT_1), false))
            let supports4 = unwrap_or(device |> gpu_supports_samples(SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_SAMPLECOUNT_4), false)
            verify(*SDL_CreateGPUColorTransferTexture(device, 4u, 4u, 1u, 1u, SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM) == 0ul)
            verify(*SDL_CreateGPUColorTransferTexture(device, 4u, 4u, 1u, 1u, SDL_GPU_TEXTUREFORMAT_D16_UNORM) == 0ul)
            check_format(device, SDL_GPU_TEXTUREFORMAT_R8_UNORM, 1u)
            check_format(device, SDL_GPU_TEXTUREFORMAT_R8G8_UNORM, 2u)
            check_format(device, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM, 4u)
            check_format(device, SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM, 4u)
            check_format(device, SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UNORM, 8u, true)
            check_format(device, SDL_GPU_TEXTUREFORMAT_R32G32B32A32_UINT, 16u, true)
            check_format(device, SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT, 16u)
            check_format(device, SDL_GPU_TEXTUREFORMAT_R32_FLOAT, 4u)
            check_format(device, SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT, 8u)
            let scope_ok_6 = device |> with_gpu_color_texture(2u, 2u, 1u, 1u, SDL_GPU_TEXTUREFORMAT_R8_UNORM) $(a : GpuTextureHandle) {
                let scope_ok_7 = device |> with_gpu_rgba_texture(2u, 2u) $(b : GpuTextureHandle) {
                    verify(!SDL_CopyGPUTextureRegion(device, a, uint2(0u), uint4(0u, 0u, 2u, 2u), b, uint2(0u), uint2(0u)))

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_7)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_6)
            print("Format queries and seven required + two optional color formats PASS: {SDL_GetGPUDeviceDriver(device)}, RGBA8 MSAA4 supported: {supports4}\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_5)
    return available ? 0 : 77
}
