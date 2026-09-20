addAnnotation(new DummyTypeAnnotation("SDL_Window", "SDL_Window", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Renderer", "SDL_Renderer", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Surface", "SDL_Surface", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Texture", "SDL_Texture", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_AudioStream", "SDL_AudioStream", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Wav", "SDL_Wav", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUDevice", "SDL_GPUDevice", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUSampler", "SDL_GPUSampler", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUCommandBuffer", "SDL_GPUCommandBuffer", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUFence", "SDL_GPUFence", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUBuffer", "SDL_GPUBuffer", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUTransferBuffer", "SDL_GPUTransferBuffer", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUTexture", "SDL_GPUTexture", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUShader", "SDL_GPUShader", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUComputePipeline", "SDL_GPUComputePipeline", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUGraphicsPipeline", "SDL_GPUGraphicsPipeline", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPURenderPass", "SDL_GPURenderPass", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUComputePass", "SDL_GPUComputePass", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_GPUCopyPass", "SDL_GPUCopyPass", 1, 1));
addAnnotation(new SDL_AudioSpecAnnotation(lib));
addAnnotation(new SDL_FColorAnnotation(lib));
addAnnotation(new SDL_FPointAnnotation(lib));
addAnnotation(new SDL_RectAnnotation(lib));
addAnnotation(new SDL_FRectAnnotation(lib));
addEnumeration(new Enumeration_SDL_FlipMode());
addAnnotation(new SDL_KeyboardEventAnnotation(lib));
addAnnotation(new SDL_MouseMotionEventAnnotation(lib));
addAnnotation(new SDL_MouseButtonEventAnnotation(lib));
addAnnotation(new SDL_MouseWheelEventAnnotation(lib));
addAnnotation(new SDL_EventAnnotation(lib));
addEnumeration(new Enumeration_SDL_GPUPrimitiveType());
addEnumeration(new Enumeration_SDL_GPULoadOp());
addEnumeration(new Enumeration_SDL_GPUStoreOp());
addEnumeration(new Enumeration_SDL_GPUIndexElementSize());
addEnumeration(new Enumeration_SDL_GPUTextureFormat());
addEnumeration(new Enumeration_SDL_GPUTextureType());
addEnumeration(new Enumeration_SDL_GPUSampleCount());
addEnumeration(new Enumeration_SDL_GPUCubeMapFace());
addEnumeration(new Enumeration_SDL_GPUTransferBufferUsage());
addEnumeration(new Enumeration_SDL_GPUShaderStage());
addEnumeration(new Enumeration_SDL_GPUVertexElementFormat());
addEnumeration(new Enumeration_SDL_GPUVertexInputRate());
addEnumeration(new Enumeration_SDL_GPUFillMode());
addEnumeration(new Enumeration_SDL_GPUCullMode());
addEnumeration(new Enumeration_SDL_GPUFrontFace());
addEnumeration(new Enumeration_SDL_GPUCompareOp());
addEnumeration(new Enumeration_SDL_GPUStencilOp());
addEnumeration(new Enumeration_SDL_GPUBlendOp());
addEnumeration(new Enumeration_SDL_GPUBlendFactor());
addEnumeration(new Enumeration_SDL_GPUFilter());
addEnumeration(new Enumeration_SDL_GPUSamplerMipmapMode());
addEnumeration(new Enumeration_SDL_GPUSamplerAddressMode());
addEnumeration(new Enumeration_SDL_GPUPresentMode());
addEnumeration(new Enumeration_SDL_GPUSwapchainComposition());
addAnnotation(new SDL_GPUViewportAnnotation(lib));
addAnnotation(new SDL_GPUTextureTransferInfoAnnotation(lib));
addAnnotation(new SDL_GPUTransferBufferLocationAnnotation(lib));
addAnnotation(new SDL_GPUTextureLocationAnnotation(lib));
addAnnotation(new SDL_GPUTextureRegionAnnotation(lib));
addAnnotation(new SDL_GPUBlitRegionAnnotation(lib));
addAnnotation(new SDL_GPUBufferLocationAnnotation(lib));
addAnnotation(new SDL_GPUBufferRegionAnnotation(lib));
addAnnotation(new SDL_GPUIndirectDrawCommandAnnotation(lib));
addAnnotation(new SDL_GPUIndexedIndirectDrawCommandAnnotation(lib));
addAnnotation(new SDL_GPUIndirectDispatchCommandAnnotation(lib));
addAnnotation(new SDL_GPUSamplerCreateInfoAnnotation(lib));
addAnnotation(new SDL_GPUVertexBufferDescriptionAnnotation(lib));
addAnnotation(new SDL_GPUVertexAttributeAnnotation(lib));
addAnnotation(new SDL_GPUVertexInputStateAnnotation(lib));
addAnnotation(new SDL_GPUStencilOpStateAnnotation(lib));
addAnnotation(new SDL_GPUColorTargetBlendStateAnnotation(lib));
addAnnotation(new SDL_GPUShaderCreateInfoAnnotation(lib));
addAnnotation(new SDL_GPUTextureCreateInfoAnnotation(lib));
addAnnotation(new SDL_GPUBufferCreateInfoAnnotation(lib));
addAnnotation(new SDL_GPUTransferBufferCreateInfoAnnotation(lib));
addAnnotation(new SDL_GPURasterizerStateAnnotation(lib));
addAnnotation(new SDL_GPUMultisampleStateAnnotation(lib));
addAnnotation(new SDL_GPUDepthStencilStateAnnotation(lib));
addAnnotation(new SDL_GPUColorTargetDescriptionAnnotation(lib));
addAnnotation(new SDL_GPUGraphicsPipelineTargetInfoAnnotation(lib));
addAnnotation(new SDL_GPUGraphicsPipelineCreateInfoAnnotation(lib));
addAnnotation(new SDL_GPUComputePipelineCreateInfoAnnotation(lib));
addAnnotation(new SDL_GPUColorTargetInfoAnnotation(lib));
addAnnotation(new SDL_GPUDepthStencilTargetInfoAnnotation(lib));
addAnnotation(new SDL_GPUBlitInfoAnnotation(lib));
addAnnotation(new SDL_GPUBufferBindingAnnotation(lib));
addAnnotation(new SDL_GPUTextureSamplerBindingAnnotation(lib));
addAnnotation(new SDL_GPUStorageBufferReadWriteBindingAnnotation(lib));
addAnnotation(new SDL_GPUStorageTextureReadWriteBindingAnnotation(lib));
addAnnotation(new SDL_VertexAnnotation(lib));
static_assert(static_cast<uint32_t>(SDL_GPU_FILTER_NEAREST) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDL_GPU_FILTER_NEAREST", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_FILTER_LINEAR) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_GPU_FILTER_LINEAR", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_PRESENTMODE_VSYNC) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDL_GPU_PRESENTMODE_VSYNC", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_PRESENTMODE_IMMEDIATE) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_GPU_PRESENTMODE_IMMEDIATE", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_PRESENTMODE_MAILBOX) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_GPU_PRESENTMODE_MAILBOX", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SWAPCHAINCOMPOSITION_SDR) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDL_GPU_SWAPCHAINCOMPOSITION_SDR", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SWAPCHAINCOMPOSITION_SDR_LINEAR) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_GPU_SWAPCHAINCOMPOSITION_SDR_LINEAR", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_GPU_SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084) == static_cast<uint32_t>(0x3ULL));
addConstant(*this, "SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084", static_cast<uint32_t>(0x3ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_INVALID) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_INVALID", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_A8_UNORM) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_A8_UNORM", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8_UNORM) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8_UNORM", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8G8_UNORM) == static_cast<uint32_t>(0x3ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8G8_UNORM", static_cast<uint32_t>(0x3ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16_UNORM) == static_cast<uint32_t>(0x5ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16_UNORM", static_cast<uint32_t>(0x5ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16G16_UNORM) == static_cast<uint32_t>(0x6ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16G16_UNORM", static_cast<uint32_t>(0x6ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UNORM) == static_cast<uint32_t>(0x7ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UNORM", static_cast<uint32_t>(0x7ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R10G10B10A2_UNORM) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R10G10B10A2_UNORM", static_cast<uint32_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_B5G6R5_UNORM) == static_cast<uint32_t>(0x9ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_B5G6R5_UNORM", static_cast<uint32_t>(0x9ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_B5G5R5A1_UNORM) == static_cast<uint32_t>(0xaULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_B5G5R5A1_UNORM", static_cast<uint32_t>(0xaULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_B4G4R4A4_UNORM) == static_cast<uint32_t>(0xbULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_B4G4R4A4_UNORM", static_cast<uint32_t>(0xbULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM) == static_cast<uint32_t>(0xcULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM", static_cast<uint32_t>(0xcULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM) == static_cast<uint32_t>(0xdULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM", static_cast<uint32_t>(0xdULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM) == static_cast<uint32_t>(0xeULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM", static_cast<uint32_t>(0xeULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM) == static_cast<uint32_t>(0xfULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM", static_cast<uint32_t>(0xfULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC4_R_UNORM) == static_cast<uint32_t>(0x10ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC4_R_UNORM", static_cast<uint32_t>(0x10ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC5_RG_UNORM) == static_cast<uint32_t>(0x11ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC5_RG_UNORM", static_cast<uint32_t>(0x11ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM) == static_cast<uint32_t>(0x12ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM", static_cast<uint32_t>(0x12ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC6H_RGB_FLOAT) == static_cast<uint32_t>(0x13ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC6H_RGB_FLOAT", static_cast<uint32_t>(0x13ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC6H_RGB_UFLOAT) == static_cast<uint32_t>(0x14ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC6H_RGB_UFLOAT", static_cast<uint32_t>(0x14ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8_SNORM) == static_cast<uint32_t>(0x15ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8_SNORM", static_cast<uint32_t>(0x15ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8G8_SNORM) == static_cast<uint32_t>(0x16ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8G8_SNORM", static_cast<uint32_t>(0x16ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8G8B8A8_SNORM) == static_cast<uint32_t>(0x17ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8G8B8A8_SNORM", static_cast<uint32_t>(0x17ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16_SNORM) == static_cast<uint32_t>(0x18ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16_SNORM", static_cast<uint32_t>(0x18ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16G16_SNORM) == static_cast<uint32_t>(0x19ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16G16_SNORM", static_cast<uint32_t>(0x19ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16G16B16A16_SNORM) == static_cast<uint32_t>(0x1aULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16G16B16A16_SNORM", static_cast<uint32_t>(0x1aULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16_FLOAT) == static_cast<uint32_t>(0x1bULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16_FLOAT", static_cast<uint32_t>(0x1bULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16G16_FLOAT) == static_cast<uint32_t>(0x1cULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16G16_FLOAT", static_cast<uint32_t>(0x1cULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT) == static_cast<uint32_t>(0x1dULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT", static_cast<uint32_t>(0x1dULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R32_FLOAT) == static_cast<uint32_t>(0x1eULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R32_FLOAT", static_cast<uint32_t>(0x1eULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R32G32_FLOAT) == static_cast<uint32_t>(0x1fULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R32G32_FLOAT", static_cast<uint32_t>(0x1fULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT) == static_cast<uint32_t>(0x20ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT", static_cast<uint32_t>(0x20ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R11G11B10_UFLOAT) == static_cast<uint32_t>(0x21ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R11G11B10_UFLOAT", static_cast<uint32_t>(0x21ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8_UINT) == static_cast<uint32_t>(0x22ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8_UINT", static_cast<uint32_t>(0x22ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8G8_UINT) == static_cast<uint32_t>(0x23ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8G8_UINT", static_cast<uint32_t>(0x23ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UINT) == static_cast<uint32_t>(0x24ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UINT", static_cast<uint32_t>(0x24ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16_UINT) == static_cast<uint32_t>(0x25ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16_UINT", static_cast<uint32_t>(0x25ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16G16_UINT) == static_cast<uint32_t>(0x26ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16G16_UINT", static_cast<uint32_t>(0x26ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UINT) == static_cast<uint32_t>(0x27ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UINT", static_cast<uint32_t>(0x27ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R32_UINT) == static_cast<uint32_t>(0x28ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R32_UINT", static_cast<uint32_t>(0x28ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R32G32_UINT) == static_cast<uint32_t>(0x29ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R32G32_UINT", static_cast<uint32_t>(0x29ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R32G32B32A32_UINT) == static_cast<uint32_t>(0x2aULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R32G32B32A32_UINT", static_cast<uint32_t>(0x2aULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8_INT) == static_cast<uint32_t>(0x2bULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8_INT", static_cast<uint32_t>(0x2bULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8G8_INT) == static_cast<uint32_t>(0x2cULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8G8_INT", static_cast<uint32_t>(0x2cULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8G8B8A8_INT) == static_cast<uint32_t>(0x2dULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8G8B8A8_INT", static_cast<uint32_t>(0x2dULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16_INT) == static_cast<uint32_t>(0x2eULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16_INT", static_cast<uint32_t>(0x2eULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16G16_INT) == static_cast<uint32_t>(0x2fULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16G16_INT", static_cast<uint32_t>(0x2fULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R16G16B16A16_INT) == static_cast<uint32_t>(0x30ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R16G16B16A16_INT", static_cast<uint32_t>(0x30ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R32_INT) == static_cast<uint32_t>(0x31ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R32_INT", static_cast<uint32_t>(0x31ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R32G32_INT) == static_cast<uint32_t>(0x32ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R32G32_INT", static_cast<uint32_t>(0x32ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R32G32B32A32_INT) == static_cast<uint32_t>(0x33ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R32G32B32A32_INT", static_cast<uint32_t>(0x33ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB) == static_cast<uint32_t>(0x34ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB", static_cast<uint32_t>(0x34ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB) == static_cast<uint32_t>(0x35ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB", static_cast<uint32_t>(0x35ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM_SRGB) == static_cast<uint32_t>(0x36ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM_SRGB", static_cast<uint32_t>(0x36ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM_SRGB) == static_cast<uint32_t>(0x37ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM_SRGB", static_cast<uint32_t>(0x37ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM_SRGB) == static_cast<uint32_t>(0x38ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM_SRGB", static_cast<uint32_t>(0x38ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB) == static_cast<uint32_t>(0x39ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB", static_cast<uint32_t>(0x39ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_D16_UNORM) == static_cast<uint32_t>(0x3aULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_D16_UNORM", static_cast<uint32_t>(0x3aULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_D24_UNORM) == static_cast<uint32_t>(0x3bULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_D24_UNORM", static_cast<uint32_t>(0x3bULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_D32_FLOAT) == static_cast<uint32_t>(0x3cULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_D32_FLOAT", static_cast<uint32_t>(0x3cULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT) == static_cast<uint32_t>(0x3dULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT", static_cast<uint32_t>(0x3dULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT) == static_cast<uint32_t>(0x3eULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT", static_cast<uint32_t>(0x3eULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM) == static_cast<uint32_t>(0x3fULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM", static_cast<uint32_t>(0x3fULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM) == static_cast<uint32_t>(0x40ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM", static_cast<uint32_t>(0x40ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_5x5_UNORM) == static_cast<uint32_t>(0x41ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_5x5_UNORM", static_cast<uint32_t>(0x41ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_6x5_UNORM) == static_cast<uint32_t>(0x42ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_6x5_UNORM", static_cast<uint32_t>(0x42ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_6x6_UNORM) == static_cast<uint32_t>(0x43ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_6x6_UNORM", static_cast<uint32_t>(0x43ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_8x5_UNORM) == static_cast<uint32_t>(0x44ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_8x5_UNORM", static_cast<uint32_t>(0x44ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_8x6_UNORM) == static_cast<uint32_t>(0x45ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_8x6_UNORM", static_cast<uint32_t>(0x45ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_8x8_UNORM) == static_cast<uint32_t>(0x46ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_8x8_UNORM", static_cast<uint32_t>(0x46ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x5_UNORM) == static_cast<uint32_t>(0x47ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x5_UNORM", static_cast<uint32_t>(0x47ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x6_UNORM) == static_cast<uint32_t>(0x48ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x6_UNORM", static_cast<uint32_t>(0x48ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x8_UNORM) == static_cast<uint32_t>(0x49ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x8_UNORM", static_cast<uint32_t>(0x49ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x10_UNORM) == static_cast<uint32_t>(0x4aULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x10_UNORM", static_cast<uint32_t>(0x4aULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_12x10_UNORM) == static_cast<uint32_t>(0x4bULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_12x10_UNORM", static_cast<uint32_t>(0x4bULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_12x12_UNORM) == static_cast<uint32_t>(0x4cULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_12x12_UNORM", static_cast<uint32_t>(0x4cULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM_SRGB) == static_cast<uint32_t>(0x4dULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM_SRGB", static_cast<uint32_t>(0x4dULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM_SRGB) == static_cast<uint32_t>(0x4eULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM_SRGB", static_cast<uint32_t>(0x4eULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_5x5_UNORM_SRGB) == static_cast<uint32_t>(0x4fULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_5x5_UNORM_SRGB", static_cast<uint32_t>(0x4fULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_6x5_UNORM_SRGB) == static_cast<uint32_t>(0x50ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_6x5_UNORM_SRGB", static_cast<uint32_t>(0x50ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_6x6_UNORM_SRGB) == static_cast<uint32_t>(0x51ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_6x6_UNORM_SRGB", static_cast<uint32_t>(0x51ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_8x5_UNORM_SRGB) == static_cast<uint32_t>(0x52ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_8x5_UNORM_SRGB", static_cast<uint32_t>(0x52ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_8x6_UNORM_SRGB) == static_cast<uint32_t>(0x53ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_8x6_UNORM_SRGB", static_cast<uint32_t>(0x53ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_8x8_UNORM_SRGB) == static_cast<uint32_t>(0x54ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_8x8_UNORM_SRGB", static_cast<uint32_t>(0x54ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x5_UNORM_SRGB) == static_cast<uint32_t>(0x55ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x5_UNORM_SRGB", static_cast<uint32_t>(0x55ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x6_UNORM_SRGB) == static_cast<uint32_t>(0x56ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x6_UNORM_SRGB", static_cast<uint32_t>(0x56ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x8_UNORM_SRGB) == static_cast<uint32_t>(0x57ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x8_UNORM_SRGB", static_cast<uint32_t>(0x57ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x10_UNORM_SRGB) == static_cast<uint32_t>(0x58ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x10_UNORM_SRGB", static_cast<uint32_t>(0x58ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_12x10_UNORM_SRGB) == static_cast<uint32_t>(0x59ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_12x10_UNORM_SRGB", static_cast<uint32_t>(0x59ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_12x12_UNORM_SRGB) == static_cast<uint32_t>(0x5aULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_12x12_UNORM_SRGB", static_cast<uint32_t>(0x5aULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_4x4_FLOAT) == static_cast<uint32_t>(0x5bULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_4x4_FLOAT", static_cast<uint32_t>(0x5bULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_5x4_FLOAT) == static_cast<uint32_t>(0x5cULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_5x4_FLOAT", static_cast<uint32_t>(0x5cULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_5x5_FLOAT) == static_cast<uint32_t>(0x5dULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_5x5_FLOAT", static_cast<uint32_t>(0x5dULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_6x5_FLOAT) == static_cast<uint32_t>(0x5eULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_6x5_FLOAT", static_cast<uint32_t>(0x5eULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_6x6_FLOAT) == static_cast<uint32_t>(0x5fULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_6x6_FLOAT", static_cast<uint32_t>(0x5fULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_8x5_FLOAT) == static_cast<uint32_t>(0x60ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_8x5_FLOAT", static_cast<uint32_t>(0x60ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_8x6_FLOAT) == static_cast<uint32_t>(0x61ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_8x6_FLOAT", static_cast<uint32_t>(0x61ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_8x8_FLOAT) == static_cast<uint32_t>(0x62ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_8x8_FLOAT", static_cast<uint32_t>(0x62ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x5_FLOAT) == static_cast<uint32_t>(0x63ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x5_FLOAT", static_cast<uint32_t>(0x63ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x6_FLOAT) == static_cast<uint32_t>(0x64ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x6_FLOAT", static_cast<uint32_t>(0x64ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x8_FLOAT) == static_cast<uint32_t>(0x65ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x8_FLOAT", static_cast<uint32_t>(0x65ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_10x10_FLOAT) == static_cast<uint32_t>(0x66ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_10x10_FLOAT", static_cast<uint32_t>(0x66ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_12x10_FLOAT) == static_cast<uint32_t>(0x67ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_12x10_FLOAT", static_cast<uint32_t>(0x67ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT) == static_cast<uint32_t>(0x68ULL));
addConstant(*this, "SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT", static_cast<uint32_t>(0x68ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTURETYPE_2D) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDL_GPU_TEXTURETYPE_2D", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTURETYPE_2D_ARRAY) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_GPU_TEXTURETYPE_2D_ARRAY", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTURETYPE_3D) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_GPU_TEXTURETYPE_3D", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTURETYPE_CUBE) == static_cast<uint32_t>(0x3ULL));
addConstant(*this, "SDL_GPU_TEXTURETYPE_CUBE", static_cast<uint32_t>(0x3ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTURETYPE_CUBE_ARRAY) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_GPU_TEXTURETYPE_CUBE_ARRAY", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SAMPLECOUNT_1) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDL_GPU_SAMPLECOUNT_1", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SAMPLECOUNT_2) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_GPU_SAMPLECOUNT_2", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SAMPLECOUNT_4) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_GPU_SAMPLECOUNT_4", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SAMPLECOUNT_8) == static_cast<uint32_t>(0x3ULL));
addConstant(*this, "SDL_GPU_SAMPLECOUNT_8", static_cast<uint32_t>(0x3ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREUSAGE_SAMPLER) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_GPU_TEXTUREUSAGE_SAMPLER", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_GPU_TEXTUREUSAGE_COLOR_TARGET", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ", static_cast<uint32_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ) == static_cast<uint32_t>(0x10ULL));
addConstant(*this, "SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ", static_cast<uint32_t>(0x10ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE) == static_cast<uint32_t>(0x20ULL));
addConstant(*this, "SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE", static_cast<uint32_t>(0x20ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE) == static_cast<uint32_t>(0x40ULL));
addConstant(*this, "SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE", static_cast<uint32_t>(0x40ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SHADERFORMAT_SPIRV) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_GPU_SHADERFORMAT_SPIRV", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SHADERFORMAT_DXBC) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_GPU_SHADERFORMAT_DXBC", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SHADERFORMAT_DXIL) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDL_GPU_SHADERFORMAT_DXIL", static_cast<uint32_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SHADERFORMAT_MSL) == static_cast<uint32_t>(0x10ULL));
addConstant(*this, "SDL_GPU_SHADERFORMAT_MSL", static_cast<uint32_t>(0x10ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_SHADERFORMAT_METALLIB) == static_cast<uint32_t>(0x20ULL));
addConstant(*this, "SDL_GPU_SHADERFORMAT_METALLIB", static_cast<uint32_t>(0x20ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_BUFFERUSAGE_VERTEX) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_GPU_BUFFERUSAGE_VERTEX", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_BUFFERUSAGE_INDEX) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_GPU_BUFFERUSAGE_INDEX", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_BUFFERUSAGE_INDIRECT) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_GPU_BUFFERUSAGE_INDIRECT", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ", static_cast<uint32_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ) == static_cast<uint32_t>(0x10ULL));
addConstant(*this, "SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ", static_cast<uint32_t>(0x10ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE) == static_cast<uint32_t>(0x20ULL));
addConstant(*this, "SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE", static_cast<uint32_t>(0x20ULL));
static_assert(static_cast<uint32_t>(SDL_INIT_VIDEO) == static_cast<uint32_t>(0x20ULL));
addConstant(*this, "SDL_INIT_VIDEO", static_cast<uint32_t>(0x20ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_RESIZABLE) == static_cast<uint64_t>(0x20ULL));
addConstant(*this, "SDL_WINDOW_RESIZABLE", static_cast<uint64_t>(0x20ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_HIDDEN) == static_cast<uint64_t>(0x8ULL));
addConstant(*this, "SDL_WINDOW_HIDDEN", static_cast<uint64_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_QUIT) == static_cast<uint32_t>(0x100ULL));
addConstant(*this, "SDL_EVENT_QUIT", static_cast<uint32_t>(0x100ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_KEY_DOWN) == static_cast<uint32_t>(0x300ULL));
addConstant(*this, "SDL_EVENT_KEY_DOWN", static_cast<uint32_t>(0x300ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_KEY_UP) == static_cast<uint32_t>(0x301ULL));
addConstant(*this, "SDL_EVENT_KEY_UP", static_cast<uint32_t>(0x301ULL));
static_assert(static_cast<uint32_t>(SDLK_ESCAPE) == static_cast<uint32_t>(0x1bULL));
addConstant(*this, "SDLK_ESCAPE", static_cast<uint32_t>(0x1bULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_TEXT_INPUT) == static_cast<uint32_t>(0x303ULL));
addConstant(*this, "SDL_EVENT_TEXT_INPUT", static_cast<uint32_t>(0x303ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_TEXT_EDITING) == static_cast<uint32_t>(0x302ULL));
addConstant(*this, "SDL_EVENT_TEXT_EDITING", static_cast<uint32_t>(0x302ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_MOUSE_MOTION) == static_cast<uint32_t>(0x400ULL));
addConstant(*this, "SDL_EVENT_MOUSE_MOTION", static_cast<uint32_t>(0x400ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_MOUSE_BUTTON_DOWN) == static_cast<uint32_t>(0x401ULL));
addConstant(*this, "SDL_EVENT_MOUSE_BUTTON_DOWN", static_cast<uint32_t>(0x401ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_MOUSE_BUTTON_UP) == static_cast<uint32_t>(0x402ULL));
addConstant(*this, "SDL_EVENT_MOUSE_BUTTON_UP", static_cast<uint32_t>(0x402ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_MOUSE_WHEEL) == static_cast<uint32_t>(0x403ULL));
addConstant(*this, "SDL_EVENT_MOUSE_WHEEL", static_cast<uint32_t>(0x403ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_CLOSE_REQUESTED) == static_cast<uint32_t>(0x210ULL));
addConstant(*this, "SDL_EVENT_WINDOW_CLOSE_REQUESTED", static_cast<uint32_t>(0x210ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_LEFT) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_BUTTON_LEFT", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_MIDDLE) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_BUTTON_MIDDLE", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_RIGHT) == static_cast<uint32_t>(0x3ULL));
addConstant(*this, "SDL_BUTTON_RIGHT", static_cast<uint32_t>(0x3ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_LMASK) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_BUTTON_LMASK", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_MMASK) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_BUTTON_MMASK", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_RMASK) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_BUTTON_RMASK", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_SHIFT) == static_cast<uint32_t>(0x3ULL));
addConstant(*this, "SDL_KMOD_SHIFT", static_cast<uint32_t>(0x3ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_CTRL) == static_cast<uint32_t>(0xc0ULL));
addConstant(*this, "SDL_KMOD_CTRL", static_cast<uint32_t>(0xc0ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_ALT) == static_cast<uint32_t>(0x300ULL));
addConstant(*this, "SDL_KMOD_ALT", static_cast<uint32_t>(0x300ULL));
static_assert(static_cast<uint32_t>(SDLK_BACKSPACE) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDLK_BACKSPACE", static_cast<uint32_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDLK_RETURN) == static_cast<uint32_t>(0xdULL));
addConstant(*this, "SDLK_RETURN", static_cast<uint32_t>(0xdULL));
static_assert(static_cast<uint32_t>(SDLK_LEFT) == static_cast<uint32_t>(0x40000050ULL));
addConstant(*this, "SDLK_LEFT", static_cast<uint32_t>(0x40000050ULL));
static_assert(static_cast<uint32_t>(SDLK_RIGHT) == static_cast<uint32_t>(0x4000004fULL));
addConstant(*this, "SDLK_RIGHT", static_cast<uint32_t>(0x4000004fULL));
static_assert(static_cast<uint32_t>(SDLK_UP) == static_cast<uint32_t>(0x40000052ULL));
addConstant(*this, "SDLK_UP", static_cast<uint32_t>(0x40000052ULL));
static_assert(static_cast<uint32_t>(SDLK_DOWN) == static_cast<uint32_t>(0x40000051ULL));
addConstant(*this, "SDLK_DOWN", static_cast<uint32_t>(0x40000051ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_A) == static_cast<int32_t>(4ULL));
addConstant(*this, "SDL_SCANCODE_A", static_cast<int32_t>(4ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_LEFT) == static_cast<int32_t>(80ULL));
addConstant(*this, "SDL_SCANCODE_LEFT", static_cast<int32_t>(80ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_RIGHT) == static_cast<int32_t>(79ULL));
addConstant(*this, "SDL_SCANCODE_RIGHT", static_cast<int32_t>(79ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_UP) == static_cast<int32_t>(82ULL));
addConstant(*this, "SDL_SCANCODE_UP", static_cast<int32_t>(82ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_DOWN) == static_cast<int32_t>(81ULL));
addConstant(*this, "SDL_SCANCODE_DOWN", static_cast<int32_t>(81ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_ESCAPE) == static_cast<int32_t>(41ULL));
addConstant(*this, "SDL_SCANCODE_ESCAPE", static_cast<int32_t>(41ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_SPACE) == static_cast<int32_t>(44ULL));
addConstant(*this, "SDL_SCANCODE_SPACE", static_cast<int32_t>(44ULL));
static_assert(static_cast<int32_t>(SDL_SCANCODE_COUNT) == static_cast<int32_t>(512ULL));
addConstant(*this, "SDL_SCANCODE_COUNT", static_cast<int32_t>(512ULL));
static_assert(static_cast<uint32_t>(SDL_INIT_AUDIO) == static_cast<uint32_t>(0x10ULL));
addConstant(*this, "SDL_INIT_AUDIO", static_cast<uint32_t>(0x10ULL));
static_assert(static_cast<uint32_t>(SDL_AUDIO_S16) == static_cast<uint32_t>(0x8010ULL));
addConstant(*this, "SDL_AUDIO_S16", static_cast<uint32_t>(0x8010ULL));
static_assert(static_cast<uint32_t>(SDL_AUDIO_S16LE) == static_cast<uint32_t>(0x8010ULL));
addConstant(*this, "SDL_AUDIO_S16LE", static_cast<uint32_t>(0x8010ULL));
static_assert(static_cast<uint32_t>(SDL_AUDIO_F32) == static_cast<uint32_t>(0x8120ULL));
addConstant(*this, "SDL_AUDIO_F32", static_cast<uint32_t>(0x8120ULL));
static_assert(static_cast<uint32_t>(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK) == static_cast<uint32_t>(0xffffffffULL));
addConstant(*this, "SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK", static_cast<uint32_t>(0xffffffffULL));
static_assert(static_cast<uint32_t>(SDL_GPU_COLORCOMPONENT_R) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_GPU_COLORCOMPONENT_R", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_COLORCOMPONENT_G) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_GPU_COLORCOMPONENT_G", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_COLORCOMPONENT_B) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_GPU_COLORCOMPONENT_B", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_GPU_COLORCOMPONENT_A) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDL_GPU_COLORCOMPONENT_A", static_cast<uint32_t>(0x8ULL));
// from SDL3/SDL_stdinc.h:1405:34
	makeExtern< void (*)(void *) , SDL_free , SimNode_ExtFuncCall >(lib,"SDL_free","SDL_free")
		->args({"mem"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_error.h:158:42
	makeExtern< const char * (*)() , SDL_GetError , SimNode_ExtFuncCall >(lib,"SDL_GetError","SDL_GetError")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1039:47
	makeExtern< unsigned int (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamDevice , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamDevice","SDL_GetAudioStreamDevice")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1061:47
	makeExtern< struct SDL_AudioStream * (*)(const struct SDL_AudioSpec *,const struct SDL_AudioSpec *) , SDL_CreateAudioStream , SimNode_ExtFuncCall >(lib,"SDL_CreateAudioStream","SDL_CreateAudioStream")
		->args({"src_spec","dst_spec"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1092:34
	makeExtern< bool (*)(struct SDL_AudioStream *,struct SDL_AudioSpec *,struct SDL_AudioSpec *) , SDL_GetAudioStreamFormat , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamFormat","SDL_GetAudioStreamFormat")
		->args({"stream","src_spec","dst_spec"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1415:34
	makeExtern< bool (*)(struct SDL_AudioStream *,const void *,int) , SDL_PutAudioStreamData , SimNode_ExtFuncCall >(lib,"SDL_PutAudioStreamData","SDL_PutAudioStreamData")
		->args({"stream","buf","len"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1445:33
	makeExtern< int (*)(struct SDL_AudioStream *,void *,int) , SDL_GetAudioStreamData , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamData","SDL_GetAudioStreamData")
		->args({"stream","buf","len"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1471:33
	makeExtern< int (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamAvailable , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamAvailable","SDL_GetAudioStreamAvailable")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1510:33
	makeExtern< int (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamQueued , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamQueued","SDL_GetAudioStreamQueued")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1531:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_FlushAudioStream , SimNode_ExtFuncCall >(lib,"SDL_FlushAudioStream","SDL_FlushAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1552:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_ClearAudioStream , SimNode_ExtFuncCall >(lib,"SDL_ClearAudioStream","SDL_ClearAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1576:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_PauseAudioStreamDevice , SimNode_ExtFuncCall >(lib,"SDL_PauseAudioStreamDevice","SDL_PauseAudioStreamDevice")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1599:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_ResumeAudioStreamDevice , SimNode_ExtFuncCall >(lib,"SDL_ResumeAudioStreamDevice","SDL_ResumeAudioStreamDevice")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1618:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_AudioStreamDevicePaused , SimNode_ExtFuncCall >(lib,"SDL_AudioStreamDevicePaused","SDL_AudioStreamDevicePaused")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1825:34
	makeExtern< void (*)(struct SDL_AudioStream *) , SDL_DestroyAudioStream , SimNode_ExtFuncCall >(lib,"SDL_DestroyAudioStream","SDL_DestroyAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:2096:34
	makeExtern< bool (*)(const char *,struct SDL_AudioSpec *,unsigned char **,unsigned int *) , SDL_LoadWAV , SimNode_ExtFuncCall >(lib,"SDL_LoadWAV","SDL_LoadWAV")
		->args({"path","spec","audio_buf","audio_len"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:213:34
	makeExtern< void (*)(struct SDL_Surface *) , SDL_DestroySurface , SimNode_ExtFuncCall >(lib,"SDL_DestroySurface","SDL_DestroySurface")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:528:43
	makeExtern< struct SDL_Surface * (*)(const char *) , SDL_LoadBMP , SimNode_ExtFuncCall >(lib,"SDL_LoadBMP","SDL_LoadBMP")
		->args({"file"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1129:42
	makeExtern< struct SDL_Window * (*)(const char *,int,int,SDL_WindowFlags) , SDL_CreateWindow , SimNode_ExtFuncCall >(lib,"SDL_CreateWindow","SDL_CreateWindow")
		->args({"title","w","h","flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1386:42
	makeExtern< unsigned int (*)(struct SDL_Window *) , SDL_GetWindowID , SimNode_ExtFuncCall >(lib,"SDL_GetWindowID","SDL_GetWindowID")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1404:42
	makeExtern< struct SDL_Window * (*)(unsigned int) , SDL_GetWindowFromID , SimNode_ExtFuncCall >(lib,"SDL_GetWindowFromID","SDL_GetWindowFromID")
		->args({"id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1615:34
	makeExtern< bool (*)(struct SDL_Window *,const char *) , SDL_SetWindowTitle , SimNode_ExtFuncCall >(lib,"SDL_SetWindowTitle","SDL_SetWindowTitle")
		->args({"window","title"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2838:34
	makeExtern< void (*)(struct SDL_Window *) , SDL_DestroyWindow , SimNode_ExtFuncCall >(lib,"SDL_DestroyWindow","SDL_DestroyWindow")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:159:42
	makeExtern< const bool * (*)(int *) , SDL_GetKeyboardState , SimNode_ExtFuncCall >(lib,"SDL_GetKeyboardState","SDL_GetKeyboardState")
		->args({"numkeys"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:379:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_StartTextInput , SimNode_ExtFuncCall >(lib,"SDL_StartTextInput","SDL_StartTextInput")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:494:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_TextInputActive , SimNode_ExtFuncCall >(lib,"SDL_TextInputActive","SDL_TextInputActive")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:512:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_StopTextInput , SimNode_ExtFuncCall >(lib,"SDL_StopTextInput","SDL_StopTextInput")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:528:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_ClearComposition , SimNode_ExtFuncCall >(lib,"SDL_ClearComposition","SDL_ClearComposition")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:261:50
	makeExtern< unsigned int (*)(float *,float *) , SDL_GetMouseState , SimNode_ExtFuncCall >(lib,"SDL_GetMouseState","SDL_GetMouseState")
		->args({"x","y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1071:34
	makeExtern< void (*)() , SDL_PumpEvents , SimNode_ExtFuncCall >(lib,"SDL_PumpEvents","SDL_PumpEvents")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1270:34
	makeExtern< bool (*)(union SDL_Event *) , SDL_PollEvent , SimNode_ExtFuncCall >(lib,"SDL_PollEvent","SDL_PollEvent")
		->args({"event"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1358:34
	makeExtern< bool (*)(union SDL_Event *) , SDL_PushEvent , SimNode_ExtFuncCall >(lib,"SDL_PushEvent","SDL_PushEvent")
		->args({"event"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:96:42
	makeExtern< const char * (*)() , SDL_GetBasePath , SimNode_ExtFuncCall >(lib,"SDL_GetBasePath","SDL_GetBasePath")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2094:34
	makeExtern< bool (*)(unsigned int,const char *) , SDL_GPUSupportsShaderFormats , SimNode_ExtFuncCall >(lib,"SDL_GPUSupportsShaderFormats","SDL_GPUSupportsShaderFormats")
		->args({"format_flags","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2108:34
	makeExtern< bool (*)(unsigned int) , SDL_GPUSupportsProperties , SimNode_ExtFuncCall >(lib,"SDL_GPUSupportsProperties","SDL_GPUSupportsProperties")
		->args({"props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2129:45
	makeExtern< struct SDL_GPUDevice * (*)(unsigned int,bool,const char *) , SDL_CreateGPUDevice , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUDevice","SDL_CreateGPUDevice")
		->args({"format_flags","debug_mode","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2177:45
	makeExtern< struct SDL_GPUDevice * (*)(unsigned int) , SDL_CreateGPUDeviceWithProperties , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUDeviceWithProperties","SDL_CreateGPUDeviceWithProperties")
		->args({"props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2200:34
	makeExtern< void (*)(struct SDL_GPUDevice *) , SDL_DestroyGPUDevice , SimNode_ExtFuncCall >(lib,"SDL_DestroyGPUDevice","SDL_DestroyGPUDevice")
		->args({"device"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2211:33
	makeExtern< int (*)() , SDL_GetNumGPUDrivers , SimNode_ExtFuncCall >(lib,"SDL_GetNumGPUDrivers","SDL_GetNumGPUDrivers")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2230:42
	makeExtern< const char * (*)(int) , SDL_GetGPUDriver , SimNode_ExtFuncCall >(lib,"SDL_GetGPUDriver","SDL_GetGPUDriver")
		->args({"index"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2240:42
	makeExtern< const char * (*)(struct SDL_GPUDevice *) , SDL_GetGPUDeviceDriver , SimNode_ExtFuncCall >(lib,"SDL_GetGPUDeviceDriver","SDL_GetGPUDeviceDriver")
		->args({"device"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2251:49
	makeExtern< unsigned int (*)(struct SDL_GPUDevice *) , SDL_GetGPUShaderFormats , SimNode_ExtFuncCall >(lib,"SDL_GetGPUShaderFormats","SDL_GetGPUShaderFormats")
		->args({"device"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2300:54
	makeExtern< struct SDL_GPUComputePipeline * (*)(struct SDL_GPUDevice *,const struct SDL_GPUComputePipelineCreateInfo *) , SDL_CreateGPUComputePipeline , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUComputePipeline","SDL_CreateGPUComputePipeline")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2327:55
	makeExtern< struct SDL_GPUGraphicsPipeline * (*)(struct SDL_GPUDevice *,const struct SDL_GPUGraphicsPipelineCreateInfo *) , SDL_CreateGPUGraphicsPipeline , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUGraphicsPipeline","SDL_CreateGPUGraphicsPipeline")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2354:46
	makeExtern< struct SDL_GPUSampler * (*)(struct SDL_GPUDevice *,const struct SDL_GPUSamplerCreateInfo *) , SDL_CreateGPUSampler , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUSampler","SDL_CreateGPUSampler")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2433:45
	makeExtern< struct SDL_GPUShader * (*)(struct SDL_GPUDevice *,const struct SDL_GPUShaderCreateInfo *) , SDL_CreateGPUShader , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUShader","SDL_CreateGPUShader")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2494:46
	makeExtern< struct SDL_GPUTexture * (*)(struct SDL_GPUDevice *,const struct SDL_GPUTextureCreateInfo *) , SDL_CreateGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUTexture","SDL_CreateGPUTexture")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2550:45
	makeExtern< struct SDL_GPUBuffer * (*)(struct SDL_GPUDevice *,const struct SDL_GPUBufferCreateInfo *) , SDL_CreateGPUBuffer , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUBuffer","SDL_CreateGPUBuffer")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2583:53
	makeExtern< struct SDL_GPUTransferBuffer * (*)(struct SDL_GPUDevice *,const struct SDL_GPUTransferBufferCreateInfo *) , SDL_CreateGPUTransferBuffer , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUTransferBuffer","SDL_CreateGPUTransferBuffer")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2608:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUBuffer *,const char *) , SDL_SetGPUBufferName , SimNode_ExtFuncCall >(lib,"SDL_SetGPUBufferName","SDL_SetGPUBufferName")
		->args({"device","buffer","text"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2631:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUTexture *,const char *) , SDL_SetGPUTextureName , SimNode_ExtFuncCall >(lib,"SDL_SetGPUTextureName","SDL_SetGPUTextureName")
		->args({"device","texture","text"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2646:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,const char *) , SDL_InsertGPUDebugLabel , SimNode_ExtFuncCall >(lib,"SDL_InsertGPUDebugLabel","SDL_InsertGPUDebugLabel")
		->args({"command_buffer","text"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2671:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,const char *) , SDL_PushGPUDebugGroup , SimNode_ExtFuncCall >(lib,"SDL_PushGPUDebugGroup","SDL_PushGPUDebugGroup")
		->args({"command_buffer","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2684:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *) , SDL_PopGPUDebugGroup , SimNode_ExtFuncCall >(lib,"SDL_PopGPUDebugGroup","SDL_PopGPUDebugGroup")
		->args({"command_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2699:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUTexture *) , SDL_ReleaseGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUTexture","SDL_ReleaseGPUTexture")
		->args({"device","texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2713:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUSampler *) , SDL_ReleaseGPUSampler , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUSampler","SDL_ReleaseGPUSampler")
		->args({"device","sampler"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2727:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUBuffer *) , SDL_ReleaseGPUBuffer , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUBuffer","SDL_ReleaseGPUBuffer")
		->args({"device","buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2741:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUTransferBuffer *) , SDL_ReleaseGPUTransferBuffer , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUTransferBuffer","SDL_ReleaseGPUTransferBuffer")
		->args({"device","transfer_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2755:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUComputePipeline *) , SDL_ReleaseGPUComputePipeline , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUComputePipeline","SDL_ReleaseGPUComputePipeline")
		->args({"device","compute_pipeline"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2769:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUShader *) , SDL_ReleaseGPUShader , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUShader","SDL_ReleaseGPUShader")
		->args({"device","shader"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2783:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUGraphicsPipeline *) , SDL_ReleaseGPUGraphicsPipeline , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUGraphicsPipeline","SDL_ReleaseGPUGraphicsPipeline")
		->args({"device","graphics_pipeline"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2811:52
	makeExtern< struct SDL_GPUCommandBuffer * (*)(struct SDL_GPUDevice *) , SDL_AcquireGPUCommandBuffer , SimNode_ExtFuncCall >(lib,"SDL_AcquireGPUCommandBuffer","SDL_AcquireGPUCommandBuffer")
		->args({"device"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2832:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,unsigned int,const void *,unsigned int) , SDL_PushGPUVertexUniformData , SimNode_ExtFuncCall >(lib,"SDL_PushGPUVertexUniformData","SDL_PushGPUVertexUniformData")
		->args({"command_buffer","slot_index","data","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2854:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,unsigned int,const void *,unsigned int) , SDL_PushGPUFragmentUniformData , SimNode_ExtFuncCall >(lib,"SDL_PushGPUFragmentUniformData","SDL_PushGPUFragmentUniformData")
		->args({"command_buffer","slot_index","data","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2876:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,unsigned int,const void *,unsigned int) , SDL_PushGPUComputeUniformData , SimNode_ExtFuncCall >(lib,"SDL_PushGPUComputeUniformData","SDL_PushGPUComputeUniformData")
		->args({"command_buffer","slot_index","data","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2909:49
	makeExtern< struct SDL_GPURenderPass * (*)(struct SDL_GPUCommandBuffer *,const struct SDL_GPUColorTargetInfo *,unsigned int,const struct SDL_GPUDepthStencilTargetInfo *) , SDL_BeginGPURenderPass , SimNode_ExtFuncCall >(lib,"SDL_BeginGPURenderPass","SDL_BeginGPURenderPass")
		->args({"command_buffer","color_target_infos","num_color_targets","depth_stencil_target_info"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2925:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,struct SDL_GPUGraphicsPipeline *) , SDL_BindGPUGraphicsPipeline , SimNode_ExtFuncCall >(lib,"SDL_BindGPUGraphicsPipeline","SDL_BindGPUGraphicsPipeline")
		->args({"render_pass","graphics_pipeline"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2937:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,const struct SDL_GPUViewport *) , SDL_SetGPUViewport , SimNode_ExtFuncCall >(lib,"SDL_SetGPUViewport","SDL_SetGPUViewport")
		->args({"render_pass","viewport"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2949:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,const struct SDL_Rect *) , SDL_SetGPUScissor , SimNode_ExtFuncCall >(lib,"SDL_SetGPUScissor","SDL_SetGPUScissor")
		->args({"render_pass","scissor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2964:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,struct SDL_FColor) , SDL_SetGPUBlendConstants , SimNode_ExtFuncCall >(lib,"SDL_SetGPUBlendConstants","SDL_SetGPUBlendConstants")
		->args({"render_pass","blend_constants"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2976:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned char) , SDL_SetGPUStencilReference , SimNode_ExtFuncCall >(lib,"SDL_SetGPUStencilReference","SDL_SetGPUStencilReference")
		->args({"render_pass","reference"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2992:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,const struct SDL_GPUBufferBinding *,unsigned int) , SDL_BindGPUVertexBuffers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUVertexBuffers","SDL_BindGPUVertexBuffers")
		->args({"render_pass","first_slot","bindings","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3009:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,const struct SDL_GPUBufferBinding *,enum SDL_GPUIndexElementSize) , SDL_BindGPUIndexBuffer , SimNode_ExtFuncCall >(lib,"SDL_BindGPUIndexBuffer","SDL_BindGPUIndexBuffer")
		->args({"render_pass","binding","index_element_size"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3033:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,const struct SDL_GPUTextureSamplerBinding *,unsigned int) , SDL_BindGPUVertexSamplers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUVertexSamplers","SDL_BindGPUVertexSamplers")
		->args({"render_pass","first_slot","texture_sampler_bindings","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3057:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,struct SDL_GPUTexture *const *,unsigned int) , SDL_BindGPUVertexStorageTextures , SimNode_ExtFuncCall >(lib,"SDL_BindGPUVertexStorageTextures","SDL_BindGPUVertexStorageTextures")
		->args({"render_pass","first_slot","storage_textures","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3081:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,struct SDL_GPUBuffer *const *,unsigned int) , SDL_BindGPUVertexStorageBuffers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUVertexStorageBuffers","SDL_BindGPUVertexStorageBuffers")
		->args({"render_pass","first_slot","storage_buffers","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3106:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,const struct SDL_GPUTextureSamplerBinding *,unsigned int) , SDL_BindGPUFragmentSamplers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUFragmentSamplers","SDL_BindGPUFragmentSamplers")
		->args({"render_pass","first_slot","texture_sampler_bindings","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3130:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,struct SDL_GPUTexture *const *,unsigned int) , SDL_BindGPUFragmentStorageTextures , SimNode_ExtFuncCall >(lib,"SDL_BindGPUFragmentStorageTextures","SDL_BindGPUFragmentStorageTextures")
		->args({"render_pass","first_slot","storage_textures","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3154:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,struct SDL_GPUBuffer *const *,unsigned int) , SDL_BindGPUFragmentStorageBuffers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUFragmentStorageBuffers","SDL_BindGPUFragmentStorageBuffers")
		->args({"render_pass","first_slot","storage_buffers","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3185:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,unsigned int,unsigned int,int,unsigned int) , SDL_DrawGPUIndexedPrimitives , SimNode_ExtFuncCall >(lib,"SDL_DrawGPUIndexedPrimitives","SDL_DrawGPUIndexedPrimitives")
		->args({"render_pass","num_indices","num_instances","first_index","vertex_offset","first_instance"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3213:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,unsigned int,unsigned int,unsigned int) , SDL_DrawGPUPrimitives , SimNode_ExtFuncCall >(lib,"SDL_DrawGPUPrimitives","SDL_DrawGPUPrimitives")
		->args({"render_pass","num_vertices","num_instances","first_vertex","first_instance"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3236:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,struct SDL_GPUBuffer *,unsigned int,unsigned int) , SDL_DrawGPUPrimitivesIndirect , SimNode_ExtFuncCall >(lib,"SDL_DrawGPUPrimitivesIndirect","SDL_DrawGPUPrimitivesIndirect")
		->args({"render_pass","buffer","offset","draw_count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3258:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,struct SDL_GPUBuffer *,unsigned int,unsigned int) , SDL_DrawGPUIndexedPrimitivesIndirect , SimNode_ExtFuncCall >(lib,"SDL_DrawGPUIndexedPrimitivesIndirect","SDL_DrawGPUIndexedPrimitivesIndirect")
		->args({"render_pass","buffer","offset","draw_count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3274:34
	makeExtern< void (*)(struct SDL_GPURenderPass *) , SDL_EndGPURenderPass , SimNode_ExtFuncCall >(lib,"SDL_EndGPURenderPass","SDL_EndGPURenderPass")
		->args({"render_pass"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3316:50
	makeExtern< struct SDL_GPUComputePass * (*)(struct SDL_GPUCommandBuffer *,const struct SDL_GPUStorageTextureReadWriteBinding *,unsigned int,const struct SDL_GPUStorageBufferReadWriteBinding *,unsigned int) , SDL_BeginGPUComputePass , SimNode_ExtFuncCall >(lib,"SDL_BeginGPUComputePass","SDL_BeginGPUComputePass")
		->args({"command_buffer","storage_texture_bindings","num_storage_texture_bindings","storage_buffer_bindings","num_storage_buffer_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3331:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,struct SDL_GPUComputePipeline *) , SDL_BindGPUComputePipeline , SimNode_ExtFuncCall >(lib,"SDL_BindGPUComputePipeline","SDL_BindGPUComputePipeline")
		->args({"compute_pass","compute_pipeline"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3354:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,unsigned int,const struct SDL_GPUTextureSamplerBinding *,unsigned int) , SDL_BindGPUComputeSamplers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUComputeSamplers","SDL_BindGPUComputeSamplers")
		->args({"compute_pass","first_slot","texture_sampler_bindings","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3378:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,unsigned int,struct SDL_GPUTexture *const *,unsigned int) , SDL_BindGPUComputeStorageTextures , SimNode_ExtFuncCall >(lib,"SDL_BindGPUComputeStorageTextures","SDL_BindGPUComputeStorageTextures")
		->args({"compute_pass","first_slot","storage_textures","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3402:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,unsigned int,struct SDL_GPUBuffer *const *,unsigned int) , SDL_BindGPUComputeStorageBuffers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUComputeStorageBuffers","SDL_BindGPUComputeStorageBuffers")
		->args({"compute_pass","first_slot","storage_buffers","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3428:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,unsigned int,unsigned int,unsigned int) , SDL_DispatchGPUCompute , SimNode_ExtFuncCall >(lib,"SDL_DispatchGPUCompute","SDL_DispatchGPUCompute")
		->args({"compute_pass","groupcount_x","groupcount_y","groupcount_z"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3452:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,struct SDL_GPUBuffer *,unsigned int) , SDL_DispatchGPUComputeIndirect , SimNode_ExtFuncCall >(lib,"SDL_DispatchGPUComputeIndirect","SDL_DispatchGPUComputeIndirect")
		->args({"compute_pass","buffer","offset"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3467:34
	makeExtern< void (*)(struct SDL_GPUComputePass *) , SDL_EndGPUComputePass , SimNode_ExtFuncCall >(lib,"SDL_EndGPUComputePass","SDL_EndGPUComputePass")
		->args({"compute_pass"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3487:36
	makeExtern< void * (*)(struct SDL_GPUDevice *,struct SDL_GPUTransferBuffer *,bool) , SDL_MapGPUTransferBuffer , SimNode_ExtFuncCall >(lib,"SDL_MapGPUTransferBuffer","SDL_MapGPUTransferBuffer")
		->args({"device","transfer_buffer","cycle"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3500:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUTransferBuffer *) , SDL_UnmapGPUTransferBuffer , SimNode_ExtFuncCall >(lib,"SDL_UnmapGPUTransferBuffer","SDL_UnmapGPUTransferBuffer")
		->args({"device","transfer_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3518:47
	makeExtern< struct SDL_GPUCopyPass * (*)(struct SDL_GPUCommandBuffer *) , SDL_BeginGPUCopyPass , SimNode_ExtFuncCall >(lib,"SDL_BeginGPUCopyPass","SDL_BeginGPUCopyPass")
		->args({"command_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3538:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUTextureTransferInfo *,const struct SDL_GPUTextureRegion *,bool) , SDL_UploadToGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_UploadToGPUTexture","SDL_UploadToGPUTexture")
		->args({"copy_pass","source","destination","cycle"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3558:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUTransferBufferLocation *,const struct SDL_GPUBufferRegion *,bool) , SDL_UploadToGPUBuffer , SimNode_ExtFuncCall >(lib,"SDL_UploadToGPUBuffer","SDL_UploadToGPUBuffer")
		->args({"copy_pass","source","destination","cycle"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3581:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUTextureLocation *,const struct SDL_GPUTextureLocation *,unsigned int,unsigned int,unsigned int,bool) , SDL_CopyGPUTextureToTexture , SimNode_ExtFuncCall >(lib,"SDL_CopyGPUTextureToTexture","SDL_CopyGPUTextureToTexture")
		->args({"copy_pass","source","destination","w","h","d","cycle"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3605:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUBufferLocation *,const struct SDL_GPUBufferLocation *,unsigned int,bool) , SDL_CopyGPUBufferToBuffer , SimNode_ExtFuncCall >(lib,"SDL_CopyGPUBufferToBuffer","SDL_CopyGPUBufferToBuffer")
		->args({"copy_pass","source","destination","size","cycle"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3625:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUTextureRegion *,const struct SDL_GPUTextureTransferInfo *) , SDL_DownloadFromGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_DownloadFromGPUTexture","SDL_DownloadFromGPUTexture")
		->args({"copy_pass","source","destination"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3642:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUBufferRegion *,const struct SDL_GPUTransferBufferLocation *) , SDL_DownloadFromGPUBuffer , SimNode_ExtFuncCall >(lib,"SDL_DownloadFromGPUBuffer","SDL_DownloadFromGPUBuffer")
		->args({"copy_pass","source","destination"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3654:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *) , SDL_EndGPUCopyPass , SimNode_ExtFuncCall >(lib,"SDL_EndGPUCopyPass","SDL_EndGPUCopyPass")
		->args({"copy_pass"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3667:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,struct SDL_GPUTexture *) , SDL_GenerateMipmapsForGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_GenerateMipmapsForGPUTexture","SDL_GenerateMipmapsForGPUTexture")
		->args({"command_buffer","texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3681:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,const struct SDL_GPUBlitInfo *) , SDL_BlitGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_BlitGPUTexture","SDL_BlitGPUTexture")
		->args({"command_buffer","info"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3701:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_Window *,enum SDL_GPUSwapchainComposition) , SDL_WindowSupportsGPUSwapchainComposition , SimNode_ExtFuncCall >(lib,"SDL_WindowSupportsGPUSwapchainComposition","SDL_WindowSupportsGPUSwapchainComposition")
		->args({"device","window","swapchain_composition"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3720:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_Window *,enum SDL_GPUPresentMode) , SDL_WindowSupportsGPUPresentMode , SimNode_ExtFuncCall >(lib,"SDL_WindowSupportsGPUPresentMode","SDL_WindowSupportsGPUPresentMode")
		->args({"device","window","present_mode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3752:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_Window *) , SDL_ClaimWindowForGPUDevice , SimNode_ExtFuncCall >(lib,"SDL_ClaimWindowForGPUDevice","SDL_ClaimWindowForGPUDevice")
		->args({"device","window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3766:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_Window *) , SDL_ReleaseWindowFromGPUDevice , SimNode_ExtFuncCall >(lib,"SDL_ReleaseWindowFromGPUDevice","SDL_ReleaseWindowFromGPUDevice")
		->args({"device","window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3793:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_Window *,enum SDL_GPUSwapchainComposition,enum SDL_GPUPresentMode) , SDL_SetGPUSwapchainParameters , SimNode_ExtFuncCall >(lib,"SDL_SetGPUSwapchainParameters","SDL_SetGPUSwapchainParameters")
		->args({"device","window","swapchain_composition","present_mode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3824:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,unsigned int) , SDL_SetGPUAllowedFramesInFlight , SimNode_ExtFuncCall >(lib,"SDL_SetGPUAllowedFramesInFlight","SDL_SetGPUAllowedFramesInFlight")
		->args({"device","allowed_frames_in_flight"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3839:50
	makeExtern< enum SDL_GPUTextureFormat (*)(struct SDL_GPUDevice *,struct SDL_Window *) , SDL_GetGPUSwapchainTextureFormat , SimNode_ExtFuncCall >(lib,"SDL_GetGPUSwapchainTextureFormat","SDL_GetGPUSwapchainTextureFormat")
		->args({"device","window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3889:34
	makeExtern< bool (*)(struct SDL_GPUCommandBuffer *,struct SDL_Window *,struct SDL_GPUTexture **,unsigned int *,unsigned int *) , SDL_AcquireGPUSwapchainTexture , SimNode_ExtFuncCall >(lib,"SDL_AcquireGPUSwapchainTexture","SDL_AcquireGPUSwapchainTexture")
		->args({"command_buffer","window","swapchain_texture","swapchain_texture_width","swapchain_texture_height"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3913:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_Window *) , SDL_WaitForGPUSwapchain , SimNode_ExtFuncCall >(lib,"SDL_WaitForGPUSwapchain","SDL_WaitForGPUSwapchain")
		->args({"device","window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3959:34
	makeExtern< bool (*)(struct SDL_GPUCommandBuffer *,struct SDL_Window *,struct SDL_GPUTexture **,unsigned int *,unsigned int *) , SDL_WaitAndAcquireGPUSwapchainTexture , SimNode_ExtFuncCall >(lib,"SDL_WaitAndAcquireGPUSwapchainTexture","SDL_WaitAndAcquireGPUSwapchainTexture")
		->args({"command_buffer","window","swapchain_texture","swapchain_texture_width","swapchain_texture_height"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3987:34
	makeExtern< bool (*)(struct SDL_GPUCommandBuffer *) , SDL_SubmitGPUCommandBuffer , SimNode_ExtFuncCall >(lib,"SDL_SubmitGPUCommandBuffer","SDL_SubmitGPUCommandBuffer")
		->args({"command_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4014:44
	makeExtern< struct SDL_GPUFence * (*)(struct SDL_GPUCommandBuffer *) , SDL_SubmitGPUCommandBufferAndAcquireFence , SimNode_ExtFuncCall >(lib,"SDL_SubmitGPUCommandBufferAndAcquireFence","SDL_SubmitGPUCommandBufferAndAcquireFence")
		->args({"command_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4039:34
	makeExtern< bool (*)(struct SDL_GPUCommandBuffer *) , SDL_CancelGPUCommandBuffer , SimNode_ExtFuncCall >(lib,"SDL_CancelGPUCommandBuffer","SDL_CancelGPUCommandBuffer")
		->args({"command_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4053:34
	makeExtern< bool (*)(struct SDL_GPUDevice *) , SDL_WaitForGPUIdle , SimNode_ExtFuncCall >(lib,"SDL_WaitForGPUIdle","SDL_WaitForGPUIdle")
		->args({"device"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4072:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,bool,struct SDL_GPUFence *const *,unsigned int) , SDL_WaitForGPUFences , SimNode_ExtFuncCall >(lib,"SDL_WaitForGPUFences","SDL_WaitForGPUFences")
		->args({"device","wait_all","fences","num_fences"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4089:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_GPUFence *) , SDL_QueryGPUFence , SimNode_ExtFuncCall >(lib,"SDL_QueryGPUFence","SDL_QueryGPUFence")
		->args({"device","fence"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4105:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUFence *) , SDL_ReleaseGPUFence , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUFence","SDL_ReleaseGPUFence")
		->args({"device","fence"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4121:36
	makeExtern< unsigned int (*)(enum SDL_GPUTextureFormat) , SDL_GPUTextureFormatTexelBlockSize , SimNode_ExtFuncCall >(lib,"SDL_GPUTextureFormatTexelBlockSize","SDL_GPUTextureFormatTexelBlockSize")
		->args({"format"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4136:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,enum SDL_GPUTextureFormat,enum SDL_GPUTextureType,unsigned int) , SDL_GPUTextureSupportsFormat , SimNode_ExtFuncCall >(lib,"SDL_GPUTextureSupportsFormat","SDL_GPUTextureSupportsFormat")
		->args({"device","format","type","usage"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4152:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,enum SDL_GPUTextureFormat,enum SDL_GPUSampleCount) , SDL_GPUTextureSupportsSampleCount , SimNode_ExtFuncCall >(lib,"SDL_GPUTextureSupportsSampleCount","SDL_GPUTextureSupportsSampleCount")
		->args({"device","format","sample_count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4168:36
	makeExtern< unsigned int (*)(enum SDL_GPUTextureFormat,unsigned int,unsigned int,unsigned int) , SDL_CalculateGPUTextureFormatSize , SimNode_ExtFuncCall >(lib,"SDL_CalculateGPUTextureFormatSize","SDL_CalculateGPUTextureFormatSize")
		->args({"format","width","height","depth_or_layer_count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:236:34
	makeExtern< bool (*)(unsigned int) , SDL_Init , SimNode_ExtFuncCall >(lib,"SDL_Init","SDL_Init")
		->args({"flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:282:43
	makeExtern< unsigned int (*)(unsigned int) , SDL_WasInit , SimNode_ExtFuncCall >(lib,"SDL_WasInit","SDL_WasInit")
		->args({"flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:300:34
	makeExtern< void (*)() , SDL_Quit , SimNode_ExtFuncCall >(lib,"SDL_Quit","SDL_Quit")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:246:44
	makeExtern< struct SDL_Renderer * (*)(struct SDL_Window *,const char *) , SDL_CreateRenderer , SimNode_ExtFuncCall >(lib,"SDL_CreateRenderer","SDL_CreateRenderer")
		->args({"window","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:345:44
	makeExtern< struct SDL_Renderer * (*)(struct SDL_Window *) , SDL_GetRenderer , SimNode_ExtFuncCall >(lib,"SDL_GetRenderer","SDL_GetRenderer")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:584:43
	makeExtern< struct SDL_Texture * (*)(struct SDL_Renderer *,struct SDL_Surface *) , SDL_CreateTextureFromSurface , SimNode_ExtFuncCall >(lib,"SDL_CreateTextureFromSurface","SDL_CreateTextureFromSurface")
		->args({"renderer","surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:865:34
	makeExtern< bool (*)(struct SDL_Texture *,float *,float *) , SDL_GetTextureSize , SimNode_ExtFuncCall >(lib,"SDL_GetTextureSize","SDL_GetTextureSize")
		->args({"texture","w","h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1343:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *) , SDL_SetRenderTarget , SimNode_ExtFuncCall >(lib,"SDL_SetRenderTarget","SDL_SetRenderTarget")
		->args({"renderer","texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1360:43
	makeExtern< struct SDL_Texture * (*)(struct SDL_Renderer *) , SDL_GetRenderTarget , SimNode_ExtFuncCall >(lib,"SDL_GetRenderTarget","SDL_GetRenderTarget")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1782:34
	makeExtern< bool (*)(struct SDL_Renderer *,unsigned char,unsigned char,unsigned char,unsigned char) , SDL_SetRenderDrawColor , SimNode_ExtFuncCall >(lib,"SDL_SetRenderDrawColor","SDL_SetRenderDrawColor")
		->args({"renderer","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1949:34
	makeExtern< bool (*)(struct SDL_Renderer *) , SDL_RenderClear , SimNode_ExtFuncCall >(lib,"SDL_RenderClear","SDL_RenderClear")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2073:34
	makeExtern< bool (*)(struct SDL_Renderer *,const struct SDL_FRect *) , SDL_RenderFillRect , SimNode_ExtFuncCall >(lib,"SDL_RenderFillRect","SDL_RenderFillRect")
		->args({"renderer","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2113:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *,const struct SDL_FRect *,const struct SDL_FRect *) , SDL_RenderTexture , SimNode_ExtFuncCall >(lib,"SDL_RenderTexture","SDL_RenderTexture")
		->args({"renderer","texture","srcrect","dstrect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2259:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *,const struct SDL_Vertex *,int,const int *,int) , SDL_RenderGeometry , SimNode_ExtFuncCall >(lib,"SDL_RenderGeometry","SDL_RenderGeometry")
		->args({"renderer","texture","vertices","num_vertices","indices","num_indices"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2374:34
	makeExtern< bool (*)(struct SDL_Renderer *) , SDL_RenderPresent , SimNode_ExtFuncCall >(lib,"SDL_RenderPresent","SDL_RenderPresent")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2391:34
	makeExtern< void (*)(struct SDL_Texture *) , SDL_DestroyTexture , SimNode_ExtFuncCall >(lib,"SDL_DestroyTexture","SDL_DestroyTexture")
		->args({"texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2407:34
	makeExtern< void (*)(struct SDL_Renderer *) , SDL_DestroyRenderer , SimNode_ExtFuncCall >(lib,"SDL_DestroyRenderer","SDL_DestroyRenderer")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:197:36
	makeExtern< Uint64 (*)() , SDL_GetTicks , SimNode_ExtFuncCall >(lib,"SDL_GetTicks","SDL_GetTicks")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:259:34
	makeExtern< void (*)(unsigned int) , SDL_Delay , SimNode_ExtFuncCall >(lib,"SDL_Delay","SDL_Delay")
		->args({"ms"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_version.h:148:33
	makeExtern< int (*)() , SDL_GetVersion , SimNode_ExtFuncCall >(lib,"SDL_GetVersion","SDL_GetVersion")
		->addToModule(*this, SideEffects::worstDefault);
