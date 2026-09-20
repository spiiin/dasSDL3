options gen2
require daslib/defer
module sdl3_gpu_texture_transfer_boost shared public
require dassdl3/sdl3_gpu_transfer_boost public

// Color or supported BC/ASTC block format, sample 1; every subresource starts with zero bits.
def public with_gpu_transfer_texture(device : SDL_GPUDevice?; width, height, layers, levels, format, texture_type : uint;
        blk : block<(texture : uint64) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let id = SDL_CreateGPUTypedTransferTexture(device,width,height,layers,levels,format,texture_type)
    if (id == 0ul) { return err(sdl_error("with_gpu_transfer_texture"), type<TT>) }
    {
        defer() { if (!SDL_ReleaseGPUTransferTexture(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUTransferTexture"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}

def public with_gpu_color_texture(device : SDL_GPUDevice?; width, height, layers, levels, format : uint;
        blk : block<(texture : uint64) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let id = SDL_CreateGPUColorTransferTexture(device,width,height,layers,levels,format)
    if (id == 0ul) { return err(sdl_error("with_gpu_color_texture"), type<TT>) }
    {
        defer() { if (!SDL_ReleaseGPUTransferTexture(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUTransferTexture"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}

def public with_gpu_rgba_texture(device : SDL_GPUDevice?; width, height, layers, levels : uint;
        blk : block<(texture : uint64) : $Result<auto(TT); SdlError> >) {
    return <- with_gpu_color_texture(device,width,height,layers,levels,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,blk)
}
def public with_gpu_rgba_texture(device : SDL_GPUDevice?; width, height : uint;
        blk : block<(texture : uint64) : $Result<auto(TT); SdlError> >) {
    return <- with_gpu_rgba_texture(device,width,height,1u,1u,blk)
}

// sub = uint2(mip,layer), region = uint4(x,y,width,height), pitch in bytes.
def public gpu_upload_texture(device : SDL_GPUDevice?; texture : uint64; sub : uint2;
        region : uint4; bytes : array<uint8>; pitch : uint; cycle : bool = false) {
    return sdl_status(SDL_UploadGPUTextureRegion(device,texture,sub,region,bytes,pitch,cycle), "gpu_upload_texture")
}

def public gpu_copy_texture(device : SDL_GPUDevice?; source : uint64; source_sub : uint2;
        source_region : uint4; destination : uint64; dest_sub, dest_origin : uint2) {
    return sdl_status(SDL_CopyGPUTextureRegion(device,source,source_sub,source_region,destination,dest_sub,dest_origin), "gpu_copy_texture")
}

// The ticket uses the same poll/wait/read API as buffer readback. Output is
// tightly packed format-native bytes; no GPU row padding reaches the script array.
def public with_gpu_texture_readback(device : SDL_GPUDevice?; texture : uint64;
        sub : uint2; region : uint4; blk : block<(ticket : uint64) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let id = SDL_RequestGPUTextureReadback(device,texture,sub,region)
    if (id == 0ul) { return err(sdl_error("with_gpu_texture_readback"), type<TT>) }
    {
        defer() { if (!SDL_ReleaseGPUReadback(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUReadback"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}
