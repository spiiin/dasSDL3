#pragma once
#include <SDL3/SDL.h>
namespace sdl3_test {
inline void fill_GPUSamplerCreateInfo(SDL_GPUSamplerCreateInfo & v) { v={};
    v.min_filter = SDL_GPU_FILTER_NEAREST;
    v.mag_filter = SDL_GPU_FILTER_LINEAR;
    v.mipmap_mode = SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
    v.address_mode_u = SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    v.address_mode_v = SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT;
    v.address_mode_w = SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    v.mip_lod_bias = 6.25f;
    v.max_anisotropy = 7.25f;
    v.compare_op = SDL_GPU_COMPAREOP_ALWAYS;
    v.min_lod = 9.25f;
    v.max_lod = 10.25f;
    v.enable_anisotropy = true;
    v.enable_compare = false;
    v.props = 4109u;
}
inline bool check_GPUSamplerCreateInfo(const SDL_GPUSamplerCreateInfo & v) { return v.min_filter == SDL_GPU_FILTER_LINEAR && v.mag_filter == SDL_GPU_FILTER_NEAREST && v.mipmap_mode == SDL_GPU_SAMPLERMIPMAPMODE_LINEAR && v.address_mode_u == SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT && v.address_mode_v == SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE && v.address_mode_w == SDL_GPU_SAMPLERADDRESSMODE_REPEAT && v.mip_lod_bias == -6.25f && v.max_anisotropy == -7.25f && v.compare_op == SDL_GPU_COMPAREOP_NOT_EQUAL && v.min_lod == -9.25f && v.max_lod == -10.25f && v.enable_anisotropy == false && v.enable_compare == true && v.props == 2147483666u; }
inline void fill_GPUStencilOpState(SDL_GPUStencilOpState & v) { v={};
    v.fail_op = SDL_GPU_STENCILOP_INVALID;
    v.pass_op = SDL_GPU_STENCILOP_KEEP;
    v.depth_fail_op = SDL_GPU_STENCILOP_ZERO;
    v.compare_op = SDL_GPU_COMPAREOP_EQUAL;
}
inline bool check_GPUStencilOpState(const SDL_GPUStencilOpState & v) { return v.fail_op == SDL_GPU_STENCILOP_INCREMENT_AND_WRAP && v.pass_op == SDL_GPU_STENCILOP_DECREMENT_AND_WRAP && v.depth_fail_op == SDL_GPU_STENCILOP_INVALID && v.compare_op == SDL_GPU_COMPAREOP_NEVER; }
inline void fill_GPUColorTargetBlendState(SDL_GPUColorTargetBlendState & v) { v={};
    v.src_color_blendfactor = SDL_GPU_BLENDFACTOR_INVALID;
    v.dst_color_blendfactor = SDL_GPU_BLENDFACTOR_ZERO;
    v.color_blend_op = SDL_GPU_BLENDOP_SUBTRACT;
    v.src_alpha_blendfactor = SDL_GPU_BLENDFACTOR_SRC_COLOR;
    v.dst_alpha_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_COLOR;
    v.alpha_blend_op = SDL_GPU_BLENDOP_MAX;
    v.color_write_mask = 134;
    v.enable_blend = true;
    v.enable_color_write_mask = false;
}
inline bool check_GPUColorTargetBlendState(const SDL_GPUColorTargetBlendState & v) { return v.src_color_blendfactor == SDL_GPU_BLENDFACTOR_SRC_ALPHA && v.dst_color_blendfactor == SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA && v.color_blend_op == SDL_GPU_BLENDOP_REVERSE_SUBTRACT && v.src_alpha_blendfactor == SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_ALPHA && v.dst_alpha_blendfactor == SDL_GPU_BLENDFACTOR_CONSTANT_COLOR && v.alpha_blend_op == SDL_GPU_BLENDOP_INVALID && v.color_write_mask == 141 && v.enable_blend == false && v.enable_color_write_mask == true; }
inline void fill_GPUTransferBufferCreateInfo(SDL_GPUTransferBufferCreateInfo & v) { v={};
    v.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    v.size = 4097u;
    v.props = 4098u;
}
inline bool check_GPUTransferBufferCreateInfo(const SDL_GPUTransferBufferCreateInfo & v) { return v.usage == SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD && v.size == 2147483654u && v.props == 2147483655u; }
inline void fill_GPUDepthStencilState(SDL_GPUDepthStencilState & v) { v={};
    v.compare_op = SDL_GPU_COMPAREOP_INVALID;
    v.back_stencil_state.fail_op = SDL_GPU_STENCILOP_KEEP;
    v.back_stencil_state.pass_op = SDL_GPU_STENCILOP_ZERO;
    v.back_stencil_state.depth_fail_op = SDL_GPU_STENCILOP_REPLACE;
    v.back_stencil_state.compare_op = SDL_GPU_COMPAREOP_LESS_OR_EQUAL;
    v.front_stencil_state.fail_op = SDL_GPU_STENCILOP_DECREMENT_AND_CLAMP;
    v.front_stencil_state.pass_op = SDL_GPU_STENCILOP_INVERT;
    v.front_stencil_state.depth_fail_op = SDL_GPU_STENCILOP_INCREMENT_AND_WRAP;
    v.front_stencil_state.compare_op = SDL_GPU_COMPAREOP_ALWAYS;
    v.compare_mask = 137;
    v.write_mask = 138;
    v.enable_depth_test = true;
    v.enable_depth_write = false;
    v.enable_stencil_test = true;
}
inline bool check_GPUDepthStencilState(const SDL_GPUDepthStencilState & v) { return v.compare_op == SDL_GPU_COMPAREOP_GREATER_OR_EQUAL && v.back_stencil_state.fail_op == SDL_GPU_STENCILOP_DECREMENT_AND_WRAP && v.back_stencil_state.pass_op == SDL_GPU_STENCILOP_INVALID && v.back_stencil_state.depth_fail_op == SDL_GPU_STENCILOP_KEEP && v.back_stencil_state.compare_op == SDL_GPU_COMPAREOP_LESS && v.front_stencil_state.fail_op == SDL_GPU_STENCILOP_REPLACE && v.front_stencil_state.pass_op == SDL_GPU_STENCILOP_INCREMENT_AND_CLAMP && v.front_stencil_state.depth_fail_op == SDL_GPU_STENCILOP_DECREMENT_AND_CLAMP && v.front_stencil_state.compare_op == SDL_GPU_COMPAREOP_NOT_EQUAL && v.compare_mask == 144 && v.write_mask == 145 && v.enable_depth_test == false && v.enable_depth_write == true && v.enable_stencil_test == false; }
inline void fill_GPUColorTargetDescription(SDL_GPUColorTargetDescription & v) { v={};
    v.format = SDL_GPU_TEXTUREFORMAT_INVALID;
    v.blend_state.src_color_blendfactor = SDL_GPU_BLENDFACTOR_ZERO;
    v.blend_state.dst_color_blendfactor = SDL_GPU_BLENDFACTOR_ONE;
    v.blend_state.color_blend_op = SDL_GPU_BLENDOP_REVERSE_SUBTRACT;
    v.blend_state.src_alpha_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_COLOR;
    v.blend_state.dst_alpha_blendfactor = SDL_GPU_BLENDFACTOR_DST_COLOR;
    v.blend_state.alpha_blend_op = SDL_GPU_BLENDOP_INVALID;
    v.blend_state.color_write_mask = 135;
    v.blend_state.enable_blend = false;
    v.blend_state.enable_color_write_mask = true;
}
inline bool check_GPUColorTargetDescription(const SDL_GPUColorTargetDescription & v) { return v.format == SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UNORM && v.blend_state.src_color_blendfactor == SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA && v.blend_state.dst_color_blendfactor == SDL_GPU_BLENDFACTOR_DST_ALPHA && v.blend_state.color_blend_op == SDL_GPU_BLENDOP_MIN && v.blend_state.src_alpha_blendfactor == SDL_GPU_BLENDFACTOR_CONSTANT_COLOR && v.blend_state.dst_alpha_blendfactor == SDL_GPU_BLENDFACTOR_ONE_MINUS_CONSTANT_COLOR && v.blend_state.alpha_blend_op == SDL_GPU_BLENDOP_ADD && v.blend_state.color_write_mask == 142 && v.blend_state.enable_blend == true && v.blend_state.enable_color_write_mask == false; }
inline SDL_GPUPrimitiveType echo_SDL_GPUPrimitiveType(SDL_GPUPrimitiveType value) { return value; }
inline SDL_GPULoadOp echo_SDL_GPULoadOp(SDL_GPULoadOp value) { return value; }
inline SDL_GPUStoreOp echo_SDL_GPUStoreOp(SDL_GPUStoreOp value) { return value; }
inline SDL_GPUIndexElementSize echo_SDL_GPUIndexElementSize(SDL_GPUIndexElementSize value) { return value; }
inline SDL_GPUCubeMapFace echo_SDL_GPUCubeMapFace(SDL_GPUCubeMapFace value) { return value; }
inline SDL_GPUTransferBufferUsage echo_SDL_GPUTransferBufferUsage(SDL_GPUTransferBufferUsage value) { return value; }
inline SDL_GPUShaderStage echo_SDL_GPUShaderStage(SDL_GPUShaderStage value) { return value; }
inline SDL_GPUCompareOp echo_SDL_GPUCompareOp(SDL_GPUCompareOp value) { return value; }
inline SDL_GPUStencilOp echo_SDL_GPUStencilOp(SDL_GPUStencilOp value) { return value; }
inline SDL_GPUBlendOp echo_SDL_GPUBlendOp(SDL_GPUBlendOp value) { return value; }
inline SDL_GPUBlendFactor echo_SDL_GPUBlendFactor(SDL_GPUBlendFactor value) { return value; }
inline SDL_GPUFilter echo_SDL_GPUFilter(SDL_GPUFilter value) { return value; }
inline SDL_GPUSamplerMipmapMode echo_SDL_GPUSamplerMipmapMode(SDL_GPUSamplerMipmapMode value) { return value; }
inline SDL_GPUSamplerAddressMode echo_SDL_GPUSamplerAddressMode(SDL_GPUSamplerAddressMode value) { return value; }
inline SDL_GPUPresentMode echo_SDL_GPUPresentMode(SDL_GPUPresentMode value) { return value; }
inline SDL_GPUSwapchainComposition echo_SDL_GPUSwapchainComposition(SDL_GPUSwapchainComposition value) { return value; }
}
