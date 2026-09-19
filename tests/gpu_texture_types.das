options gen2
require dassdl3/sdl3_gpu_utilities_boost

def read_equal(device : SDL_GPUDevice?; id : uint64; sub : uint2; rect : uint4; expected : array<uint8>) {
    var actual : array<uint8>
    resize(actual,length(expected))
    device |> with_gpu_texture_readback(id,sub,rect) $(ticket) {
        device |> gpu_wait_readback(ticket)
        device |> gpu_readback_bytes(ticket,actual)
    }
    for (i in 0 .. length(actual)) { verify(actual[i] == expected[i]) }
}
def check_bc(device : SDL_GPUDevice?; format : uint) {
    if (!(device |> gpu_supports_format(format,SDL_GPU_TEXTURETYPE_2D_ARRAY,SDL_GPU_TEXTUREUSAGE_SAMPLER))) {
        verify(SDL_CreateGPUTypedTransferTexture(device,12u,8u,2u,4u,format,SDL_GPU_TEXTURETYPE_2D_ARRAY) == 0ul)
        print("BC optional format {format} unsupported\n")
        return
    }
    print("BC test format {format}\n")
    let block_bytes = gpu_format_block_bytes(format)
    let row = 3u*block_bytes
    let pitch = row+3u
    var source, tight, zero, one : array<uint8>
    resize(source,int(pitch+row)); resize(tight,int(row*2u)); resize(zero,int(row*2u)); resize(one,int(block_bytes))
    for (i in 0 .. length(source)) { source[i] = uint8((i*17+31)%256) }
    for (y in 0 .. 2) { for (x in 0 .. int(row)) { tight[y*int(row)+x] = source[y*int(pitch)+x] } }
    for (i in 0 .. length(one)) { one[i] = uint8(i*3+7) }
    var stale = 0ul
    device |> with_gpu_transfer_texture(12u,8u,2u,4u,format,SDL_GPU_TEXTURETYPE_2D_ARRAY) $(a) {
        stale = a
        device |> with_gpu_transfer_texture(12u,8u,2u,4u,format,SDL_GPU_TEXTURETYPE_2D_ARRAY) $(b) {
            read_equal(device,a,uint2(0u),uint4(0u,0u,12u,8u),zero)
            device |> gpu_upload_texture(a,uint2(0u,1u),uint4(0u,0u,12u,8u),source,pitch)
            read_equal(device,a,uint2(0u,1u),uint4(0u,0u,12u,8u),tight)
            verify(!SDL_UploadGPUTextureRegion(device,a,uint2(0u),uint4(1u,0u,4u,4u),one,block_bytes,false))
            verify(!SDL_UploadGPUTextureRegion(device,a,uint2(0u),uint4(0u,0u,3u,4u),one,block_bytes,false))
            verify(!SDL_UploadGPUTextureRegion(device,a,uint2(0u),uint4(0u,0u,4u,4u),one,block_bytes-1u,false))
            verify(!SDL_UploadGPUTextureRegion(device,a,uint2(0u),uint4(0u,0u,12u,8u),source,pitch,true))
            verify(SDL_RequestGPUTextureReadback(device,a,uint2(0u),uint4(0u,1u,4u,4u)) == 0ul)
            device |> gpu_copy_texture(a,uint2(0u,1u),uint4(4u,4u,4u,4u),b,uint2(0u),uint2(8u,0u))
            var copied : array<uint8>
            resize(copied,int(row*2u))
            for (i in 0 .. int(block_bytes)) { copied[int(2u*block_bytes)+i] = tight[int(row+block_bytes)+i] }
            read_equal(device,b,uint2(0u),uint4(0u,0u,12u,8u),copied)
            read_equal(device,b,uint2(0u,1u),uint4(0u,0u,12u,8u),zero)
            // Mip 1 is 6x4: final 2-pixel edge occupies one complete block_bytes.
            device |> gpu_upload_texture(a,uint2(1u,1u),uint4(4u,0u,2u,4u),one,block_bytes)
            print("BC mip edge copy\n")
            device |> gpu_copy_texture(a,uint2(1u,1u),uint4(4u,0u,2u,4u),b,uint2(1u),uint2(4u,0u))
            read_equal(device,b,uint2(1u),uint4(4u,0u,2u,4u),one)
            // Smallest mips still contain a full compressed block_bytes.
            device |> gpu_upload_texture(a,uint2(3u,1u),uint4(0u,0u,1u,1u),one,block_bytes)
            read_equal(device,a,uint2(3u,1u),uint4(0u,0u,1u,1u),one)
        }
    }
    verify(SDL_RequestGPUTextureReadback(device,stale,uint2(0u),uint4(0u,0u,4u,4u)) == 0ul)
}
def check_cube(device : SDL_GPUDevice?; format, count, levels, texture_type : uint) {
    let bc = format == SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM
    let pitch = bc ? 16u : 32u
    var data, zero : array<uint8>
    resize(data,bc ? 32 : 256); resize(zero,length(data))
    device |> with_gpu_transfer_texture(8u,8u,count,levels,format,texture_type) $(cube) {
        for (face in 0u .. count) {
            read_equal(device,cube,uint2(0u,face),uint4(0u,0u,8u,8u),zero)
            for (i in 0 .. length(data)) { data[i] = uint8(int(face)*13+i) }
            device |> gpu_upload_texture(cube,uint2(0u,face),uint4(0u,0u,8u,8u),data,pitch)
        }
        for (face in 0u .. count) {
            for (i in 0 .. length(data)) { data[i] = uint8(int(face)*13+i) }
            read_equal(device,cube,uint2(0u,face),uint4(0u,0u,8u,8u),data)
        }
        verify(SDL_RequestGPUTextureReadback(device,cube,uint2(0u,count),uint4(0u,0u,8u,8u)) == 0ul)
        if (levels > 1u) {
            var small : array<uint8>
            resize(small,bc ? 8 : 4)
            device |> gpu_upload_texture(cube,uint2(3u,count-1u),uint4(0u,0u,1u,1u),small,bc ? 8u : 4u)
            read_equal(device,cube,uint2(3u,count-1u),uint4(0u,0u,1u,1u),small)
        }
    }
}
[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            let rgba = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM
            verify(SDL_CreateGPUTypedTransferTexture(device,4u,4u,1u,1u,rgba,SDL_GPU_TEXTURETYPE_3D) == 0ul)
            verify(SDL_CreateGPUTypedTransferTexture(device,4u,8u,6u,1u,rgba,SDL_GPU_TEXTURETYPE_CUBE) == 0ul)
            verify(SDL_CreateGPUTypedTransferTexture(device,4u,4u,5u,1u,rgba,SDL_GPU_TEXTURETYPE_CUBE) == 0ul)
            verify(SDL_CreateGPUTypedTransferTexture(device,4u,4u,7u,1u,rgba,SDL_GPU_TEXTURETYPE_CUBE_ARRAY) == 0ul)
            verify(SDL_CreateGPUTypedTransferTexture(device,4u,4u,0u,1u,rgba,SDL_GPU_TEXTURETYPE_CUBE_ARRAY) == 0ul)
            verify(SDL_CreateGPUTypedTransferTexture(device,8192u,8192u,252u,1u,rgba,SDL_GPU_TEXTURETYPE_CUBE_ARRAY) == 0ul)
            verify(SDL_CreateGPUTypedTransferTexture(device,7u,4u,1u,1u,SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM,SDL_GPU_TEXTURETYPE_2D) == 0ul)
            verify(SDL_CreateGPUTypedTransferTexture(device,4u,4u,1u,1u,SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM,SDL_GPU_TEXTURETYPE_2D) == 0ul)
            for (f in SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM .. SDL_GPU_TEXTUREFORMAT_BC6H_RGB_UFLOAT+1u) { check_bc(device,f) }
            for (f in SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM_SRGB .. SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB+1u) { check_bc(device,f) }
            check_cube(device,rgba,6u,4u,SDL_GPU_TEXTURETYPE_CUBE)
            check_cube(device,rgba,12u,4u,SDL_GPU_TEXTURETYPE_CUBE_ARRAY)
            check_cube(device,SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM,6u,4u,SDL_GPU_TEXTURETYPE_CUBE)
            // New scopes preserve cleanup on panic and source-independent tickets.
            var escaped = 0ul
            var caught = false
            try {
                device |> with_gpu_transfer_texture(4u,4u,6u,1u,rgba,SDL_GPU_TEXTURETYPE_CUBE) $(cube) {
                    escaped = cube
                    panic("cube scope marker")
                }
            } recover { caught = true }
            verify(caught)
            verify(!SDL_ReleaseGPUTransferTexture(device,escaped))
            let cube = SDL_CreateGPUTypedTransferTexture(device,4u,4u,6u,1u,rgba,SDL_GPU_TEXTURETYPE_CUBE)
            verify(cube != 0ul)
            var face, result : array<uint8>
            resize(face,64); resize(result,64)
            for (i in 0 .. 64) { face[i] = uint8(i*3) }
            device |> gpu_upload_texture(cube,uint2(0u,5u),uint4(0u,0u,4u,4u),face,16u)
            let ticket = SDL_RequestGPUTextureReadback(device,cube,uint2(0u,5u),uint4(0u,0u,4u,4u))
            verify(ticket != 0ul)
            with_gpu_device() $(other) {
                verify(SDL_RequestGPUTextureReadback(other,cube,uint2(0u),uint4(0u,0u,4u,4u)) == 0ul)
                verify(!SDL_ReleaseGPUTransferTexture(other,cube))
            }
            verify(SDL_ReleaseGPUTransferTexture(device,cube))
            device |> gpu_wait_readback(ticket)
            device |> gpu_readback_bytes(ticket,result)
            for (i in 0 .. 64) { verify(result[i] == face[i]) }
            verify(SDL_ReleaseGPUReadback(device,ticket))
            print("BC blocks and cube face/mip roundtrips PASS: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    return available ? 0 : 77
}
