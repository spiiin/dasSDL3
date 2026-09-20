options gen2
require dassdl3/sdl3_gpu_formats_boost

def read_equal(device : SDL_GPUDevice?; texture : uint64; sub : uint2; region : uint4; expected : array<uint8>) {
    var actual : array<uint8>
    resize(actual,length(expected))
    let scope_ok_0 = device |> with_gpu_texture_readback(texture,sub,region) $(ticket) {
        device |> gpu_wait_readback(ticket)
        device |> gpu_readback_bytes(ticket,actual)
    }
    verify(scope_ok_0)
    for (i in 0 .. length(actual)) { verify(actual[i] == expected[i]) }
}
def roundtrip(device : SDL_GPUDevice?; format : uint) {
    let extent = gpu_format_block_extent(format)
    let width = extent.x*3u
    let height = extent.y*3u
    var n = (width > height ? width : height)
    var levels = 1u
    while (n > 1u) { n /= 2u; levels++ }
    var padded, packed, zero, one : array<uint8>
    resize(padded,154); resize(packed,144); resize(zero,144); resize(one,16)
    for (i in 0 .. length(padded)) { padded[i] = uint8(i*17+9) }
    for (y in 0 .. 3) { for (x in 0 .. 48) { packed[y*48+x] = padded[y*53+x] } }
    for (i in 0 .. 16) { one[i] = uint8(i*7+19) }
    var stale = 0ul
    let scope_ok_1 = device |> with_gpu_transfer_texture(width,height,2u,levels,format,SDL_GPU_TEXTURETYPE_2D_ARRAY) $(a) {
        stale = a
        let scope_ok_2 = device |> with_gpu_transfer_texture(width,height,2u,levels,format,SDL_GPU_TEXTURETYPE_2D_ARRAY) $(b) {
            read_equal(device,a,uint2(0u,1u),uint4(0u,0u,width,height),zero)
            device |> gpu_upload_texture(a,uint2(0u,1u),uint4(0u,0u,width,height),padded,53u)
            for (i in 0 .. length(padded)) { padded[i] = uint8(0) }
            read_equal(device,a,uint2(0u,1u),uint4(0u,0u,width,height),packed)
            read_equal(device,a,uint2(0u),uint4(0u,0u,width,height),zero)
            verify(!SDL_UploadGPUTextureRegion(device,a,uint2(0u),uint4(1u,0u,extent.x,extent.y),one,16u,false))
            verify(!SDL_UploadGPUTextureRegion(device,a,uint2(0u),uint4(0u,1u,extent.x,extent.y),one,16u,false))
            verify(!SDL_UploadGPUTextureRegion(device,a,uint2(0u),uint4(0u,0u,extent.x,extent.y),one,15u,false))
            device |> gpu_copy_texture(a,uint2(0u,1u),uint4(extent.x,extent.y,extent.x,extent.y),b,uint2(0u),uint2(extent.x*2u,0u))
            var copied : array<uint8>
            resize(copied,144)
            for (i in 0 .. 16) { copied[32+i] = packed[64+i] }
            read_equal(device,b,uint2(0u),uint4(0u,0u,width,height),copied)
            // The second mip has a partial bottom-right block, including nonsquare formats.
            let edge = uint4(extent.x,extent.y,width/2u-extent.x,height/2u-extent.y)
            device |> gpu_upload_texture(a,uint2(1u,1u),edge,one,16u)
            read_equal(device,a,uint2(1u,1u),edge,one)
            device |> gpu_copy_texture(a,uint2(1u,1u),edge,b,uint2(1u),uint2(extent.x,extent.y))
            read_equal(device,b,uint2(1u),edge,one)
            var edge_full : array<uint8>
            resize(edge_full,64)
            for (i in 0 .. 16) { edge_full[48+i] = one[i] }
            read_equal(device,b,uint2(1u),uint4(0u,0u,width/2u,height/2u),edge_full)
            device |> gpu_upload_texture(a,uint2(levels-1u,1u),uint4(0u,0u,1u,1u),one,16u)
            read_equal(device,a,uint2(levels-1u,1u),uint4(0u,0u,1u,1u),one)
        }
        verify(scope_ok_2)
    }
    verify(scope_ok_1)
    verify(!SDL_ReleaseGPUTransferTexture(device,stale))
}
[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_3 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            var raw_count, usable_count = 0
            for (format in SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM .. SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT+1u) {
                let extent = gpu_format_block_extent(format)
                if (device |> gpu_supports_format(format,SDL_GPU_TEXTURETYPE_2D_ARRAY,SDL_GPU_TEXTUREUSAGE_SAMPLER)) { raw_count++ }
                if (device |> gpu_supports_texture_transfer(format,SDL_GPU_TEXTURETYPE_2D_ARRAY)) {
                    roundtrip(device,format)
                    usable_count++
                } else {
                    verify(SDL_CreateGPUTypedTransferTexture(device,extent.x*3u,extent.y*3u,2u,3u,format,SDL_GPU_TEXTURETYPE_2D_ARRAY) == 0ul)
                }
            }
            verify(SDL_GPUTextureTransferSupportedChecked(device,0xffffffffu,SDL_GPU_TEXTURETYPE_2D) == -1)
            verify(SDL_GPUTextureTransferSupportedChecked(device,SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM,0xffffffffu) == -1)
            verify(!(device |> gpu_supports_texture_transfer(SDL_GPU_TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTURETYPE_2D)))
            verify(!(device |> gpu_supports_texture_transfer(SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM,SDL_GPU_TEXTURETYPE_3D)))
            if (SDL_GetGPUDeviceDriver(device) == "vulkan") {
                verify(!(device |> gpu_supports_texture_transfer(SDL_GPU_TEXTUREFORMAT_ASTC_12x10_FLOAT,SDL_GPU_TEXTURETYPE_2D)))
            }
            print("ASTC {SDL_GetGPUDeviceDriver(device)}: raw SDL reports {raw_count}/42, completed transfer roundtrips {usable_count}/42\n")
            if (usable_count == 0) { print("ASTC GPU roundtrip UNAVAILABLE; capability/rejection checks passed\n") }
        }
    }
    verify(scope_ok_3)
    return available ? 0 : 77
}
