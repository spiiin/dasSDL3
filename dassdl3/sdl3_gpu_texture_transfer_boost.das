options gen2
require daslib/defer
module sdl3_gpu_texture_transfer_boost shared public
require dassdl3/sdl3_gpu_transfer_boost public

// Color or supported BC/ASTC block format, sample 1; every subresource starts with zero bits.
def public with_gpu_transfer_texture(device : SDL_GPUDevice?; width, height, layers, levels, format, texture_type : uint;
        blk : block<(texture : uint64) : void>) {
    let id = SDL_CreateGPUTypedTransferTexture(device,width,height,layers,levels,format,texture_type)
    if (id == 0ul) { return false }
    {
        defer() { SDL_ReleaseGPUTransferTexture(device,id) }
        blk(id)
        return true
    }
}

def public with_gpu_color_texture(device : SDL_GPUDevice?; width, height, layers, levels, format : uint;
        blk : block<(texture : uint64) : void>) {
    let id = SDL_CreateGPUColorTransferTexture(device,width,height,layers,levels,format)
    if (id == 0ul) { return false }
    {
        defer() { SDL_ReleaseGPUTransferTexture(device,id) }
        blk(id)
        return true
    }
}

def public with_gpu_rgba_texture(device : SDL_GPUDevice?; width, height, layers, levels : uint;
        blk : block<(texture : uint64) : void>) {
    return with_gpu_color_texture(device,width,height,layers,levels,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,blk)
}
def public with_gpu_rgba_texture(device : SDL_GPUDevice?; width, height : uint;
        blk : block<(texture : uint64) : void>) {
    return with_gpu_rgba_texture(device,width,height,1u,1u,blk)
}

// sub = uint2(mip,layer), region = uint4(x,y,width,height), pitch in bytes.
def public gpu_upload_texture(device : SDL_GPUDevice?; texture : uint64; sub : uint2;
        region : uint4; bytes : array<uint8>; pitch : uint; cycle : bool = false) {
    return SDL_UploadGPUTextureRegion(device,texture,sub,region,bytes,pitch,cycle)
}

def public gpu_copy_texture(device : SDL_GPUDevice?; source : uint64; source_sub : uint2;
        source_region : uint4; destination : uint64; dest_sub, dest_origin : uint2) {
    return SDL_CopyGPUTextureRegion(device,source,source_sub,source_region,destination,dest_sub,dest_origin)
}

// The ticket uses the same poll/wait/read API as buffer readback. Output is
// tightly packed format-native bytes; no GPU row padding reaches the script array.
def public with_gpu_texture_readback(device : SDL_GPUDevice?; texture : uint64;
        sub : uint2; region : uint4; blk : block<(ticket : uint64) : void>) {
    let id = SDL_RequestGPUTextureReadback(device,texture,sub,region)
    if (id == 0ul) { return false }
    {
        defer() { SDL_ReleaseGPUReadback(device,id) }
        blk(id)
        return true
    }
}
