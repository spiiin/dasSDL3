options gen2
require dassdl3/sdl3_gpu_volume_boost
require daslib/rtti
require daslib/strings_boost

def equal(a, b : array<uint8>) {
    verify(length(a) == length(b))
    for (i in 0 .. length(a)) { if (a[i] != b[i]) { panic("volume byte {i}: {a[i]} != {b[i]}") } }
}
def read_equal(device : SDL_GPUDevice?; volume : uint64; mip : uint; origin, size : uint3; expected : array<uint8>) {
    var actual : array<uint8>
    resize(actual,length(expected))
    let scope_ok_0 = device |> with_gpu_volume_readback(volume,mip,origin,size) $(ticket : uint64) {
        is_ok(device |> gpu_wait_readback(ticket))
        is_ok(device |> gpu_readback_bytes(ticket,actual))

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
    equal(actual,expected)
}
def check_format(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; bpp : int) {
    if (!(unwrap_or(device |> gpu_supports_format(uint(format),SDL_GPU_TEXTURETYPE_3D,SDL_GPU_TEXTUREUSAGE_SAMPLER), false))) {
        verify(SDL_CreateGPUVolume(device,uint3(5u,3u,3u),3u,uint(format)) == 0ul)
        print("Optional 3D format unsupported: {uint(format)}\n")
        return
    }
    let size = uint3(5u,3u,3u)
    let row = 5*bpp+3
    let slice = row*3+5
    var padded, packed, zero : array<uint8>
    resize(padded,slice*2+row*2+5*bpp)
    resize(packed,45*bpp); resize(zero,45*bpp)
    for (i in 0 .. length(padded)) { padded[i] = uint8(i*17+23) }
    for (z in 0 .. 3) { for (y in 0 .. 3) { for (x in 0 .. 5*bpp) {
        packed[(z*3+y)*5*bpp+x] = padded[z*slice+y*row+x]
    } } }
    let scope_ok_1 = device |> with_gpu_volume(size,3u,format) $(volume : uint64) {
        read_equal(device,volume,0u,uint3(0u),size,zero)
        var mip_bytes : array<uint8>
        resize(mip_bytes,2*bpp)
        read_equal(device,volume,1u,uint3(0u),uint3(2u,1u,1u),mip_bytes)
        is_ok(device |> gpu_upload_volume(volume,0u,uint3(0u),size,padded,uint(row),uint(slice)))
        for (i in 0 .. length(padded)) { padded[i] = uint8(0) }
        read_equal(device,volume,0u,uint3(0u),size,packed)
        verify(!SDL_UploadGPUVolume(device,volume,0u,uint3(0u),size,packed,uint(5*bpp),uint(15*bpp),true))
        verify(!SDL_UploadGPUVolume(device,volume,0u,uint3(0u),size,packed,uint(5*bpp-1),uint(15*bpp),false))
        verify(!SDL_UploadGPUVolume(device,volume,0u,uint3(0u),size,packed,uint(5*bpp),uint(15*bpp-1),false))
        verify(!SDL_UploadGPUVolume(device,volume,0u,uint3(0u),size,packed,0xffffffffu,0xffffffffu,false))
        verify(!SDL_UploadGPUVolume(device,volume,0u,uint3(0u),size,mip_bytes,uint(5*bpp),uint(15*bpp),false))
        verify(SDL_RequestGPUVolumeReadback(device,volume,3u,uint3(0u),uint3(1u)) == 0ul)
        verify(SDL_RequestGPUVolumeReadback(device,volume,1u,uint3(0u,0u,1u),uint3(1u)) == 0ul)
        verify(SDL_RequestGPUVolumeReadback(device,volume,0u,uint3(0xffffffffu,0u,0u),uint3(1u)) == 0ul)
        verify(SDL_RequestGPUVolumeReadback(device,volume,0u,uint3(0u),uint3(1u,0u,1u)) == 0ul)
        verify(SDL_RequestGPUVolumeReadback(device,volume,0u,uint3(0u),uint3(1u,1u,4u)) == 0ul)
        verify(!SDL_CopyGPUVolume(device,volume,0u,uint3(0u),uint3(1u),volume,1u,uint3(0u)))
        verify(SDL_RequestGPUTextureReadback(device,volume,uint2(0u),uint4(0u,0u,1u,1u)) == 0ul)
        if (format != SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) {
            let scope_ok_2 = device |> with_gpu_volume(uint3(1u)) $(rgba : uint64) {
                verify(!SDL_CopyGPUVolume(device,volume,0u,uint3(0u),uint3(1u),rgba,0u,uint3(0u)))

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_2)
        }
        // Partial update crosses two z slices; preserve every neighboring byte.
        var patch, patch_tight : array<uint8>
        resize(patch,4*bpp+3); resize(patch_tight,4*bpp)
        for (i in 0 .. length(patch)) { patch[i] = uint8(i*11+91) }
        for (z in 0 .. 2) { for (x in 0 .. 2*bpp) {
            packed[((z+1)*3+1)*5*bpp+bpp+x] = patch[z*(2*bpp+3)+x]
            patch_tight[z*2*bpp+x] = patch[z*(2*bpp+3)+x]
        } }
        is_ok(device |> gpu_upload_volume(volume,0u,uint3(1u,1u,1u),uint3(2u,1u,2u),patch,uint(2*bpp),uint(2*bpp+3)))
        read_equal(device,volume,0u,uint3(0u),size,packed)
        read_equal(device,volume,0u,uint3(1u,1u,1u),uint3(2u,1u,2u),patch_tight)
        let scope_ok_3 = device |> with_gpu_volume(uint3(6u,4u,4u),3u,format) $(dest : uint64) {
            is_ok(device |> gpu_copy_volume(volume,0u,uint3(1u,1u,1u),uint3(2u,1u,2u),dest,0u,uint3(3u,2u,1u)))
            var expected : array<uint8>
            resize(expected,96*bpp)
            for (z in 0 .. 2) { for (x in 0 .. 2*bpp) {
                expected[((z+1)*4+2)*6*bpp+3*bpp+x] = patch_tight[z*2*bpp+x]
            } }
            read_equal(device,dest,0u,uint3(0u),uint3(6u,4u,4u),expected)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_3)
        for (i in 0 .. length(mip_bytes)) { mip_bytes[i] = uint8(i*5+67) }
        is_ok(device |> gpu_upload_volume(volume,1u,uint3(0u),uint3(2u,1u,1u),mip_bytes,uint(2*bpp),uint(2*bpp)))
        read_equal(device,volume,1u,uint3(0u),uint3(2u,1u,1u),mip_bytes)
        let scope_ok_4 = device |> with_gpu_volume(uint3(4u,2u,2u),2u,format) $(dest : uint64) {
            is_ok(device |> gpu_copy_volume(volume,1u,uint3(0u),uint3(2u,1u,1u),dest,1u,uint3(0u)))
            read_equal(device,dest,1u,uint3(0u),uint3(2u,1u,1u),mip_bytes)
            var base_zero : array<uint8>
            resize(base_zero,16*bpp)
            read_equal(device,dest,0u,uint3(0u),uint3(4u,2u,2u),base_zero)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_4)
        resize(mip_bytes,bpp)
        is_ok(device |> gpu_upload_volume(volume,2u,uint3(0u),uint3(1u),mip_bytes,uint(bpp),uint(bpp)))
        read_equal(device,volume,2u,uint3(0u),uint3(1u),mip_bytes)
        read_equal(device,volume,0u,uint3(0u),size,packed)
        // Rejected pre-submit requests preserve validity and original contents.
        verify(!SDLTest_volume_fail_upload(device,volume,packed))
        verify(SDL_RequestGPUVolumeReadback(device,volume,0u,uint3(0u),size) == 0ul)
        verify(!SDL_UploadGPUVolume(device,volume,0u,uint3(0u),uint3(1u),mip_bytes,uint(bpp),uint(bpp),false))
        read_equal(device,volume,2u,uint3(0u),uint3(1u),mip_bytes)
        is_ok(device |> gpu_upload_volume(volume,0u,uint3(0u),size,packed,uint(5*bpp),uint(15*bpp)))
        read_equal(device,volume,0u,uint3(0u),size,packed)
        let scope_ok_5 = device |> with_gpu_volume(size,3u,format) $(dest : uint64) {
            verify(!SDLTest_volume_fail_copy(device,volume,dest))
            verify(SDL_RequestGPUVolumeReadback(device,dest,0u,uint3(0u),size) == 0ul)
            is_ok(device |> gpu_upload_volume(dest,0u,uint3(0u),size,zero,uint(5*bpp),uint(15*bpp)))
            read_equal(device,dest,0u,uint3(0u),size,zero)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_5)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_1)
}
def check_lifetime(device : SDL_GPUDevice?) {
    let format = SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM
    var data, zero, actual : array<uint8>
    resize(data,48); resize(zero,48); resize(actual,48)
    for (i in 0 .. 48) { data[i] = uint8(i+1) }
    let volume = SDL_CreateGPUVolume(device,uint3(3u,2u,2u),1u,uint(format))
    verify(volume != 0ul)
    is_ok(device |> gpu_upload_volume(volume,0u,uint3(0u),uint3(3u,2u,2u),data,12u,24u,true))
    let scope_ok_6 = device |> with_gpu_volume_readback(volume,0u,uint3(0u),uint3(3u,2u,2u)) $(ticket : uint64) {
        is_ok(device |> gpu_upload_volume(volume,0u,uint3(0u),uint3(3u,2u,2u),zero,12u,24u,true))
        verify(SDL_ReleaseGPUVolume(device,volume))
        verify(!SDL_ReleaseGPUVolume(device,ticket))
        is_ok(device |> gpu_wait_readback(ticket))
        is_ok(device |> gpu_readback_bytes(ticket,actual))
        equal(actual,data)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_6)
    verify(!SDL_ReleaseGPUVolume(device,volume))
    var stale, dead_ticket = 0ul
    var caught = false
    {
        let scope_ok_7 = device |> with_gpu_volume(uint3(3u,2u,2u)) $(owned : uint64) {
            stale = owned
            let scope_ok_8 = device |> with_gpu_volume_readback(owned,0u,uint3(0u),uint3(3u,2u,2u)) $(ticket : uint64) {
                dead_ticket = ticket
                caught = !is_ok(set_title(null,"expected SDL failure")); return sdl_ok()
            } |> is_ok
            verify(scope_ok_8)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_7)
    }
    verify(caught && !SDLTest_volume_exists(stale))
    verify(SDL_PollGPUReadback(device,dead_ticket) == -1)
    let scope_ok_9 = device |> with_gpu_volume(uint3(1u)) $(owned : uint64) { stale = owned; return sdl_ok()
    } |> is_ok
    verify(scope_ok_9)
    verify(!SDLTest_volume_exists(stale))
    let scope_ok_10 = device |> with_gpu_volume(uint3(3u,2u,2u)) $(owned : uint64) {
        for (i in 0 .. 32) {
            let scope_ok_11 = device |> with_gpu_volume_readback(owned,0u,uint3(0u),uint3(3u,2u,2u)) $(ticket : uint64) { dead_ticket = ticket; return sdl_ok()
            } |> is_ok
            verify(scope_ok_11)
            verify(SDL_PollGPUReadback(device,dead_ticket) == -1)
        }
        var other_id = 0ul
        let second = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(other : SDL_GPUDevice?) {
            verify(!SDL_ReleaseGPUVolume(other,owned))
            verify(SDL_RequestGPUVolumeReadback(other,owned,0u,uint3(0u),uint3(1u)) == 0ul)
            other_id = SDL_CreateGPUVolume(other,uint3(2u),1u,uint(format))
            verify(other_id != 0ul)
            verify(!SDL_CopyGPUVolume(device,owned,0u,uint3(0u),uint3(1u),other_id,0u,uint3(0u)))
            verify(SDL_RequestGPUVolumeReadback(other,other_id,0u,uint3(0u),uint3(2u)) != 0ul)
            // Device cleanup owns the deliberately unclosed volume and ticket.

            return sdl_ok()
        } |> is_ok
        verify(second && !SDLTest_volume_exists(other_id))
        read_equal(device,owned,0u,uint3(0u),uint3(3u,2u,2u),zero)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_10)
    let scope_ok_12 = device |> with_gpu_rgba_texture(1u,1u) $(texture : uint64) {
        verify(SDL_RequestGPUVolumeReadback(device,texture,0u,uint3(0u),uint3(1u)) == 0ul)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_12)
    verify(SDLTest_volume_count(device) == 0u)
}
[export]
def main(smoke : bool) : int {
    var available = false
    verify(SDL_CreateGPUVolume(null,uint3(1u),1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) == 0ul)
    let scope_ok_13 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            let rgba = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM
            verify(SDL_CreateGPUVolume(device,uint3(0u,1u,1u),1u,rgba) == 0ul)
            verify(SDL_CreateGPUVolume(device,uint3(1u,1u,0xffffffffu),1u,rgba) == 0ul)
            verify(SDL_CreateGPUVolume(device,uint3(2048u),1u,rgba) == 0ul)
            verify(SDL_CreateGPUVolume(device,uint3(256u),2u,rgba) == 0ul) // Full mip sum over 64 MiB.
            verify(SDL_CreateGPUVolume(device,uint3(1u),2u,rgba) == 0ul)
            verify(SDL_CreateGPUVolume(device,uint3(1u),0u,rgba) == 0ul)
            verify(SDL_CreateGPUVolume(device,uint3(1u),1u,0xffffffffu) == 0ul)
            verify(SDL_CreateGPUVolume(device,uint3(4u),1u,SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM) == 0ul)
            verify(SDL_CreateGPUVolume(device,uint3(4u),1u,SDL_GPU_TEXTUREFORMAT_D32_FLOAT) == 0ul)
            check_format(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,4)
            check_format(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8_UNORM,1)
            check_format(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_UNORM,2)
            check_format(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT,8)
            check_format(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32B32A32_FLOAT,16)
            // Depth alone determines mip count here; mip 1 still has two slices.
            let scope_ok_14 = device |> with_gpu_volume(uint3(1u,1u,5u),3u,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(deep : uint64) {
                var zero, pair : array<uint8>
                resize(zero,20); resize(pair,8)
                read_equal(device,deep,0u,uint3(0u),uint3(1u,1u,5u),zero)
                read_equal(device,deep,1u,uint3(0u),uint3(1u,1u,2u),pair)
                for (i in 0 .. 8) { pair[i] = uint8(i+39) }
                is_ok(device |> gpu_upload_volume(deep,1u,uint3(0u),uint3(1u,1u,2u),pair,4u,4u))
                read_equal(device,deep,1u,uint3(0u),uint3(1u,1u,2u),pair)
                read_equal(device,deep,0u,uint3(0u),uint3(1u,1u,5u),zero)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_14)
            check_lifetime(device)
            print("GPU 3D pitch, regions, mips, copies, snapshots, failures and ownership PASS: {SDL_GetGPUDeviceDriver(device)}\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_13)
    return available ? 0 : 77
}
