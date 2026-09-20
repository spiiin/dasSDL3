options gen2
require sdl3

[export]
def main(smoke : bool) : int {
    {
        var value : SDL_GPUViewport
        SDLTest_fill_GPUViewport(value)
        verify(value.x == -1.25)
        verify(value.y == 2.5)
        verify(value.w == 640.0)
        verify(value.h == 480.0)
        verify(value.min_depth == 0.25)
        verify(value.max_depth == 0.75)
        value.x = 23.5
        value.y = 23.5
        value.w = 23.5
        value.h = 23.5
        value.min_depth = 23.5
        value.max_depth = 23.5
        verify(SDLTest_check_GPUViewport(value))
        var copies : array<SDL_GPUViewport>
        push(copies,value)
        verify(SDLTest_check_GPUViewport(copies[0]))
    }
    {
        var value : SDL_GPUIndirectDrawCommand
        SDLTest_fill_GPUIndirectDrawCommand(value)
        verify(value.num_vertices == 4294967295u)
        verify(value.num_instances == 7u)
        verify(value.first_vertex == 8u)
        verify(value.first_instance == 9u)
        value.num_vertices = 2147483653u
        value.num_instances = 2147483653u
        value.first_vertex = 2147483653u
        value.first_instance = 2147483653u
        verify(SDLTest_check_GPUIndirectDrawCommand(value))
        var copies : array<SDL_GPUIndirectDrawCommand>
        push(copies,value)
        verify(SDLTest_check_GPUIndirectDrawCommand(copies[0]))
    }
    {
        var value : SDL_GPUIndexedIndirectDrawCommand
        SDLTest_fill_GPUIndexedIndirectDrawCommand(value)
        verify(value.num_indices == 12u)
        verify(value.num_instances == 3u)
        verify(value.first_index == 24u)
        verify(value.vertex_offset == -37)
        verify(value.first_instance == 5u)
        value.num_indices = 2147483653u
        value.num_instances = 2147483653u
        value.first_index = 2147483653u
        value.vertex_offset = -123
        value.first_instance = 2147483653u
        verify(SDLTest_check_GPUIndexedIndirectDrawCommand(value))
        var copies : array<SDL_GPUIndexedIndirectDrawCommand>
        push(copies,value)
        verify(SDLTest_check_GPUIndexedIndirectDrawCommand(copies[0]))
    }
    {
        var value : SDL_GPUIndirectDispatchCommand
        SDLTest_fill_GPUIndirectDispatchCommand(value)
        verify(value.groupcount_x == 11u)
        verify(value.groupcount_y == 13u)
        verify(value.groupcount_z == 17u)
        value.groupcount_x = 2147483653u
        value.groupcount_y = 2147483653u
        value.groupcount_z = 2147483653u
        verify(SDLTest_check_GPUIndirectDispatchCommand(value))
        var copies : array<SDL_GPUIndirectDispatchCommand>
        push(copies,value)
        verify(SDLTest_check_GPUIndirectDispatchCommand(copies[0]))
    }
    {
        var value : SDL_GPUBufferCreateInfo
        SDLTest_fill_GPUBufferCreateInfo(value)
        verify(value.usage == SDL_GPU_BUFFERUSAGE_INDIRECT)
        verify(value.size == 4096u)
        verify(value.props == 0u)
        value.usage = 2147483653u
        value.size = 2147483653u
        value.props = 2147483653u
        verify(SDLTest_check_GPUBufferCreateInfo(value))
        var copies : array<SDL_GPUBufferCreateInfo>
        push(copies,value)
        verify(SDLTest_check_GPUBufferCreateInfo(copies[0]))
    }
    {
        var value : SDL_GPUTextureCreateInfo
        SDLTest_fill_GPUTextureCreateInfo(value)
        verify(value.texture_type == SDL_GPUTextureType.TEXTURETYPE_2D_ARRAY)
        verify(value.format == SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
        verify(value.usage == SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)
        verify(value.width == 64u)
        verify(value.height == 32u)
        verify(value.layer_count_or_depth == 6u)
        verify(value.num_levels == 3u)
        verify(value.sample_count == SDL_GPUSampleCount.SAMPLECOUNT_4)
        verify(value.props == 0u)
        value.texture_type = SDL_GPUTextureType.TEXTURETYPE_2D
        value.format = SDL_GPUTextureFormat.TEXTUREFORMAT_INVALID
        value.usage = 2147483653u
        value.width = 2147483653u
        value.height = 2147483653u
        value.layer_count_or_depth = 2147483653u
        value.num_levels = 2147483653u
        value.sample_count = SDL_GPUSampleCount.SAMPLECOUNT_1
        value.props = 2147483653u
        verify(SDLTest_check_GPUTextureCreateInfo(value))
        var copies : array<SDL_GPUTextureCreateInfo>
        push(copies,value)
        verify(SDLTest_check_GPUTextureCreateInfo(copies[0]))
    }
    {
        var value : SDL_GPUVertexBufferDescription
        SDLTest_fill_GPUVertexBufferDescription(value)
        verify(value.slot == 2u)
        verify(value.pitch == 48u)
        verify(value.input_rate == SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE)
        verify(value.instance_step_rate == 0u)
        value.slot = 2147483653u
        value.pitch = 2147483653u
        value.input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX
        value.instance_step_rate = 2147483653u
        verify(SDLTest_check_GPUVertexBufferDescription(value))
        var copies : array<SDL_GPUVertexBufferDescription>
        push(copies,value)
        verify(SDLTest_check_GPUVertexBufferDescription(copies[0]))
    }
    {
        var value : SDL_GPUVertexAttribute
        SDLTest_fill_GPUVertexAttribute(value)
        verify(value.location == 3u)
        verify(value.buffer_slot == 2u)
        verify(value.format == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3)
        verify(value.offset == 12u)
        value.location = 2147483653u
        value.buffer_slot = 2147483653u
        value.format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_INVALID
        value.offset = 2147483653u
        verify(SDLTest_check_GPUVertexAttribute(value))
        var copies : array<SDL_GPUVertexAttribute>
        push(copies,value)
        verify(SDLTest_check_GPUVertexAttribute(copies[0]))
    }
    {
        var value : SDL_GPURasterizerState
        SDLTest_fill_GPURasterizerState(value)
        verify(value.fill_mode == SDL_GPUFillMode.FILLMODE_LINE)
        verify(value.cull_mode == SDL_GPUCullMode.CULLMODE_BACK)
        verify(value.front_face == SDL_GPUFrontFace.FRONTFACE_CLOCKWISE)
        verify(value.depth_bias_constant_factor == -2.25)
        verify(value.depth_bias_clamp == 0.5)
        verify(value.depth_bias_slope_factor == 3.75)
        verify(value.enable_depth_bias == true)
        verify(value.enable_depth_clip == false)
        value.fill_mode = SDL_GPUFillMode.FILLMODE_FILL
        value.cull_mode = SDL_GPUCullMode.CULLMODE_NONE
        value.front_face = SDL_GPUFrontFace.FRONTFACE_COUNTER_CLOCKWISE
        value.depth_bias_constant_factor = 23.5
        value.depth_bias_clamp = 23.5
        value.depth_bias_slope_factor = 23.5
        value.enable_depth_bias = false
        value.enable_depth_clip = true
        verify(SDLTest_check_GPURasterizerState(value))
        var copies : array<SDL_GPURasterizerState>
        push(copies,value)
        verify(SDLTest_check_GPURasterizerState(copies[0]))
    }
    {
        var value : SDL_GPUMultisampleState
        SDLTest_fill_GPUMultisampleState(value)
        verify(value.sample_count == SDL_GPUSampleCount.SAMPLECOUNT_8)
        verify(value.sample_mask == 0u)
        verify(value.enable_mask == false)
        value.sample_count = SDL_GPUSampleCount.SAMPLECOUNT_1
        value.sample_mask = 2147483653u
        value.enable_mask = true
        verify(SDLTest_check_GPUMultisampleState(value))
        var copies : array<SDL_GPUMultisampleState>
        push(copies,value)
        verify(SDLTest_check_GPUMultisampleState(copies[0]))
    }
    verify(SDLTest_echo_SDL_GPUTextureType(SDL_GPUTextureType.TEXTURETYPE_2D) == SDL_GPUTextureType.TEXTURETYPE_2D)
    verify(uint(SDL_GPUTextureType.TEXTURETYPE_2D) == SDL_GPU_TEXTURETYPE_2D)
    verify(SDLTest_echo_SDL_GPUTextureType(SDL_GPUTextureType.TEXTURETYPE_2D_ARRAY) == SDL_GPUTextureType.TEXTURETYPE_2D_ARRAY)
    verify(uint(SDL_GPUTextureType.TEXTURETYPE_2D_ARRAY) == SDL_GPU_TEXTURETYPE_2D_ARRAY)
    verify(SDLTest_echo_SDL_GPUTextureType(SDL_GPUTextureType.TEXTURETYPE_3D) == SDL_GPUTextureType.TEXTURETYPE_3D)
    verify(uint(SDL_GPUTextureType.TEXTURETYPE_3D) == SDL_GPU_TEXTURETYPE_3D)
    verify(SDLTest_echo_SDL_GPUTextureType(SDL_GPUTextureType.TEXTURETYPE_CUBE) == SDL_GPUTextureType.TEXTURETYPE_CUBE)
    verify(uint(SDL_GPUTextureType.TEXTURETYPE_CUBE) == SDL_GPU_TEXTURETYPE_CUBE)
    verify(SDLTest_echo_SDL_GPUTextureType(SDL_GPUTextureType.TEXTURETYPE_CUBE_ARRAY) == SDL_GPUTextureType.TEXTURETYPE_CUBE_ARRAY)
    verify(uint(SDL_GPUTextureType.TEXTURETYPE_CUBE_ARRAY) == SDL_GPU_TEXTURETYPE_CUBE_ARRAY)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_INVALID) == SDL_GPUTextureFormat.TEXTUREFORMAT_INVALID)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_INVALID) == SDL_GPU_TEXTUREFORMAT_INVALID)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_A8_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_A8_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_A8_UNORM) == SDL_GPU_TEXTUREFORMAT_A8_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8_UNORM) == SDL_GPU_TEXTUREFORMAT_R8_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_UNORM) == SDL_GPU_TEXTUREFORMAT_R8G8_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) == SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16_UNORM) == SDL_GPU_TEXTUREFORMAT_R16_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_UNORM) == SDL_GPU_TEXTUREFORMAT_R16G16_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_UNORM) == SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R10G10B10A2_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R10G10B10A2_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R10G10B10A2_UNORM) == SDL_GPU_TEXTUREFORMAT_R10G10B10A2_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_B5G6R5_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_B5G6R5_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_B5G6R5_UNORM) == SDL_GPU_TEXTUREFORMAT_B5G6R5_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_B5G5R5A1_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_B5G5R5A1_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_B5G5R5A1_UNORM) == SDL_GPU_TEXTUREFORMAT_B5G5R5A1_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_B4G4R4A4_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_B4G4R4A4_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_B4G4R4A4_UNORM) == SDL_GPU_TEXTUREFORMAT_B4G4R4A4_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_B8G8R8A8_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_B8G8R8A8_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_B8G8R8A8_UNORM) == SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC1_RGBA_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC1_RGBA_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC1_RGBA_UNORM) == SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC2_RGBA_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC2_RGBA_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC2_RGBA_UNORM) == SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC3_RGBA_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC3_RGBA_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC3_RGBA_UNORM) == SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC4_R_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC4_R_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC4_R_UNORM) == SDL_GPU_TEXTUREFORMAT_BC4_R_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC5_RG_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC5_RG_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC5_RG_UNORM) == SDL_GPU_TEXTUREFORMAT_BC5_RG_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC7_RGBA_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC7_RGBA_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC7_RGBA_UNORM) == SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC6H_RGB_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC6H_RGB_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC6H_RGB_FLOAT) == SDL_GPU_TEXTUREFORMAT_BC6H_RGB_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC6H_RGB_UFLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC6H_RGB_UFLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC6H_RGB_UFLOAT) == SDL_GPU_TEXTUREFORMAT_BC6H_RGB_UFLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8_SNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8_SNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8_SNORM) == SDL_GPU_TEXTUREFORMAT_R8_SNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_SNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_SNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_SNORM) == SDL_GPU_TEXTUREFORMAT_R8G8_SNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_SNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_SNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_SNORM) == SDL_GPU_TEXTUREFORMAT_R8G8B8A8_SNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16_SNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16_SNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16_SNORM) == SDL_GPU_TEXTUREFORMAT_R16_SNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_SNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_SNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_SNORM) == SDL_GPU_TEXTUREFORMAT_R16G16_SNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_SNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_SNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_SNORM) == SDL_GPU_TEXTUREFORMAT_R16G16B16A16_SNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16_FLOAT) == SDL_GPU_TEXTUREFORMAT_R16_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_FLOAT) == SDL_GPU_TEXTUREFORMAT_R16G16_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT) == SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R32_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R32_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R32_FLOAT) == SDL_GPU_TEXTUREFORMAT_R32_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32_FLOAT) == SDL_GPU_TEXTUREFORMAT_R32G32_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32B32A32_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32B32A32_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32B32A32_FLOAT) == SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R11G11B10_UFLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R11G11B10_UFLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R11G11B10_UFLOAT) == SDL_GPU_TEXTUREFORMAT_R11G11B10_UFLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8_UINT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8_UINT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8_UINT) == SDL_GPU_TEXTUREFORMAT_R8_UINT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_UINT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_UINT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_UINT) == SDL_GPU_TEXTUREFORMAT_R8G8_UINT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UINT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UINT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UINT) == SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UINT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16_UINT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16_UINT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16_UINT) == SDL_GPU_TEXTUREFORMAT_R16_UINT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_UINT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_UINT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_UINT) == SDL_GPU_TEXTUREFORMAT_R16G16_UINT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_UINT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_UINT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_UINT) == SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UINT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R32_UINT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R32_UINT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R32_UINT) == SDL_GPU_TEXTUREFORMAT_R32_UINT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32_UINT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32_UINT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32_UINT) == SDL_GPU_TEXTUREFORMAT_R32G32_UINT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32B32A32_UINT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32B32A32_UINT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32B32A32_UINT) == SDL_GPU_TEXTUREFORMAT_R32G32B32A32_UINT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8_INT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8_INT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8_INT) == SDL_GPU_TEXTUREFORMAT_R8_INT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_INT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_INT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8_INT) == SDL_GPU_TEXTUREFORMAT_R8G8_INT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_INT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_INT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_INT) == SDL_GPU_TEXTUREFORMAT_R8G8B8A8_INT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16_INT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16_INT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16_INT) == SDL_GPU_TEXTUREFORMAT_R16_INT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_INT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_INT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16_INT) == SDL_GPU_TEXTUREFORMAT_R16G16_INT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_INT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_INT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_INT) == SDL_GPU_TEXTUREFORMAT_R16G16B16A16_INT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R32_INT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R32_INT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R32_INT) == SDL_GPU_TEXTUREFORMAT_R32_INT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32_INT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32_INT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32_INT) == SDL_GPU_TEXTUREFORMAT_R32G32_INT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32B32A32_INT) == SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32B32A32_INT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32B32A32_INT) == SDL_GPU_TEXTUREFORMAT_R32G32B32A32_INT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC1_RGBA_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC1_RGBA_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC1_RGBA_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC2_RGBA_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC2_RGBA_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC2_RGBA_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC3_RGBA_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC3_RGBA_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC3_RGBA_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_D16_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_D16_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_D16_UNORM) == SDL_GPU_TEXTUREFORMAT_D16_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM) == SDL_GPU_TEXTUREFORMAT_D24_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) == SDL_GPU_TEXTUREFORMAT_D32_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM_S8_UINT) == SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM_S8_UINT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM_S8_UINT) == SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT_S8_UINT) == SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT_S8_UINT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT_S8_UINT) == SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_4x4_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_4x4_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_4x4_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x4_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x4_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x4_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x5_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x5_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x5_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_5x5_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x5_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x5_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x5_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_6x5_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x6_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x6_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x6_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_6x6_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x5_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x5_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x5_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_8x5_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x6_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x6_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x6_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_8x6_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x8_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x8_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x8_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_8x8_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x5_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x5_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x5_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_10x5_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x6_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x6_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x6_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_10x6_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x8_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x8_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x8_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_10x8_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x10_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x10_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x10_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_10x10_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x10_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x10_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x10_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_12x10_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x12_UNORM) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x12_UNORM)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x12_UNORM) == SDL_GPU_TEXTUREFORMAT_ASTC_12x12_UNORM)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_4x4_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_4x4_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_4x4_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x4_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x4_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x4_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x5_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x5_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x5_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_5x5_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x5_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x5_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x5_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_6x5_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x6_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x6_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x6_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_6x6_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x5_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x5_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x5_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_8x5_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x6_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x6_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x6_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_8x6_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x8_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x8_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x8_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_8x8_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x5_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x5_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x5_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_10x5_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x6_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x6_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x6_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_10x6_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x8_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x8_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x8_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_10x8_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x10_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x10_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x10_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_10x10_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x10_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x10_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x10_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_12x10_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x12_UNORM_SRGB) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x12_UNORM_SRGB)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x12_UNORM_SRGB) == SDL_GPU_TEXTUREFORMAT_ASTC_12x12_UNORM_SRGB)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_4x4_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_4x4_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_4x4_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_4x4_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x4_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x4_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x4_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_5x4_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x5_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x5_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_5x5_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_5x5_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x5_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x5_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x5_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_6x5_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x6_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x6_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_6x6_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_6x6_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x5_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x5_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x5_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_8x5_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x6_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x6_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x6_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_8x6_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x8_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x8_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_8x8_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_8x8_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x5_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x5_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x5_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_10x5_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x6_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x6_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x6_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_10x6_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x8_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x8_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x8_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_10x8_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x10_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x10_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_10x10_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_10x10_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x10_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x10_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x10_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_12x10_FLOAT)
    verify(SDLTest_echo_SDL_GPUTextureFormat(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x12_FLOAT) == SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x12_FLOAT)
    verify(uint(SDL_GPUTextureFormat.TEXTUREFORMAT_ASTC_12x12_FLOAT) == SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT)
    verify(SDLTest_echo_SDL_GPUSampleCount(SDL_GPUSampleCount.SAMPLECOUNT_1) == SDL_GPUSampleCount.SAMPLECOUNT_1)
    verify(uint(SDL_GPUSampleCount.SAMPLECOUNT_1) == SDL_GPU_SAMPLECOUNT_1)
    verify(SDLTest_echo_SDL_GPUSampleCount(SDL_GPUSampleCount.SAMPLECOUNT_2) == SDL_GPUSampleCount.SAMPLECOUNT_2)
    verify(uint(SDL_GPUSampleCount.SAMPLECOUNT_2) == SDL_GPU_SAMPLECOUNT_2)
    verify(SDLTest_echo_SDL_GPUSampleCount(SDL_GPUSampleCount.SAMPLECOUNT_4) == SDL_GPUSampleCount.SAMPLECOUNT_4)
    verify(uint(SDL_GPUSampleCount.SAMPLECOUNT_4) == SDL_GPU_SAMPLECOUNT_4)
    verify(SDLTest_echo_SDL_GPUSampleCount(SDL_GPUSampleCount.SAMPLECOUNT_8) == SDL_GPUSampleCount.SAMPLECOUNT_8)
    verify(uint(SDL_GPUSampleCount.SAMPLECOUNT_8) == SDL_GPU_SAMPLECOUNT_8)
    verify(SDLTest_echo_SDL_GPUVertexInputRate(SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX) == SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX)
    verify(SDLTest_echo_SDL_GPUVertexInputRate(SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE) == SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_INVALID) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_INVALID)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_INT) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_INT)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_INT2) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_INT2)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_INT3) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_INT3)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_INT4) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_INT4)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UINT) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UINT)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UINT2) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UINT2)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UINT3) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UINT3)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UINT4) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UINT4)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_BYTE2) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_BYTE2)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_BYTE4) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_BYTE4)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UBYTE2) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UBYTE2)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UBYTE4) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UBYTE4)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_BYTE2_NORM) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_BYTE2_NORM)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_BYTE4_NORM) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_BYTE4_NORM)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UBYTE2_NORM) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UBYTE2_NORM)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UBYTE4_NORM) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UBYTE4_NORM)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_SHORT2) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_SHORT2)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_SHORT4) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_SHORT4)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_USHORT2) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_USHORT2)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_USHORT4) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_USHORT4)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_SHORT2_NORM) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_SHORT2_NORM)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_SHORT4_NORM) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_SHORT4_NORM)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_USHORT2_NORM) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_USHORT2_NORM)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_USHORT4_NORM) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_USHORT4_NORM)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_HALF2) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_HALF2)
    verify(SDLTest_echo_SDL_GPUVertexElementFormat(SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_HALF4) == SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_HALF4)
    verify(SDLTest_echo_SDL_GPUFillMode(SDL_GPUFillMode.FILLMODE_FILL) == SDL_GPUFillMode.FILLMODE_FILL)
    verify(SDLTest_echo_SDL_GPUFillMode(SDL_GPUFillMode.FILLMODE_LINE) == SDL_GPUFillMode.FILLMODE_LINE)
    verify(SDLTest_echo_SDL_GPUCullMode(SDL_GPUCullMode.CULLMODE_NONE) == SDL_GPUCullMode.CULLMODE_NONE)
    verify(SDLTest_echo_SDL_GPUCullMode(SDL_GPUCullMode.CULLMODE_FRONT) == SDL_GPUCullMode.CULLMODE_FRONT)
    verify(SDLTest_echo_SDL_GPUCullMode(SDL_GPUCullMode.CULLMODE_BACK) == SDL_GPUCullMode.CULLMODE_BACK)
    verify(SDLTest_echo_SDL_GPUFrontFace(SDL_GPUFrontFace.FRONTFACE_COUNTER_CLOCKWISE) == SDL_GPUFrontFace.FRONTFACE_COUNTER_CLOCKWISE)
    verify(SDLTest_echo_SDL_GPUFrontFace(SDL_GPUFrontFace.FRONTFACE_CLOCKWISE) == SDL_GPUFrontFace.FRONTFACE_CLOCKWISE)
    print("GPU POD/native field and typed enum roundtrips PASS\n")
    return 0
}
