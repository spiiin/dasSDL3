options gen2
require sdl3

[export]
def main(smoke : bool) : int {
    {
        var value : SDL_GPUSamplerCreateInfo
        SDLTest_fill_GPUSamplerCreateInfo(value)
        verify(value.min_filter == SDL_GPUFilter.FILTER_NEAREST)
        verify(value.mag_filter == SDL_GPUFilter.FILTER_LINEAR)
        verify(value.mipmap_mode == SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_NEAREST)
        verify(value.address_mode_u == SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT)
        verify(value.address_mode_v == SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_MIRRORED_REPEAT)
        verify(value.address_mode_w == SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE)
        verify(value.mip_lod_bias == 6.25)
        verify(value.max_anisotropy == 7.25)
        verify(value.compare_op == SDL_GPUCompareOp.COMPAREOP_ALWAYS)
        verify(value.min_lod == 9.25)
        verify(value.max_lod == 10.25)
        verify(value.enable_anisotropy == true)
        verify(value.enable_compare == false)
        verify(value.props == 4109u)
        value.min_filter = SDL_GPUFilter.FILTER_LINEAR
        value.mag_filter = SDL_GPUFilter.FILTER_NEAREST
        value.mipmap_mode = SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR
        value.address_mode_u = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_MIRRORED_REPEAT
        value.address_mode_v = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE
        value.address_mode_w = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT
        value.mip_lod_bias = -6.25
        value.max_anisotropy = -7.25
        value.compare_op = SDL_GPUCompareOp.COMPAREOP_NOT_EQUAL
        value.min_lod = -9.25
        value.max_lod = -10.25
        value.enable_anisotropy = false
        value.enable_compare = true
        value.props = 2147483666u
        verify(SDLTest_check_GPUSamplerCreateInfo(value))
        var copies : array<SDL_GPUSamplerCreateInfo>
        push(copies, value)
        verify(SDLTest_check_GPUSamplerCreateInfo(copies[0]))
        SDLTest_fill_GPUSamplerCreateInfo(copies[0])
        verify(SDLTest_check_GPUSamplerCreateInfo(value)) // Independent value copy, including nested state.
    }
    {
        var value : SDL_GPUStencilOpState
        SDLTest_fill_GPUStencilOpState(value)
        verify(value.fail_op == SDL_GPUStencilOp.STENCILOP_INVALID)
        verify(value.pass_op == SDL_GPUStencilOp.STENCILOP_KEEP)
        verify(value.depth_fail_op == SDL_GPUStencilOp.STENCILOP_ZERO)
        verify(value.compare_op == SDL_GPUCompareOp.COMPAREOP_EQUAL)
        value.fail_op = SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_WRAP
        value.pass_op = SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_WRAP
        value.depth_fail_op = SDL_GPUStencilOp.STENCILOP_INVALID
        value.compare_op = SDL_GPUCompareOp.COMPAREOP_NEVER
        verify(SDLTest_check_GPUStencilOpState(value))
        var copies : array<SDL_GPUStencilOpState>
        push(copies, value)
        verify(SDLTest_check_GPUStencilOpState(copies[0]))
        SDLTest_fill_GPUStencilOpState(copies[0])
        verify(SDLTest_check_GPUStencilOpState(value)) // Independent value copy, including nested state.
    }
    {
        var value : SDL_GPUColorTargetBlendState
        SDLTest_fill_GPUColorTargetBlendState(value)
        verify(value.src_color_blendfactor == SDL_GPUBlendFactor.BLENDFACTOR_INVALID)
        verify(value.dst_color_blendfactor == SDL_GPUBlendFactor.BLENDFACTOR_ZERO)
        verify(value.color_blend_op == SDL_GPUBlendOp.BLENDOP_SUBTRACT)
        verify(value.src_alpha_blendfactor == SDL_GPUBlendFactor.BLENDFACTOR_SRC_COLOR)
        verify(value.dst_alpha_blendfactor == SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_COLOR)
        verify(value.alpha_blend_op == SDL_GPUBlendOp.BLENDOP_MAX)
        verify(value.color_write_mask == uint8(134))
        verify(value.enable_blend == true)
        verify(value.enable_color_write_mask == false)
        value.src_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA
        value.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA
        value.color_blend_op = SDL_GPUBlendOp.BLENDOP_REVERSE_SUBTRACT
        value.src_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_DST_ALPHA
        value.dst_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_CONSTANT_COLOR
        value.alpha_blend_op = SDL_GPUBlendOp.BLENDOP_INVALID
        value.color_write_mask = uint8(141)
        value.enable_blend = false
        value.enable_color_write_mask = true
        verify(SDLTest_check_GPUColorTargetBlendState(value))
        var copies : array<SDL_GPUColorTargetBlendState>
        push(copies, value)
        verify(SDLTest_check_GPUColorTargetBlendState(copies[0]))
        SDLTest_fill_GPUColorTargetBlendState(copies[0])
        verify(SDLTest_check_GPUColorTargetBlendState(value)) // Independent value copy, including nested state.
    }
    {
        var value : SDL_GPUTransferBufferCreateInfo
        SDLTest_fill_GPUTransferBufferCreateInfo(value)
        verify(value.usage == SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD)
        verify(value.size == 4097u)
        verify(value.props == 4098u)
        value.usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD
        value.size = 2147483654u
        value.props = 2147483655u
        verify(SDLTest_check_GPUTransferBufferCreateInfo(value))
        var copies : array<SDL_GPUTransferBufferCreateInfo>
        push(copies, value)
        verify(SDLTest_check_GPUTransferBufferCreateInfo(copies[0]))
        SDLTest_fill_GPUTransferBufferCreateInfo(copies[0])
        verify(SDLTest_check_GPUTransferBufferCreateInfo(value)) // Independent value copy, including nested state.
    }
    {
        var value : SDL_GPUDepthStencilState
        SDLTest_fill_GPUDepthStencilState(value)
        verify(value.compare_op == SDL_GPUCompareOp.COMPAREOP_INVALID)
        verify(value.back_stencil_state.fail_op == SDL_GPUStencilOp.STENCILOP_KEEP)
        verify(value.back_stencil_state.pass_op == SDL_GPUStencilOp.STENCILOP_ZERO)
        verify(value.back_stencil_state.depth_fail_op == SDL_GPUStencilOp.STENCILOP_REPLACE)
        verify(value.back_stencil_state.compare_op == SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL)
        verify(value.front_stencil_state.fail_op == SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_CLAMP)
        verify(value.front_stencil_state.pass_op == SDL_GPUStencilOp.STENCILOP_INVERT)
        verify(value.front_stencil_state.depth_fail_op == SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_WRAP)
        verify(value.front_stencil_state.compare_op == SDL_GPUCompareOp.COMPAREOP_ALWAYS)
        verify(value.compare_mask == uint8(137))
        verify(value.write_mask == uint8(138))
        verify(value.enable_depth_test == true)
        verify(value.enable_depth_write == false)
        verify(value.enable_stencil_test == true)
        value.compare_op = SDL_GPUCompareOp.COMPAREOP_GREATER_OR_EQUAL
        value.back_stencil_state.fail_op = SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_WRAP
        value.back_stencil_state.pass_op = SDL_GPUStencilOp.STENCILOP_INVALID
        value.back_stencil_state.depth_fail_op = SDL_GPUStencilOp.STENCILOP_KEEP
        value.back_stencil_state.compare_op = SDL_GPUCompareOp.COMPAREOP_LESS
        value.front_stencil_state.fail_op = SDL_GPUStencilOp.STENCILOP_REPLACE
        value.front_stencil_state.pass_op = SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_CLAMP
        value.front_stencil_state.depth_fail_op = SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_CLAMP
        value.front_stencil_state.compare_op = SDL_GPUCompareOp.COMPAREOP_NOT_EQUAL
        value.compare_mask = uint8(144)
        value.write_mask = uint8(145)
        value.enable_depth_test = false
        value.enable_depth_write = true
        value.enable_stencil_test = false
        verify(SDLTest_check_GPUDepthStencilState(value))
        var copies : array<SDL_GPUDepthStencilState>
        push(copies, value)
        verify(SDLTest_check_GPUDepthStencilState(copies[0]))
        SDLTest_fill_GPUDepthStencilState(copies[0])
        verify(SDLTest_check_GPUDepthStencilState(value)) // Independent value copy, including nested state.
    }
    {
        var value : SDL_GPUColorTargetDescription
        SDLTest_fill_GPUColorTargetDescription(value)
        verify(value.format == SDL_GPUTextureFormat.TEXTUREFORMAT_INVALID)
        verify(value.blend_state.src_color_blendfactor == SDL_GPUBlendFactor.BLENDFACTOR_ZERO)
        verify(value.blend_state.dst_color_blendfactor == SDL_GPUBlendFactor.BLENDFACTOR_ONE)
        verify(value.blend_state.color_blend_op == SDL_GPUBlendOp.BLENDOP_REVERSE_SUBTRACT)
        verify(value.blend_state.src_alpha_blendfactor == SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_COLOR)
        verify(value.blend_state.dst_alpha_blendfactor == SDL_GPUBlendFactor.BLENDFACTOR_DST_COLOR)
        verify(value.blend_state.alpha_blend_op == SDL_GPUBlendOp.BLENDOP_INVALID)
        verify(value.blend_state.color_write_mask == uint8(135))
        verify(value.blend_state.enable_blend == false)
        verify(value.blend_state.enable_color_write_mask == true)
        value.format = SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_UNORM
        value.blend_state.src_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA
        value.blend_state.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_DST_ALPHA
        value.blend_state.color_blend_op = SDL_GPUBlendOp.BLENDOP_MIN
        value.blend_state.src_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_CONSTANT_COLOR
        value.blend_state.dst_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_CONSTANT_COLOR
        value.blend_state.alpha_blend_op = SDL_GPUBlendOp.BLENDOP_ADD
        value.blend_state.color_write_mask = uint8(142)
        value.blend_state.enable_blend = true
        value.blend_state.enable_color_write_mask = false
        verify(SDLTest_check_GPUColorTargetDescription(value))
        var copies : array<SDL_GPUColorTargetDescription>
        push(copies, value)
        verify(SDLTest_check_GPUColorTargetDescription(copies[0]))
        SDLTest_fill_GPUColorTargetDescription(copies[0])
        verify(SDLTest_check_GPUColorTargetDescription(value)) // Independent value copy, including nested state.
    }
    verify(SDLTest_echo_SDL_GPUPrimitiveType(SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST) == SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
    verify(SDLTest_echo_SDL_GPUPrimitiveType(SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLESTRIP) == SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLESTRIP)
    verify(SDLTest_echo_SDL_GPUPrimitiveType(SDL_GPUPrimitiveType.PRIMITIVETYPE_LINELIST) == SDL_GPUPrimitiveType.PRIMITIVETYPE_LINELIST)
    verify(SDLTest_echo_SDL_GPUPrimitiveType(SDL_GPUPrimitiveType.PRIMITIVETYPE_LINESTRIP) == SDL_GPUPrimitiveType.PRIMITIVETYPE_LINESTRIP)
    verify(SDLTest_echo_SDL_GPUPrimitiveType(SDL_GPUPrimitiveType.PRIMITIVETYPE_POINTLIST) == SDL_GPUPrimitiveType.PRIMITIVETYPE_POINTLIST)
    verify(SDLTest_echo_SDL_GPULoadOp(SDL_GPULoadOp.LOADOP_LOAD) == SDL_GPULoadOp.LOADOP_LOAD)
    verify(SDLTest_echo_SDL_GPULoadOp(SDL_GPULoadOp.LOADOP_CLEAR) == SDL_GPULoadOp.LOADOP_CLEAR)
    verify(SDLTest_echo_SDL_GPULoadOp(SDL_GPULoadOp.LOADOP_DONT_CARE) == SDL_GPULoadOp.LOADOP_DONT_CARE)
    verify(SDLTest_echo_SDL_GPUStoreOp(SDL_GPUStoreOp.STOREOP_STORE) == SDL_GPUStoreOp.STOREOP_STORE)
    verify(SDLTest_echo_SDL_GPUStoreOp(SDL_GPUStoreOp.STOREOP_DONT_CARE) == SDL_GPUStoreOp.STOREOP_DONT_CARE)
    verify(SDLTest_echo_SDL_GPUStoreOp(SDL_GPUStoreOp.STOREOP_RESOLVE) == SDL_GPUStoreOp.STOREOP_RESOLVE)
    verify(SDLTest_echo_SDL_GPUStoreOp(SDL_GPUStoreOp.STOREOP_RESOLVE_AND_STORE) == SDL_GPUStoreOp.STOREOP_RESOLVE_AND_STORE)
    verify(SDLTest_echo_SDL_GPUIndexElementSize(SDL_GPUIndexElementSize.INDEXELEMENTSIZE_16BIT) == SDL_GPUIndexElementSize.INDEXELEMENTSIZE_16BIT)
    verify(SDLTest_echo_SDL_GPUIndexElementSize(SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT) == SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
    verify(SDLTest_echo_SDL_GPUCubeMapFace(SDL_GPUCubeMapFace.CUBEMAPFACE_POSITIVEX) == SDL_GPUCubeMapFace.CUBEMAPFACE_POSITIVEX)
    verify(SDLTest_echo_SDL_GPUCubeMapFace(SDL_GPUCubeMapFace.CUBEMAPFACE_NEGATIVEX) == SDL_GPUCubeMapFace.CUBEMAPFACE_NEGATIVEX)
    verify(SDLTest_echo_SDL_GPUCubeMapFace(SDL_GPUCubeMapFace.CUBEMAPFACE_POSITIVEY) == SDL_GPUCubeMapFace.CUBEMAPFACE_POSITIVEY)
    verify(SDLTest_echo_SDL_GPUCubeMapFace(SDL_GPUCubeMapFace.CUBEMAPFACE_NEGATIVEY) == SDL_GPUCubeMapFace.CUBEMAPFACE_NEGATIVEY)
    verify(SDLTest_echo_SDL_GPUCubeMapFace(SDL_GPUCubeMapFace.CUBEMAPFACE_POSITIVEZ) == SDL_GPUCubeMapFace.CUBEMAPFACE_POSITIVEZ)
    verify(SDLTest_echo_SDL_GPUCubeMapFace(SDL_GPUCubeMapFace.CUBEMAPFACE_NEGATIVEZ) == SDL_GPUCubeMapFace.CUBEMAPFACE_NEGATIVEZ)
    verify(SDLTest_echo_SDL_GPUTransferBufferUsage(SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD) == SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD)
    verify(SDLTest_echo_SDL_GPUTransferBufferUsage(SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD) == SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD)
    verify(SDLTest_echo_SDL_GPUShaderStage(SDL_GPUShaderStage.SHADERSTAGE_VERTEX) == SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    verify(SDLTest_echo_SDL_GPUShaderStage(SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT) == SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    verify(SDLTest_echo_SDL_GPUCompareOp(SDL_GPUCompareOp.COMPAREOP_INVALID) == SDL_GPUCompareOp.COMPAREOP_INVALID)
    verify(SDLTest_echo_SDL_GPUCompareOp(SDL_GPUCompareOp.COMPAREOP_NEVER) == SDL_GPUCompareOp.COMPAREOP_NEVER)
    verify(SDLTest_echo_SDL_GPUCompareOp(SDL_GPUCompareOp.COMPAREOP_LESS) == SDL_GPUCompareOp.COMPAREOP_LESS)
    verify(SDLTest_echo_SDL_GPUCompareOp(SDL_GPUCompareOp.COMPAREOP_EQUAL) == SDL_GPUCompareOp.COMPAREOP_EQUAL)
    verify(SDLTest_echo_SDL_GPUCompareOp(SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL) == SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL)
    verify(SDLTest_echo_SDL_GPUCompareOp(SDL_GPUCompareOp.COMPAREOP_GREATER) == SDL_GPUCompareOp.COMPAREOP_GREATER)
    verify(SDLTest_echo_SDL_GPUCompareOp(SDL_GPUCompareOp.COMPAREOP_NOT_EQUAL) == SDL_GPUCompareOp.COMPAREOP_NOT_EQUAL)
    verify(SDLTest_echo_SDL_GPUCompareOp(SDL_GPUCompareOp.COMPAREOP_GREATER_OR_EQUAL) == SDL_GPUCompareOp.COMPAREOP_GREATER_OR_EQUAL)
    verify(SDLTest_echo_SDL_GPUCompareOp(SDL_GPUCompareOp.COMPAREOP_ALWAYS) == SDL_GPUCompareOp.COMPAREOP_ALWAYS)
    verify(SDLTest_echo_SDL_GPUStencilOp(SDL_GPUStencilOp.STENCILOP_INVALID) == SDL_GPUStencilOp.STENCILOP_INVALID)
    verify(SDLTest_echo_SDL_GPUStencilOp(SDL_GPUStencilOp.STENCILOP_KEEP) == SDL_GPUStencilOp.STENCILOP_KEEP)
    verify(SDLTest_echo_SDL_GPUStencilOp(SDL_GPUStencilOp.STENCILOP_ZERO) == SDL_GPUStencilOp.STENCILOP_ZERO)
    verify(SDLTest_echo_SDL_GPUStencilOp(SDL_GPUStencilOp.STENCILOP_REPLACE) == SDL_GPUStencilOp.STENCILOP_REPLACE)
    verify(SDLTest_echo_SDL_GPUStencilOp(SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_CLAMP) == SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_CLAMP)
    verify(SDLTest_echo_SDL_GPUStencilOp(SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_CLAMP) == SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_CLAMP)
    verify(SDLTest_echo_SDL_GPUStencilOp(SDL_GPUStencilOp.STENCILOP_INVERT) == SDL_GPUStencilOp.STENCILOP_INVERT)
    verify(SDLTest_echo_SDL_GPUStencilOp(SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_WRAP) == SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_WRAP)
    verify(SDLTest_echo_SDL_GPUStencilOp(SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_WRAP) == SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_WRAP)
    verify(SDLTest_echo_SDL_GPUBlendOp(SDL_GPUBlendOp.BLENDOP_INVALID) == SDL_GPUBlendOp.BLENDOP_INVALID)
    verify(SDLTest_echo_SDL_GPUBlendOp(SDL_GPUBlendOp.BLENDOP_ADD) == SDL_GPUBlendOp.BLENDOP_ADD)
    verify(SDLTest_echo_SDL_GPUBlendOp(SDL_GPUBlendOp.BLENDOP_SUBTRACT) == SDL_GPUBlendOp.BLENDOP_SUBTRACT)
    verify(SDLTest_echo_SDL_GPUBlendOp(SDL_GPUBlendOp.BLENDOP_REVERSE_SUBTRACT) == SDL_GPUBlendOp.BLENDOP_REVERSE_SUBTRACT)
    verify(SDLTest_echo_SDL_GPUBlendOp(SDL_GPUBlendOp.BLENDOP_MIN) == SDL_GPUBlendOp.BLENDOP_MIN)
    verify(SDLTest_echo_SDL_GPUBlendOp(SDL_GPUBlendOp.BLENDOP_MAX) == SDL_GPUBlendOp.BLENDOP_MAX)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_INVALID) == SDL_GPUBlendFactor.BLENDFACTOR_INVALID)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_ZERO) == SDL_GPUBlendFactor.BLENDFACTOR_ZERO)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_ONE) == SDL_GPUBlendFactor.BLENDFACTOR_ONE)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_SRC_COLOR) == SDL_GPUBlendFactor.BLENDFACTOR_SRC_COLOR)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_COLOR) == SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_COLOR)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_DST_COLOR) == SDL_GPUBlendFactor.BLENDFACTOR_DST_COLOR)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_DST_COLOR) == SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_DST_COLOR)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA) == SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA) == SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_DST_ALPHA) == SDL_GPUBlendFactor.BLENDFACTOR_DST_ALPHA)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_DST_ALPHA) == SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_DST_ALPHA)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_CONSTANT_COLOR) == SDL_GPUBlendFactor.BLENDFACTOR_CONSTANT_COLOR)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_CONSTANT_COLOR) == SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_CONSTANT_COLOR)
    verify(SDLTest_echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA_SATURATE) == SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA_SATURATE)
    verify(SDLTest_echo_SDL_GPUFilter(SDL_GPUFilter.FILTER_NEAREST) == SDL_GPUFilter.FILTER_NEAREST)
    verify(uint(SDL_GPUFilter.FILTER_NEAREST) == SDL_GPU_FILTER_NEAREST)
    verify(SDLTest_echo_SDL_GPUFilter(SDL_GPUFilter.FILTER_LINEAR) == SDL_GPUFilter.FILTER_LINEAR)
    verify(uint(SDL_GPUFilter.FILTER_LINEAR) == SDL_GPU_FILTER_LINEAR)
    verify(SDLTest_echo_SDL_GPUSamplerMipmapMode(SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_NEAREST) == SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_NEAREST)
    verify(SDLTest_echo_SDL_GPUSamplerMipmapMode(SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR) == SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR)
    verify(SDLTest_echo_SDL_GPUSamplerAddressMode(SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT) == SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT)
    verify(SDLTest_echo_SDL_GPUSamplerAddressMode(SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_MIRRORED_REPEAT) == SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_MIRRORED_REPEAT)
    verify(SDLTest_echo_SDL_GPUSamplerAddressMode(SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE) == SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE)
    verify(SDLTest_echo_SDL_GPUPresentMode(SDL_GPUPresentMode.PRESENTMODE_VSYNC) == SDL_GPUPresentMode.PRESENTMODE_VSYNC)
    verify(uint(SDL_GPUPresentMode.PRESENTMODE_VSYNC) == SDL_GPU_PRESENTMODE_VSYNC)
    verify(SDLTest_echo_SDL_GPUPresentMode(SDL_GPUPresentMode.PRESENTMODE_IMMEDIATE) == SDL_GPUPresentMode.PRESENTMODE_IMMEDIATE)
    verify(uint(SDL_GPUPresentMode.PRESENTMODE_IMMEDIATE) == SDL_GPU_PRESENTMODE_IMMEDIATE)
    verify(SDLTest_echo_SDL_GPUPresentMode(SDL_GPUPresentMode.PRESENTMODE_MAILBOX) == SDL_GPUPresentMode.PRESENTMODE_MAILBOX)
    verify(uint(SDL_GPUPresentMode.PRESENTMODE_MAILBOX) == SDL_GPU_PRESENTMODE_MAILBOX)
    verify(SDLTest_echo_SDL_GPUSwapchainComposition(SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR) == SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR)
    verify(uint(SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR) == SDL_GPU_SWAPCHAINCOMPOSITION_SDR)
    verify(SDLTest_echo_SDL_GPUSwapchainComposition(SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR_LINEAR) == SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR_LINEAR)
    verify(uint(SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR_LINEAR) == SDL_GPU_SWAPCHAINCOMPOSITION_SDR_LINEAR)
    verify(SDLTest_echo_SDL_GPUSwapchainComposition(SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR) == SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR)
    verify(uint(SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR) == SDL_GPU_SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR)
    verify(SDLTest_echo_SDL_GPUSwapchainComposition(SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_HDR10_ST2084) == SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_HDR10_ST2084)
    verify(uint(SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_HDR10_ST2084) == SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084)
    print("GPU nested pipeline descriptors and remaining enum roundtrips PASS\n")
    return 0
}
