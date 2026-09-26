options gen2
require dassdl3/sdl3_gpu_texture_transfer_boost
require daslib/rtti
require daslib/strings_boost

def check(ok : bool) { if (!ok) { panic("GPU texture transfer test: {SDL_GetError()}") } }
def equal(a, b : array<uint8>) {
    verify(length(a) == length(b))
    for (i in 0 .. length(a)) { verify(a[i] == b[i]) }
}
def pixels(device : SDL_GPUDevice?; texture : GpuTextureHandle; sub : uint2; width, height : uint; expected : array<uint8>) {
    var actual : array<uint8>
    resize(actual, int(width * height * 4u))
    let scope_ok_0 = device |> with_gpu_texture_readback(texture, sub, uint4(0u, 0u, width, height)) $(ticket : GpuReadbackHandle) {
        is_ok(device |> gpu_wait_readback(ticket))
        is_ok(device |> gpu_readback_bytes(ticket, actual))
        equal(actual, expected)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
}
def zeros(device : SDL_GPUDevice?; texture : GpuTextureHandle; sub : uint2; width, height : uint) {
    var expected : array<uint8>
    resize(expected, int(width * height * 4u))
    for (i in 0 .. length(expected)) { expected[i] = uint8(0) }
    pixels(device, texture, sub, width, height, expected)
}
[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_1 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS, true, "") $(device : SDL_GPUDevice?) {
            verify(*SDL_CreateGPUTransferTexture(device, 0u, 1u, 1u, 1u) == 0ul)
            verify(*SDL_CreateGPUTransferTexture(device, 8193u, 1u, 1u, 1u) == 0ul)
            verify(*SDL_CreateGPUTransferTexture(device, 1u, 1u, 0u, 1u) == 0ul)
            verify(*SDL_CreateGPUTransferTexture(device, 1u, 1u, 257u, 1u) == 0ul)
            verify(*SDL_CreateGPUTransferTexture(device, 7u, 5u, 1u, 4u) == 0ul)
            verify(*SDL_CreateGPUTransferTexture(device, 8192u, 8192u, 1u, 1u) == 0ul)
            verify(*SDL_CreateGPUTransferTexture(device, 1024u, 1024u, 17u, 1u) == 0ul)
            var packed, padded : array<uint8>
            resize(packed, 140)
            resize(padded, 152)// odd byte pitch, minimal final row.
            for (pixel_byte in 0 .. 140) { let y = pixel_byte / 28; let x = pixel_byte % 28;
                packed[y * 28 + x] = uint8((y * 47 + x * 7 + 5) % 256)
                padded[y * 31 + x] = packed[y * 28 + x]
            }
            var stale : GpuTextureHandle
            let scope_ok_2 = device |> with_gpu_rgba_texture(7u, 5u, 2u, 3u) $(source : GpuTextureHandle) {
                stale = source
                for (layer in 0u .. 2u) {
                    zeros(device, source, uint2(0u, layer), 7u, 5u)
                    zeros(device, source, uint2(1u, layer), 3u, 2u)
                    zeros(device, source, uint2(2u, layer), 1u, 1u)
                }
                verify(!SDL_UploadGPUTextureRegion(device, source, uint2(0u), uint4(0u, 0u, 7u, 5u), padded, 27u, false))
                verify(!SDL_UploadGPUTextureRegion(device, source, uint2(0u), uint4(0u, 0u, 7u, 5u), padded, 32u, false))
                verify(!SDL_UploadGPUTextureRegion(device, source, uint2(0u), uint4(0u, 0u, 7u, 5u), padded, 31u, true))
                verify(*SDL_RequestGPUTextureReadback(device, source, uint2(3u, 0u), uint4(0u, 0u, 1u, 1u)) == 0ul)
                verify(*SDL_RequestGPUTextureReadback(device, source, uint2(0u, 2u), uint4(0u, 0u, 1u, 1u)) == 0ul)
                verify(*SDL_RequestGPUTextureReadback(device, source, uint2(0u), uint4(0xffffffffu, 0u, 1u, 1u)) == 0ul)
                verify(*SDL_RequestGPUTextureReadback(device, source, uint2(0u), uint4(6u, 4u, 2u, 2u)) == 0ul)
                verify(*SDL_RequestGPUTextureReadback(device, source, uint2(0u), uint4(0u)) == 0ul)
                verify(!SDL_CopyGPUTextureRegion(device, source, uint2(0u), uint4(0u, 0u, 1u, 1u), source, uint2(0u), uint2(1u)))
                is_ok(device |> gpu_upload_texture(source, uint2(0u), uint4(0u, 0u, 7u, 5u), padded, 31u))
                clear(padded) // The upload must own a copy already.
                pixels(device, source, uint2(0u), 7u, 5u, packed)
                zeros(device, source, uint2(0u, 1u), 7u, 5u)
                zeros(device, source, uint2(1u, 0u), 3u, 2u)
                var tiny : array<uint8>
                resize(tiny, 4)
                tiny[0] = uint8(19); tiny[1] = uint8(28); tiny[2] = uint8(73); tiny[3] = uint8(11)
                is_ok(device |> gpu_upload_texture(source, uint2(2u, 1u), uint4(0u, 0u, 1u, 1u), tiny, 4u))
                pixels(device, source, uint2(2u, 1u), 1u, 1u, tiny)
                // Partial upload must preserve every other pixel, mip and layer.
                is_ok(device |> gpu_upload_texture(source, uint2(0u), uint4(4u, 3u, 1u, 1u), tiny, 4u))
                for (c in 0 .. 4) { packed[100 + c] = tiny[c] }
                pixels(device, source, uint2(0u), 7u, 5u, packed)
                pixels(device, source, uint2(2u, 1u), 1u, 1u, tiny)
                zeros(device, source, uint2(0u, 1u), 7u, 5u)
                let scope_ok_3 = device |> with_gpu_rgba_texture(8u, 6u, 2u, 3u) $(destination : GpuTextureHandle) {
                    verify(!SDL_CopyGPUTextureRegion(device, source, uint2(0u), uint4(2u, 1u, 3u, 2u), destination, uint2(1u, 1u), uint2(3u, 1u)))
                    is_ok(device |> gpu_copy_texture(source, uint2(0u), uint4(2u, 1u, 3u, 2u), destination, uint2(1u, 1u), uint2(1u, 1u)))
                    var expected : array<uint8>
                    resize(expected, 48)
                    for (i in 0 .. 48) { expected[i] = uint8(0) }
                    for (pixel_byte in 0 .. 24) { let y = pixel_byte / 12; let x = pixel_byte % 12; expected[(y + 1) * 16 + 4 + x] = packed[(y + 1) * 28 + 8 + x] }
                    pixels(device, destination, uint2(1u, 1u), 4u, 3u, expected)
                    zeros(device, destination, uint2(0u, 1u), 8u, 6u)
                    zeros(device, destination, uint2(1u, 0u), 4u, 3u)
                    let other_available = with_gpu_device(GPU_SHADER_FORMATS, true, "") $(other : SDL_GPUDevice?) {
                        verify(!SDL_ReleaseGPUTransferTexture(other, source))
                        verify(*SDL_RequestGPUTextureReadback(other, source, uint2(0u), uint4(0u, 0u, 1u, 1u)) == 0ul)
                        let own = SDL_CreateGPUTransferTexture(other, 3u, 2u, 2u, 2u)
                        verify(*own != 0ul)
                        verify(!SDL_CopyGPUTextureRegion(device, source, uint2(0u), uint4(0u, 0u, 1u, 1u), own, uint2(0u), uint2(0u)))
                        verify(*SDL_RequestGPUTextureReadback(other, own, uint2(0u), uint4(0u, 0u, 3u, 2u)) != 0ul)
                        // Deliberately leave texture/ticket for device-specific cleanup.

                        return sdl_ok()
                    } |> is_ok
                    verify(other_available)
                    pixels(device, destination, uint2(1u, 1u), 4u, 3u, expected)

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_3)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_2)
            verify(!SDL_ReleaseGPUTransferTexture(device, stale))
            // Queued snapshot, cycling and release of source before reading.
            let texture = SDL_CreateGPUTransferTexture(device, 7u, 5u, 1u, 1u)
            verify(*texture != 0ul)
            is_ok(device |> gpu_upload_texture(texture, uint2(0u), uint4(0u, 0u, 7u, 5u), packed, 28u, true))
            var dead_ticket : GpuReadbackHandle
            let scope_ok_4 = device |> with_gpu_texture_readback(texture, uint2(0u), uint4(0u, 0u, 7u, 5u)) $(ticket : GpuReadbackHandle) {
                dead_ticket = ticket
                var zero, actual : array<uint8>
                resize(zero, 140); resize(actual, 140)
                for (i in 0 .. 140) { zero[i] = uint8(0) }
                verify(!SDL_ReleaseGPUTransferTexture(device, GpuTextureHandle(*ticket)))
                verify(*SDL_RequestGPUBufferReadback(device, GpuBufferHandle(*texture), 0u, 4u) == 0ul)
                is_ok(device |> gpu_upload_texture(texture, uint2(0u), uint4(0u, 0u, 7u, 5u), zero, 28u, true))
                check(SDL_ReleaseGPUTransferTexture(device, texture))
                is_ok(device |> gpu_wait_readback(ticket))
                verify(!SDL_ReadGPUReadback(device, ticket, padded))
                is_ok(device |> gpu_readback_bytes(ticket, actual))
                equal(actual, packed)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_4)
            verify(SDL_PollGPUReadback(device, dead_ticket) == -1)
            var caught = false
            {
                let scope_ok_5 = device |> with_gpu_rgba_texture(1u, 1u) $(owned : GpuTextureHandle) {
                    stale = owned
                    let scope_ok_6 = device |> with_gpu_texture_readback(owned, uint2(0u), uint4(0u, 0u, 1u, 1u)) $(ticket : GpuReadbackHandle) {
                        dead_ticket = ticket
                        caught = !is_ok(set_title(null, "expected SDL failure")); return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_6)

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_5)
            }
            verify(caught && !SDL_ReleaseGPUTransferTexture(device, stale))
            verify(SDL_PollGPUReadback(device, dead_ticket) == -1)
            let scope_ok_7 = device |> with_gpu_rgba_texture(1u, 1u) $(owned : GpuTextureHandle) { stale = owned; return sdl_ok()
            } |> is_ok
            verify(scope_ok_7)
            verify(!SDL_ReleaseGPUTransferTexture(device, stale))
            let scope_ok_8 = device |> with_gpu_rgba_texture(3u, 2u) $(owned : GpuTextureHandle) {
                for (i in 0 .. 64) {
                    let scope_ok_9 = device |> with_gpu_texture_readback(owned, uint2(0u), uint4(0u, 0u, 3u, 2u)) $(ticket : GpuReadbackHandle) { dead_ticket = ticket; return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_9)
                    verify(SDL_PollGPUReadback(device, dead_ticket) == -1)
                }
                zeros(device, owned, uint2(0u), 3u, 2u)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_8)
            print("GPU texture mip/layer, pitch, copy, snapshots, bounds and scopes PASS: {SDL_GetGPUDeviceDriver(device)}\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_1)
    return available ? 0 : 77
}
