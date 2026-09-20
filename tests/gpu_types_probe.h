#pragma once
#include <SDL3/SDL.h>
namespace sdl3_test {
inline void fill_GPUViewport(SDL_GPUViewport & v) { v={};
    v.x=-1.25f;
    v.y=2.5f;
    v.w=640.0f;
    v.h=480.0f;
    v.min_depth=0.25f;
    v.max_depth=0.75f;
}
inline bool check_GPUViewport(const SDL_GPUViewport & v) { return v.x==23.5f && v.y==23.5f && v.w==23.5f && v.h==23.5f && v.min_depth==23.5f && v.max_depth==23.5f; }
inline void fill_GPUIndirectDrawCommand(SDL_GPUIndirectDrawCommand & v) { v={};
    v.num_vertices=4294967295u;
    v.num_instances=7u;
    v.first_vertex=8u;
    v.first_instance=9u;
}
inline bool check_GPUIndirectDrawCommand(const SDL_GPUIndirectDrawCommand & v) { return v.num_vertices==2147483653u && v.num_instances==2147483653u && v.first_vertex==2147483653u && v.first_instance==2147483653u; }
inline void fill_GPUIndexedIndirectDrawCommand(SDL_GPUIndexedIndirectDrawCommand & v) { v={};
    v.num_indices=12u;
    v.num_instances=3u;
    v.first_index=24u;
    v.vertex_offset=-37;
    v.first_instance=5u;
}
inline bool check_GPUIndexedIndirectDrawCommand(const SDL_GPUIndexedIndirectDrawCommand & v) { return v.num_indices==2147483653u && v.num_instances==2147483653u && v.first_index==2147483653u && v.vertex_offset==-123 && v.first_instance==2147483653u; }
inline void fill_GPUIndirectDispatchCommand(SDL_GPUIndirectDispatchCommand & v) { v={};
    v.groupcount_x=11u;
    v.groupcount_y=13u;
    v.groupcount_z=17u;
}
inline bool check_GPUIndirectDispatchCommand(const SDL_GPUIndirectDispatchCommand & v) { return v.groupcount_x==2147483653u && v.groupcount_y==2147483653u && v.groupcount_z==2147483653u; }
inline void fill_GPUBufferCreateInfo(SDL_GPUBufferCreateInfo & v) { v={};
    v.usage=SDL_GPU_BUFFERUSAGE_INDIRECT;
    v.size=4096u;
    v.props=0u;
}
inline bool check_GPUBufferCreateInfo(const SDL_GPUBufferCreateInfo & v) { return v.usage==2147483653u && v.size==2147483653u && v.props==2147483653u; }
inline void fill_GPUTextureCreateInfo(SDL_GPUTextureCreateInfo & v) { v={};
    v.type=SDL_GPU_TEXTURETYPE_2D_ARRAY;
    v.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    v.usage=SDL_GPU_TEXTUREUSAGE_COLOR_TARGET;
    v.width=64u;
    v.height=32u;
    v.layer_count_or_depth=6u;
    v.num_levels=3u;
    v.sample_count=SDL_GPU_SAMPLECOUNT_4;
    v.props=0u;
}
inline bool check_GPUTextureCreateInfo(const SDL_GPUTextureCreateInfo & v) { return v.type==0 && v.format==0 && v.usage==2147483653u && v.width==2147483653u && v.height==2147483653u && v.layer_count_or_depth==2147483653u && v.num_levels==2147483653u && v.sample_count==0 && v.props==2147483653u; }
inline void fill_GPUVertexBufferDescription(SDL_GPUVertexBufferDescription & v) { v={};
    v.slot=2u;
    v.pitch=48u;
    v.input_rate=SDL_GPU_VERTEXINPUTRATE_INSTANCE;
    v.instance_step_rate=0u;
}
inline bool check_GPUVertexBufferDescription(const SDL_GPUVertexBufferDescription & v) { return v.slot==2147483653u && v.pitch==2147483653u && v.input_rate==0 && v.instance_step_rate==2147483653u; }
inline void fill_GPUVertexAttribute(SDL_GPUVertexAttribute & v) { v={};
    v.location=3u;
    v.buffer_slot=2u;
    v.format=SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3;
    v.offset=12u;
}
inline bool check_GPUVertexAttribute(const SDL_GPUVertexAttribute & v) { return v.location==2147483653u && v.buffer_slot==2147483653u && v.format==0 && v.offset==2147483653u; }
inline void fill_GPURasterizerState(SDL_GPURasterizerState & v) { v={};
    v.fill_mode=SDL_GPU_FILLMODE_LINE;
    v.cull_mode=SDL_GPU_CULLMODE_BACK;
    v.front_face=SDL_GPU_FRONTFACE_CLOCKWISE;
    v.depth_bias_constant_factor=-2.25f;
    v.depth_bias_clamp=0.5f;
    v.depth_bias_slope_factor=3.75f;
    v.enable_depth_bias=true;
    v.enable_depth_clip=false;
}
inline bool check_GPURasterizerState(const SDL_GPURasterizerState & v) { return v.fill_mode==0 && v.cull_mode==0 && v.front_face==0 && v.depth_bias_constant_factor==23.5f && v.depth_bias_clamp==23.5f && v.depth_bias_slope_factor==23.5f && v.enable_depth_bias==false && v.enable_depth_clip==true; }
inline void fill_GPUMultisampleState(SDL_GPUMultisampleState & v) { v={};
    v.sample_count=SDL_GPU_SAMPLECOUNT_8;
    v.sample_mask=0u;
    v.enable_mask=false;
}
inline bool check_GPUMultisampleState(const SDL_GPUMultisampleState & v) { return v.sample_count==0 && v.sample_mask==2147483653u && v.enable_mask==true; }
inline SDL_GPUTextureType echo_SDL_GPUTextureType(SDL_GPUTextureType v) { return v; }
inline SDL_GPUTextureFormat echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat v) { return v; }
inline SDL_GPUSampleCount echo_SDL_GPUSampleCount(SDL_GPUSampleCount v) { return v; }
inline SDL_GPUVertexInputRate echo_SDL_GPUVertexInputRate(SDL_GPUVertexInputRate v) { return v; }
inline SDL_GPUVertexElementFormat echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat v) { return v; }
inline SDL_GPUFillMode echo_SDL_GPUFillMode(SDL_GPUFillMode v) { return v; }
inline SDL_GPUCullMode echo_SDL_GPUCullMode(SDL_GPUCullMode v) { return v; }
inline SDL_GPUFrontFace echo_SDL_GPUFrontFace(SDL_GPUFrontFace v) { return v; }
}
