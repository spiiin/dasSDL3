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
addAnnotation(new DummyTypeAnnotation("SDL_Palette", "SDL_Palette", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_IOStream", "SDL_IOStream", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_HitTestBinding", "SDL_HitTestBinding", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Cursor", "SDL_Cursor", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Joystick", "SDL_Joystick", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Gamepad", "SDL_Gamepad", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Sensor", "SDL_Sensor", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Haptic", "SDL_Haptic", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_hid_device", "SDL_hid_device", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Storage", "SDL_Storage", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_AsyncIO", "SDL_AsyncIO", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_AsyncIOQueue", "SDL_AsyncIOQueue", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Camera", "SDL_Camera", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Mutex", "SDL_Mutex", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_RWLock", "SDL_RWLock", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Semaphore", "SDL_Semaphore", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Condition", "SDL_Condition", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Thread", "SDL_Thread", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Process", "SDL_Process", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_SharedObject", "SDL_SharedObject", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_Tray", "SDL_Tray", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_TrayMenu", "SDL_TrayMenu", 1, 1));
addAnnotation(new DummyTypeAnnotation("SDL_TrayEntry", "SDL_TrayEntry", 1, 1));
addEnumeration(new Enumeration_SDL_AsyncIOTaskType());
addEnumeration(new Enumeration_SDL_AsyncIOResult());
addAnnotation(new SDL_AsyncIOOutcomeAnnotation(lib));
addAnnotation(new SDL_AtomicIntAnnotation(lib));
addAnnotation(new SDL_AtomicU32Annotation(lib));
addEnumeration(new Enumeration_SDL_PropertyType());
addEnumeration(new Enumeration_SDL_ThreadPriority());
addEnumeration(new Enumeration_SDL_ThreadState());
addEnumeration(new Enumeration_SDL_InitStatus());
addAnnotation(new SDL_InitStateAnnotation(lib));
addEnumeration(new Enumeration_SDL_IOStatus());
addEnumeration(new Enumeration_SDL_IOWhence());
addAnnotation(new SDL_IOStreamInterfaceAnnotation(lib));
addEnumeration(new Enumeration_SDL_AudioFormat());
addAnnotation(new SDL_AudioSpecAnnotation(lib));
addEnumeration(new Enumeration_SDL_BlendOperation());
addEnumeration(new Enumeration_SDL_BlendFactor());
addEnumeration(new Enumeration_SDL_PixelFormat());
addEnumeration(new Enumeration_SDL_Colorspace());
addAnnotation(new SDL_ColorAnnotation(lib));
addAnnotation(new SDL_FColorAnnotation(lib));
addAnnotation(new SDL_PixelFormatDetailsAnnotation(lib));
addAnnotation(new SDL_PointAnnotation(lib));
addAnnotation(new SDL_FPointAnnotation(lib));
addAnnotation(new SDL_RectAnnotation(lib));
addAnnotation(new SDL_FRectAnnotation(lib));
addEnumeration(new Enumeration_SDL_ScaleMode());
addEnumeration(new Enumeration_SDL_FlipMode());
addAnnotation(new SDL_CameraSpecAnnotation(lib));
addEnumeration(new Enumeration_SDL_CameraPosition());
addEnumeration(new Enumeration_SDL_CameraPermissionState());
addEnumeration(new Enumeration_SDL_SystemTheme());
addAnnotation(new SDL_DisplayModeAnnotation(lib));
addEnumeration(new Enumeration_SDL_DisplayOrientation());
addEnumeration(new Enumeration_SDL_FlashOperation());
addEnumeration(new Enumeration_SDL_HitTestResult());
addAnnotation(new SDL_DialogFileFilterAnnotation(lib));
addEnumeration(new Enumeration_SDL_FileDialogType());
addAnnotation(new SDL_GUIDAnnotation(lib));
addEnumeration(new Enumeration_SDL_PowerState());
addEnumeration(new Enumeration_SDL_SensorType());
addEnumeration(new Enumeration_SDL_JoystickType());
addEnumeration(new Enumeration_SDL_JoystickConnectionState());
addAnnotation(new SDL_VirtualJoystickTouchpadDescAnnotation(lib));
addAnnotation(new SDL_VirtualJoystickSensorDescAnnotation(lib));
addAnnotation(new SDL_VirtualJoystickDescAnnotation(lib));
addEnumeration(new Enumeration_SDL_GamepadType());
addEnumeration(new Enumeration_SDL_GamepadButton());
addEnumeration(new Enumeration_SDL_GamepadButtonLabel());
addEnumeration(new Enumeration_SDL_GamepadAxis());
addEnumeration(new Enumeration_SDL_GamepadBindingType());
addAnnotation(new SDL_GamepadBindingAnnotation(lib));
addEnumeration(new Enumeration_SDL_Scancode());
addEnumeration(new Enumeration_SDL_TextInputType());
addEnumeration(new Enumeration_SDL_Capitalization());
addEnumeration(new Enumeration_SDL_SystemCursor());
addEnumeration(new Enumeration_SDL_TouchDeviceType());
addAnnotation(new SDL_FingerAnnotation(lib));
addEnumeration(new Enumeration_SDL_PenAxis());
addAnnotation(new SDL_KeyboardEventAnnotation(lib));
addAnnotation(new SDL_TextEditingCandidatesEventAnnotation(lib));
addAnnotation(new SDL_MouseMotionEventAnnotation(lib));
addAnnotation(new SDL_MouseButtonEventAnnotation(lib));
addAnnotation(new SDL_MouseWheelEventAnnotation(lib));
addAnnotation(new SDL_JoyAxisEventAnnotation(lib));
addAnnotation(new SDL_JoyBallEventAnnotation(lib));
addAnnotation(new SDL_JoyHatEventAnnotation(lib));
addAnnotation(new SDL_JoyButtonEventAnnotation(lib));
addAnnotation(new SDL_JoyDeviceEventAnnotation(lib));
addAnnotation(new SDL_JoyBatteryEventAnnotation(lib));
addAnnotation(new SDL_GamepadAxisEventAnnotation(lib));
addAnnotation(new SDL_GamepadButtonEventAnnotation(lib));
addAnnotation(new SDL_GamepadDeviceEventAnnotation(lib));
addAnnotation(new SDL_GamepadTouchpadEventAnnotation(lib));
addAnnotation(new SDL_GamepadSensorEventAnnotation(lib));
addAnnotation(new SDL_TouchFingerEventAnnotation(lib));
addAnnotation(new SDL_PenProximityEventAnnotation(lib));
addAnnotation(new SDL_PenMotionEventAnnotation(lib));
addAnnotation(new SDL_PenTouchEventAnnotation(lib));
addAnnotation(new SDL_PenButtonEventAnnotation(lib));
addAnnotation(new SDL_PenAxisEventAnnotation(lib));
addAnnotation(new SDL_ClipboardEventAnnotation(lib));
addAnnotation(new SDL_SensorEventAnnotation(lib));
addAnnotation(new SDL_EventAnnotation(lib));
addEnumeration(new Enumeration_SDL_EventAction());
addEnumeration(new Enumeration_SDL_Folder());
addEnumeration(new Enumeration_SDL_PathType());
addAnnotation(new SDL_PathInfoAnnotation(lib));
addEnumeration(new Enumeration_SDL_EnumerationResult());
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
addAnnotation(new SDL_HapticDirectionAnnotation(lib));
addAnnotation(new SDL_HapticConstantAnnotation(lib));
addAnnotation(new SDL_HapticPeriodicAnnotation(lib));
addAnnotation(new SDL_HapticConditionAnnotation(lib));
addAnnotation(new SDL_HapticRampAnnotation(lib));
addAnnotation(new SDL_HapticLeftRightAnnotation(lib));
addAnnotation(new SDL_HapticCustomAnnotation(lib));
addAnnotation(new SDL_HapticEffectAnnotation(lib));
addEnumeration(new Enumeration_SDL_hid_bus_type());
addAnnotation(new SDL_hid_device_infoAnnotation(lib));
addEnumeration(new Enumeration_SDL_HintPriority());
addAnnotation(new SDL_LocaleAnnotation(lib));
addEnumeration(new Enumeration_SDL_LogCategory());
addEnumeration(new Enumeration_SDL_LogPriority());
addEnumeration(new Enumeration_SDL_ProcessIO());
addAnnotation(new SDL_VertexAnnotation(lib));
addEnumeration(new Enumeration_SDL_TextureAccess());
addEnumeration(new Enumeration_SDL_RendererLogicalPresentation());
addAnnotation(new SDL_StorageInterfaceAnnotation(lib));
addEnumeration(new Enumeration_SDL_Sandbox());
addAnnotation(new SDL_DateTimeAnnotation(lib));
addEnumeration(new Enumeration_SDL_DateFormat());
addEnumeration(new Enumeration_SDL_TimeFormat());
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
static_assert(static_cast<uint32_t>(SDL_INIT_JOYSTICK) == static_cast<uint32_t>(0x200ULL));
addConstant(*this, "SDL_INIT_JOYSTICK", static_cast<uint32_t>(0x200ULL));
static_assert(static_cast<uint32_t>(SDL_INIT_HAPTIC) == static_cast<uint32_t>(0x1000ULL));
addConstant(*this, "SDL_INIT_HAPTIC", static_cast<uint32_t>(0x1000ULL));
static_assert(static_cast<uint32_t>(SDL_INIT_GAMEPAD) == static_cast<uint32_t>(0x2000ULL));
addConstant(*this, "SDL_INIT_GAMEPAD", static_cast<uint32_t>(0x2000ULL));
static_assert(static_cast<uint32_t>(SDL_INIT_EVENTS) == static_cast<uint32_t>(0x4000ULL));
addConstant(*this, "SDL_INIT_EVENTS", static_cast<uint32_t>(0x4000ULL));
static_assert(static_cast<uint32_t>(SDL_INIT_SENSOR) == static_cast<uint32_t>(0x8000ULL));
addConstant(*this, "SDL_INIT_SENSOR", static_cast<uint32_t>(0x8000ULL));
static_assert(static_cast<uint32_t>(SDL_INIT_CAMERA) == static_cast<uint32_t>(0x10000ULL));
addConstant(*this, "SDL_INIT_CAMERA", static_cast<uint32_t>(0x10000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_FULLSCREEN) == static_cast<uint64_t>(0x1ULL));
addConstant(*this, "SDL_WINDOW_FULLSCREEN", static_cast<uint64_t>(0x1ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_OPENGL) == static_cast<uint64_t>(0x2ULL));
addConstant(*this, "SDL_WINDOW_OPENGL", static_cast<uint64_t>(0x2ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_OCCLUDED) == static_cast<uint64_t>(0x4ULL));
addConstant(*this, "SDL_WINDOW_OCCLUDED", static_cast<uint64_t>(0x4ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_BORDERLESS) == static_cast<uint64_t>(0x10ULL));
addConstant(*this, "SDL_WINDOW_BORDERLESS", static_cast<uint64_t>(0x10ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_MINIMIZED) == static_cast<uint64_t>(0x40ULL));
addConstant(*this, "SDL_WINDOW_MINIMIZED", static_cast<uint64_t>(0x40ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_MAXIMIZED) == static_cast<uint64_t>(0x80ULL));
addConstant(*this, "SDL_WINDOW_MAXIMIZED", static_cast<uint64_t>(0x80ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_MOUSE_GRABBED) == static_cast<uint64_t>(0x100ULL));
addConstant(*this, "SDL_WINDOW_MOUSE_GRABBED", static_cast<uint64_t>(0x100ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_INPUT_FOCUS) == static_cast<uint64_t>(0x200ULL));
addConstant(*this, "SDL_WINDOW_INPUT_FOCUS", static_cast<uint64_t>(0x200ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_MOUSE_FOCUS) == static_cast<uint64_t>(0x400ULL));
addConstant(*this, "SDL_WINDOW_MOUSE_FOCUS", static_cast<uint64_t>(0x400ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_EXTERNAL) == static_cast<uint64_t>(0x800ULL));
addConstant(*this, "SDL_WINDOW_EXTERNAL", static_cast<uint64_t>(0x800ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_MODAL) == static_cast<uint64_t>(0x1000ULL));
addConstant(*this, "SDL_WINDOW_MODAL", static_cast<uint64_t>(0x1000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_HIGH_PIXEL_DENSITY) == static_cast<uint64_t>(0x2000ULL));
addConstant(*this, "SDL_WINDOW_HIGH_PIXEL_DENSITY", static_cast<uint64_t>(0x2000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_MOUSE_CAPTURE) == static_cast<uint64_t>(0x4000ULL));
addConstant(*this, "SDL_WINDOW_MOUSE_CAPTURE", static_cast<uint64_t>(0x4000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_MOUSE_RELATIVE_MODE) == static_cast<uint64_t>(0x8000ULL));
addConstant(*this, "SDL_WINDOW_MOUSE_RELATIVE_MODE", static_cast<uint64_t>(0x8000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_ALWAYS_ON_TOP) == static_cast<uint64_t>(0x10000ULL));
addConstant(*this, "SDL_WINDOW_ALWAYS_ON_TOP", static_cast<uint64_t>(0x10000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_UTILITY) == static_cast<uint64_t>(0x20000ULL));
addConstant(*this, "SDL_WINDOW_UTILITY", static_cast<uint64_t>(0x20000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_TOOLTIP) == static_cast<uint64_t>(0x40000ULL));
addConstant(*this, "SDL_WINDOW_TOOLTIP", static_cast<uint64_t>(0x40000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_POPUP_MENU) == static_cast<uint64_t>(0x80000ULL));
addConstant(*this, "SDL_WINDOW_POPUP_MENU", static_cast<uint64_t>(0x80000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_KEYBOARD_GRABBED) == static_cast<uint64_t>(0x100000ULL));
addConstant(*this, "SDL_WINDOW_KEYBOARD_GRABBED", static_cast<uint64_t>(0x100000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_VULKAN) == static_cast<uint64_t>(0x10000000ULL));
addConstant(*this, "SDL_WINDOW_VULKAN", static_cast<uint64_t>(0x10000000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_METAL) == static_cast<uint64_t>(0x20000000ULL));
addConstant(*this, "SDL_WINDOW_METAL", static_cast<uint64_t>(0x20000000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_TRANSPARENT) == static_cast<uint64_t>(0x40000000ULL));
addConstant(*this, "SDL_WINDOW_TRANSPARENT", static_cast<uint64_t>(0x40000000ULL));
static_assert(static_cast<uint64_t>(SDL_WINDOW_NOT_FOCUSABLE) == static_cast<uint64_t>(0x80000000ULL));
addConstant(*this, "SDL_WINDOW_NOT_FOCUSABLE", static_cast<uint64_t>(0x80000000ULL));
static_assert(static_cast<int32_t>(SDL_WINDOWPOS_UNDEFINED) == static_cast<int32_t>(536805376ULL));
addConstant(*this, "SDL_WINDOWPOS_UNDEFINED", static_cast<int32_t>(536805376ULL));
static_assert(static_cast<int32_t>(SDL_WINDOWPOS_CENTERED) == static_cast<int32_t>(805240832ULL));
addConstant(*this, "SDL_WINDOWPOS_CENTERED", static_cast<int32_t>(805240832ULL));
static_assert(static_cast<int32_t>(SDL_WINDOW_SURFACE_VSYNC_DISABLED) == static_cast<int32_t>(0ULL));
addConstant(*this, "SDL_WINDOW_SURFACE_VSYNC_DISABLED", static_cast<int32_t>(0ULL));
static_assert(static_cast<int32_t>(SDL_WINDOW_SURFACE_VSYNC_ADAPTIVE) == static_cast<int32_t>(-1ULL));
addConstant(*this, "SDL_WINDOW_SURFACE_VSYNC_ADAPTIVE", static_cast<int32_t>(-1ULL));
static_assert(static_cast<uint32_t>(SDL_BLENDMODE_NONE) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDL_BLENDMODE_NONE", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDL_BLENDMODE_BLEND) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_BLENDMODE_BLEND", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_BLENDMODE_BLEND_PREMULTIPLIED) == static_cast<uint32_t>(0x10ULL));
addConstant(*this, "SDL_BLENDMODE_BLEND_PREMULTIPLIED", static_cast<uint32_t>(0x10ULL));
static_assert(static_cast<uint32_t>(SDL_BLENDMODE_ADD) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_BLENDMODE_ADD", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_BLENDMODE_ADD_PREMULTIPLIED) == static_cast<uint32_t>(0x20ULL));
addConstant(*this, "SDL_BLENDMODE_ADD_PREMULTIPLIED", static_cast<uint32_t>(0x20ULL));
static_assert(static_cast<uint32_t>(SDL_BLENDMODE_MOD) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_BLENDMODE_MOD", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_BLENDMODE_MUL) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDL_BLENDMODE_MUL", static_cast<uint32_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDL_BLENDMODE_INVALID) == static_cast<uint32_t>(0x7fffffffULL));
addConstant(*this, "SDL_BLENDMODE_INVALID", static_cast<uint32_t>(0x7fffffffULL));
static_assert(static_cast<int32_t>(SDL_RENDERER_VSYNC_DISABLED) == static_cast<int32_t>(0ULL));
addConstant(*this, "SDL_RENDERER_VSYNC_DISABLED", static_cast<int32_t>(0ULL));
static_assert(static_cast<int32_t>(SDL_RENDERER_VSYNC_ADAPTIVE) == static_cast<int32_t>(-1ULL));
addConstant(*this, "SDL_RENDERER_VSYNC_ADAPTIVE", static_cast<int32_t>(-1ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_FIRST) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDL_EVENT_FIRST", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_TERMINATING) == static_cast<uint32_t>(0x101ULL));
addConstant(*this, "SDL_EVENT_TERMINATING", static_cast<uint32_t>(0x101ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_LOW_MEMORY) == static_cast<uint32_t>(0x102ULL));
addConstant(*this, "SDL_EVENT_LOW_MEMORY", static_cast<uint32_t>(0x102ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WILL_ENTER_BACKGROUND) == static_cast<uint32_t>(0x103ULL));
addConstant(*this, "SDL_EVENT_WILL_ENTER_BACKGROUND", static_cast<uint32_t>(0x103ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DID_ENTER_BACKGROUND) == static_cast<uint32_t>(0x104ULL));
addConstant(*this, "SDL_EVENT_DID_ENTER_BACKGROUND", static_cast<uint32_t>(0x104ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WILL_ENTER_FOREGROUND) == static_cast<uint32_t>(0x105ULL));
addConstant(*this, "SDL_EVENT_WILL_ENTER_FOREGROUND", static_cast<uint32_t>(0x105ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DID_ENTER_FOREGROUND) == static_cast<uint32_t>(0x106ULL));
addConstant(*this, "SDL_EVENT_DID_ENTER_FOREGROUND", static_cast<uint32_t>(0x106ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_LOCALE_CHANGED) == static_cast<uint32_t>(0x107ULL));
addConstant(*this, "SDL_EVENT_LOCALE_CHANGED", static_cast<uint32_t>(0x107ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_SYSTEM_THEME_CHANGED) == static_cast<uint32_t>(0x108ULL));
addConstant(*this, "SDL_EVENT_SYSTEM_THEME_CHANGED", static_cast<uint32_t>(0x108ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DISPLAY_ORIENTATION) == static_cast<uint32_t>(0x151ULL));
addConstant(*this, "SDL_EVENT_DISPLAY_ORIENTATION", static_cast<uint32_t>(0x151ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DISPLAY_ADDED) == static_cast<uint32_t>(0x152ULL));
addConstant(*this, "SDL_EVENT_DISPLAY_ADDED", static_cast<uint32_t>(0x152ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DISPLAY_REMOVED) == static_cast<uint32_t>(0x153ULL));
addConstant(*this, "SDL_EVENT_DISPLAY_REMOVED", static_cast<uint32_t>(0x153ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DISPLAY_MOVED) == static_cast<uint32_t>(0x154ULL));
addConstant(*this, "SDL_EVENT_DISPLAY_MOVED", static_cast<uint32_t>(0x154ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED) == static_cast<uint32_t>(0x155ULL));
addConstant(*this, "SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED", static_cast<uint32_t>(0x155ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED) == static_cast<uint32_t>(0x156ULL));
addConstant(*this, "SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED", static_cast<uint32_t>(0x156ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED) == static_cast<uint32_t>(0x157ULL));
addConstant(*this, "SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED", static_cast<uint32_t>(0x157ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DISPLAY_FIRST) == static_cast<uint32_t>(0x151ULL));
addConstant(*this, "SDL_EVENT_DISPLAY_FIRST", static_cast<uint32_t>(0x151ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DISPLAY_LAST) == static_cast<uint32_t>(0x158ULL));
addConstant(*this, "SDL_EVENT_DISPLAY_LAST", static_cast<uint32_t>(0x158ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_SHOWN) == static_cast<uint32_t>(0x202ULL));
addConstant(*this, "SDL_EVENT_WINDOW_SHOWN", static_cast<uint32_t>(0x202ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_HIDDEN) == static_cast<uint32_t>(0x203ULL));
addConstant(*this, "SDL_EVENT_WINDOW_HIDDEN", static_cast<uint32_t>(0x203ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_EXPOSED) == static_cast<uint32_t>(0x204ULL));
addConstant(*this, "SDL_EVENT_WINDOW_EXPOSED", static_cast<uint32_t>(0x204ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_MOVED) == static_cast<uint32_t>(0x205ULL));
addConstant(*this, "SDL_EVENT_WINDOW_MOVED", static_cast<uint32_t>(0x205ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_RESIZED) == static_cast<uint32_t>(0x206ULL));
addConstant(*this, "SDL_EVENT_WINDOW_RESIZED", static_cast<uint32_t>(0x206ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED) == static_cast<uint32_t>(0x207ULL));
addConstant(*this, "SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED", static_cast<uint32_t>(0x207ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_METAL_VIEW_RESIZED) == static_cast<uint32_t>(0x208ULL));
addConstant(*this, "SDL_EVENT_WINDOW_METAL_VIEW_RESIZED", static_cast<uint32_t>(0x208ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_MINIMIZED) == static_cast<uint32_t>(0x209ULL));
addConstant(*this, "SDL_EVENT_WINDOW_MINIMIZED", static_cast<uint32_t>(0x209ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_MAXIMIZED) == static_cast<uint32_t>(0x20aULL));
addConstant(*this, "SDL_EVENT_WINDOW_MAXIMIZED", static_cast<uint32_t>(0x20aULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_RESTORED) == static_cast<uint32_t>(0x20bULL));
addConstant(*this, "SDL_EVENT_WINDOW_RESTORED", static_cast<uint32_t>(0x20bULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_MOUSE_ENTER) == static_cast<uint32_t>(0x20cULL));
addConstant(*this, "SDL_EVENT_WINDOW_MOUSE_ENTER", static_cast<uint32_t>(0x20cULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_MOUSE_LEAVE) == static_cast<uint32_t>(0x20dULL));
addConstant(*this, "SDL_EVENT_WINDOW_MOUSE_LEAVE", static_cast<uint32_t>(0x20dULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_FOCUS_GAINED) == static_cast<uint32_t>(0x20eULL));
addConstant(*this, "SDL_EVENT_WINDOW_FOCUS_GAINED", static_cast<uint32_t>(0x20eULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_FOCUS_LOST) == static_cast<uint32_t>(0x20fULL));
addConstant(*this, "SDL_EVENT_WINDOW_FOCUS_LOST", static_cast<uint32_t>(0x20fULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_HIT_TEST) == static_cast<uint32_t>(0x211ULL));
addConstant(*this, "SDL_EVENT_WINDOW_HIT_TEST", static_cast<uint32_t>(0x211ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_ICCPROF_CHANGED) == static_cast<uint32_t>(0x212ULL));
addConstant(*this, "SDL_EVENT_WINDOW_ICCPROF_CHANGED", static_cast<uint32_t>(0x212ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_DISPLAY_CHANGED) == static_cast<uint32_t>(0x213ULL));
addConstant(*this, "SDL_EVENT_WINDOW_DISPLAY_CHANGED", static_cast<uint32_t>(0x213ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED) == static_cast<uint32_t>(0x214ULL));
addConstant(*this, "SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED", static_cast<uint32_t>(0x214ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_SAFE_AREA_CHANGED) == static_cast<uint32_t>(0x215ULL));
addConstant(*this, "SDL_EVENT_WINDOW_SAFE_AREA_CHANGED", static_cast<uint32_t>(0x215ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_OCCLUDED) == static_cast<uint32_t>(0x216ULL));
addConstant(*this, "SDL_EVENT_WINDOW_OCCLUDED", static_cast<uint32_t>(0x216ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_ENTER_FULLSCREEN) == static_cast<uint32_t>(0x217ULL));
addConstant(*this, "SDL_EVENT_WINDOW_ENTER_FULLSCREEN", static_cast<uint32_t>(0x217ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_LEAVE_FULLSCREEN) == static_cast<uint32_t>(0x218ULL));
addConstant(*this, "SDL_EVENT_WINDOW_LEAVE_FULLSCREEN", static_cast<uint32_t>(0x218ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_DESTROYED) == static_cast<uint32_t>(0x219ULL));
addConstant(*this, "SDL_EVENT_WINDOW_DESTROYED", static_cast<uint32_t>(0x219ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_HDR_STATE_CHANGED) == static_cast<uint32_t>(0x21aULL));
addConstant(*this, "SDL_EVENT_WINDOW_HDR_STATE_CHANGED", static_cast<uint32_t>(0x21aULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_FIRST) == static_cast<uint32_t>(0x202ULL));
addConstant(*this, "SDL_EVENT_WINDOW_FIRST", static_cast<uint32_t>(0x202ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_WINDOW_LAST) == static_cast<uint32_t>(0x21aULL));
addConstant(*this, "SDL_EVENT_WINDOW_LAST", static_cast<uint32_t>(0x21aULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_KEYMAP_CHANGED) == static_cast<uint32_t>(0x304ULL));
addConstant(*this, "SDL_EVENT_KEYMAP_CHANGED", static_cast<uint32_t>(0x304ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_KEYBOARD_ADDED) == static_cast<uint32_t>(0x305ULL));
addConstant(*this, "SDL_EVENT_KEYBOARD_ADDED", static_cast<uint32_t>(0x305ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_KEYBOARD_REMOVED) == static_cast<uint32_t>(0x306ULL));
addConstant(*this, "SDL_EVENT_KEYBOARD_REMOVED", static_cast<uint32_t>(0x306ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_TEXT_EDITING_CANDIDATES) == static_cast<uint32_t>(0x307ULL));
addConstant(*this, "SDL_EVENT_TEXT_EDITING_CANDIDATES", static_cast<uint32_t>(0x307ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_MOUSE_ADDED) == static_cast<uint32_t>(0x404ULL));
addConstant(*this, "SDL_EVENT_MOUSE_ADDED", static_cast<uint32_t>(0x404ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_MOUSE_REMOVED) == static_cast<uint32_t>(0x405ULL));
addConstant(*this, "SDL_EVENT_MOUSE_REMOVED", static_cast<uint32_t>(0x405ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_JOYSTICK_AXIS_MOTION) == static_cast<uint32_t>(0x600ULL));
addConstant(*this, "SDL_EVENT_JOYSTICK_AXIS_MOTION", static_cast<uint32_t>(0x600ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_JOYSTICK_BALL_MOTION) == static_cast<uint32_t>(0x601ULL));
addConstant(*this, "SDL_EVENT_JOYSTICK_BALL_MOTION", static_cast<uint32_t>(0x601ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_JOYSTICK_HAT_MOTION) == static_cast<uint32_t>(0x602ULL));
addConstant(*this, "SDL_EVENT_JOYSTICK_HAT_MOTION", static_cast<uint32_t>(0x602ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_JOYSTICK_BUTTON_DOWN) == static_cast<uint32_t>(0x603ULL));
addConstant(*this, "SDL_EVENT_JOYSTICK_BUTTON_DOWN", static_cast<uint32_t>(0x603ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_JOYSTICK_BUTTON_UP) == static_cast<uint32_t>(0x604ULL));
addConstant(*this, "SDL_EVENT_JOYSTICK_BUTTON_UP", static_cast<uint32_t>(0x604ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_JOYSTICK_ADDED) == static_cast<uint32_t>(0x605ULL));
addConstant(*this, "SDL_EVENT_JOYSTICK_ADDED", static_cast<uint32_t>(0x605ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_JOYSTICK_REMOVED) == static_cast<uint32_t>(0x606ULL));
addConstant(*this, "SDL_EVENT_JOYSTICK_REMOVED", static_cast<uint32_t>(0x606ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_JOYSTICK_BATTERY_UPDATED) == static_cast<uint32_t>(0x607ULL));
addConstant(*this, "SDL_EVENT_JOYSTICK_BATTERY_UPDATED", static_cast<uint32_t>(0x607ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_JOYSTICK_UPDATE_COMPLETE) == static_cast<uint32_t>(0x608ULL));
addConstant(*this, "SDL_EVENT_JOYSTICK_UPDATE_COMPLETE", static_cast<uint32_t>(0x608ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_AXIS_MOTION) == static_cast<uint32_t>(0x650ULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_AXIS_MOTION", static_cast<uint32_t>(0x650ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_BUTTON_DOWN) == static_cast<uint32_t>(0x651ULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_BUTTON_DOWN", static_cast<uint32_t>(0x651ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_BUTTON_UP) == static_cast<uint32_t>(0x652ULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_BUTTON_UP", static_cast<uint32_t>(0x652ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_ADDED) == static_cast<uint32_t>(0x653ULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_ADDED", static_cast<uint32_t>(0x653ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_REMOVED) == static_cast<uint32_t>(0x654ULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_REMOVED", static_cast<uint32_t>(0x654ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_REMAPPED) == static_cast<uint32_t>(0x655ULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_REMAPPED", static_cast<uint32_t>(0x655ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN) == static_cast<uint32_t>(0x656ULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN", static_cast<uint32_t>(0x656ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION) == static_cast<uint32_t>(0x657ULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION", static_cast<uint32_t>(0x657ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_TOUCHPAD_UP) == static_cast<uint32_t>(0x658ULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_TOUCHPAD_UP", static_cast<uint32_t>(0x658ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_SENSOR_UPDATE) == static_cast<uint32_t>(0x659ULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_SENSOR_UPDATE", static_cast<uint32_t>(0x659ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_UPDATE_COMPLETE) == static_cast<uint32_t>(0x65aULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_UPDATE_COMPLETE", static_cast<uint32_t>(0x65aULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED) == static_cast<uint32_t>(0x65bULL));
addConstant(*this, "SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED", static_cast<uint32_t>(0x65bULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_FINGER_DOWN) == static_cast<uint32_t>(0x700ULL));
addConstant(*this, "SDL_EVENT_FINGER_DOWN", static_cast<uint32_t>(0x700ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_FINGER_UP) == static_cast<uint32_t>(0x701ULL));
addConstant(*this, "SDL_EVENT_FINGER_UP", static_cast<uint32_t>(0x701ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_FINGER_MOTION) == static_cast<uint32_t>(0x702ULL));
addConstant(*this, "SDL_EVENT_FINGER_MOTION", static_cast<uint32_t>(0x702ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_FINGER_CANCELED) == static_cast<uint32_t>(0x703ULL));
addConstant(*this, "SDL_EVENT_FINGER_CANCELED", static_cast<uint32_t>(0x703ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_CLIPBOARD_UPDATE) == static_cast<uint32_t>(0x900ULL));
addConstant(*this, "SDL_EVENT_CLIPBOARD_UPDATE", static_cast<uint32_t>(0x900ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DROP_FILE) == static_cast<uint32_t>(0x1000ULL));
addConstant(*this, "SDL_EVENT_DROP_FILE", static_cast<uint32_t>(0x1000ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DROP_TEXT) == static_cast<uint32_t>(0x1001ULL));
addConstant(*this, "SDL_EVENT_DROP_TEXT", static_cast<uint32_t>(0x1001ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DROP_BEGIN) == static_cast<uint32_t>(0x1002ULL));
addConstant(*this, "SDL_EVENT_DROP_BEGIN", static_cast<uint32_t>(0x1002ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DROP_COMPLETE) == static_cast<uint32_t>(0x1003ULL));
addConstant(*this, "SDL_EVENT_DROP_COMPLETE", static_cast<uint32_t>(0x1003ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_DROP_POSITION) == static_cast<uint32_t>(0x1004ULL));
addConstant(*this, "SDL_EVENT_DROP_POSITION", static_cast<uint32_t>(0x1004ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_AUDIO_DEVICE_ADDED) == static_cast<uint32_t>(0x1100ULL));
addConstant(*this, "SDL_EVENT_AUDIO_DEVICE_ADDED", static_cast<uint32_t>(0x1100ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_AUDIO_DEVICE_REMOVED) == static_cast<uint32_t>(0x1101ULL));
addConstant(*this, "SDL_EVENT_AUDIO_DEVICE_REMOVED", static_cast<uint32_t>(0x1101ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED) == static_cast<uint32_t>(0x1102ULL));
addConstant(*this, "SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED", static_cast<uint32_t>(0x1102ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_SENSOR_UPDATE) == static_cast<uint32_t>(0x1200ULL));
addConstant(*this, "SDL_EVENT_SENSOR_UPDATE", static_cast<uint32_t>(0x1200ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PEN_PROXIMITY_IN) == static_cast<uint32_t>(0x1300ULL));
addConstant(*this, "SDL_EVENT_PEN_PROXIMITY_IN", static_cast<uint32_t>(0x1300ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PEN_PROXIMITY_OUT) == static_cast<uint32_t>(0x1301ULL));
addConstant(*this, "SDL_EVENT_PEN_PROXIMITY_OUT", static_cast<uint32_t>(0x1301ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PEN_DOWN) == static_cast<uint32_t>(0x1302ULL));
addConstant(*this, "SDL_EVENT_PEN_DOWN", static_cast<uint32_t>(0x1302ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PEN_UP) == static_cast<uint32_t>(0x1303ULL));
addConstant(*this, "SDL_EVENT_PEN_UP", static_cast<uint32_t>(0x1303ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PEN_BUTTON_DOWN) == static_cast<uint32_t>(0x1304ULL));
addConstant(*this, "SDL_EVENT_PEN_BUTTON_DOWN", static_cast<uint32_t>(0x1304ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PEN_BUTTON_UP) == static_cast<uint32_t>(0x1305ULL));
addConstant(*this, "SDL_EVENT_PEN_BUTTON_UP", static_cast<uint32_t>(0x1305ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PEN_MOTION) == static_cast<uint32_t>(0x1306ULL));
addConstant(*this, "SDL_EVENT_PEN_MOTION", static_cast<uint32_t>(0x1306ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PEN_AXIS) == static_cast<uint32_t>(0x1307ULL));
addConstant(*this, "SDL_EVENT_PEN_AXIS", static_cast<uint32_t>(0x1307ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_CAMERA_DEVICE_ADDED) == static_cast<uint32_t>(0x1400ULL));
addConstant(*this, "SDL_EVENT_CAMERA_DEVICE_ADDED", static_cast<uint32_t>(0x1400ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_CAMERA_DEVICE_REMOVED) == static_cast<uint32_t>(0x1401ULL));
addConstant(*this, "SDL_EVENT_CAMERA_DEVICE_REMOVED", static_cast<uint32_t>(0x1401ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_CAMERA_DEVICE_APPROVED) == static_cast<uint32_t>(0x1402ULL));
addConstant(*this, "SDL_EVENT_CAMERA_DEVICE_APPROVED", static_cast<uint32_t>(0x1402ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_CAMERA_DEVICE_DENIED) == static_cast<uint32_t>(0x1403ULL));
addConstant(*this, "SDL_EVENT_CAMERA_DEVICE_DENIED", static_cast<uint32_t>(0x1403ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_RENDER_TARGETS_RESET) == static_cast<uint32_t>(0x2000ULL));
addConstant(*this, "SDL_EVENT_RENDER_TARGETS_RESET", static_cast<uint32_t>(0x2000ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_RENDER_DEVICE_RESET) == static_cast<uint32_t>(0x2001ULL));
addConstant(*this, "SDL_EVENT_RENDER_DEVICE_RESET", static_cast<uint32_t>(0x2001ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_RENDER_DEVICE_LOST) == static_cast<uint32_t>(0x2002ULL));
addConstant(*this, "SDL_EVENT_RENDER_DEVICE_LOST", static_cast<uint32_t>(0x2002ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PRIVATE0) == static_cast<uint32_t>(0x4000ULL));
addConstant(*this, "SDL_EVENT_PRIVATE0", static_cast<uint32_t>(0x4000ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PRIVATE1) == static_cast<uint32_t>(0x4001ULL));
addConstant(*this, "SDL_EVENT_PRIVATE1", static_cast<uint32_t>(0x4001ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PRIVATE2) == static_cast<uint32_t>(0x4002ULL));
addConstant(*this, "SDL_EVENT_PRIVATE2", static_cast<uint32_t>(0x4002ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_PRIVATE3) == static_cast<uint32_t>(0x4003ULL));
addConstant(*this, "SDL_EVENT_PRIVATE3", static_cast<uint32_t>(0x4003ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_POLL_SENTINEL) == static_cast<uint32_t>(0x7f00ULL));
addConstant(*this, "SDL_EVENT_POLL_SENTINEL", static_cast<uint32_t>(0x7f00ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_USER) == static_cast<uint32_t>(0x8000ULL));
addConstant(*this, "SDL_EVENT_USER", static_cast<uint32_t>(0x8000ULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_LAST) == static_cast<uint32_t>(0xffffULL));
addConstant(*this, "SDL_EVENT_LAST", static_cast<uint32_t>(0xffffULL));
static_assert(static_cast<uint32_t>(SDL_EVENT_ENUM_PADDING) == static_cast<uint32_t>(0x7fffffffULL));
addConstant(*this, "SDL_EVENT_ENUM_PADDING", static_cast<uint32_t>(0x7fffffffULL));
static_assert(static_cast<uint32_t>(SDLK_EXTENDED_MASK) == static_cast<uint32_t>(0x20000000ULL));
addConstant(*this, "SDLK_EXTENDED_MASK", static_cast<uint32_t>(0x20000000ULL));
static_assert(static_cast<uint32_t>(SDLK_SCANCODE_MASK) == static_cast<uint32_t>(0x40000000ULL));
addConstant(*this, "SDLK_SCANCODE_MASK", static_cast<uint32_t>(0x40000000ULL));
static_assert(static_cast<uint32_t>(SDLK_UNKNOWN) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDLK_UNKNOWN", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDLK_TAB) == static_cast<uint32_t>(0x9ULL));
addConstant(*this, "SDLK_TAB", static_cast<uint32_t>(0x9ULL));
static_assert(static_cast<uint32_t>(SDLK_SPACE) == static_cast<uint32_t>(0x20ULL));
addConstant(*this, "SDLK_SPACE", static_cast<uint32_t>(0x20ULL));
static_assert(static_cast<uint32_t>(SDLK_EXCLAIM) == static_cast<uint32_t>(0x21ULL));
addConstant(*this, "SDLK_EXCLAIM", static_cast<uint32_t>(0x21ULL));
static_assert(static_cast<uint32_t>(SDLK_DBLAPOSTROPHE) == static_cast<uint32_t>(0x22ULL));
addConstant(*this, "SDLK_DBLAPOSTROPHE", static_cast<uint32_t>(0x22ULL));
static_assert(static_cast<uint32_t>(SDLK_HASH) == static_cast<uint32_t>(0x23ULL));
addConstant(*this, "SDLK_HASH", static_cast<uint32_t>(0x23ULL));
static_assert(static_cast<uint32_t>(SDLK_DOLLAR) == static_cast<uint32_t>(0x24ULL));
addConstant(*this, "SDLK_DOLLAR", static_cast<uint32_t>(0x24ULL));
static_assert(static_cast<uint32_t>(SDLK_PERCENT) == static_cast<uint32_t>(0x25ULL));
addConstant(*this, "SDLK_PERCENT", static_cast<uint32_t>(0x25ULL));
static_assert(static_cast<uint32_t>(SDLK_AMPERSAND) == static_cast<uint32_t>(0x26ULL));
addConstant(*this, "SDLK_AMPERSAND", static_cast<uint32_t>(0x26ULL));
static_assert(static_cast<uint32_t>(SDLK_APOSTROPHE) == static_cast<uint32_t>(0x27ULL));
addConstant(*this, "SDLK_APOSTROPHE", static_cast<uint32_t>(0x27ULL));
static_assert(static_cast<uint32_t>(SDLK_LEFTPAREN) == static_cast<uint32_t>(0x28ULL));
addConstant(*this, "SDLK_LEFTPAREN", static_cast<uint32_t>(0x28ULL));
static_assert(static_cast<uint32_t>(SDLK_RIGHTPAREN) == static_cast<uint32_t>(0x29ULL));
addConstant(*this, "SDLK_RIGHTPAREN", static_cast<uint32_t>(0x29ULL));
static_assert(static_cast<uint32_t>(SDLK_ASTERISK) == static_cast<uint32_t>(0x2aULL));
addConstant(*this, "SDLK_ASTERISK", static_cast<uint32_t>(0x2aULL));
static_assert(static_cast<uint32_t>(SDLK_PLUS) == static_cast<uint32_t>(0x2bULL));
addConstant(*this, "SDLK_PLUS", static_cast<uint32_t>(0x2bULL));
static_assert(static_cast<uint32_t>(SDLK_COMMA) == static_cast<uint32_t>(0x2cULL));
addConstant(*this, "SDLK_COMMA", static_cast<uint32_t>(0x2cULL));
static_assert(static_cast<uint32_t>(SDLK_MINUS) == static_cast<uint32_t>(0x2dULL));
addConstant(*this, "SDLK_MINUS", static_cast<uint32_t>(0x2dULL));
static_assert(static_cast<uint32_t>(SDLK_PERIOD) == static_cast<uint32_t>(0x2eULL));
addConstant(*this, "SDLK_PERIOD", static_cast<uint32_t>(0x2eULL));
static_assert(static_cast<uint32_t>(SDLK_SLASH) == static_cast<uint32_t>(0x2fULL));
addConstant(*this, "SDLK_SLASH", static_cast<uint32_t>(0x2fULL));
static_assert(static_cast<uint32_t>(SDLK_0) == static_cast<uint32_t>(0x30ULL));
addConstant(*this, "SDLK_0", static_cast<uint32_t>(0x30ULL));
static_assert(static_cast<uint32_t>(SDLK_1) == static_cast<uint32_t>(0x31ULL));
addConstant(*this, "SDLK_1", static_cast<uint32_t>(0x31ULL));
static_assert(static_cast<uint32_t>(SDLK_2) == static_cast<uint32_t>(0x32ULL));
addConstant(*this, "SDLK_2", static_cast<uint32_t>(0x32ULL));
static_assert(static_cast<uint32_t>(SDLK_3) == static_cast<uint32_t>(0x33ULL));
addConstant(*this, "SDLK_3", static_cast<uint32_t>(0x33ULL));
static_assert(static_cast<uint32_t>(SDLK_4) == static_cast<uint32_t>(0x34ULL));
addConstant(*this, "SDLK_4", static_cast<uint32_t>(0x34ULL));
static_assert(static_cast<uint32_t>(SDLK_5) == static_cast<uint32_t>(0x35ULL));
addConstant(*this, "SDLK_5", static_cast<uint32_t>(0x35ULL));
static_assert(static_cast<uint32_t>(SDLK_6) == static_cast<uint32_t>(0x36ULL));
addConstant(*this, "SDLK_6", static_cast<uint32_t>(0x36ULL));
static_assert(static_cast<uint32_t>(SDLK_7) == static_cast<uint32_t>(0x37ULL));
addConstant(*this, "SDLK_7", static_cast<uint32_t>(0x37ULL));
static_assert(static_cast<uint32_t>(SDLK_8) == static_cast<uint32_t>(0x38ULL));
addConstant(*this, "SDLK_8", static_cast<uint32_t>(0x38ULL));
static_assert(static_cast<uint32_t>(SDLK_9) == static_cast<uint32_t>(0x39ULL));
addConstant(*this, "SDLK_9", static_cast<uint32_t>(0x39ULL));
static_assert(static_cast<uint32_t>(SDLK_COLON) == static_cast<uint32_t>(0x3aULL));
addConstant(*this, "SDLK_COLON", static_cast<uint32_t>(0x3aULL));
static_assert(static_cast<uint32_t>(SDLK_SEMICOLON) == static_cast<uint32_t>(0x3bULL));
addConstant(*this, "SDLK_SEMICOLON", static_cast<uint32_t>(0x3bULL));
static_assert(static_cast<uint32_t>(SDLK_LESS) == static_cast<uint32_t>(0x3cULL));
addConstant(*this, "SDLK_LESS", static_cast<uint32_t>(0x3cULL));
static_assert(static_cast<uint32_t>(SDLK_EQUALS) == static_cast<uint32_t>(0x3dULL));
addConstant(*this, "SDLK_EQUALS", static_cast<uint32_t>(0x3dULL));
static_assert(static_cast<uint32_t>(SDLK_GREATER) == static_cast<uint32_t>(0x3eULL));
addConstant(*this, "SDLK_GREATER", static_cast<uint32_t>(0x3eULL));
static_assert(static_cast<uint32_t>(SDLK_QUESTION) == static_cast<uint32_t>(0x3fULL));
addConstant(*this, "SDLK_QUESTION", static_cast<uint32_t>(0x3fULL));
static_assert(static_cast<uint32_t>(SDLK_AT) == static_cast<uint32_t>(0x40ULL));
addConstant(*this, "SDLK_AT", static_cast<uint32_t>(0x40ULL));
static_assert(static_cast<uint32_t>(SDLK_LEFTBRACKET) == static_cast<uint32_t>(0x5bULL));
addConstant(*this, "SDLK_LEFTBRACKET", static_cast<uint32_t>(0x5bULL));
static_assert(static_cast<uint32_t>(SDLK_BACKSLASH) == static_cast<uint32_t>(0x5cULL));
addConstant(*this, "SDLK_BACKSLASH", static_cast<uint32_t>(0x5cULL));
static_assert(static_cast<uint32_t>(SDLK_RIGHTBRACKET) == static_cast<uint32_t>(0x5dULL));
addConstant(*this, "SDLK_RIGHTBRACKET", static_cast<uint32_t>(0x5dULL));
static_assert(static_cast<uint32_t>(SDLK_CARET) == static_cast<uint32_t>(0x5eULL));
addConstant(*this, "SDLK_CARET", static_cast<uint32_t>(0x5eULL));
static_assert(static_cast<uint32_t>(SDLK_UNDERSCORE) == static_cast<uint32_t>(0x5fULL));
addConstant(*this, "SDLK_UNDERSCORE", static_cast<uint32_t>(0x5fULL));
static_assert(static_cast<uint32_t>(SDLK_GRAVE) == static_cast<uint32_t>(0x60ULL));
addConstant(*this, "SDLK_GRAVE", static_cast<uint32_t>(0x60ULL));
static_assert(static_cast<uint32_t>(SDLK_A) == static_cast<uint32_t>(0x61ULL));
addConstant(*this, "SDLK_A", static_cast<uint32_t>(0x61ULL));
static_assert(static_cast<uint32_t>(SDLK_B) == static_cast<uint32_t>(0x62ULL));
addConstant(*this, "SDLK_B", static_cast<uint32_t>(0x62ULL));
static_assert(static_cast<uint32_t>(SDLK_C) == static_cast<uint32_t>(0x63ULL));
addConstant(*this, "SDLK_C", static_cast<uint32_t>(0x63ULL));
static_assert(static_cast<uint32_t>(SDLK_D) == static_cast<uint32_t>(0x64ULL));
addConstant(*this, "SDLK_D", static_cast<uint32_t>(0x64ULL));
static_assert(static_cast<uint32_t>(SDLK_E) == static_cast<uint32_t>(0x65ULL));
addConstant(*this, "SDLK_E", static_cast<uint32_t>(0x65ULL));
static_assert(static_cast<uint32_t>(SDLK_F) == static_cast<uint32_t>(0x66ULL));
addConstant(*this, "SDLK_F", static_cast<uint32_t>(0x66ULL));
static_assert(static_cast<uint32_t>(SDLK_G) == static_cast<uint32_t>(0x67ULL));
addConstant(*this, "SDLK_G", static_cast<uint32_t>(0x67ULL));
static_assert(static_cast<uint32_t>(SDLK_H) == static_cast<uint32_t>(0x68ULL));
addConstant(*this, "SDLK_H", static_cast<uint32_t>(0x68ULL));
static_assert(static_cast<uint32_t>(SDLK_I) == static_cast<uint32_t>(0x69ULL));
addConstant(*this, "SDLK_I", static_cast<uint32_t>(0x69ULL));
static_assert(static_cast<uint32_t>(SDLK_J) == static_cast<uint32_t>(0x6aULL));
addConstant(*this, "SDLK_J", static_cast<uint32_t>(0x6aULL));
static_assert(static_cast<uint32_t>(SDLK_K) == static_cast<uint32_t>(0x6bULL));
addConstant(*this, "SDLK_K", static_cast<uint32_t>(0x6bULL));
static_assert(static_cast<uint32_t>(SDLK_L) == static_cast<uint32_t>(0x6cULL));
addConstant(*this, "SDLK_L", static_cast<uint32_t>(0x6cULL));
static_assert(static_cast<uint32_t>(SDLK_M) == static_cast<uint32_t>(0x6dULL));
addConstant(*this, "SDLK_M", static_cast<uint32_t>(0x6dULL));
static_assert(static_cast<uint32_t>(SDLK_N) == static_cast<uint32_t>(0x6eULL));
addConstant(*this, "SDLK_N", static_cast<uint32_t>(0x6eULL));
static_assert(static_cast<uint32_t>(SDLK_O) == static_cast<uint32_t>(0x6fULL));
addConstant(*this, "SDLK_O", static_cast<uint32_t>(0x6fULL));
static_assert(static_cast<uint32_t>(SDLK_P) == static_cast<uint32_t>(0x70ULL));
addConstant(*this, "SDLK_P", static_cast<uint32_t>(0x70ULL));
static_assert(static_cast<uint32_t>(SDLK_Q) == static_cast<uint32_t>(0x71ULL));
addConstant(*this, "SDLK_Q", static_cast<uint32_t>(0x71ULL));
static_assert(static_cast<uint32_t>(SDLK_R) == static_cast<uint32_t>(0x72ULL));
addConstant(*this, "SDLK_R", static_cast<uint32_t>(0x72ULL));
static_assert(static_cast<uint32_t>(SDLK_S) == static_cast<uint32_t>(0x73ULL));
addConstant(*this, "SDLK_S", static_cast<uint32_t>(0x73ULL));
static_assert(static_cast<uint32_t>(SDLK_T) == static_cast<uint32_t>(0x74ULL));
addConstant(*this, "SDLK_T", static_cast<uint32_t>(0x74ULL));
static_assert(static_cast<uint32_t>(SDLK_U) == static_cast<uint32_t>(0x75ULL));
addConstant(*this, "SDLK_U", static_cast<uint32_t>(0x75ULL));
static_assert(static_cast<uint32_t>(SDLK_V) == static_cast<uint32_t>(0x76ULL));
addConstant(*this, "SDLK_V", static_cast<uint32_t>(0x76ULL));
static_assert(static_cast<uint32_t>(SDLK_W) == static_cast<uint32_t>(0x77ULL));
addConstant(*this, "SDLK_W", static_cast<uint32_t>(0x77ULL));
static_assert(static_cast<uint32_t>(SDLK_X) == static_cast<uint32_t>(0x78ULL));
addConstant(*this, "SDLK_X", static_cast<uint32_t>(0x78ULL));
static_assert(static_cast<uint32_t>(SDLK_Y) == static_cast<uint32_t>(0x79ULL));
addConstant(*this, "SDLK_Y", static_cast<uint32_t>(0x79ULL));
static_assert(static_cast<uint32_t>(SDLK_Z) == static_cast<uint32_t>(0x7aULL));
addConstant(*this, "SDLK_Z", static_cast<uint32_t>(0x7aULL));
static_assert(static_cast<uint32_t>(SDLK_LEFTBRACE) == static_cast<uint32_t>(0x7bULL));
addConstant(*this, "SDLK_LEFTBRACE", static_cast<uint32_t>(0x7bULL));
static_assert(static_cast<uint32_t>(SDLK_PIPE) == static_cast<uint32_t>(0x7cULL));
addConstant(*this, "SDLK_PIPE", static_cast<uint32_t>(0x7cULL));
static_assert(static_cast<uint32_t>(SDLK_RIGHTBRACE) == static_cast<uint32_t>(0x7dULL));
addConstant(*this, "SDLK_RIGHTBRACE", static_cast<uint32_t>(0x7dULL));
static_assert(static_cast<uint32_t>(SDLK_TILDE) == static_cast<uint32_t>(0x7eULL));
addConstant(*this, "SDLK_TILDE", static_cast<uint32_t>(0x7eULL));
static_assert(static_cast<uint32_t>(SDLK_DELETE) == static_cast<uint32_t>(0x7fULL));
addConstant(*this, "SDLK_DELETE", static_cast<uint32_t>(0x7fULL));
static_assert(static_cast<uint32_t>(SDLK_PLUSMINUS) == static_cast<uint32_t>(0xb1ULL));
addConstant(*this, "SDLK_PLUSMINUS", static_cast<uint32_t>(0xb1ULL));
static_assert(static_cast<uint32_t>(SDLK_CAPSLOCK) == static_cast<uint32_t>(0x40000039ULL));
addConstant(*this, "SDLK_CAPSLOCK", static_cast<uint32_t>(0x40000039ULL));
static_assert(static_cast<uint32_t>(SDLK_F1) == static_cast<uint32_t>(0x4000003aULL));
addConstant(*this, "SDLK_F1", static_cast<uint32_t>(0x4000003aULL));
static_assert(static_cast<uint32_t>(SDLK_F2) == static_cast<uint32_t>(0x4000003bULL));
addConstant(*this, "SDLK_F2", static_cast<uint32_t>(0x4000003bULL));
static_assert(static_cast<uint32_t>(SDLK_F3) == static_cast<uint32_t>(0x4000003cULL));
addConstant(*this, "SDLK_F3", static_cast<uint32_t>(0x4000003cULL));
static_assert(static_cast<uint32_t>(SDLK_F4) == static_cast<uint32_t>(0x4000003dULL));
addConstant(*this, "SDLK_F4", static_cast<uint32_t>(0x4000003dULL));
static_assert(static_cast<uint32_t>(SDLK_F5) == static_cast<uint32_t>(0x4000003eULL));
addConstant(*this, "SDLK_F5", static_cast<uint32_t>(0x4000003eULL));
static_assert(static_cast<uint32_t>(SDLK_F6) == static_cast<uint32_t>(0x4000003fULL));
addConstant(*this, "SDLK_F6", static_cast<uint32_t>(0x4000003fULL));
static_assert(static_cast<uint32_t>(SDLK_F7) == static_cast<uint32_t>(0x40000040ULL));
addConstant(*this, "SDLK_F7", static_cast<uint32_t>(0x40000040ULL));
static_assert(static_cast<uint32_t>(SDLK_F8) == static_cast<uint32_t>(0x40000041ULL));
addConstant(*this, "SDLK_F8", static_cast<uint32_t>(0x40000041ULL));
static_assert(static_cast<uint32_t>(SDLK_F9) == static_cast<uint32_t>(0x40000042ULL));
addConstant(*this, "SDLK_F9", static_cast<uint32_t>(0x40000042ULL));
static_assert(static_cast<uint32_t>(SDLK_F10) == static_cast<uint32_t>(0x40000043ULL));
addConstant(*this, "SDLK_F10", static_cast<uint32_t>(0x40000043ULL));
static_assert(static_cast<uint32_t>(SDLK_F11) == static_cast<uint32_t>(0x40000044ULL));
addConstant(*this, "SDLK_F11", static_cast<uint32_t>(0x40000044ULL));
static_assert(static_cast<uint32_t>(SDLK_F12) == static_cast<uint32_t>(0x40000045ULL));
addConstant(*this, "SDLK_F12", static_cast<uint32_t>(0x40000045ULL));
static_assert(static_cast<uint32_t>(SDLK_PRINTSCREEN) == static_cast<uint32_t>(0x40000046ULL));
addConstant(*this, "SDLK_PRINTSCREEN", static_cast<uint32_t>(0x40000046ULL));
static_assert(static_cast<uint32_t>(SDLK_SCROLLLOCK) == static_cast<uint32_t>(0x40000047ULL));
addConstant(*this, "SDLK_SCROLLLOCK", static_cast<uint32_t>(0x40000047ULL));
static_assert(static_cast<uint32_t>(SDLK_PAUSE) == static_cast<uint32_t>(0x40000048ULL));
addConstant(*this, "SDLK_PAUSE", static_cast<uint32_t>(0x40000048ULL));
static_assert(static_cast<uint32_t>(SDLK_INSERT) == static_cast<uint32_t>(0x40000049ULL));
addConstant(*this, "SDLK_INSERT", static_cast<uint32_t>(0x40000049ULL));
static_assert(static_cast<uint32_t>(SDLK_HOME) == static_cast<uint32_t>(0x4000004aULL));
addConstant(*this, "SDLK_HOME", static_cast<uint32_t>(0x4000004aULL));
static_assert(static_cast<uint32_t>(SDLK_PAGEUP) == static_cast<uint32_t>(0x4000004bULL));
addConstant(*this, "SDLK_PAGEUP", static_cast<uint32_t>(0x4000004bULL));
static_assert(static_cast<uint32_t>(SDLK_END) == static_cast<uint32_t>(0x4000004dULL));
addConstant(*this, "SDLK_END", static_cast<uint32_t>(0x4000004dULL));
static_assert(static_cast<uint32_t>(SDLK_PAGEDOWN) == static_cast<uint32_t>(0x4000004eULL));
addConstant(*this, "SDLK_PAGEDOWN", static_cast<uint32_t>(0x4000004eULL));
static_assert(static_cast<uint32_t>(SDLK_NUMLOCKCLEAR) == static_cast<uint32_t>(0x40000053ULL));
addConstant(*this, "SDLK_NUMLOCKCLEAR", static_cast<uint32_t>(0x40000053ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_DIVIDE) == static_cast<uint32_t>(0x40000054ULL));
addConstant(*this, "SDLK_KP_DIVIDE", static_cast<uint32_t>(0x40000054ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_MULTIPLY) == static_cast<uint32_t>(0x40000055ULL));
addConstant(*this, "SDLK_KP_MULTIPLY", static_cast<uint32_t>(0x40000055ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_MINUS) == static_cast<uint32_t>(0x40000056ULL));
addConstant(*this, "SDLK_KP_MINUS", static_cast<uint32_t>(0x40000056ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_PLUS) == static_cast<uint32_t>(0x40000057ULL));
addConstant(*this, "SDLK_KP_PLUS", static_cast<uint32_t>(0x40000057ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_ENTER) == static_cast<uint32_t>(0x40000058ULL));
addConstant(*this, "SDLK_KP_ENTER", static_cast<uint32_t>(0x40000058ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_1) == static_cast<uint32_t>(0x40000059ULL));
addConstant(*this, "SDLK_KP_1", static_cast<uint32_t>(0x40000059ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_2) == static_cast<uint32_t>(0x4000005aULL));
addConstant(*this, "SDLK_KP_2", static_cast<uint32_t>(0x4000005aULL));
static_assert(static_cast<uint32_t>(SDLK_KP_3) == static_cast<uint32_t>(0x4000005bULL));
addConstant(*this, "SDLK_KP_3", static_cast<uint32_t>(0x4000005bULL));
static_assert(static_cast<uint32_t>(SDLK_KP_4) == static_cast<uint32_t>(0x4000005cULL));
addConstant(*this, "SDLK_KP_4", static_cast<uint32_t>(0x4000005cULL));
static_assert(static_cast<uint32_t>(SDLK_KP_5) == static_cast<uint32_t>(0x4000005dULL));
addConstant(*this, "SDLK_KP_5", static_cast<uint32_t>(0x4000005dULL));
static_assert(static_cast<uint32_t>(SDLK_KP_6) == static_cast<uint32_t>(0x4000005eULL));
addConstant(*this, "SDLK_KP_6", static_cast<uint32_t>(0x4000005eULL));
static_assert(static_cast<uint32_t>(SDLK_KP_7) == static_cast<uint32_t>(0x4000005fULL));
addConstant(*this, "SDLK_KP_7", static_cast<uint32_t>(0x4000005fULL));
static_assert(static_cast<uint32_t>(SDLK_KP_8) == static_cast<uint32_t>(0x40000060ULL));
addConstant(*this, "SDLK_KP_8", static_cast<uint32_t>(0x40000060ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_9) == static_cast<uint32_t>(0x40000061ULL));
addConstant(*this, "SDLK_KP_9", static_cast<uint32_t>(0x40000061ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_0) == static_cast<uint32_t>(0x40000062ULL));
addConstant(*this, "SDLK_KP_0", static_cast<uint32_t>(0x40000062ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_PERIOD) == static_cast<uint32_t>(0x40000063ULL));
addConstant(*this, "SDLK_KP_PERIOD", static_cast<uint32_t>(0x40000063ULL));
static_assert(static_cast<uint32_t>(SDLK_APPLICATION) == static_cast<uint32_t>(0x40000065ULL));
addConstant(*this, "SDLK_APPLICATION", static_cast<uint32_t>(0x40000065ULL));
static_assert(static_cast<uint32_t>(SDLK_POWER) == static_cast<uint32_t>(0x40000066ULL));
addConstant(*this, "SDLK_POWER", static_cast<uint32_t>(0x40000066ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_EQUALS) == static_cast<uint32_t>(0x40000067ULL));
addConstant(*this, "SDLK_KP_EQUALS", static_cast<uint32_t>(0x40000067ULL));
static_assert(static_cast<uint32_t>(SDLK_F13) == static_cast<uint32_t>(0x40000068ULL));
addConstant(*this, "SDLK_F13", static_cast<uint32_t>(0x40000068ULL));
static_assert(static_cast<uint32_t>(SDLK_F14) == static_cast<uint32_t>(0x40000069ULL));
addConstant(*this, "SDLK_F14", static_cast<uint32_t>(0x40000069ULL));
static_assert(static_cast<uint32_t>(SDLK_F15) == static_cast<uint32_t>(0x4000006aULL));
addConstant(*this, "SDLK_F15", static_cast<uint32_t>(0x4000006aULL));
static_assert(static_cast<uint32_t>(SDLK_F16) == static_cast<uint32_t>(0x4000006bULL));
addConstant(*this, "SDLK_F16", static_cast<uint32_t>(0x4000006bULL));
static_assert(static_cast<uint32_t>(SDLK_F17) == static_cast<uint32_t>(0x4000006cULL));
addConstant(*this, "SDLK_F17", static_cast<uint32_t>(0x4000006cULL));
static_assert(static_cast<uint32_t>(SDLK_F18) == static_cast<uint32_t>(0x4000006dULL));
addConstant(*this, "SDLK_F18", static_cast<uint32_t>(0x4000006dULL));
static_assert(static_cast<uint32_t>(SDLK_F19) == static_cast<uint32_t>(0x4000006eULL));
addConstant(*this, "SDLK_F19", static_cast<uint32_t>(0x4000006eULL));
static_assert(static_cast<uint32_t>(SDLK_F20) == static_cast<uint32_t>(0x4000006fULL));
addConstant(*this, "SDLK_F20", static_cast<uint32_t>(0x4000006fULL));
static_assert(static_cast<uint32_t>(SDLK_F21) == static_cast<uint32_t>(0x40000070ULL));
addConstant(*this, "SDLK_F21", static_cast<uint32_t>(0x40000070ULL));
static_assert(static_cast<uint32_t>(SDLK_F22) == static_cast<uint32_t>(0x40000071ULL));
addConstant(*this, "SDLK_F22", static_cast<uint32_t>(0x40000071ULL));
static_assert(static_cast<uint32_t>(SDLK_F23) == static_cast<uint32_t>(0x40000072ULL));
addConstant(*this, "SDLK_F23", static_cast<uint32_t>(0x40000072ULL));
static_assert(static_cast<uint32_t>(SDLK_F24) == static_cast<uint32_t>(0x40000073ULL));
addConstant(*this, "SDLK_F24", static_cast<uint32_t>(0x40000073ULL));
static_assert(static_cast<uint32_t>(SDLK_EXECUTE) == static_cast<uint32_t>(0x40000074ULL));
addConstant(*this, "SDLK_EXECUTE", static_cast<uint32_t>(0x40000074ULL));
static_assert(static_cast<uint32_t>(SDLK_HELP) == static_cast<uint32_t>(0x40000075ULL));
addConstant(*this, "SDLK_HELP", static_cast<uint32_t>(0x40000075ULL));
static_assert(static_cast<uint32_t>(SDLK_MENU) == static_cast<uint32_t>(0x40000076ULL));
addConstant(*this, "SDLK_MENU", static_cast<uint32_t>(0x40000076ULL));
static_assert(static_cast<uint32_t>(SDLK_SELECT) == static_cast<uint32_t>(0x40000077ULL));
addConstant(*this, "SDLK_SELECT", static_cast<uint32_t>(0x40000077ULL));
static_assert(static_cast<uint32_t>(SDLK_STOP) == static_cast<uint32_t>(0x40000078ULL));
addConstant(*this, "SDLK_STOP", static_cast<uint32_t>(0x40000078ULL));
static_assert(static_cast<uint32_t>(SDLK_AGAIN) == static_cast<uint32_t>(0x40000079ULL));
addConstant(*this, "SDLK_AGAIN", static_cast<uint32_t>(0x40000079ULL));
static_assert(static_cast<uint32_t>(SDLK_UNDO) == static_cast<uint32_t>(0x4000007aULL));
addConstant(*this, "SDLK_UNDO", static_cast<uint32_t>(0x4000007aULL));
static_assert(static_cast<uint32_t>(SDLK_CUT) == static_cast<uint32_t>(0x4000007bULL));
addConstant(*this, "SDLK_CUT", static_cast<uint32_t>(0x4000007bULL));
static_assert(static_cast<uint32_t>(SDLK_COPY) == static_cast<uint32_t>(0x4000007cULL));
addConstant(*this, "SDLK_COPY", static_cast<uint32_t>(0x4000007cULL));
static_assert(static_cast<uint32_t>(SDLK_PASTE) == static_cast<uint32_t>(0x4000007dULL));
addConstant(*this, "SDLK_PASTE", static_cast<uint32_t>(0x4000007dULL));
static_assert(static_cast<uint32_t>(SDLK_FIND) == static_cast<uint32_t>(0x4000007eULL));
addConstant(*this, "SDLK_FIND", static_cast<uint32_t>(0x4000007eULL));
static_assert(static_cast<uint32_t>(SDLK_MUTE) == static_cast<uint32_t>(0x4000007fULL));
addConstant(*this, "SDLK_MUTE", static_cast<uint32_t>(0x4000007fULL));
static_assert(static_cast<uint32_t>(SDLK_VOLUMEUP) == static_cast<uint32_t>(0x40000080ULL));
addConstant(*this, "SDLK_VOLUMEUP", static_cast<uint32_t>(0x40000080ULL));
static_assert(static_cast<uint32_t>(SDLK_VOLUMEDOWN) == static_cast<uint32_t>(0x40000081ULL));
addConstant(*this, "SDLK_VOLUMEDOWN", static_cast<uint32_t>(0x40000081ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_COMMA) == static_cast<uint32_t>(0x40000085ULL));
addConstant(*this, "SDLK_KP_COMMA", static_cast<uint32_t>(0x40000085ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_EQUALSAS400) == static_cast<uint32_t>(0x40000086ULL));
addConstant(*this, "SDLK_KP_EQUALSAS400", static_cast<uint32_t>(0x40000086ULL));
static_assert(static_cast<uint32_t>(SDLK_ALTERASE) == static_cast<uint32_t>(0x40000099ULL));
addConstant(*this, "SDLK_ALTERASE", static_cast<uint32_t>(0x40000099ULL));
static_assert(static_cast<uint32_t>(SDLK_SYSREQ) == static_cast<uint32_t>(0x4000009aULL));
addConstant(*this, "SDLK_SYSREQ", static_cast<uint32_t>(0x4000009aULL));
static_assert(static_cast<uint32_t>(SDLK_CANCEL) == static_cast<uint32_t>(0x4000009bULL));
addConstant(*this, "SDLK_CANCEL", static_cast<uint32_t>(0x4000009bULL));
static_assert(static_cast<uint32_t>(SDLK_CLEAR) == static_cast<uint32_t>(0x4000009cULL));
addConstant(*this, "SDLK_CLEAR", static_cast<uint32_t>(0x4000009cULL));
static_assert(static_cast<uint32_t>(SDLK_PRIOR) == static_cast<uint32_t>(0x4000009dULL));
addConstant(*this, "SDLK_PRIOR", static_cast<uint32_t>(0x4000009dULL));
static_assert(static_cast<uint32_t>(SDLK_RETURN2) == static_cast<uint32_t>(0x4000009eULL));
addConstant(*this, "SDLK_RETURN2", static_cast<uint32_t>(0x4000009eULL));
static_assert(static_cast<uint32_t>(SDLK_SEPARATOR) == static_cast<uint32_t>(0x4000009fULL));
addConstant(*this, "SDLK_SEPARATOR", static_cast<uint32_t>(0x4000009fULL));
static_assert(static_cast<uint32_t>(SDLK_OUT) == static_cast<uint32_t>(0x400000a0ULL));
addConstant(*this, "SDLK_OUT", static_cast<uint32_t>(0x400000a0ULL));
static_assert(static_cast<uint32_t>(SDLK_OPER) == static_cast<uint32_t>(0x400000a1ULL));
addConstant(*this, "SDLK_OPER", static_cast<uint32_t>(0x400000a1ULL));
static_assert(static_cast<uint32_t>(SDLK_CLEARAGAIN) == static_cast<uint32_t>(0x400000a2ULL));
addConstant(*this, "SDLK_CLEARAGAIN", static_cast<uint32_t>(0x400000a2ULL));
static_assert(static_cast<uint32_t>(SDLK_CRSEL) == static_cast<uint32_t>(0x400000a3ULL));
addConstant(*this, "SDLK_CRSEL", static_cast<uint32_t>(0x400000a3ULL));
static_assert(static_cast<uint32_t>(SDLK_EXSEL) == static_cast<uint32_t>(0x400000a4ULL));
addConstant(*this, "SDLK_EXSEL", static_cast<uint32_t>(0x400000a4ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_00) == static_cast<uint32_t>(0x400000b0ULL));
addConstant(*this, "SDLK_KP_00", static_cast<uint32_t>(0x400000b0ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_000) == static_cast<uint32_t>(0x400000b1ULL));
addConstant(*this, "SDLK_KP_000", static_cast<uint32_t>(0x400000b1ULL));
static_assert(static_cast<uint32_t>(SDLK_THOUSANDSSEPARATOR) == static_cast<uint32_t>(0x400000b2ULL));
addConstant(*this, "SDLK_THOUSANDSSEPARATOR", static_cast<uint32_t>(0x400000b2ULL));
static_assert(static_cast<uint32_t>(SDLK_DECIMALSEPARATOR) == static_cast<uint32_t>(0x400000b3ULL));
addConstant(*this, "SDLK_DECIMALSEPARATOR", static_cast<uint32_t>(0x400000b3ULL));
static_assert(static_cast<uint32_t>(SDLK_CURRENCYUNIT) == static_cast<uint32_t>(0x400000b4ULL));
addConstant(*this, "SDLK_CURRENCYUNIT", static_cast<uint32_t>(0x400000b4ULL));
static_assert(static_cast<uint32_t>(SDLK_CURRENCYSUBUNIT) == static_cast<uint32_t>(0x400000b5ULL));
addConstant(*this, "SDLK_CURRENCYSUBUNIT", static_cast<uint32_t>(0x400000b5ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_LEFTPAREN) == static_cast<uint32_t>(0x400000b6ULL));
addConstant(*this, "SDLK_KP_LEFTPAREN", static_cast<uint32_t>(0x400000b6ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_RIGHTPAREN) == static_cast<uint32_t>(0x400000b7ULL));
addConstant(*this, "SDLK_KP_RIGHTPAREN", static_cast<uint32_t>(0x400000b7ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_LEFTBRACE) == static_cast<uint32_t>(0x400000b8ULL));
addConstant(*this, "SDLK_KP_LEFTBRACE", static_cast<uint32_t>(0x400000b8ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_RIGHTBRACE) == static_cast<uint32_t>(0x400000b9ULL));
addConstant(*this, "SDLK_KP_RIGHTBRACE", static_cast<uint32_t>(0x400000b9ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_TAB) == static_cast<uint32_t>(0x400000baULL));
addConstant(*this, "SDLK_KP_TAB", static_cast<uint32_t>(0x400000baULL));
static_assert(static_cast<uint32_t>(SDLK_KP_BACKSPACE) == static_cast<uint32_t>(0x400000bbULL));
addConstant(*this, "SDLK_KP_BACKSPACE", static_cast<uint32_t>(0x400000bbULL));
static_assert(static_cast<uint32_t>(SDLK_KP_A) == static_cast<uint32_t>(0x400000bcULL));
addConstant(*this, "SDLK_KP_A", static_cast<uint32_t>(0x400000bcULL));
static_assert(static_cast<uint32_t>(SDLK_KP_B) == static_cast<uint32_t>(0x400000bdULL));
addConstant(*this, "SDLK_KP_B", static_cast<uint32_t>(0x400000bdULL));
static_assert(static_cast<uint32_t>(SDLK_KP_C) == static_cast<uint32_t>(0x400000beULL));
addConstant(*this, "SDLK_KP_C", static_cast<uint32_t>(0x400000beULL));
static_assert(static_cast<uint32_t>(SDLK_KP_D) == static_cast<uint32_t>(0x400000bfULL));
addConstant(*this, "SDLK_KP_D", static_cast<uint32_t>(0x400000bfULL));
static_assert(static_cast<uint32_t>(SDLK_KP_E) == static_cast<uint32_t>(0x400000c0ULL));
addConstant(*this, "SDLK_KP_E", static_cast<uint32_t>(0x400000c0ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_F) == static_cast<uint32_t>(0x400000c1ULL));
addConstant(*this, "SDLK_KP_F", static_cast<uint32_t>(0x400000c1ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_XOR) == static_cast<uint32_t>(0x400000c2ULL));
addConstant(*this, "SDLK_KP_XOR", static_cast<uint32_t>(0x400000c2ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_POWER) == static_cast<uint32_t>(0x400000c3ULL));
addConstant(*this, "SDLK_KP_POWER", static_cast<uint32_t>(0x400000c3ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_PERCENT) == static_cast<uint32_t>(0x400000c4ULL));
addConstant(*this, "SDLK_KP_PERCENT", static_cast<uint32_t>(0x400000c4ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_LESS) == static_cast<uint32_t>(0x400000c5ULL));
addConstant(*this, "SDLK_KP_LESS", static_cast<uint32_t>(0x400000c5ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_GREATER) == static_cast<uint32_t>(0x400000c6ULL));
addConstant(*this, "SDLK_KP_GREATER", static_cast<uint32_t>(0x400000c6ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_AMPERSAND) == static_cast<uint32_t>(0x400000c7ULL));
addConstant(*this, "SDLK_KP_AMPERSAND", static_cast<uint32_t>(0x400000c7ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_DBLAMPERSAND) == static_cast<uint32_t>(0x400000c8ULL));
addConstant(*this, "SDLK_KP_DBLAMPERSAND", static_cast<uint32_t>(0x400000c8ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_VERTICALBAR) == static_cast<uint32_t>(0x400000c9ULL));
addConstant(*this, "SDLK_KP_VERTICALBAR", static_cast<uint32_t>(0x400000c9ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_DBLVERTICALBAR) == static_cast<uint32_t>(0x400000caULL));
addConstant(*this, "SDLK_KP_DBLVERTICALBAR", static_cast<uint32_t>(0x400000caULL));
static_assert(static_cast<uint32_t>(SDLK_KP_COLON) == static_cast<uint32_t>(0x400000cbULL));
addConstant(*this, "SDLK_KP_COLON", static_cast<uint32_t>(0x400000cbULL));
static_assert(static_cast<uint32_t>(SDLK_KP_HASH) == static_cast<uint32_t>(0x400000ccULL));
addConstant(*this, "SDLK_KP_HASH", static_cast<uint32_t>(0x400000ccULL));
static_assert(static_cast<uint32_t>(SDLK_KP_SPACE) == static_cast<uint32_t>(0x400000cdULL));
addConstant(*this, "SDLK_KP_SPACE", static_cast<uint32_t>(0x400000cdULL));
static_assert(static_cast<uint32_t>(SDLK_KP_AT) == static_cast<uint32_t>(0x400000ceULL));
addConstant(*this, "SDLK_KP_AT", static_cast<uint32_t>(0x400000ceULL));
static_assert(static_cast<uint32_t>(SDLK_KP_EXCLAM) == static_cast<uint32_t>(0x400000cfULL));
addConstant(*this, "SDLK_KP_EXCLAM", static_cast<uint32_t>(0x400000cfULL));
static_assert(static_cast<uint32_t>(SDLK_KP_MEMSTORE) == static_cast<uint32_t>(0x400000d0ULL));
addConstant(*this, "SDLK_KP_MEMSTORE", static_cast<uint32_t>(0x400000d0ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_MEMRECALL) == static_cast<uint32_t>(0x400000d1ULL));
addConstant(*this, "SDLK_KP_MEMRECALL", static_cast<uint32_t>(0x400000d1ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_MEMCLEAR) == static_cast<uint32_t>(0x400000d2ULL));
addConstant(*this, "SDLK_KP_MEMCLEAR", static_cast<uint32_t>(0x400000d2ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_MEMADD) == static_cast<uint32_t>(0x400000d3ULL));
addConstant(*this, "SDLK_KP_MEMADD", static_cast<uint32_t>(0x400000d3ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_MEMSUBTRACT) == static_cast<uint32_t>(0x400000d4ULL));
addConstant(*this, "SDLK_KP_MEMSUBTRACT", static_cast<uint32_t>(0x400000d4ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_MEMMULTIPLY) == static_cast<uint32_t>(0x400000d5ULL));
addConstant(*this, "SDLK_KP_MEMMULTIPLY", static_cast<uint32_t>(0x400000d5ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_MEMDIVIDE) == static_cast<uint32_t>(0x400000d6ULL));
addConstant(*this, "SDLK_KP_MEMDIVIDE", static_cast<uint32_t>(0x400000d6ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_PLUSMINUS) == static_cast<uint32_t>(0x400000d7ULL));
addConstant(*this, "SDLK_KP_PLUSMINUS", static_cast<uint32_t>(0x400000d7ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_CLEAR) == static_cast<uint32_t>(0x400000d8ULL));
addConstant(*this, "SDLK_KP_CLEAR", static_cast<uint32_t>(0x400000d8ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_CLEARENTRY) == static_cast<uint32_t>(0x400000d9ULL));
addConstant(*this, "SDLK_KP_CLEARENTRY", static_cast<uint32_t>(0x400000d9ULL));
static_assert(static_cast<uint32_t>(SDLK_KP_BINARY) == static_cast<uint32_t>(0x400000daULL));
addConstant(*this, "SDLK_KP_BINARY", static_cast<uint32_t>(0x400000daULL));
static_assert(static_cast<uint32_t>(SDLK_KP_OCTAL) == static_cast<uint32_t>(0x400000dbULL));
addConstant(*this, "SDLK_KP_OCTAL", static_cast<uint32_t>(0x400000dbULL));
static_assert(static_cast<uint32_t>(SDLK_KP_DECIMAL) == static_cast<uint32_t>(0x400000dcULL));
addConstant(*this, "SDLK_KP_DECIMAL", static_cast<uint32_t>(0x400000dcULL));
static_assert(static_cast<uint32_t>(SDLK_KP_HEXADECIMAL) == static_cast<uint32_t>(0x400000ddULL));
addConstant(*this, "SDLK_KP_HEXADECIMAL", static_cast<uint32_t>(0x400000ddULL));
static_assert(static_cast<uint32_t>(SDLK_LCTRL) == static_cast<uint32_t>(0x400000e0ULL));
addConstant(*this, "SDLK_LCTRL", static_cast<uint32_t>(0x400000e0ULL));
static_assert(static_cast<uint32_t>(SDLK_LSHIFT) == static_cast<uint32_t>(0x400000e1ULL));
addConstant(*this, "SDLK_LSHIFT", static_cast<uint32_t>(0x400000e1ULL));
static_assert(static_cast<uint32_t>(SDLK_LALT) == static_cast<uint32_t>(0x400000e2ULL));
addConstant(*this, "SDLK_LALT", static_cast<uint32_t>(0x400000e2ULL));
static_assert(static_cast<uint32_t>(SDLK_LGUI) == static_cast<uint32_t>(0x400000e3ULL));
addConstant(*this, "SDLK_LGUI", static_cast<uint32_t>(0x400000e3ULL));
static_assert(static_cast<uint32_t>(SDLK_RCTRL) == static_cast<uint32_t>(0x400000e4ULL));
addConstant(*this, "SDLK_RCTRL", static_cast<uint32_t>(0x400000e4ULL));
static_assert(static_cast<uint32_t>(SDLK_RSHIFT) == static_cast<uint32_t>(0x400000e5ULL));
addConstant(*this, "SDLK_RSHIFT", static_cast<uint32_t>(0x400000e5ULL));
static_assert(static_cast<uint32_t>(SDLK_RALT) == static_cast<uint32_t>(0x400000e6ULL));
addConstant(*this, "SDLK_RALT", static_cast<uint32_t>(0x400000e6ULL));
static_assert(static_cast<uint32_t>(SDLK_RGUI) == static_cast<uint32_t>(0x400000e7ULL));
addConstant(*this, "SDLK_RGUI", static_cast<uint32_t>(0x400000e7ULL));
static_assert(static_cast<uint32_t>(SDLK_MODE) == static_cast<uint32_t>(0x40000101ULL));
addConstant(*this, "SDLK_MODE", static_cast<uint32_t>(0x40000101ULL));
static_assert(static_cast<uint32_t>(SDLK_SLEEP) == static_cast<uint32_t>(0x40000102ULL));
addConstant(*this, "SDLK_SLEEP", static_cast<uint32_t>(0x40000102ULL));
static_assert(static_cast<uint32_t>(SDLK_WAKE) == static_cast<uint32_t>(0x40000103ULL));
addConstant(*this, "SDLK_WAKE", static_cast<uint32_t>(0x40000103ULL));
static_assert(static_cast<uint32_t>(SDLK_CHANNEL_INCREMENT) == static_cast<uint32_t>(0x40000104ULL));
addConstant(*this, "SDLK_CHANNEL_INCREMENT", static_cast<uint32_t>(0x40000104ULL));
static_assert(static_cast<uint32_t>(SDLK_CHANNEL_DECREMENT) == static_cast<uint32_t>(0x40000105ULL));
addConstant(*this, "SDLK_CHANNEL_DECREMENT", static_cast<uint32_t>(0x40000105ULL));
static_assert(static_cast<uint32_t>(SDLK_MEDIA_PLAY) == static_cast<uint32_t>(0x40000106ULL));
addConstant(*this, "SDLK_MEDIA_PLAY", static_cast<uint32_t>(0x40000106ULL));
static_assert(static_cast<uint32_t>(SDLK_MEDIA_PAUSE) == static_cast<uint32_t>(0x40000107ULL));
addConstant(*this, "SDLK_MEDIA_PAUSE", static_cast<uint32_t>(0x40000107ULL));
static_assert(static_cast<uint32_t>(SDLK_MEDIA_RECORD) == static_cast<uint32_t>(0x40000108ULL));
addConstant(*this, "SDLK_MEDIA_RECORD", static_cast<uint32_t>(0x40000108ULL));
static_assert(static_cast<uint32_t>(SDLK_MEDIA_FAST_FORWARD) == static_cast<uint32_t>(0x40000109ULL));
addConstant(*this, "SDLK_MEDIA_FAST_FORWARD", static_cast<uint32_t>(0x40000109ULL));
static_assert(static_cast<uint32_t>(SDLK_MEDIA_REWIND) == static_cast<uint32_t>(0x4000010aULL));
addConstant(*this, "SDLK_MEDIA_REWIND", static_cast<uint32_t>(0x4000010aULL));
static_assert(static_cast<uint32_t>(SDLK_MEDIA_NEXT_TRACK) == static_cast<uint32_t>(0x4000010bULL));
addConstant(*this, "SDLK_MEDIA_NEXT_TRACK", static_cast<uint32_t>(0x4000010bULL));
static_assert(static_cast<uint32_t>(SDLK_MEDIA_PREVIOUS_TRACK) == static_cast<uint32_t>(0x4000010cULL));
addConstant(*this, "SDLK_MEDIA_PREVIOUS_TRACK", static_cast<uint32_t>(0x4000010cULL));
static_assert(static_cast<uint32_t>(SDLK_MEDIA_STOP) == static_cast<uint32_t>(0x4000010dULL));
addConstant(*this, "SDLK_MEDIA_STOP", static_cast<uint32_t>(0x4000010dULL));
static_assert(static_cast<uint32_t>(SDLK_MEDIA_EJECT) == static_cast<uint32_t>(0x4000010eULL));
addConstant(*this, "SDLK_MEDIA_EJECT", static_cast<uint32_t>(0x4000010eULL));
static_assert(static_cast<uint32_t>(SDLK_MEDIA_PLAY_PAUSE) == static_cast<uint32_t>(0x4000010fULL));
addConstant(*this, "SDLK_MEDIA_PLAY_PAUSE", static_cast<uint32_t>(0x4000010fULL));
static_assert(static_cast<uint32_t>(SDLK_MEDIA_SELECT) == static_cast<uint32_t>(0x40000110ULL));
addConstant(*this, "SDLK_MEDIA_SELECT", static_cast<uint32_t>(0x40000110ULL));
static_assert(static_cast<uint32_t>(SDLK_AC_NEW) == static_cast<uint32_t>(0x40000111ULL));
addConstant(*this, "SDLK_AC_NEW", static_cast<uint32_t>(0x40000111ULL));
static_assert(static_cast<uint32_t>(SDLK_AC_OPEN) == static_cast<uint32_t>(0x40000112ULL));
addConstant(*this, "SDLK_AC_OPEN", static_cast<uint32_t>(0x40000112ULL));
static_assert(static_cast<uint32_t>(SDLK_AC_CLOSE) == static_cast<uint32_t>(0x40000113ULL));
addConstant(*this, "SDLK_AC_CLOSE", static_cast<uint32_t>(0x40000113ULL));
static_assert(static_cast<uint32_t>(SDLK_AC_EXIT) == static_cast<uint32_t>(0x40000114ULL));
addConstant(*this, "SDLK_AC_EXIT", static_cast<uint32_t>(0x40000114ULL));
static_assert(static_cast<uint32_t>(SDLK_AC_SAVE) == static_cast<uint32_t>(0x40000115ULL));
addConstant(*this, "SDLK_AC_SAVE", static_cast<uint32_t>(0x40000115ULL));
static_assert(static_cast<uint32_t>(SDLK_AC_PRINT) == static_cast<uint32_t>(0x40000116ULL));
addConstant(*this, "SDLK_AC_PRINT", static_cast<uint32_t>(0x40000116ULL));
static_assert(static_cast<uint32_t>(SDLK_AC_PROPERTIES) == static_cast<uint32_t>(0x40000117ULL));
addConstant(*this, "SDLK_AC_PROPERTIES", static_cast<uint32_t>(0x40000117ULL));
static_assert(static_cast<uint32_t>(SDLK_AC_SEARCH) == static_cast<uint32_t>(0x40000118ULL));
addConstant(*this, "SDLK_AC_SEARCH", static_cast<uint32_t>(0x40000118ULL));
static_assert(static_cast<uint32_t>(SDLK_AC_HOME) == static_cast<uint32_t>(0x40000119ULL));
addConstant(*this, "SDLK_AC_HOME", static_cast<uint32_t>(0x40000119ULL));
static_assert(static_cast<uint32_t>(SDLK_AC_BACK) == static_cast<uint32_t>(0x4000011aULL));
addConstant(*this, "SDLK_AC_BACK", static_cast<uint32_t>(0x4000011aULL));
static_assert(static_cast<uint32_t>(SDLK_AC_FORWARD) == static_cast<uint32_t>(0x4000011bULL));
addConstant(*this, "SDLK_AC_FORWARD", static_cast<uint32_t>(0x4000011bULL));
static_assert(static_cast<uint32_t>(SDLK_AC_STOP) == static_cast<uint32_t>(0x4000011cULL));
addConstant(*this, "SDLK_AC_STOP", static_cast<uint32_t>(0x4000011cULL));
static_assert(static_cast<uint32_t>(SDLK_AC_REFRESH) == static_cast<uint32_t>(0x4000011dULL));
addConstant(*this, "SDLK_AC_REFRESH", static_cast<uint32_t>(0x4000011dULL));
static_assert(static_cast<uint32_t>(SDLK_AC_BOOKMARKS) == static_cast<uint32_t>(0x4000011eULL));
addConstant(*this, "SDLK_AC_BOOKMARKS", static_cast<uint32_t>(0x4000011eULL));
static_assert(static_cast<uint32_t>(SDLK_SOFTLEFT) == static_cast<uint32_t>(0x4000011fULL));
addConstant(*this, "SDLK_SOFTLEFT", static_cast<uint32_t>(0x4000011fULL));
static_assert(static_cast<uint32_t>(SDLK_SOFTRIGHT) == static_cast<uint32_t>(0x40000120ULL));
addConstant(*this, "SDLK_SOFTRIGHT", static_cast<uint32_t>(0x40000120ULL));
static_assert(static_cast<uint32_t>(SDLK_CALL) == static_cast<uint32_t>(0x40000121ULL));
addConstant(*this, "SDLK_CALL", static_cast<uint32_t>(0x40000121ULL));
static_assert(static_cast<uint32_t>(SDLK_ENDCALL) == static_cast<uint32_t>(0x40000122ULL));
addConstant(*this, "SDLK_ENDCALL", static_cast<uint32_t>(0x40000122ULL));
static_assert(static_cast<uint32_t>(SDLK_LEFT_TAB) == static_cast<uint32_t>(0x20000001ULL));
addConstant(*this, "SDLK_LEFT_TAB", static_cast<uint32_t>(0x20000001ULL));
static_assert(static_cast<uint32_t>(SDLK_LEVEL5_SHIFT) == static_cast<uint32_t>(0x20000002ULL));
addConstant(*this, "SDLK_LEVEL5_SHIFT", static_cast<uint32_t>(0x20000002ULL));
static_assert(static_cast<uint32_t>(SDLK_MULTI_KEY_COMPOSE) == static_cast<uint32_t>(0x20000003ULL));
addConstant(*this, "SDLK_MULTI_KEY_COMPOSE", static_cast<uint32_t>(0x20000003ULL));
static_assert(static_cast<uint32_t>(SDLK_LMETA) == static_cast<uint32_t>(0x20000004ULL));
addConstant(*this, "SDLK_LMETA", static_cast<uint32_t>(0x20000004ULL));
static_assert(static_cast<uint32_t>(SDLK_RMETA) == static_cast<uint32_t>(0x20000005ULL));
addConstant(*this, "SDLK_RMETA", static_cast<uint32_t>(0x20000005ULL));
static_assert(static_cast<uint32_t>(SDLK_LHYPER) == static_cast<uint32_t>(0x20000006ULL));
addConstant(*this, "SDLK_LHYPER", static_cast<uint32_t>(0x20000006ULL));
static_assert(static_cast<uint32_t>(SDLK_RHYPER) == static_cast<uint32_t>(0x20000007ULL));
addConstant(*this, "SDLK_RHYPER", static_cast<uint32_t>(0x20000007ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_NONE) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDL_KMOD_NONE", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_LSHIFT) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_KMOD_LSHIFT", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_RSHIFT) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_KMOD_RSHIFT", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_LEVEL5) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_KMOD_LEVEL5", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_LCTRL) == static_cast<uint32_t>(0x40ULL));
addConstant(*this, "SDL_KMOD_LCTRL", static_cast<uint32_t>(0x40ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_RCTRL) == static_cast<uint32_t>(0x80ULL));
addConstant(*this, "SDL_KMOD_RCTRL", static_cast<uint32_t>(0x80ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_LALT) == static_cast<uint32_t>(0x100ULL));
addConstant(*this, "SDL_KMOD_LALT", static_cast<uint32_t>(0x100ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_RALT) == static_cast<uint32_t>(0x200ULL));
addConstant(*this, "SDL_KMOD_RALT", static_cast<uint32_t>(0x200ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_LGUI) == static_cast<uint32_t>(0x400ULL));
addConstant(*this, "SDL_KMOD_LGUI", static_cast<uint32_t>(0x400ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_RGUI) == static_cast<uint32_t>(0x800ULL));
addConstant(*this, "SDL_KMOD_RGUI", static_cast<uint32_t>(0x800ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_NUM) == static_cast<uint32_t>(0x1000ULL));
addConstant(*this, "SDL_KMOD_NUM", static_cast<uint32_t>(0x1000ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_CAPS) == static_cast<uint32_t>(0x2000ULL));
addConstant(*this, "SDL_KMOD_CAPS", static_cast<uint32_t>(0x2000ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_MODE) == static_cast<uint32_t>(0x4000ULL));
addConstant(*this, "SDL_KMOD_MODE", static_cast<uint32_t>(0x4000ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_SCROLL) == static_cast<uint32_t>(0x8000ULL));
addConstant(*this, "SDL_KMOD_SCROLL", static_cast<uint32_t>(0x8000ULL));
static_assert(static_cast<uint32_t>(SDL_KMOD_GUI) == static_cast<uint32_t>(0xc00ULL));
addConstant(*this, "SDL_KMOD_GUI", static_cast<uint32_t>(0xc00ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_X1) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_BUTTON_X1", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_X2) == static_cast<uint32_t>(0x5ULL));
addConstant(*this, "SDL_BUTTON_X2", static_cast<uint32_t>(0x5ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_X1MASK) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDL_BUTTON_X1MASK", static_cast<uint32_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDL_BUTTON_X2MASK) == static_cast<uint32_t>(0x10ULL));
addConstant(*this, "SDL_BUTTON_X2MASK", static_cast<uint32_t>(0x10ULL));
static_assert(static_cast<uint32_t>(SDL_HAT_CENTERED) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDL_HAT_CENTERED", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDL_HAT_UP) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_HAT_UP", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_HAT_RIGHT) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_HAT_RIGHT", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_HAT_DOWN) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_HAT_DOWN", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_HAT_LEFT) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDL_HAT_LEFT", static_cast<uint32_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDL_HAT_RIGHTUP) == static_cast<uint32_t>(0x3ULL));
addConstant(*this, "SDL_HAT_RIGHTUP", static_cast<uint32_t>(0x3ULL));
static_assert(static_cast<uint32_t>(SDL_HAT_RIGHTDOWN) == static_cast<uint32_t>(0x6ULL));
addConstant(*this, "SDL_HAT_RIGHTDOWN", static_cast<uint32_t>(0x6ULL));
static_assert(static_cast<uint32_t>(SDL_HAT_LEFTUP) == static_cast<uint32_t>(0x9ULL));
addConstant(*this, "SDL_HAT_LEFTUP", static_cast<uint32_t>(0x9ULL));
static_assert(static_cast<uint32_t>(SDL_HAT_LEFTDOWN) == static_cast<uint32_t>(0xcULL));
addConstant(*this, "SDL_HAT_LEFTDOWN", static_cast<uint32_t>(0xcULL));
static_assert(static_cast<uint32_t>(SDL_PEN_INPUT_DOWN) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_PEN_INPUT_DOWN", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_PEN_INPUT_BUTTON_1) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_PEN_INPUT_BUTTON_1", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_PEN_INPUT_BUTTON_2) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_PEN_INPUT_BUTTON_2", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_PEN_INPUT_BUTTON_3) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDL_PEN_INPUT_BUTTON_3", static_cast<uint32_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDL_PEN_INPUT_BUTTON_4) == static_cast<uint32_t>(0x10ULL));
addConstant(*this, "SDL_PEN_INPUT_BUTTON_4", static_cast<uint32_t>(0x10ULL));
static_assert(static_cast<uint32_t>(SDL_PEN_INPUT_BUTTON_5) == static_cast<uint32_t>(0x20ULL));
addConstant(*this, "SDL_PEN_INPUT_BUTTON_5", static_cast<uint32_t>(0x20ULL));
static_assert(static_cast<uint32_t>(SDL_PEN_INPUT_ERASER_TIP) == static_cast<uint32_t>(0x40000000ULL));
addConstant(*this, "SDL_PEN_INPUT_ERASER_TIP", static_cast<uint32_t>(0x40000000ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_CONSTANT) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_HAPTIC_CONSTANT", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_SINE) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_HAPTIC_SINE", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_SQUARE) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_HAPTIC_SQUARE", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_TRIANGLE) == static_cast<uint32_t>(0x8ULL));
addConstant(*this, "SDL_HAPTIC_TRIANGLE", static_cast<uint32_t>(0x8ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_SAWTOOTHUP) == static_cast<uint32_t>(0x10ULL));
addConstant(*this, "SDL_HAPTIC_SAWTOOTHUP", static_cast<uint32_t>(0x10ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_SAWTOOTHDOWN) == static_cast<uint32_t>(0x20ULL));
addConstant(*this, "SDL_HAPTIC_SAWTOOTHDOWN", static_cast<uint32_t>(0x20ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_RAMP) == static_cast<uint32_t>(0x40ULL));
addConstant(*this, "SDL_HAPTIC_RAMP", static_cast<uint32_t>(0x40ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_SPRING) == static_cast<uint32_t>(0x80ULL));
addConstant(*this, "SDL_HAPTIC_SPRING", static_cast<uint32_t>(0x80ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_DAMPER) == static_cast<uint32_t>(0x100ULL));
addConstant(*this, "SDL_HAPTIC_DAMPER", static_cast<uint32_t>(0x100ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_INERTIA) == static_cast<uint32_t>(0x200ULL));
addConstant(*this, "SDL_HAPTIC_INERTIA", static_cast<uint32_t>(0x200ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_FRICTION) == static_cast<uint32_t>(0x400ULL));
addConstant(*this, "SDL_HAPTIC_FRICTION", static_cast<uint32_t>(0x400ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_LEFTRIGHT) == static_cast<uint32_t>(0x800ULL));
addConstant(*this, "SDL_HAPTIC_LEFTRIGHT", static_cast<uint32_t>(0x800ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_RESERVED1) == static_cast<uint32_t>(0x1000ULL));
addConstant(*this, "SDL_HAPTIC_RESERVED1", static_cast<uint32_t>(0x1000ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_RESERVED2) == static_cast<uint32_t>(0x2000ULL));
addConstant(*this, "SDL_HAPTIC_RESERVED2", static_cast<uint32_t>(0x2000ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_RESERVED3) == static_cast<uint32_t>(0x4000ULL));
addConstant(*this, "SDL_HAPTIC_RESERVED3", static_cast<uint32_t>(0x4000ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_CUSTOM) == static_cast<uint32_t>(0x8000ULL));
addConstant(*this, "SDL_HAPTIC_CUSTOM", static_cast<uint32_t>(0x8000ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_GAIN) == static_cast<uint32_t>(0x10000ULL));
addConstant(*this, "SDL_HAPTIC_GAIN", static_cast<uint32_t>(0x10000ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_AUTOCENTER) == static_cast<uint32_t>(0x20000ULL));
addConstant(*this, "SDL_HAPTIC_AUTOCENTER", static_cast<uint32_t>(0x20000ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_STATUS) == static_cast<uint32_t>(0x40000ULL));
addConstant(*this, "SDL_HAPTIC_STATUS", static_cast<uint32_t>(0x40000ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_PAUSE) == static_cast<uint32_t>(0x80000ULL));
addConstant(*this, "SDL_HAPTIC_PAUSE", static_cast<uint32_t>(0x80000ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_POLAR) == static_cast<uint32_t>(0x0ULL));
addConstant(*this, "SDL_HAPTIC_POLAR", static_cast<uint32_t>(0x0ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_CARTESIAN) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_HAPTIC_CARTESIAN", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_SPHERICAL) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_HAPTIC_SPHERICAL", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_STEERING_AXIS) == static_cast<uint32_t>(0x3ULL));
addConstant(*this, "SDL_HAPTIC_STEERING_AXIS", static_cast<uint32_t>(0x3ULL));
static_assert(static_cast<uint32_t>(SDL_HAPTIC_INFINITY) == static_cast<uint32_t>(0xffffffffULL));
addConstant(*this, "SDL_HAPTIC_INFINITY", static_cast<uint32_t>(0xffffffffULL));
static_assert(static_cast<uint32_t>(SDL_TOUCH_MOUSEID) == static_cast<uint32_t>(0xffffffffULL));
addConstant(*this, "SDL_TOUCH_MOUSEID", static_cast<uint32_t>(0xffffffffULL));
static_assert(static_cast<uint32_t>(SDL_PEN_MOUSEID) == static_cast<uint32_t>(0xfffffffeULL));
addConstant(*this, "SDL_PEN_MOUSEID", static_cast<uint32_t>(0xfffffffeULL));
static_assert(static_cast<uint64_t>(SDL_MOUSE_TOUCHID) == static_cast<uint64_t>(0xffffffffffffffffULL));
addConstant(*this, "SDL_MOUSE_TOUCHID", static_cast<uint64_t>(0xffffffffffffffffULL));
static_assert(static_cast<uint64_t>(SDL_PEN_TOUCHID) == static_cast<uint64_t>(0xfffffffffffffffeULL));
addConstant(*this, "SDL_PEN_TOUCHID", static_cast<uint64_t>(0xfffffffffffffffeULL));
static_assert(static_cast<float>(SDL_STANDARD_GRAVITY) == static_cast<float>(9.806650161743164));
addConstant(*this, "SDL_STANDARD_GRAVITY", static_cast<float>(9.806650161743164));
static_assert(static_cast<uint32_t>(SDL_GLOB_CASEINSENSITIVE) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_GLOB_CASEINSENSITIVE", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_AUDIO_DEVICE_DEFAULT_RECORDING) == static_cast<uint32_t>(0xfffffffeULL));
addConstant(*this, "SDL_AUDIO_DEVICE_DEFAULT_RECORDING", static_cast<uint32_t>(0xfffffffeULL));
static_assert(static_cast<uint32_t>(SDL_TRAYENTRY_BUTTON) == static_cast<uint32_t>(0x1ULL));
addConstant(*this, "SDL_TRAYENTRY_BUTTON", static_cast<uint32_t>(0x1ULL));
static_assert(static_cast<uint32_t>(SDL_TRAYENTRY_CHECKBOX) == static_cast<uint32_t>(0x2ULL));
addConstant(*this, "SDL_TRAYENTRY_CHECKBOX", static_cast<uint32_t>(0x2ULL));
static_assert(static_cast<uint32_t>(SDL_TRAYENTRY_SUBMENU) == static_cast<uint32_t>(0x4ULL));
addConstant(*this, "SDL_TRAYENTRY_SUBMENU", static_cast<uint32_t>(0x4ULL));
static_assert(static_cast<uint32_t>(SDL_TRAYENTRY_DISABLED) == static_cast<uint32_t>(0x80000000ULL));
addConstant(*this, "SDL_TRAYENTRY_DISABLED", static_cast<uint32_t>(0x80000000ULL));
static_assert(static_cast<uint32_t>(SDL_TRAYENTRY_CHECKED) == static_cast<uint32_t>(0x40000000ULL));
addConstant(*this, "SDL_TRAYENTRY_CHECKED", static_cast<uint32_t>(0x40000000ULL));
// from SDL3/SDL_stdinc.h:1427:34
	makeExtern< void (*)(void *) , SDL_free , SimNode_ExtFuncCall >(lib,"SDL_free","SDL_free")
		->args({"mem"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_asyncio.h:224:43
	makeExtern< struct SDL_AsyncIO * (*)(const char *,const char *) , SDL_AsyncIOFromFile , SimNode_ExtFuncCall >(lib,"SDL_AsyncIOFromFile","SDL_AsyncIOFromFile")
		->args({"file","mode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_asyncio.h:241:36
	makeExtern< Sint64 (*)(struct SDL_AsyncIO *) , SDL_GetAsyncIOSize , SimNode_ExtFuncCall >(lib,"SDL_GetAsyncIOSize","SDL_GetAsyncIOSize")
		->args({"asyncio"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_asyncio.h:279:34
	makeExtern< bool (*)(struct SDL_AsyncIO *,void *,Uint64,Uint64,struct SDL_AsyncIOQueue *,void *) , SDL_ReadAsyncIO , SimNode_ExtFuncCall >(lib,"SDL_ReadAsyncIO","SDL_ReadAsyncIO")
		->args({"asyncio","ptr","offset","size","queue","userdata"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_asyncio.h:316:34
	makeExtern< bool (*)(struct SDL_AsyncIO *,void *,Uint64,Uint64,struct SDL_AsyncIOQueue *,void *) , SDL_WriteAsyncIO , SimNode_ExtFuncCall >(lib,"SDL_WriteAsyncIO","SDL_WriteAsyncIO")
		->args({"asyncio","ptr","offset","size","queue","userdata"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_asyncio.h:365:34
	makeExtern< bool (*)(struct SDL_AsyncIO *,bool,struct SDL_AsyncIOQueue *,void *) , SDL_CloseAsyncIO , SimNode_ExtFuncCall >(lib,"SDL_CloseAsyncIO","SDL_CloseAsyncIO")
		->args({"asyncio","flush","queue","userdata"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_asyncio.h:384:48
	makeExtern< struct SDL_AsyncIOQueue * (*)() , SDL_CreateAsyncIOQueue , SimNode_ExtFuncCall >(lib,"SDL_CreateAsyncIOQueue","SDL_CreateAsyncIOQueue")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_asyncio.h:414:34
	makeExtern< void (*)(struct SDL_AsyncIOQueue *) , SDL_DestroyAsyncIOQueue , SimNode_ExtFuncCall >(lib,"SDL_DestroyAsyncIOQueue","SDL_DestroyAsyncIOQueue")
		->args({"queue"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_asyncio.h:440:34
	makeExtern< bool (*)(struct SDL_AsyncIOQueue *,struct SDL_AsyncIOOutcome *) , SDL_GetAsyncIOResult , SimNode_ExtFuncCall >(lib,"SDL_GetAsyncIOResult","SDL_GetAsyncIOResult")
		->args({"queue","outcome"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_asyncio.h:484:34
	makeExtern< bool (*)(struct SDL_AsyncIOQueue *,struct SDL_AsyncIOOutcome *,int) , SDL_WaitAsyncIOResult , SimNode_ExtFuncCall >(lib,"SDL_WaitAsyncIOResult","SDL_WaitAsyncIOResult")
		->args({"queue","outcome","timeoutMS"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_asyncio.h:508:34
	makeExtern< void (*)(struct SDL_AsyncIOQueue *) , SDL_SignalAsyncIOQueue , SimNode_ExtFuncCall >(lib,"SDL_SignalAsyncIOQueue","SDL_SignalAsyncIOQueue")
		->args({"queue"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_asyncio.h:542:34
	makeExtern< bool (*)(const char *,struct SDL_AsyncIOQueue *,void *) , SDL_LoadFileAsync , SimNode_ExtFuncCall >(lib,"SDL_LoadFileAsync","SDL_LoadFileAsync")
		->args({"file","queue","userdata"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:100:34
	makeExtern< bool (*)(int *) , SDL_TryLockSpinlock , SimNode_ExtFuncCall >(lib,"SDL_TryLockSpinlock","SDL_TryLockSpinlock")
		->args({"lock"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:117:34
	makeExtern< void (*)(int *) , SDL_LockSpinlock , SimNode_ExtFuncCall >(lib,"SDL_LockSpinlock","SDL_LockSpinlock")
		->args({"lock"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:136:34
	makeExtern< void (*)(int *) , SDL_UnlockSpinlock , SimNode_ExtFuncCall >(lib,"SDL_UnlockSpinlock","SDL_UnlockSpinlock")
		->args({"lock"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:195:34
	makeExtern< void (*)() , SDL_MemoryBarrierReleaseFunction , SimNode_ExtFuncCall >(lib,"SDL_MemoryBarrierReleaseFunction","SDL_MemoryBarrierReleaseFunction")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:215:34
	makeExtern< void (*)() , SDL_MemoryBarrierAcquireFunction , SimNode_ExtFuncCall >(lib,"SDL_MemoryBarrierAcquireFunction","SDL_MemoryBarrierAcquireFunction")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:425:34
	makeExtern< bool (*)(struct SDL_AtomicInt *,int,int) , SDL_CompareAndSwapAtomicInt , SimNode_ExtFuncCall >(lib,"SDL_CompareAndSwapAtomicInt","SDL_CompareAndSwapAtomicInt")
		->args({"a","oldval","newval"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:445:33
	makeExtern< int (*)(struct SDL_AtomicInt *,int) , SDL_SetAtomicInt , SimNode_ExtFuncCall >(lib,"SDL_SetAtomicInt","SDL_SetAtomicInt")
		->args({"a","v"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:462:33
	makeExtern< int (*)(struct SDL_AtomicInt *) , SDL_GetAtomicInt , SimNode_ExtFuncCall >(lib,"SDL_GetAtomicInt","SDL_GetAtomicInt")
		->args({"a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:483:33
	makeExtern< int (*)(struct SDL_AtomicInt *,int) , SDL_AddAtomicInt , SimNode_ExtFuncCall >(lib,"SDL_AddAtomicInt","SDL_AddAtomicInt")
		->args({"a","v"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:570:34
	makeExtern< bool (*)(struct SDL_AtomicU32 *,unsigned int,unsigned int) , SDL_CompareAndSwapAtomicU32 , SimNode_ExtFuncCall >(lib,"SDL_CompareAndSwapAtomicU32","SDL_CompareAndSwapAtomicU32")
		->args({"a","oldval","newval"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:590:36
	makeExtern< unsigned int (*)(struct SDL_AtomicU32 *,unsigned int) , SDL_SetAtomicU32 , SimNode_ExtFuncCall >(lib,"SDL_SetAtomicU32","SDL_SetAtomicU32")
		->args({"a","v"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:607:36
	makeExtern< unsigned int (*)(struct SDL_AtomicU32 *) , SDL_GetAtomicU32 , SimNode_ExtFuncCall >(lib,"SDL_GetAtomicU32","SDL_GetAtomicU32")
		->args({"a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:625:36
	makeExtern< unsigned int (*)(struct SDL_AtomicU32 *,int) , SDL_AddAtomicU32 , SimNode_ExtFuncCall >(lib,"SDL_AddAtomicU32","SDL_AddAtomicU32")
		->args({"a","v"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:646:34
	makeExtern< bool (*)(void **,void *,void *) , SDL_CompareAndSwapAtomicPointer , SimNode_ExtFuncCall >(lib,"SDL_CompareAndSwapAtomicPointer","SDL_CompareAndSwapAtomicPointer")
		->args({"a","oldval","newval"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:665:36
	makeExtern< void * (*)(void **,void *) , SDL_SetAtomicPointer , SimNode_ExtFuncCall >(lib,"SDL_SetAtomicPointer","SDL_SetAtomicPointer")
		->args({"a","v"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_atomic.h:683:36
	makeExtern< void * (*)(void **) , SDL_GetAtomicPointer , SimNode_ExtFuncCall >(lib,"SDL_GetAtomicPointer","SDL_GetAtomicPointer")
		->args({"a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_error.h:121:34
	makeExtern< bool (*)() , SDL_OutOfMemory , SimNode_ExtFuncCall >(lib,"SDL_OutOfMemory","SDL_OutOfMemory")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_error.h:158:42
	makeExtern< const char * (*)() , SDL_GetError , SimNode_ExtFuncCall >(lib,"SDL_GetError","SDL_GetError")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_error.h:172:34
	makeExtern< bool (*)() , SDL_ClearError , SimNode_ExtFuncCall >(lib,"SDL_ClearError","SDL_ClearError")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:118:46
	makeExtern< unsigned int (*)() , SDL_GetGlobalProperties , SimNode_ExtFuncCall >(lib,"SDL_GetGlobalProperties","SDL_GetGlobalProperties")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:134:46
	makeExtern< unsigned int (*)() , SDL_CreateProperties , SimNode_ExtFuncCall >(lib,"SDL_CreateProperties","SDL_CreateProperties")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:155:34
	makeExtern< bool (*)(unsigned int,unsigned int) , SDL_CopyProperties , SimNode_ExtFuncCall >(lib,"SDL_CopyProperties","SDL_CopyProperties")
		->args({"src","dst"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:179:34
	makeExtern< bool (*)(unsigned int) , SDL_LockProperties , SimNode_ExtFuncCall >(lib,"SDL_LockProperties","SDL_LockProperties")
		->args({"props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:192:34
	makeExtern< void (*)(unsigned int) , SDL_UnlockProperties , SimNode_ExtFuncCall >(lib,"SDL_UnlockProperties","SDL_UnlockProperties")
		->args({"props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:270:34
	makeExtern< bool (*)(unsigned int,const char *,void *) , SDL_SetPointerProperty , SimNode_ExtFuncCall >(lib,"SDL_SetPointerProperty","SDL_SetPointerProperty")
		->args({"props","name","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:290:34
	makeExtern< bool (*)(unsigned int,const char *,const char *) , SDL_SetStringProperty , SimNode_ExtFuncCall >(lib,"SDL_SetStringProperty","SDL_SetStringProperty")
		->args({"props","name","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:307:34
	makeExtern< bool (*)(unsigned int,const char *,Sint64) , SDL_SetNumberProperty , SimNode_ExtFuncCall >(lib,"SDL_SetNumberProperty","SDL_SetNumberProperty")
		->args({"props","name","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:324:34
	makeExtern< bool (*)(unsigned int,const char *,float) , SDL_SetFloatProperty , SimNode_ExtFuncCall >(lib,"SDL_SetFloatProperty","SDL_SetFloatProperty")
		->args({"props","name","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:341:34
	makeExtern< bool (*)(unsigned int,const char *,bool) , SDL_SetBooleanProperty , SimNode_ExtFuncCall >(lib,"SDL_SetBooleanProperty","SDL_SetBooleanProperty")
		->args({"props","name","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:356:34
	makeExtern< bool (*)(unsigned int,const char *) , SDL_HasProperty , SimNode_ExtFuncCall >(lib,"SDL_HasProperty","SDL_HasProperty")
		->args({"props","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:372:46
	makeExtern< enum SDL_PropertyType (*)(unsigned int,const char *) , SDL_GetPropertyType , SimNode_ExtFuncCall >(lib,"SDL_GetPropertyType","SDL_GetPropertyType")
		->args({"props","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:405:36
	makeExtern< void * (*)(unsigned int,const char *,void *) , SDL_GetPointerProperty , SimNode_ExtFuncCall >(lib,"SDL_GetPointerProperty","SDL_GetPointerProperty")
		->args({"props","name","default_value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:429:42
	makeExtern< const char * (*)(unsigned int,const char *,const char *) , SDL_GetStringProperty , SimNode_ExtFuncCall >(lib,"SDL_GetStringProperty","SDL_GetStringProperty")
		->args({"props","name","default_value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:451:36
	makeExtern< Sint64 (*)(unsigned int,const char *,Sint64) , SDL_GetNumberProperty , SimNode_ExtFuncCall >(lib,"SDL_GetNumberProperty","SDL_GetNumberProperty")
		->args({"props","name","default_value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:473:35
	makeExtern< float (*)(unsigned int,const char *,float) , SDL_GetFloatProperty , SimNode_ExtFuncCall >(lib,"SDL_GetFloatProperty","SDL_GetFloatProperty")
		->args({"props","name","default_value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:495:34
	makeExtern< bool (*)(unsigned int,const char *,bool) , SDL_GetBooleanProperty , SimNode_ExtFuncCall >(lib,"SDL_GetBooleanProperty","SDL_GetBooleanProperty")
		->args({"props","name","default_value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:509:34
	makeExtern< bool (*)(unsigned int,const char *) , SDL_ClearProperty , SimNode_ExtFuncCall >(lib,"SDL_ClearProperty","SDL_ClearProperty")
		->args({"props","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_properties.h:564:34
	makeExtern< void (*)(unsigned int) , SDL_DestroyProperties , SimNode_ExtFuncCall >(lib,"SDL_DestroyProperties","SDL_DestroyProperties")
		->args({"props"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_CreateThreadRuntime), SDL_CreateThreadRuntime, SimNode_ExtFuncCall>(lib,"SDL_CreateThreadRuntime","SDL_CreateThreadRuntimeAddress")->args({"fn","name","data","pfnBeginThread","pfnEndThread"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_CreateThreadWithPropertiesRuntime), SDL_CreateThreadWithPropertiesRuntime, SimNode_ExtFuncCall>(lib,"SDL_CreateThreadWithPropertiesRuntime","SDL_CreateThreadWithPropertiesRuntimeAddress")->args({"props","pfnBeginThread","pfnEndThread"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_thread.h:378:42
	makeExtern< const char * (*)(struct SDL_Thread *) , SDL_GetThreadName , SimNode_ExtFuncCall >(lib,"SDL_GetThreadName","SDL_GetThreadName")
		->args({"thread"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_thread.h:398:42
	makeExtern< SDL_ThreadID (*)() , SDL_GetCurrentThreadID , SimNode_ExtFuncCall >(lib,"SDL_GetCurrentThreadID","SDL_GetCurrentThreadID")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_thread.h:417:42
	makeExtern< SDL_ThreadID (*)(struct SDL_Thread *) , SDL_GetThreadID , SimNode_ExtFuncCall >(lib,"SDL_GetThreadID","SDL_GetThreadID")
		->args({"thread"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_thread.h:434:34
	makeExtern< bool (*)(enum SDL_ThreadPriority) , SDL_SetCurrentThreadPriority , SimNode_ExtFuncCall >(lib,"SDL_SetCurrentThreadPriority","SDL_SetCurrentThreadPriority")
		->args({"priority"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_thread.h:472:34
	makeExtern< void (*)(struct SDL_Thread *,int *) , SDL_WaitThread , SimNode_ExtFuncCall >(lib,"SDL_WaitThread","SDL_WaitThread")
		->args({"thread","status"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_thread.h:487:45
	makeExtern< enum SDL_ThreadState (*)(struct SDL_Thread *) , SDL_GetThreadState , SimNode_ExtFuncCall >(lib,"SDL_GetThreadState","SDL_GetThreadState")
		->args({"thread"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_thread.h:525:34
	makeExtern< void (*)(struct SDL_Thread *) , SDL_DetachThread , SimNode_ExtFuncCall >(lib,"SDL_DetachThread","SDL_DetachThread")
		->args({"thread"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_thread.h:540:36
	makeExtern< void * (*)(struct SDL_AtomicInt *) , SDL_GetTLS , SimNode_ExtFuncCall >(lib,"SDL_GetTLS","SDL_GetTLS")
		->args({"id"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_SetTLS), SDL_SetTLS, SimNode_ExtFuncCall>(lib,"SDL_SetTLS","SDL_SetTLSAddress")->args({"id","value","destructor"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_thread.h:594:34
	makeExtern< void (*)() , SDL_CleanupTLS , SimNode_ExtFuncCall >(lib,"SDL_CleanupTLS","SDL_CleanupTLS")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:320:41
	makeExtern< struct SDL_Mutex * (*)() , SDL_CreateMutex , SimNode_ExtFuncCall >(lib,"SDL_CreateMutex","SDL_CreateMutex")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:346:34
	makeExtern< void (*)(struct SDL_Mutex *) , SDL_LockMutex , SimNode_ExtFuncCall >(lib,"SDL_LockMutex","SDL_LockMutex")
		->args({"mutex"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:369:34
	makeExtern< bool (*)(struct SDL_Mutex *) , SDL_TryLockMutex , SimNode_ExtFuncCall >(lib,"SDL_TryLockMutex","SDL_TryLockMutex")
		->args({"mutex"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:391:34
	makeExtern< void (*)(struct SDL_Mutex *) , SDL_UnlockMutex , SimNode_ExtFuncCall >(lib,"SDL_UnlockMutex","SDL_UnlockMutex")
		->args({"mutex"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:410:34
	makeExtern< void (*)(struct SDL_Mutex *) , SDL_DestroyMutex , SimNode_ExtFuncCall >(lib,"SDL_DestroyMutex","SDL_DestroyMutex")
		->args({"mutex"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:482:42
	makeExtern< struct SDL_RWLock * (*)() , SDL_CreateRWLock , SimNode_ExtFuncCall >(lib,"SDL_CreateRWLock","SDL_CreateRWLock")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:521:34
	makeExtern< void (*)(struct SDL_RWLock *) , SDL_LockRWLockForReading , SimNode_ExtFuncCall >(lib,"SDL_LockRWLockForReading","SDL_LockRWLockForReading")
		->args({"rwlock"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:554:34
	makeExtern< void (*)(struct SDL_RWLock *) , SDL_LockRWLockForWriting , SimNode_ExtFuncCall >(lib,"SDL_LockRWLockForWriting","SDL_LockRWLockForWriting")
		->args({"rwlock"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:581:34
	makeExtern< bool (*)(struct SDL_RWLock *) , SDL_TryLockRWLockForReading , SimNode_ExtFuncCall >(lib,"SDL_TryLockRWLockForReading","SDL_TryLockRWLockForReading")
		->args({"rwlock"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:613:34
	makeExtern< bool (*)(struct SDL_RWLock *) , SDL_TryLockRWLockForWriting , SimNode_ExtFuncCall >(lib,"SDL_TryLockRWLockForWriting","SDL_TryLockRWLockForWriting")
		->args({"rwlock"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:641:34
	makeExtern< void (*)(struct SDL_RWLock *) , SDL_UnlockRWLock , SimNode_ExtFuncCall >(lib,"SDL_UnlockRWLock","SDL_UnlockRWLock")
		->args({"rwlock"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:660:34
	makeExtern< void (*)(struct SDL_RWLock *) , SDL_DestroyRWLock , SimNode_ExtFuncCall >(lib,"SDL_DestroyRWLock","SDL_DestroyRWLock")
		->args({"rwlock"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:710:45
	makeExtern< struct SDL_Semaphore * (*)(unsigned int) , SDL_CreateSemaphore , SimNode_ExtFuncCall >(lib,"SDL_CreateSemaphore","SDL_CreateSemaphore")
		->args({"initial_value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:726:34
	makeExtern< void (*)(struct SDL_Semaphore *) , SDL_DestroySemaphore , SimNode_ExtFuncCall >(lib,"SDL_DestroySemaphore","SDL_DestroySemaphore")
		->args({"sem"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:748:34
	makeExtern< void (*)(struct SDL_Semaphore *) , SDL_WaitSemaphore , SimNode_ExtFuncCall >(lib,"SDL_WaitSemaphore","SDL_WaitSemaphore")
		->args({"sem"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:769:34
	makeExtern< bool (*)(struct SDL_Semaphore *) , SDL_TryWaitSemaphore , SimNode_ExtFuncCall >(lib,"SDL_TryWaitSemaphore","SDL_TryWaitSemaphore")
		->args({"sem"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:791:34
	makeExtern< bool (*)(struct SDL_Semaphore *,int) , SDL_WaitSemaphoreTimeout , SimNode_ExtFuncCall >(lib,"SDL_WaitSemaphoreTimeout","SDL_WaitSemaphoreTimeout")
		->args({"sem","timeoutMS"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:806:34
	makeExtern< void (*)(struct SDL_Semaphore *) , SDL_SignalSemaphore , SimNode_ExtFuncCall >(lib,"SDL_SignalSemaphore","SDL_SignalSemaphore")
		->args({"sem"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:818:36
	makeExtern< unsigned int (*)(struct SDL_Semaphore *) , SDL_GetSemaphoreValue , SimNode_ExtFuncCall >(lib,"SDL_GetSemaphoreValue","SDL_GetSemaphoreValue")
		->args({"sem"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:859:45
	makeExtern< struct SDL_Condition * (*)() , SDL_CreateCondition , SimNode_ExtFuncCall >(lib,"SDL_CreateCondition","SDL_CreateCondition")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:872:34
	makeExtern< void (*)(struct SDL_Condition *) , SDL_DestroyCondition , SimNode_ExtFuncCall >(lib,"SDL_DestroyCondition","SDL_DestroyCondition")
		->args({"cond"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:887:34
	makeExtern< void (*)(struct SDL_Condition *) , SDL_SignalCondition , SimNode_ExtFuncCall >(lib,"SDL_SignalCondition","SDL_SignalCondition")
		->args({"cond"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:902:34
	makeExtern< void (*)(struct SDL_Condition *) , SDL_BroadcastCondition , SimNode_ExtFuncCall >(lib,"SDL_BroadcastCondition","SDL_BroadcastCondition")
		->args({"cond"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:930:34
	makeExtern< void (*)(struct SDL_Condition *,struct SDL_Mutex *) , SDL_WaitCondition , SimNode_ExtFuncCall >(lib,"SDL_WaitCondition","SDL_WaitCondition")
		->args({"cond","mutex"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:960:34
	makeExtern< bool (*)(struct SDL_Condition *,struct SDL_Mutex *,int) , SDL_WaitConditionTimeout , SimNode_ExtFuncCall >(lib,"SDL_WaitConditionTimeout","SDL_WaitConditionTimeout")
		->args({"cond","mutex","timeoutMS"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:1067:34
	makeExtern< bool (*)(struct SDL_InitState *) , SDL_ShouldInit , SimNode_ExtFuncCall >(lib,"SDL_ShouldInit","SDL_ShouldInit")
		->args({"state"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:1088:34
	makeExtern< bool (*)(struct SDL_InitState *) , SDL_ShouldQuit , SimNode_ExtFuncCall >(lib,"SDL_ShouldQuit","SDL_ShouldQuit")
		->args({"state"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mutex.h:1107:34
	makeExtern< void (*)(struct SDL_InitState *,bool) , SDL_SetInitialized , SimNode_ExtFuncCall >(lib,"SDL_SetInitialized","SDL_SetInitialized")
		->args({"state","initialized"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:278:44
	makeExtern< struct SDL_IOStream * (*)(const char *,const char *) , SDL_IOFromFile , SimNode_ExtFuncCall >(lib,"SDL_IOFromFile","SDL_IOFromFile")
		->args({"file","mode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:330:44
	makeExtern< struct SDL_IOStream * (*)(void *,size_t) , SDL_IOFromMem , SimNode_ExtFuncCall >(lib,"SDL_IOFromMem","SDL_IOFromMem")
		->args({"mem","size"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:381:44
	makeExtern< struct SDL_IOStream * (*)(const void *,size_t) , SDL_IOFromConstMem , SimNode_ExtFuncCall >(lib,"SDL_IOFromConstMem","SDL_IOFromConstMem")
		->args({"mem","size"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:411:44
	makeExtern< struct SDL_IOStream * (*)() , SDL_IOFromDynamicMem , SimNode_ExtFuncCall >(lib,"SDL_IOFromDynamicMem","SDL_IOFromDynamicMem")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:446:44
	makeExtern< struct SDL_IOStream * (*)(const struct SDL_IOStreamInterface *,void *) , SDL_OpenIO , SimNode_ExtFuncCall >(lib,"SDL_OpenIO","SDL_OpenIO")
		->args({"iface","userdata"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:478:34
	makeExtern< bool (*)(struct SDL_IOStream *) , SDL_CloseIO , SimNode_ExtFuncCall >(lib,"SDL_CloseIO","SDL_CloseIO")
		->args({"context"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:491:46
	makeExtern< unsigned int (*)(struct SDL_IOStream *) , SDL_GetIOProperties , SimNode_ExtFuncCall >(lib,"SDL_GetIOProperties","SDL_GetIOProperties")
		->args({"context"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:511:42
	makeExtern< enum SDL_IOStatus (*)(struct SDL_IOStream *) , SDL_GetIOStatus , SimNode_ExtFuncCall >(lib,"SDL_GetIOStatus","SDL_GetIOStatus")
		->args({"context"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:525:36
	makeExtern< Sint64 (*)(struct SDL_IOStream *) , SDL_GetIOSize , SimNode_ExtFuncCall >(lib,"SDL_GetIOSize","SDL_GetIOSize")
		->args({"context"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:554:36
	makeExtern< Sint64 (*)(struct SDL_IOStream *,Sint64,enum SDL_IOWhence) , SDL_SeekIO , SimNode_ExtFuncCall >(lib,"SDL_SeekIO","SDL_SeekIO")
		->args({"context","offset","whence"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:574:36
	makeExtern< Sint64 (*)(struct SDL_IOStream *) , SDL_TellIO , SimNode_ExtFuncCall >(lib,"SDL_TellIO","SDL_TellIO")
		->args({"context"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:604:36
	makeExtern< size_t (*)(struct SDL_IOStream *,void *,size_t) , SDL_ReadIO , SimNode_ExtFuncCall >(lib,"SDL_ReadIO","SDL_ReadIO")
		->args({"context","ptr","size"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:640:36
	makeExtern< size_t (*)(struct SDL_IOStream *,const void *,size_t) , SDL_WriteIO , SimNode_ExtFuncCall >(lib,"SDL_WriteIO","SDL_WriteIO")
		->args({"context","ptr","size"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:701:34
	makeExtern< bool (*)(struct SDL_IOStream *) , SDL_FlushIO , SimNode_ExtFuncCall >(lib,"SDL_FlushIO","SDL_FlushIO")
		->args({"context"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:727:36
	makeExtern< void * (*)(struct SDL_IOStream *,size_t *,bool) , SDL_LoadFile_IO , SimNode_ExtFuncCall >(lib,"SDL_LoadFile_IO","SDL_LoadFile_IO")
		->args({"src","datasize","closeio"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:750:36
	makeExtern< void * (*)(const char *,size_t *) , SDL_LoadFile , SimNode_ExtFuncCall >(lib,"SDL_LoadFile","SDL_LoadFile")
		->args({"file","datasize"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:771:34
	makeExtern< bool (*)(struct SDL_IOStream *,const void *,size_t,bool) , SDL_SaveFile_IO , SimNode_ExtFuncCall >(lib,"SDL_SaveFile_IO","SDL_SaveFile_IO")
		->args({"src","data","datasize","closeio"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:790:34
	makeExtern< bool (*)(const char *,const void *,size_t) , SDL_SaveFile , SimNode_ExtFuncCall >(lib,"SDL_SaveFile","SDL_SaveFile")
		->args({"file","data","datasize"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:816:34
	makeExtern< bool (*)(struct SDL_IOStream *,unsigned char *) , SDL_ReadU8 , SimNode_ExtFuncCall >(lib,"SDL_ReadU8","SDL_ReadU8")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:835:34
	makeExtern< bool (*)(struct SDL_IOStream *,signed char *) , SDL_ReadS8 , SimNode_ExtFuncCall >(lib,"SDL_ReadS8","SDL_ReadS8")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:858:34
	makeExtern< bool (*)(struct SDL_IOStream *,unsigned short *) , SDL_ReadU16LE , SimNode_ExtFuncCall >(lib,"SDL_ReadU16LE","SDL_ReadU16LE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:881:34
	makeExtern< bool (*)(struct SDL_IOStream *,short *) , SDL_ReadS16LE , SimNode_ExtFuncCall >(lib,"SDL_ReadS16LE","SDL_ReadS16LE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:904:34
	makeExtern< bool (*)(struct SDL_IOStream *,unsigned short *) , SDL_ReadU16BE , SimNode_ExtFuncCall >(lib,"SDL_ReadU16BE","SDL_ReadU16BE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:927:34
	makeExtern< bool (*)(struct SDL_IOStream *,short *) , SDL_ReadS16BE , SimNode_ExtFuncCall >(lib,"SDL_ReadS16BE","SDL_ReadS16BE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:950:34
	makeExtern< bool (*)(struct SDL_IOStream *,unsigned int *) , SDL_ReadU32LE , SimNode_ExtFuncCall >(lib,"SDL_ReadU32LE","SDL_ReadU32LE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:973:34
	makeExtern< bool (*)(struct SDL_IOStream *,int *) , SDL_ReadS32LE , SimNode_ExtFuncCall >(lib,"SDL_ReadS32LE","SDL_ReadS32LE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:996:34
	makeExtern< bool (*)(struct SDL_IOStream *,unsigned int *) , SDL_ReadU32BE , SimNode_ExtFuncCall >(lib,"SDL_ReadU32BE","SDL_ReadU32BE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1019:34
	makeExtern< bool (*)(struct SDL_IOStream *,int *) , SDL_ReadS32BE , SimNode_ExtFuncCall >(lib,"SDL_ReadS32BE","SDL_ReadS32BE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1042:34
	makeExtern< bool (*)(struct SDL_IOStream *,Uint64 *) , SDL_ReadU64LE , SimNode_ExtFuncCall >(lib,"SDL_ReadU64LE","SDL_ReadU64LE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1065:34
	makeExtern< bool (*)(struct SDL_IOStream *,Sint64 *) , SDL_ReadS64LE , SimNode_ExtFuncCall >(lib,"SDL_ReadS64LE","SDL_ReadS64LE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1088:34
	makeExtern< bool (*)(struct SDL_IOStream *,Uint64 *) , SDL_ReadU64BE , SimNode_ExtFuncCall >(lib,"SDL_ReadU64BE","SDL_ReadU64BE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1111:34
	makeExtern< bool (*)(struct SDL_IOStream *,Sint64 *) , SDL_ReadS64BE , SimNode_ExtFuncCall >(lib,"SDL_ReadS64BE","SDL_ReadS64BE")
		->args({"src","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1133:34
	makeExtern< bool (*)(struct SDL_IOStream *,unsigned char) , SDL_WriteU8 , SimNode_ExtFuncCall >(lib,"SDL_WriteU8","SDL_WriteU8")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1147:34
	makeExtern< bool (*)(struct SDL_IOStream *,signed char) , SDL_WriteS8 , SimNode_ExtFuncCall >(lib,"SDL_WriteS8","SDL_WriteS8")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1166:34
	makeExtern< bool (*)(struct SDL_IOStream *,unsigned short) , SDL_WriteU16LE , SimNode_ExtFuncCall >(lib,"SDL_WriteU16LE","SDL_WriteU16LE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1185:34
	makeExtern< bool (*)(struct SDL_IOStream *,short) , SDL_WriteS16LE , SimNode_ExtFuncCall >(lib,"SDL_WriteS16LE","SDL_WriteS16LE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1203:34
	makeExtern< bool (*)(struct SDL_IOStream *,unsigned short) , SDL_WriteU16BE , SimNode_ExtFuncCall >(lib,"SDL_WriteU16BE","SDL_WriteU16BE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1221:34
	makeExtern< bool (*)(struct SDL_IOStream *,short) , SDL_WriteS16BE , SimNode_ExtFuncCall >(lib,"SDL_WriteS16BE","SDL_WriteS16BE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1240:34
	makeExtern< bool (*)(struct SDL_IOStream *,unsigned int) , SDL_WriteU32LE , SimNode_ExtFuncCall >(lib,"SDL_WriteU32LE","SDL_WriteU32LE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1259:34
	makeExtern< bool (*)(struct SDL_IOStream *,int) , SDL_WriteS32LE , SimNode_ExtFuncCall >(lib,"SDL_WriteS32LE","SDL_WriteS32LE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1277:34
	makeExtern< bool (*)(struct SDL_IOStream *,unsigned int) , SDL_WriteU32BE , SimNode_ExtFuncCall >(lib,"SDL_WriteU32BE","SDL_WriteU32BE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1295:34
	makeExtern< bool (*)(struct SDL_IOStream *,int) , SDL_WriteS32BE , SimNode_ExtFuncCall >(lib,"SDL_WriteS32BE","SDL_WriteS32BE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1314:34
	makeExtern< bool (*)(struct SDL_IOStream *,Uint64) , SDL_WriteU64LE , SimNode_ExtFuncCall >(lib,"SDL_WriteU64LE","SDL_WriteU64LE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1333:34
	makeExtern< bool (*)(struct SDL_IOStream *,Sint64) , SDL_WriteS64LE , SimNode_ExtFuncCall >(lib,"SDL_WriteS64LE","SDL_WriteS64LE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1351:34
	makeExtern< bool (*)(struct SDL_IOStream *,Uint64) , SDL_WriteU64BE , SimNode_ExtFuncCall >(lib,"SDL_WriteU64BE","SDL_WriteU64BE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_iostream.h:1369:34
	makeExtern< bool (*)(struct SDL_IOStream *,Sint64) , SDL_WriteS64BE , SimNode_ExtFuncCall >(lib,"SDL_WriteS64BE","SDL_WriteS64BE")
		->args({"dst","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:478:33
	makeExtern< int (*)() , SDL_GetNumAudioDrivers , SimNode_ExtFuncCall >(lib,"SDL_GetNumAudioDrivers","SDL_GetNumAudioDrivers")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:502:42
	makeExtern< const char * (*)(int) , SDL_GetAudioDriver , SimNode_ExtFuncCall >(lib,"SDL_GetAudioDriver","SDL_GetAudioDriver")
		->args({"index"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:518:42
	makeExtern< const char * (*)() , SDL_GetCurrentAudioDriver , SimNode_ExtFuncCall >(lib,"SDL_GetCurrentAudioDriver","SDL_GetCurrentAudioDriver")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:547:49
	makeExtern< unsigned int * (*)(int *) , SDL_GetAudioPlaybackDevices , SimNode_ExtFuncCall >(lib,"SDL_GetAudioPlaybackDevices","SDL_GetAudioPlaybackDevices")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:576:49
	makeExtern< unsigned int * (*)(int *) , SDL_GetAudioRecordingDevices , SimNode_ExtFuncCall >(lib,"SDL_GetAudioRecordingDevices","SDL_GetAudioRecordingDevices")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:601:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetAudioDeviceName , SimNode_ExtFuncCall >(lib,"SDL_GetAudioDeviceName","SDL_GetAudioDeviceName")
		->args({"devid"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:636:34
	makeExtern< bool (*)(unsigned int,struct SDL_AudioSpec *,int *) , SDL_GetAudioDeviceFormat , SimNode_ExtFuncCall >(lib,"SDL_GetAudioDeviceFormat","SDL_GetAudioDeviceFormat")
		->args({"devid","spec","sample_frames"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:659:35
	makeExtern< int * (*)(unsigned int,int *) , SDL_GetAudioDeviceChannelMap , SimNode_ExtFuncCall >(lib,"SDL_GetAudioDeviceChannelMap","SDL_GetAudioDeviceChannelMap")
		->args({"devid","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:735:47
	makeExtern< unsigned int (*)(unsigned int,const struct SDL_AudioSpec *) , SDL_OpenAudioDevice , SimNode_ExtFuncCall >(lib,"SDL_OpenAudioDevice","SDL_OpenAudioDevice")
		->args({"devid","spec"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:760:34
	makeExtern< bool (*)(unsigned int) , SDL_IsAudioDevicePhysical , SimNode_ExtFuncCall >(lib,"SDL_IsAudioDevicePhysical","SDL_IsAudioDevicePhysical")
		->args({"devid"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:774:34
	makeExtern< bool (*)(unsigned int) , SDL_IsAudioDevicePlayback , SimNode_ExtFuncCall >(lib,"SDL_IsAudioDevicePlayback","SDL_IsAudioDevicePlayback")
		->args({"devid"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:805:34
	makeExtern< bool (*)(unsigned int) , SDL_PauseAudioDevice , SimNode_ExtFuncCall >(lib,"SDL_PauseAudioDevice","SDL_PauseAudioDevice")
		->args({"devid"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:833:34
	makeExtern< bool (*)(unsigned int) , SDL_ResumeAudioDevice , SimNode_ExtFuncCall >(lib,"SDL_ResumeAudioDevice","SDL_ResumeAudioDevice")
		->args({"devid"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:855:34
	makeExtern< bool (*)(unsigned int) , SDL_AudioDevicePaused , SimNode_ExtFuncCall >(lib,"SDL_AudioDevicePaused","SDL_AudioDevicePaused")
		->args({"devid"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:878:35
	makeExtern< float (*)(unsigned int) , SDL_GetAudioDeviceGain , SimNode_ExtFuncCall >(lib,"SDL_GetAudioDeviceGain","SDL_GetAudioDeviceGain")
		->args({"devid"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:913:34
	makeExtern< bool (*)(unsigned int,float) , SDL_SetAudioDeviceGain , SimNode_ExtFuncCall >(lib,"SDL_SetAudioDeviceGain","SDL_SetAudioDeviceGain")
		->args({"devid","gain"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:934:34
	makeExtern< void (*)(unsigned int) , SDL_CloseAudioDevice , SimNode_ExtFuncCall >(lib,"SDL_CloseAudioDevice","SDL_CloseAudioDevice")
		->args({"devid"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:974:34
	makeExtern< bool (*)(unsigned int,struct SDL_AudioStream *const *,int) , SDL_BindAudioStreams , SimNode_ExtFuncCall >(lib,"SDL_BindAudioStreams","SDL_BindAudioStreams")
		->args({"devid","streams","num_streams"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:995:34
	makeExtern< bool (*)(unsigned int,struct SDL_AudioStream *) , SDL_BindAudioStream , SimNode_ExtFuncCall >(lib,"SDL_BindAudioStream","SDL_BindAudioStream")
		->args({"devid","stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1016:34
	makeExtern< void (*)(struct SDL_AudioStream *const *,int) , SDL_UnbindAudioStreams , SimNode_ExtFuncCall >(lib,"SDL_UnbindAudioStreams","SDL_UnbindAudioStreams")
		->args({"streams","num_streams"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1032:34
	makeExtern< void (*)(struct SDL_AudioStream *) , SDL_UnbindAudioStream , SimNode_ExtFuncCall >(lib,"SDL_UnbindAudioStream","SDL_UnbindAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1053:47
	makeExtern< unsigned int (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamDevice , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamDevice","SDL_GetAudioStreamDevice")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1082:47
	makeExtern< struct SDL_AudioStream * (*)(const struct SDL_AudioSpec *,const struct SDL_AudioSpec *) , SDL_CreateAudioStream , SimNode_ExtFuncCall >(lib,"SDL_CreateAudioStream","SDL_CreateAudioStream")
		->args({"src_spec","dst_spec"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1106:46
	makeExtern< unsigned int (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamProperties , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamProperties","SDL_GetAudioStreamProperties")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1127:34
	makeExtern< bool (*)(struct SDL_AudioStream *,struct SDL_AudioSpec *,struct SDL_AudioSpec *) , SDL_GetAudioStreamFormat , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamFormat","SDL_GetAudioStreamFormat")
		->args({"stream","src_spec","dst_spec"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1167:34
	makeExtern< bool (*)(struct SDL_AudioStream *,const struct SDL_AudioSpec *,const struct SDL_AudioSpec *) , SDL_SetAudioStreamFormat , SimNode_ExtFuncCall >(lib,"SDL_SetAudioStreamFormat","SDL_SetAudioStreamFormat")
		->args({"stream","src_spec","dst_spec"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1183:35
	makeExtern< float (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamFrequencyRatio , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamFrequencyRatio","SDL_GetAudioStreamFrequencyRatio")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1211:34
	makeExtern< bool (*)(struct SDL_AudioStream *,float) , SDL_SetAudioStreamFrequencyRatio , SimNode_ExtFuncCall >(lib,"SDL_SetAudioStreamFrequencyRatio","SDL_SetAudioStreamFrequencyRatio")
		->args({"stream","ratio"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1232:35
	makeExtern< float (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamGain , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamGain","SDL_GetAudioStreamGain")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1257:34
	makeExtern< bool (*)(struct SDL_AudioStream *,float) , SDL_SetAudioStreamGain , SimNode_ExtFuncCall >(lib,"SDL_SetAudioStreamGain","SDL_SetAudioStreamGain")
		->args({"stream","gain"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1281:35
	makeExtern< int * (*)(struct SDL_AudioStream *,int *) , SDL_GetAudioStreamInputChannelMap , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamInputChannelMap","SDL_GetAudioStreamInputChannelMap")
		->args({"stream","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1305:35
	makeExtern< int * (*)(struct SDL_AudioStream *,int *) , SDL_GetAudioStreamOutputChannelMap , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamOutputChannelMap","SDL_GetAudioStreamOutputChannelMap")
		->args({"stream","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1365:34
	makeExtern< bool (*)(struct SDL_AudioStream *,const int *,int) , SDL_SetAudioStreamInputChannelMap , SimNode_ExtFuncCall >(lib,"SDL_SetAudioStreamInputChannelMap","SDL_SetAudioStreamInputChannelMap")
		->args({"stream","chmap","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1423:34
	makeExtern< bool (*)(struct SDL_AudioStream *,const int *,int) , SDL_SetAudioStreamOutputChannelMap , SimNode_ExtFuncCall >(lib,"SDL_SetAudioStreamOutputChannelMap","SDL_SetAudioStreamOutputChannelMap")
		->args({"stream","chmap","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1453:34
	makeExtern< bool (*)(struct SDL_AudioStream *,const void *,int) , SDL_PutAudioStreamData , SimNode_ExtFuncCall >(lib,"SDL_PutAudioStreamData","SDL_PutAudioStreamData")
		->args({"stream","buf","len"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1613:33
	makeExtern< int (*)(struct SDL_AudioStream *,void *,int) , SDL_GetAudioStreamData , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamData","SDL_GetAudioStreamData")
		->args({"stream","buf","len"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1639:33
	makeExtern< int (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamAvailable , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamAvailable","SDL_GetAudioStreamAvailable")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1678:33
	makeExtern< int (*)(struct SDL_AudioStream *) , SDL_GetAudioStreamQueued , SimNode_ExtFuncCall >(lib,"SDL_GetAudioStreamQueued","SDL_GetAudioStreamQueued")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1699:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_FlushAudioStream , SimNode_ExtFuncCall >(lib,"SDL_FlushAudioStream","SDL_FlushAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1720:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_ClearAudioStream , SimNode_ExtFuncCall >(lib,"SDL_ClearAudioStream","SDL_ClearAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1744:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_PauseAudioStreamDevice , SimNode_ExtFuncCall >(lib,"SDL_PauseAudioStreamDevice","SDL_PauseAudioStreamDevice")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1767:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_ResumeAudioStreamDevice , SimNode_ExtFuncCall >(lib,"SDL_ResumeAudioStreamDevice","SDL_ResumeAudioStreamDevice")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1786:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_AudioStreamDevicePaused , SimNode_ExtFuncCall >(lib,"SDL_AudioStreamDevicePaused","SDL_AudioStreamDevicePaused")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1815:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_LockAudioStream , SimNode_ExtFuncCall >(lib,"SDL_LockAudioStream","SDL_LockAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1834:34
	makeExtern< bool (*)(struct SDL_AudioStream *) , SDL_UnlockAudioStream , SimNode_ExtFuncCall >(lib,"SDL_UnlockAudioStream","SDL_UnlockAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_SetAudioStreamGetCallback), SDL_SetAudioStreamGetCallback, SimNode_ExtFuncCall>(lib,"SDL_SetAudioStreamGetCallback","SDL_SetAudioStreamGetCallbackAddress")->args({"stream","callback","userdata"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_SetAudioStreamPutCallback), SDL_SetAudioStreamPutCallback, SimNode_ExtFuncCall>(lib,"SDL_SetAudioStreamPutCallback","SDL_SetAudioStreamPutCallbackAddress")->args({"stream","callback","userdata"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:1995:34
	makeExtern< void (*)(struct SDL_AudioStream *) , SDL_DestroyAudioStream , SimNode_ExtFuncCall >(lib,"SDL_DestroyAudioStream","SDL_DestroyAudioStream")
		->args({"stream"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_OpenAudioDeviceStream), SDL_OpenAudioDeviceStream, SimNode_ExtFuncCall>(lib,"SDL_OpenAudioDeviceStream","SDL_OpenAudioDeviceStreamAddress")->args({"devid","spec","callback","userdata"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_SetAudioPostmixCallback), SDL_SetAudioPostmixCallback, SimNode_ExtFuncCall>(lib,"SDL_SetAudioPostmixCallback","SDL_SetAudioPostmixCallbackAddress")->args({"devid","callback","userdata"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:2230:34
	makeExtern< bool (*)(struct SDL_IOStream *,bool,struct SDL_AudioSpec *,unsigned char **,unsigned int *) , SDL_LoadWAV_IO , SimNode_ExtFuncCall >(lib,"SDL_LoadWAV_IO","SDL_LoadWAV_IO")
		->args({"src","closeio","spec","audio_buf","audio_len"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:2266:34
	makeExtern< bool (*)(const char *,struct SDL_AudioSpec *,unsigned char **,unsigned int *) , SDL_LoadWAV , SimNode_ExtFuncCall >(lib,"SDL_LoadWAV","SDL_LoadWAV")
		->args({"path","spec","audio_buf","audio_len"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:2302:34
	makeExtern< bool (*)(unsigned char *,const unsigned char *,enum SDL_AudioFormat,unsigned int,float) , SDL_MixAudio , SimNode_ExtFuncCall >(lib,"SDL_MixAudio","SDL_MixAudio")
		->args({"dst","src","format","len","volume"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:2332:34
	makeExtern< bool (*)(const struct SDL_AudioSpec *,const unsigned char *,int,const struct SDL_AudioSpec *,unsigned char **,int *) , SDL_ConvertAudioSamples , SimNode_ExtFuncCall >(lib,"SDL_ConvertAudioSamples","SDL_ConvertAudioSamples")
		->args({"src_spec","src_data","src_len","dst_spec","dst_data","dst_len"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:2345:42
	makeExtern< const char * (*)(enum SDL_AudioFormat) , SDL_GetAudioFormatName , SimNode_ExtFuncCall >(lib,"SDL_GetAudioFormatName","SDL_GetAudioFormatName")
		->args({"format"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_audio.h:2361:33
	makeExtern< int (*)(enum SDL_AudioFormat) , SDL_GetSilenceValueForFormat , SimNode_ExtFuncCall >(lib,"SDL_GetSilenceValueForFormat","SDL_GetSilenceValueForFormat")
		->args({"format"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_blendmode.h:189:43
	makeExtern< unsigned int (*)(enum SDL_BlendFactor,enum SDL_BlendFactor,enum SDL_BlendOperation,enum SDL_BlendFactor,enum SDL_BlendFactor,enum SDL_BlendOperation) , SDL_ComposeCustomBlendMode , SimNode_ExtFuncCall >(lib,"SDL_ComposeCustomBlendMode","SDL_ComposeCustomBlendMode")
		->args({"srcColorFactor","dstColorFactor","colorOperation","srcAlphaFactor","dstAlphaFactor","alphaOperation"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_pixels.h:1185:42
	makeExtern< const char * (*)(enum SDL_PixelFormat) , SDL_GetPixelFormatName , SimNode_ExtFuncCall >(lib,"SDL_GetPixelFormatName","SDL_GetPixelFormatName")
		->args({"format"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_pixels.h:1205:34
	makeExtern< bool (*)(enum SDL_PixelFormat,int *,unsigned int *,unsigned int *,unsigned int *,unsigned int *) , SDL_GetMasksForPixelFormat , SimNode_ExtFuncCall >(lib,"SDL_GetMasksForPixelFormat","SDL_GetMasksForPixelFormat")
		->args({"format","bpp","Rmask","Gmask","Bmask","Amask"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_pixels.h:1227:45
	makeExtern< enum SDL_PixelFormat (*)(int,unsigned int,unsigned int,unsigned int,unsigned int) , SDL_GetPixelFormatForMasks , SimNode_ExtFuncCall >(lib,"SDL_GetPixelFormatForMasks","SDL_GetPixelFormatForMasks")
		->args({"bpp","Rmask","Gmask","Bmask","Amask"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_pixels.h:1244:60
	makeExtern< const struct SDL_PixelFormatDetails * (*)(enum SDL_PixelFormat) , SDL_GetPixelFormatDetails , SimNode_ExtFuncCall >(lib,"SDL_GetPixelFormatDetails","SDL_GetPixelFormatDetails")
		->args({"format"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_pixels.h:1264:43
	makeExtern< struct SDL_Palette * (*)(int) , SDL_CreatePalette , SimNode_ExtFuncCall >(lib,"SDL_CreatePalette","SDL_CreatePalette")
		->args({"ncolors"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_pixels.h:1281:34
	makeExtern< bool (*)(struct SDL_Palette *,const struct SDL_Color *,int,int) , SDL_SetPaletteColors , SimNode_ExtFuncCall >(lib,"SDL_SetPaletteColors","SDL_SetPaletteColors")
		->args({"palette","colors","firstcolor","ncolors"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_pixels.h:1295:34
	makeExtern< void (*)(struct SDL_Palette *) , SDL_DestroyPalette , SimNode_ExtFuncCall >(lib,"SDL_DestroyPalette","SDL_DestroyPalette")
		->args({"palette"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_pixels.h:1333:36
	makeExtern< unsigned int (*)(const struct SDL_PixelFormatDetails *,const struct SDL_Palette *,unsigned char,unsigned char,unsigned char) , SDL_MapRGB , SimNode_ExtFuncCall >(lib,"SDL_MapRGB","SDL_MapRGB")
		->args({"format","palette","r","g","b"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_pixels.h:1372:36
	makeExtern< unsigned int (*)(const struct SDL_PixelFormatDetails *,const struct SDL_Palette *,unsigned char,unsigned char,unsigned char,unsigned char) , SDL_MapRGBA , SimNode_ExtFuncCall >(lib,"SDL_MapRGBA","SDL_MapRGBA")
		->args({"format","palette","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_pixels.h:1400:34
	makeExtern< void (*)(unsigned int,const struct SDL_PixelFormatDetails *,const struct SDL_Palette *,unsigned char *,unsigned char *,unsigned char *) , SDL_GetRGB , SimNode_ExtFuncCall >(lib,"SDL_GetRGB","SDL_GetRGB")
		->args({"pixelvalue","format","palette","r","g","b"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_pixels.h:1432:34
	makeExtern< void (*)(unsigned int,const struct SDL_PixelFormatDetails *,const struct SDL_Palette *,unsigned char *,unsigned char *,unsigned char *,unsigned char *) , SDL_GetRGBA , SimNode_ExtFuncCall >(lib,"SDL_GetRGBA","SDL_GetRGBA")
		->args({"pixelvalue","format","palette","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:129:23
	makeExtern< void (*)(const struct SDL_Rect *,struct SDL_FRect *) , SDL_RectToFRect , SimNode_ExtFuncCall >(lib,"SDL_RectToFRect","SDL_RectToFRect")
		->args({"rect","frect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:158:23
	makeExtern< bool (*)(const struct SDL_Point *,const struct SDL_Rect *) , SDL_PointInRect , SimNode_ExtFuncCall >(lib,"SDL_PointInRect","SDL_PointInRect")
		->args({"p","r"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:182:23
	makeExtern< bool (*)(const struct SDL_Rect *) , SDL_RectEmpty , SimNode_ExtFuncCall >(lib,"SDL_RectEmpty","SDL_RectEmpty")
		->args({"r"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:206:23
	makeExtern< bool (*)(const struct SDL_Rect *,const struct SDL_Rect *) , SDL_RectsEqual , SimNode_ExtFuncCall >(lib,"SDL_RectsEqual","SDL_RectsEqual")
		->args({"a","b"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:227:34
	makeExtern< bool (*)(const struct SDL_Rect *,const struct SDL_Rect *) , SDL_HasRectIntersection , SimNode_ExtFuncCall >(lib,"SDL_HasRectIntersection","SDL_HasRectIntersection")
		->args({"A","B"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:246:34
	makeExtern< bool (*)(const struct SDL_Rect *,const struct SDL_Rect *,struct SDL_Rect *) , SDL_GetRectIntersection , SimNode_ExtFuncCall >(lib,"SDL_GetRectIntersection","SDL_GetRectIntersection")
		->args({"A","B","result"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:262:34
	makeExtern< bool (*)(const struct SDL_Rect *,const struct SDL_Rect *,struct SDL_Rect *) , SDL_GetRectUnion , SimNode_ExtFuncCall >(lib,"SDL_GetRectUnion","SDL_GetRectUnion")
		->args({"A","B","result"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:283:34
	makeExtern< bool (*)(const struct SDL_Point *,int,const struct SDL_Rect *,struct SDL_Rect *) , SDL_GetRectEnclosingPoints , SimNode_ExtFuncCall >(lib,"SDL_GetRectEnclosingPoints","SDL_GetRectEnclosingPoints")
		->args({"points","count","clip","result"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:305:34
	makeExtern< bool (*)(const struct SDL_Rect *,int *,int *,int *,int *) , SDL_GetRectAndLineIntersection , SimNode_ExtFuncCall >(lib,"SDL_GetRectAndLineIntersection","SDL_GetRectAndLineIntersection")
		->args({"rect","X1","Y1","X2","Y2"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:331:23
	makeExtern< bool (*)(const struct SDL_FPoint *,const struct SDL_FRect *) , SDL_PointInRectFloat , SimNode_ExtFuncCall >(lib,"SDL_PointInRectFloat","SDL_PointInRectFloat")
		->args({"p","r"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:355:23
	makeExtern< bool (*)(const struct SDL_FRect *) , SDL_RectEmptyFloat , SimNode_ExtFuncCall >(lib,"SDL_RectEmptyFloat","SDL_RectEmptyFloat")
		->args({"r"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:385:23
	makeExtern< bool (*)(const struct SDL_FRect *,const struct SDL_FRect *,float) , SDL_RectsEqualEpsilon , SimNode_ExtFuncCall >(lib,"SDL_RectsEqualEpsilon","SDL_RectsEqualEpsilon")
		->args({"a","b","epsilon"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:420:23
	makeExtern< bool (*)(const struct SDL_FRect *,const struct SDL_FRect *) , SDL_RectsEqualFloat , SimNode_ExtFuncCall >(lib,"SDL_RectsEqualFloat","SDL_RectsEqualFloat")
		->args({"a","b"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:440:34
	makeExtern< bool (*)(const struct SDL_FRect *,const struct SDL_FRect *) , SDL_HasRectIntersectionFloat , SimNode_ExtFuncCall >(lib,"SDL_HasRectIntersectionFloat","SDL_HasRectIntersectionFloat")
		->args({"A","B"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:459:34
	makeExtern< bool (*)(const struct SDL_FRect *,const struct SDL_FRect *,struct SDL_FRect *) , SDL_GetRectIntersectionFloat , SimNode_ExtFuncCall >(lib,"SDL_GetRectIntersectionFloat","SDL_GetRectIntersectionFloat")
		->args({"A","B","result"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:475:34
	makeExtern< bool (*)(const struct SDL_FRect *,const struct SDL_FRect *,struct SDL_FRect *) , SDL_GetRectUnionFloat , SimNode_ExtFuncCall >(lib,"SDL_GetRectUnionFloat","SDL_GetRectUnionFloat")
		->args({"A","B","result"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:497:34
	makeExtern< bool (*)(const struct SDL_FPoint *,int,const struct SDL_FRect *,struct SDL_FRect *) , SDL_GetRectEnclosingPointsFloat , SimNode_ExtFuncCall >(lib,"SDL_GetRectEnclosingPointsFloat","SDL_GetRectEnclosingPointsFloat")
		->args({"points","count","clip","result"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_rect.h:520:34
	makeExtern< bool (*)(const struct SDL_FRect *,float *,float *,float *,float *) , SDL_GetRectAndLineIntersectionFloat , SimNode_ExtFuncCall >(lib,"SDL_GetRectAndLineIntersectionFloat","SDL_GetRectAndLineIntersectionFloat")
		->args({"rect","X1","Y1","X2","Y2"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:173:43
	makeExtern< struct SDL_Surface * (*)(int,int,enum SDL_PixelFormat) , SDL_CreateSurface , SimNode_ExtFuncCall >(lib,"SDL_CreateSurface","SDL_CreateSurface")
		->args({"width","height","format"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:203:43
	makeExtern< struct SDL_Surface * (*)(int,int,enum SDL_PixelFormat,void *,int) , SDL_CreateSurfaceFrom , SimNode_ExtFuncCall >(lib,"SDL_CreateSurfaceFrom","SDL_CreateSurfaceFrom")
		->args({"width","height","format","pixels","pitch"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:219:34
	makeExtern< void (*)(struct SDL_Surface *) , SDL_DestroySurface , SimNode_ExtFuncCall >(lib,"SDL_DestroySurface","SDL_DestroySurface")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:259:46
	makeExtern< unsigned int (*)(struct SDL_Surface *) , SDL_GetSurfaceProperties , SimNode_ExtFuncCall >(lib,"SDL_GetSurfaceProperties","SDL_GetSurfaceProperties")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:287:34
	makeExtern< bool (*)(struct SDL_Surface *,enum SDL_Colorspace) , SDL_SetSurfaceColorspace , SimNode_ExtFuncCall >(lib,"SDL_SetSurfaceColorspace","SDL_SetSurfaceColorspace")
		->args({"surface","colorspace"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:307:44
	makeExtern< enum SDL_Colorspace (*)(struct SDL_Surface *) , SDL_GetSurfaceColorspace , SimNode_ExtFuncCall >(lib,"SDL_GetSurfaceColorspace","SDL_GetSurfaceColorspace")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:338:43
	makeExtern< struct SDL_Palette * (*)(struct SDL_Surface *) , SDL_CreateSurfacePalette , SimNode_ExtFuncCall >(lib,"SDL_CreateSurfacePalette","SDL_CreateSurfacePalette")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:361:34
	makeExtern< bool (*)(struct SDL_Surface *,struct SDL_Palette *) , SDL_SetSurfacePalette , SimNode_ExtFuncCall >(lib,"SDL_SetSurfacePalette","SDL_SetSurfacePalette")
		->args({"surface","palette"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:376:43
	makeExtern< struct SDL_Palette * (*)(struct SDL_Surface *) , SDL_GetSurfacePalette , SimNode_ExtFuncCall >(lib,"SDL_GetSurfacePalette","SDL_GetSurfacePalette")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:404:34
	makeExtern< bool (*)(struct SDL_Surface *,struct SDL_Surface *) , SDL_AddSurfaceAlternateImage , SimNode_ExtFuncCall >(lib,"SDL_AddSurfaceAlternateImage","SDL_AddSurfaceAlternateImage")
		->args({"surface","image"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:420:34
	makeExtern< bool (*)(struct SDL_Surface *) , SDL_SurfaceHasAlternateImages , SimNode_ExtFuncCall >(lib,"SDL_SurfaceHasAlternateImages","SDL_SurfaceHasAlternateImages")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:448:44
	makeExtern< struct SDL_Surface ** (*)(struct SDL_Surface *,int *) , SDL_GetSurfaceImages , SimNode_ExtFuncCall >(lib,"SDL_GetSurfaceImages","SDL_GetSurfaceImages")
		->args({"surface","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:467:34
	makeExtern< void (*)(struct SDL_Surface *) , SDL_RemoveSurfaceAlternateImages , SimNode_ExtFuncCall >(lib,"SDL_RemoveSurfaceAlternateImages","SDL_RemoveSurfaceAlternateImages")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:495:34
	makeExtern< bool (*)(struct SDL_Surface *) , SDL_LockSurface , SimNode_ExtFuncCall >(lib,"SDL_LockSurface","SDL_LockSurface")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:510:34
	makeExtern< void (*)(struct SDL_Surface *) , SDL_UnlockSurface , SimNode_ExtFuncCall >(lib,"SDL_UnlockSurface","SDL_UnlockSurface")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:572:43
	makeExtern< struct SDL_Surface * (*)(struct SDL_IOStream *,bool) , SDL_LoadBMP_IO , SimNode_ExtFuncCall >(lib,"SDL_LoadBMP_IO","SDL_LoadBMP_IO")
		->args({"src","closeio"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:592:43
	makeExtern< struct SDL_Surface * (*)(const char *) , SDL_LoadBMP , SimNode_ExtFuncCall >(lib,"SDL_LoadBMP","SDL_LoadBMP")
		->args({"file"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:618:34
	makeExtern< bool (*)(struct SDL_Surface *,struct SDL_IOStream *,bool) , SDL_SaveBMP_IO , SimNode_ExtFuncCall >(lib,"SDL_SaveBMP_IO","SDL_SaveBMP_IO")
		->args({"surface","dst","closeio"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:642:34
	makeExtern< bool (*)(struct SDL_Surface *,const char *) , SDL_SaveBMP , SimNode_ExtFuncCall >(lib,"SDL_SaveBMP","SDL_SaveBMP")
		->args({"surface","file"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:752:34
	makeExtern< bool (*)(struct SDL_Surface *,bool) , SDL_SetSurfaceRLE , SimNode_ExtFuncCall >(lib,"SDL_SetSurfaceRLE","SDL_SetSurfaceRLE")
		->args({"surface","enabled"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:768:34
	makeExtern< bool (*)(struct SDL_Surface *) , SDL_SurfaceHasRLE , SimNode_ExtFuncCall >(lib,"SDL_SurfaceHasRLE","SDL_SurfaceHasRLE")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:795:34
	makeExtern< bool (*)(struct SDL_Surface *,bool,unsigned int) , SDL_SetSurfaceColorKey , SimNode_ExtFuncCall >(lib,"SDL_SetSurfaceColorKey","SDL_SetSurfaceColorKey")
		->args({"surface","enabled","key"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:812:34
	makeExtern< bool (*)(struct SDL_Surface *) , SDL_SurfaceHasColorKey , SimNode_ExtFuncCall >(lib,"SDL_SurfaceHasColorKey","SDL_SurfaceHasColorKey")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:834:34
	makeExtern< bool (*)(struct SDL_Surface *,unsigned int *) , SDL_GetSurfaceColorKey , SimNode_ExtFuncCall >(lib,"SDL_GetSurfaceColorKey","SDL_GetSurfaceColorKey")
		->args({"surface","key"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:860:34
	makeExtern< bool (*)(struct SDL_Surface *,unsigned char,unsigned char,unsigned char) , SDL_SetSurfaceColorMod , SimNode_ExtFuncCall >(lib,"SDL_SetSurfaceColorMod","SDL_SetSurfaceColorMod")
		->args({"surface","r","g","b"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:881:34
	makeExtern< bool (*)(struct SDL_Surface *,unsigned char *,unsigned char *,unsigned char *) , SDL_GetSurfaceColorMod , SimNode_ExtFuncCall >(lib,"SDL_GetSurfaceColorMod","SDL_GetSurfaceColorMod")
		->args({"surface","r","g","b"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:904:34
	makeExtern< bool (*)(struct SDL_Surface *,unsigned char) , SDL_SetSurfaceAlphaMod , SimNode_ExtFuncCall >(lib,"SDL_SetSurfaceAlphaMod","SDL_SetSurfaceAlphaMod")
		->args({"surface","alpha"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:921:34
	makeExtern< bool (*)(struct SDL_Surface *,unsigned char *) , SDL_GetSurfaceAlphaMod , SimNode_ExtFuncCall >(lib,"SDL_GetSurfaceAlphaMod","SDL_GetSurfaceAlphaMod")
		->args({"surface","alpha"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:942:34
	makeExtern< bool (*)(struct SDL_Surface *,unsigned int) , SDL_SetSurfaceBlendMode , SimNode_ExtFuncCall >(lib,"SDL_SetSurfaceBlendMode","SDL_SetSurfaceBlendMode")
		->args({"surface","blendMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:958:34
	makeExtern< bool (*)(struct SDL_Surface *,unsigned int *) , SDL_GetSurfaceBlendMode , SimNode_ExtFuncCall >(lib,"SDL_GetSurfaceBlendMode","SDL_GetSurfaceBlendMode")
		->args({"surface","blendMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:982:34
	makeExtern< bool (*)(struct SDL_Surface *,const struct SDL_Rect *) , SDL_SetSurfaceClipRect , SimNode_ExtFuncCall >(lib,"SDL_SetSurfaceClipRect","SDL_SetSurfaceClipRect")
		->args({"surface","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1004:34
	makeExtern< bool (*)(struct SDL_Surface *,struct SDL_Rect *) , SDL_GetSurfaceClipRect , SimNode_ExtFuncCall >(lib,"SDL_GetSurfaceClipRect","SDL_GetSurfaceClipRect")
		->args({"surface","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1019:34
	makeExtern< bool (*)(struct SDL_Surface *,enum SDL_FlipMode) , SDL_FlipSurface , SimNode_ExtFuncCall >(lib,"SDL_FlipSurface","SDL_FlipSurface")
		->args({"surface","flip"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1069:43
	makeExtern< struct SDL_Surface * (*)(struct SDL_Surface *) , SDL_DuplicateSurface , SimNode_ExtFuncCall >(lib,"SDL_DuplicateSurface","SDL_DuplicateSurface")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1091:43
	makeExtern< struct SDL_Surface * (*)(struct SDL_Surface *,int,int,enum SDL_ScaleMode) , SDL_ScaleSurface , SimNode_ExtFuncCall >(lib,"SDL_ScaleSurface","SDL_ScaleSurface")
		->args({"surface","width","height","scaleMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1120:43
	makeExtern< struct SDL_Surface * (*)(struct SDL_Surface *,enum SDL_PixelFormat) , SDL_ConvertSurface , SimNode_ExtFuncCall >(lib,"SDL_ConvertSurface","SDL_ConvertSurface")
		->args({"surface","format"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1149:43
	makeExtern< struct SDL_Surface * (*)(struct SDL_Surface *,enum SDL_PixelFormat,struct SDL_Palette *,enum SDL_Colorspace,unsigned int) , SDL_ConvertSurfaceAndColorspace , SimNode_ExtFuncCall >(lib,"SDL_ConvertSurfaceAndColorspace","SDL_ConvertSurfaceAndColorspace")
		->args({"surface","format","palette","colorspace","props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1173:34
	makeExtern< bool (*)(int,int,enum SDL_PixelFormat,const void *,int,enum SDL_PixelFormat,void *,int) , SDL_ConvertPixels , SimNode_ExtFuncCall >(lib,"SDL_ConvertPixels","SDL_ConvertPixels")
		->args({"width","height","src_format","src","src_pitch","dst_format","dst","dst_pitch"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1206:34
	makeExtern< bool (*)(int,int,enum SDL_PixelFormat,enum SDL_Colorspace,unsigned int,const void *,int,enum SDL_PixelFormat,enum SDL_Colorspace,unsigned int,void *,int) , SDL_ConvertPixelsAndColorspace , SimNode_ExtFuncCall >(lib,"SDL_ConvertPixelsAndColorspace","SDL_ConvertPixelsAndColorspace")
		->args({"width","height","src_format","src_colorspace","src_properties","src","src_pitch","dst_format","dst_colorspace","dst_properties","dst","dst_pitch"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1232:34
	makeExtern< bool (*)(int,int,enum SDL_PixelFormat,const void *,int,enum SDL_PixelFormat,void *,int,bool) , SDL_PremultiplyAlpha , SimNode_ExtFuncCall >(lib,"SDL_PremultiplyAlpha","SDL_PremultiplyAlpha")
		->args({"width","height","src_format","src","src_pitch","dst_format","dst","dst_pitch","linear"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1250:34
	makeExtern< bool (*)(struct SDL_Surface *,bool) , SDL_PremultiplySurfaceAlpha , SimNode_ExtFuncCall >(lib,"SDL_PremultiplySurfaceAlpha","SDL_PremultiplySurfaceAlpha")
		->args({"surface","linear"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1273:34
	makeExtern< bool (*)(struct SDL_Surface *,float,float,float,float) , SDL_ClearSurface , SimNode_ExtFuncCall >(lib,"SDL_ClearSurface","SDL_ClearSurface")
		->args({"surface","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1301:34
	makeExtern< bool (*)(struct SDL_Surface *,const struct SDL_Rect *,unsigned int) , SDL_FillSurfaceRect , SimNode_ExtFuncCall >(lib,"SDL_FillSurfaceRect","SDL_FillSurfaceRect")
		->args({"dst","rect","color"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1329:34
	makeExtern< bool (*)(struct SDL_Surface *,const struct SDL_Rect *,int,unsigned int) , SDL_FillSurfaceRects , SimNode_ExtFuncCall >(lib,"SDL_FillSurfaceRects","SDL_FillSurfaceRects")
		->args({"dst","rects","count","color"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1402:34
	makeExtern< bool (*)(struct SDL_Surface *,const struct SDL_Rect *,struct SDL_Surface *,const struct SDL_Rect *) , SDL_BlitSurface , SimNode_ExtFuncCall >(lib,"SDL_BlitSurface","SDL_BlitSurface")
		->args({"src","srcrect","dst","dstrect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1426:34
	makeExtern< bool (*)(struct SDL_Surface *,const struct SDL_Rect *,struct SDL_Surface *,const struct SDL_Rect *) , SDL_BlitSurfaceUnchecked , SimNode_ExtFuncCall >(lib,"SDL_BlitSurfaceUnchecked","SDL_BlitSurfaceUnchecked")
		->args({"src","srcrect","dst","dstrect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1450:34
	makeExtern< bool (*)(struct SDL_Surface *,const struct SDL_Rect *,struct SDL_Surface *,const struct SDL_Rect *,enum SDL_ScaleMode) , SDL_BlitSurfaceScaled , SimNode_ExtFuncCall >(lib,"SDL_BlitSurfaceScaled","SDL_BlitSurfaceScaled")
		->args({"src","srcrect","dst","dstrect","scaleMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1475:34
	makeExtern< bool (*)(struct SDL_Surface *,const struct SDL_Rect *,struct SDL_Surface *,const struct SDL_Rect *,enum SDL_ScaleMode) , SDL_BlitSurfaceUncheckedScaled , SimNode_ExtFuncCall >(lib,"SDL_BlitSurfaceUncheckedScaled","SDL_BlitSurfaceUncheckedScaled")
		->args({"src","srcrect","dst","dstrect","scaleMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1498:34
	makeExtern< bool (*)(struct SDL_Surface *,const struct SDL_Rect *,struct SDL_Surface *,const struct SDL_Rect *,enum SDL_ScaleMode) , SDL_StretchSurface , SimNode_ExtFuncCall >(lib,"SDL_StretchSurface","SDL_StretchSurface")
		->args({"src","srcrect","dst","dstrect","scaleMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1523:34
	makeExtern< bool (*)(struct SDL_Surface *,const struct SDL_Rect *,struct SDL_Surface *,const struct SDL_Rect *) , SDL_BlitSurfaceTiled , SimNode_ExtFuncCall >(lib,"SDL_BlitSurfaceTiled","SDL_BlitSurfaceTiled")
		->args({"src","srcrect","dst","dstrect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1552:34
	makeExtern< bool (*)(struct SDL_Surface *,const struct SDL_Rect *,float,enum SDL_ScaleMode,struct SDL_Surface *,const struct SDL_Rect *) , SDL_BlitSurfaceTiledWithScale , SimNode_ExtFuncCall >(lib,"SDL_BlitSurfaceTiledWithScale","SDL_BlitSurfaceTiledWithScale")
		->args({"src","srcrect","scale","scaleMode","dst","dstrect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1588:34
	makeExtern< bool (*)(struct SDL_Surface *,const struct SDL_Rect *,int,int,int,int,float,enum SDL_ScaleMode,struct SDL_Surface *,const struct SDL_Rect *) , SDL_BlitSurface9Grid , SimNode_ExtFuncCall >(lib,"SDL_BlitSurface9Grid","SDL_BlitSurface9Grid")
		->args({"src","srcrect","left_width","right_width","top_height","bottom_height","scale","scaleMode","dst","dstrect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1621:36
	makeExtern< unsigned int (*)(struct SDL_Surface *,unsigned char,unsigned char,unsigned char) , SDL_MapSurfaceRGB , SimNode_ExtFuncCall >(lib,"SDL_MapSurfaceRGB","SDL_MapSurfaceRGB")
		->args({"surface","r","g","b"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1655:36
	makeExtern< unsigned int (*)(struct SDL_Surface *,unsigned char,unsigned char,unsigned char,unsigned char) , SDL_MapSurfaceRGBA , SimNode_ExtFuncCall >(lib,"SDL_MapSurfaceRGBA","SDL_MapSurfaceRGBA")
		->args({"surface","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1685:34
	makeExtern< bool (*)(struct SDL_Surface *,int,int,unsigned char *,unsigned char *,unsigned char *,unsigned char *) , SDL_ReadSurfacePixel , SimNode_ExtFuncCall >(lib,"SDL_ReadSurfacePixel","SDL_ReadSurfacePixel")
		->args({"surface","x","y","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1712:34
	makeExtern< bool (*)(struct SDL_Surface *,int,int,float *,float *,float *,float *) , SDL_ReadSurfacePixelFloat , SimNode_ExtFuncCall >(lib,"SDL_ReadSurfacePixelFloat","SDL_ReadSurfacePixelFloat")
		->args({"surface","x","y","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1738:34
	makeExtern< bool (*)(struct SDL_Surface *,int,int,unsigned char,unsigned char,unsigned char,unsigned char) , SDL_WriteSurfacePixel , SimNode_ExtFuncCall >(lib,"SDL_WriteSurfacePixel","SDL_WriteSurfacePixel")
		->args({"surface","x","y","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_surface.h:1761:34
	makeExtern< bool (*)(struct SDL_Surface *,int,int,float,float,float,float) , SDL_WriteSurfacePixelFloat , SimNode_ExtFuncCall >(lib,"SDL_WriteSurfacePixelFloat","SDL_WriteSurfacePixelFloat")
		->args({"surface","x","y","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:175:33
	makeExtern< int (*)() , SDL_GetNumCameraDrivers , SimNode_ExtFuncCall >(lib,"SDL_GetNumCameraDrivers","SDL_GetNumCameraDrivers")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:199:42
	makeExtern< const char * (*)(int) , SDL_GetCameraDriver , SimNode_ExtFuncCall >(lib,"SDL_GetCameraDriver","SDL_GetCameraDriver")
		->args({"index"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:215:42
	makeExtern< const char * (*)() , SDL_GetCurrentCameraDriver , SimNode_ExtFuncCall >(lib,"SDL_GetCurrentCameraDriver","SDL_GetCurrentCameraDriver")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:232:44
	makeExtern< unsigned int * (*)(int *) , SDL_GetCameras , SimNode_ExtFuncCall >(lib,"SDL_GetCameras","SDL_GetCameras")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:271:47
	makeExtern< struct SDL_CameraSpec ** (*)(unsigned int,int *) , SDL_GetCameraSupportedFormats , SimNode_ExtFuncCall >(lib,"SDL_GetCameraSupportedFormats","SDL_GetCameraSupportedFormats")
		->args({"instance_id","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:286:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetCameraName , SimNode_ExtFuncCall >(lib,"SDL_GetCameraName","SDL_GetCameraName")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:305:48
	makeExtern< enum SDL_CameraPosition (*)(unsigned int) , SDL_GetCameraPosition , SimNode_ExtFuncCall >(lib,"SDL_GetCameraPosition","SDL_GetCameraPosition")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:352:42
	makeExtern< struct SDL_Camera * (*)(unsigned int,const struct SDL_CameraSpec *) , SDL_OpenCamera , SimNode_ExtFuncCall >(lib,"SDL_OpenCamera","SDL_OpenCamera")
		->args({"instance_id","spec"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:387:55
	makeExtern< enum SDL_CameraPermissionState (*)(struct SDL_Camera *) , SDL_GetCameraPermissionState , SimNode_ExtFuncCall >(lib,"SDL_GetCameraPermissionState","SDL_GetCameraPermissionState")
		->args({"camera"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:402:42
	makeExtern< unsigned int (*)(struct SDL_Camera *) , SDL_GetCameraID , SimNode_ExtFuncCall >(lib,"SDL_GetCameraID","SDL_GetCameraID")
		->args({"camera"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:415:46
	makeExtern< unsigned int (*)(struct SDL_Camera *) , SDL_GetCameraProperties , SimNode_ExtFuncCall >(lib,"SDL_GetCameraProperties","SDL_GetCameraProperties")
		->args({"camera"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:441:34
	makeExtern< bool (*)(struct SDL_Camera *,struct SDL_CameraSpec *) , SDL_GetCameraFormat , SimNode_ExtFuncCall >(lib,"SDL_GetCameraFormat","SDL_GetCameraFormat")
		->args({"camera","spec"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:484:43
	makeExtern< struct SDL_Surface * (*)(struct SDL_Camera *,Uint64 *) , SDL_AcquireCameraFrame , SimNode_ExtFuncCall >(lib,"SDL_AcquireCameraFrame","SDL_AcquireCameraFrame")
		->args({"camera","timestampNS"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:512:34
	makeExtern< void (*)(struct SDL_Camera *,struct SDL_Surface *) , SDL_ReleaseCameraFrame , SimNode_ExtFuncCall >(lib,"SDL_ReleaseCameraFrame","SDL_ReleaseCameraFrame")
		->args({"camera","frame"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_camera.h:527:34
	makeExtern< void (*)(struct SDL_Camera *) , SDL_CloseCamera , SimNode_ExtFuncCall >(lib,"SDL_CloseCamera","SDL_CloseCamera")
		->args({"camera"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_clipboard.h:104:34
	makeExtern< bool (*)(const char *) , SDL_SetClipboardText , SimNode_ExtFuncCall >(lib,"SDL_SetClipboardText","SDL_SetClipboardText")
		->args({"text"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_clipboard.h:123:36
	makeExtern< char * (*)() , SDL_GetClipboardText , SimNode_ExtFuncCall >(lib,"SDL_GetClipboardText","SDL_GetClipboardText")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_clipboard.h:137:34
	makeExtern< bool (*)() , SDL_HasClipboardText , SimNode_ExtFuncCall >(lib,"SDL_HasClipboardText","SDL_HasClipboardText")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_clipboard.h:153:34
	makeExtern< bool (*)(const char *) , SDL_SetPrimarySelectionText , SimNode_ExtFuncCall >(lib,"SDL_SetPrimarySelectionText","SDL_SetPrimarySelectionText")
		->args({"text"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_clipboard.h:172:36
	makeExtern< char * (*)() , SDL_GetPrimarySelectionText , SimNode_ExtFuncCall >(lib,"SDL_GetPrimarySelectionText","SDL_GetPrimarySelectionText")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_clipboard.h:187:34
	makeExtern< bool (*)() , SDL_HasPrimarySelectionText , SimNode_ExtFuncCall >(lib,"SDL_HasPrimarySelectionText","SDL_HasPrimarySelectionText")
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_SetClipboardData), SDL_SetClipboardData, SimNode_ExtFuncCall>(lib,"SDL_SetClipboardData","SDL_SetClipboardDataAddress")->args({"callback","cleanup","userdata","mime_types","num_mime_types"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_clipboard.h:269:34
	makeExtern< bool (*)() , SDL_ClearClipboardData , SimNode_ExtFuncCall >(lib,"SDL_ClearClipboardData","SDL_ClearClipboardData")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_clipboard.h:290:36
	makeExtern< void * (*)(const char *,size_t *) , SDL_GetClipboardData , SimNode_ExtFuncCall >(lib,"SDL_GetClipboardData","SDL_GetClipboardData")
		->args({"mime_type","size"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_clipboard.h:306:34
	makeExtern< bool (*)(const char *) , SDL_HasClipboardData , SimNode_ExtFuncCall >(lib,"SDL_HasClipboardData","SDL_HasClipboardData")
		->args({"mime_type"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_clipboard.h:323:37
	makeExtern< char ** (*)(size_t *) , SDL_GetClipboardMimeTypes , SimNode_ExtFuncCall >(lib,"SDL_GetClipboardMimeTypes","SDL_GetClipboardMimeTypes")
		->args({"num_mime_types"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:563:33
	makeExtern< int (*)() , SDL_GetNumVideoDrivers , SimNode_ExtFuncCall >(lib,"SDL_GetNumVideoDrivers","SDL_GetNumVideoDrivers")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:585:42
	makeExtern< const char * (*)(int) , SDL_GetVideoDriver , SimNode_ExtFuncCall >(lib,"SDL_GetVideoDriver","SDL_GetVideoDriver")
		->args({"index"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:604:42
	makeExtern< const char * (*)() , SDL_GetCurrentVideoDriver , SimNode_ExtFuncCall >(lib,"SDL_GetCurrentVideoDriver","SDL_GetCurrentVideoDriver")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:615:45
	makeExtern< enum SDL_SystemTheme (*)() , SDL_GetSystemTheme , SimNode_ExtFuncCall >(lib,"SDL_GetSystemTheme","SDL_GetSystemTheme")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:630:45
	makeExtern< unsigned int * (*)(int *) , SDL_GetDisplays , SimNode_ExtFuncCall >(lib,"SDL_GetDisplays","SDL_GetDisplays")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:644:43
	makeExtern< unsigned int (*)() , SDL_GetPrimaryDisplay , SimNode_ExtFuncCall >(lib,"SDL_GetPrimaryDisplay","SDL_GetPrimaryDisplay")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:682:46
	makeExtern< unsigned int (*)(unsigned int) , SDL_GetDisplayProperties , SimNode_ExtFuncCall >(lib,"SDL_GetDisplayProperties","SDL_GetDisplayProperties")
		->args({"displayID"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:702:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetDisplayName , SimNode_ExtFuncCall >(lib,"SDL_GetDisplayName","SDL_GetDisplayName")
		->args({"displayID"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:722:34
	makeExtern< bool (*)(unsigned int,struct SDL_Rect *) , SDL_GetDisplayBounds , SimNode_ExtFuncCall >(lib,"SDL_GetDisplayBounds","SDL_GetDisplayBounds")
		->args({"displayID","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:748:34
	makeExtern< bool (*)(unsigned int,struct SDL_Rect *) , SDL_GetDisplayUsableBounds , SimNode_ExtFuncCall >(lib,"SDL_GetDisplayUsableBounds","SDL_GetDisplayUsableBounds")
		->args({"displayID","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:763:52
	makeExtern< enum SDL_DisplayOrientation (*)(unsigned int) , SDL_GetNaturalDisplayOrientation , SimNode_ExtFuncCall >(lib,"SDL_GetNaturalDisplayOrientation","SDL_GetNaturalDisplayOrientation")
		->args({"displayID"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:778:52
	makeExtern< enum SDL_DisplayOrientation (*)(unsigned int) , SDL_GetCurrentDisplayOrientation , SimNode_ExtFuncCall >(lib,"SDL_GetCurrentDisplayOrientation","SDL_GetCurrentDisplayOrientation")
		->args({"displayID"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:805:35
	makeExtern< float (*)(unsigned int) , SDL_GetDisplayContentScale , SimNode_ExtFuncCall >(lib,"SDL_GetDisplayContentScale","SDL_GetDisplayContentScale")
		->args({"displayID"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:833:48
	makeExtern< struct SDL_DisplayMode ** (*)(unsigned int,int *) , SDL_GetFullscreenDisplayModes , SimNode_ExtFuncCall >(lib,"SDL_GetFullscreenDisplayModes","SDL_GetFullscreenDisplayModes")
		->args({"displayID","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:864:34
	makeExtern< bool (*)(unsigned int,int,int,float,bool,struct SDL_DisplayMode *) , SDL_GetClosestFullscreenDisplayMode , SimNode_ExtFuncCall >(lib,"SDL_GetClosestFullscreenDisplayMode","SDL_GetClosestFullscreenDisplayMode")
		->args({"displayID","w","h","refresh_rate","include_high_density_modes","closest"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:885:53
	makeExtern< const struct SDL_DisplayMode * (*)(unsigned int) , SDL_GetDesktopDisplayMode , SimNode_ExtFuncCall >(lib,"SDL_GetDesktopDisplayMode","SDL_GetDesktopDisplayMode")
		->args({"displayID"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:906:53
	makeExtern< const struct SDL_DisplayMode * (*)(unsigned int) , SDL_GetCurrentDisplayMode , SimNode_ExtFuncCall >(lib,"SDL_GetCurrentDisplayMode","SDL_GetCurrentDisplayMode")
		->args({"displayID"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:922:43
	makeExtern< unsigned int (*)(const struct SDL_Point *) , SDL_GetDisplayForPoint , SimNode_ExtFuncCall >(lib,"SDL_GetDisplayForPoint","SDL_GetDisplayForPoint")
		->args({"point"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:939:43
	makeExtern< unsigned int (*)(const struct SDL_Rect *) , SDL_GetDisplayForRect , SimNode_ExtFuncCall >(lib,"SDL_GetDisplayForRect","SDL_GetDisplayForRect")
		->args({"rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:956:43
	makeExtern< unsigned int (*)(struct SDL_Window *) , SDL_GetDisplayForWindow , SimNode_ExtFuncCall >(lib,"SDL_GetDisplayForWindow","SDL_GetDisplayForWindow")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:975:35
	makeExtern< float (*)(struct SDL_Window *) , SDL_GetWindowPixelDensity , SimNode_ExtFuncCall >(lib,"SDL_GetWindowPixelDensity","SDL_GetWindowPixelDensity")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:999:35
	makeExtern< float (*)(struct SDL_Window *) , SDL_GetWindowDisplayScale , SimNode_ExtFuncCall >(lib,"SDL_GetWindowDisplayScale","SDL_GetWindowDisplayScale")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1034:34
	makeExtern< bool (*)(struct SDL_Window *,const struct SDL_DisplayMode *) , SDL_SetWindowFullscreenMode , SimNode_ExtFuncCall >(lib,"SDL_SetWindowFullscreenMode","SDL_SetWindowFullscreenMode")
		->args({"window","mode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1050:53
	makeExtern< const struct SDL_DisplayMode * (*)(struct SDL_Window *) , SDL_GetWindowFullscreenMode , SimNode_ExtFuncCall >(lib,"SDL_GetWindowFullscreenMode","SDL_GetWindowFullscreenMode")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1065:36
	makeExtern< void * (*)(struct SDL_Window *,size_t *) , SDL_GetWindowICCProfile , SimNode_ExtFuncCall >(lib,"SDL_GetWindowICCProfile","SDL_GetWindowICCProfile")
		->args({"window","size"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1079:45
	makeExtern< enum SDL_PixelFormat (*)(struct SDL_Window *) , SDL_GetWindowPixelFormat , SimNode_ExtFuncCall >(lib,"SDL_GetWindowPixelFormat","SDL_GetWindowPixelFormat")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1095:43
	makeExtern< struct SDL_Window ** (*)(int *) , SDL_GetWindows , SimNode_ExtFuncCall >(lib,"SDL_GetWindows","SDL_GetWindows")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1184:42
	makeExtern< struct SDL_Window * (*)(const char *,int,int,SDL_WindowFlags) , SDL_CreateWindow , SimNode_ExtFuncCall >(lib,"SDL_CreateWindow","SDL_CreateWindow")
		->args({"title","w","h","flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1260:42
	makeExtern< struct SDL_Window * (*)(struct SDL_Window *,int,int,int,int,SDL_WindowFlags) , SDL_CreatePopupWindow , SimNode_ExtFuncCall >(lib,"SDL_CreatePopupWindow","SDL_CreatePopupWindow")
		->args({"parent","offset_x","offset_y","w","h","flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1409:42
	makeExtern< struct SDL_Window * (*)(unsigned int) , SDL_CreateWindowWithProperties , SimNode_ExtFuncCall >(lib,"SDL_CreateWindowWithProperties","SDL_CreateWindowWithProperties")
		->args({"props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1466:42
	makeExtern< unsigned int (*)(struct SDL_Window *) , SDL_GetWindowID , SimNode_ExtFuncCall >(lib,"SDL_GetWindowID","SDL_GetWindowID")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1484:42
	makeExtern< struct SDL_Window * (*)(unsigned int) , SDL_GetWindowFromID , SimNode_ExtFuncCall >(lib,"SDL_GetWindowFromID","SDL_GetWindowFromID")
		->args({"id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1499:42
	makeExtern< struct SDL_Window * (*)(struct SDL_Window *) , SDL_GetWindowParent , SimNode_ExtFuncCall >(lib,"SDL_GetWindowParent","SDL_GetWindowParent")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1628:46
	makeExtern< unsigned int (*)(struct SDL_Window *) , SDL_GetWindowProperties , SimNode_ExtFuncCall >(lib,"SDL_GetWindowProperties","SDL_GetWindowProperties")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1687:45
	makeExtern< SDL_WindowFlags (*)(struct SDL_Window *) , SDL_GetWindowFlags , SimNode_ExtFuncCall >(lib,"SDL_GetWindowFlags","SDL_GetWindowFlags")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1705:34
	makeExtern< bool (*)(struct SDL_Window *,const char *) , SDL_SetWindowTitle , SimNode_ExtFuncCall >(lib,"SDL_SetWindowTitle","SDL_SetWindowTitle")
		->args({"window","title"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1720:42
	makeExtern< const char * (*)(struct SDL_Window *) , SDL_GetWindowTitle , SimNode_ExtFuncCall >(lib,"SDL_GetWindowTitle","SDL_GetWindowTitle")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1747:34
	makeExtern< bool (*)(struct SDL_Window *,struct SDL_Surface *) , SDL_SetWindowIcon , SimNode_ExtFuncCall >(lib,"SDL_SetWindowIcon","SDL_SetWindowIcon")
		->args({"window","icon"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1788:34
	makeExtern< bool (*)(struct SDL_Window *,int,int) , SDL_SetWindowPosition , SimNode_ExtFuncCall >(lib,"SDL_SetWindowPosition","SDL_SetWindowPosition")
		->args({"window","x","y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1813:34
	makeExtern< bool (*)(struct SDL_Window *,int *,int *) , SDL_GetWindowPosition , SimNode_ExtFuncCall >(lib,"SDL_GetWindowPosition","SDL_GetWindowPosition")
		->args({"window","x","y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1850:34
	makeExtern< bool (*)(struct SDL_Window *,int,int) , SDL_SetWindowSize , SimNode_ExtFuncCall >(lib,"SDL_SetWindowSize","SDL_SetWindowSize")
		->args({"window","w","h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1874:34
	makeExtern< bool (*)(struct SDL_Window *,int *,int *) , SDL_GetWindowSize , SimNode_ExtFuncCall >(lib,"SDL_GetWindowSize","SDL_GetWindowSize")
		->args({"window","w","h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1896:34
	makeExtern< bool (*)(struct SDL_Window *,struct SDL_Rect *) , SDL_GetWindowSafeArea , SimNode_ExtFuncCall >(lib,"SDL_GetWindowSafeArea","SDL_GetWindowSafeArea")
		->args({"window","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1937:34
	makeExtern< bool (*)(struct SDL_Window *,float,float) , SDL_SetWindowAspectRatio , SimNode_ExtFuncCall >(lib,"SDL_SetWindowAspectRatio","SDL_SetWindowAspectRatio")
		->args({"window","min_aspect","max_aspect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1956:34
	makeExtern< bool (*)(struct SDL_Window *,float *,float *) , SDL_GetWindowAspectRatio , SimNode_ExtFuncCall >(lib,"SDL_GetWindowAspectRatio","SDL_GetWindowAspectRatio")
		->args({"window","min_aspect","max_aspect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:1993:34
	makeExtern< bool (*)(struct SDL_Window *,int *,int *,int *,int *) , SDL_GetWindowBordersSize , SimNode_ExtFuncCall >(lib,"SDL_GetWindowBordersSize","SDL_GetWindowBordersSize")
		->args({"window","top","left","bottom","right"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2013:34
	makeExtern< bool (*)(struct SDL_Window *,int *,int *) , SDL_GetWindowSizeInPixels , SimNode_ExtFuncCall >(lib,"SDL_GetWindowSizeInPixels","SDL_GetWindowSizeInPixels")
		->args({"window","w","h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2031:34
	makeExtern< bool (*)(struct SDL_Window *,int,int) , SDL_SetWindowMinimumSize , SimNode_ExtFuncCall >(lib,"SDL_SetWindowMinimumSize","SDL_SetWindowMinimumSize")
		->args({"window","min_w","min_h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2051:34
	makeExtern< bool (*)(struct SDL_Window *,int *,int *) , SDL_GetWindowMinimumSize , SimNode_ExtFuncCall >(lib,"SDL_GetWindowMinimumSize","SDL_GetWindowMinimumSize")
		->args({"window","w","h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2069:34
	makeExtern< bool (*)(struct SDL_Window *,int,int) , SDL_SetWindowMaximumSize , SimNode_ExtFuncCall >(lib,"SDL_SetWindowMaximumSize","SDL_SetWindowMaximumSize")
		->args({"window","max_w","max_h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2089:34
	makeExtern< bool (*)(struct SDL_Window *,int *,int *) , SDL_GetWindowMaximumSize , SimNode_ExtFuncCall >(lib,"SDL_GetWindowMaximumSize","SDL_GetWindowMaximumSize")
		->args({"window","w","h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2111:34
	makeExtern< bool (*)(struct SDL_Window *,bool) , SDL_SetWindowBordered , SimNode_ExtFuncCall >(lib,"SDL_SetWindowBordered","SDL_SetWindowBordered")
		->args({"window","bordered"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2133:34
	makeExtern< bool (*)(struct SDL_Window *,bool) , SDL_SetWindowResizable , SimNode_ExtFuncCall >(lib,"SDL_SetWindowResizable","SDL_SetWindowResizable")
		->args({"window","resizable"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2152:34
	makeExtern< bool (*)(struct SDL_Window *,bool) , SDL_SetWindowAlwaysOnTop , SimNode_ExtFuncCall >(lib,"SDL_SetWindowAlwaysOnTop","SDL_SetWindowAlwaysOnTop")
		->args({"window","on_top"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2199:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_ShowWindow , SimNode_ExtFuncCall >(lib,"SDL_ShowWindow","SDL_ShowWindow")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2215:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_HideWindow , SimNode_ExtFuncCall >(lib,"SDL_HideWindow","SDL_HideWindow")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2235:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_RaiseWindow , SimNode_ExtFuncCall >(lib,"SDL_RaiseWindow","SDL_RaiseWindow")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2269:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_MaximizeWindow , SimNode_ExtFuncCall >(lib,"SDL_MaximizeWindow","SDL_MaximizeWindow")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2298:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_MinimizeWindow , SimNode_ExtFuncCall >(lib,"SDL_MinimizeWindow","SDL_MinimizeWindow")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2328:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_RestoreWindow , SimNode_ExtFuncCall >(lib,"SDL_RestoreWindow","SDL_RestoreWindow")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2360:34
	makeExtern< bool (*)(struct SDL_Window *,bool) , SDL_SetWindowFullscreen , SimNode_ExtFuncCall >(lib,"SDL_SetWindowFullscreen","SDL_SetWindowFullscreen")
		->args({"window","fullscreen"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2391:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_SyncWindow , SimNode_ExtFuncCall >(lib,"SDL_SyncWindow","SDL_SyncWindow")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2406:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_WindowHasSurface , SimNode_ExtFuncCall >(lib,"SDL_WindowHasSurface","SDL_WindowHasSurface")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2435:43
	makeExtern< struct SDL_Surface * (*)(struct SDL_Window *) , SDL_GetWindowSurface , SimNode_ExtFuncCall >(lib,"SDL_GetWindowSurface","SDL_GetWindowSurface")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2461:34
	makeExtern< bool (*)(struct SDL_Window *,int) , SDL_SetWindowSurfaceVSync , SimNode_ExtFuncCall >(lib,"SDL_SetWindowSurfaceVSync","SDL_SetWindowSurfaceVSync")
		->args({"window","vsync"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2481:34
	makeExtern< bool (*)(struct SDL_Window *,int *) , SDL_GetWindowSurfaceVSync , SimNode_ExtFuncCall >(lib,"SDL_GetWindowSurfaceVSync","SDL_GetWindowSurfaceVSync")
		->args({"window","vsync"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2502:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_UpdateWindowSurface , SimNode_ExtFuncCall >(lib,"SDL_UpdateWindowSurface","SDL_UpdateWindowSurface")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2531:34
	makeExtern< bool (*)(struct SDL_Window *,const struct SDL_Rect *,int) , SDL_UpdateWindowSurfaceRects , SimNode_ExtFuncCall >(lib,"SDL_UpdateWindowSurfaceRects","SDL_UpdateWindowSurfaceRects")
		->args({"window","rects","numrects"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2547:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_DestroyWindowSurface , SimNode_ExtFuncCall >(lib,"SDL_DestroyWindowSurface","SDL_DestroyWindowSurface")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2580:34
	makeExtern< bool (*)(struct SDL_Window *,bool) , SDL_SetWindowKeyboardGrab , SimNode_ExtFuncCall >(lib,"SDL_SetWindowKeyboardGrab","SDL_SetWindowKeyboardGrab")
		->args({"window","grabbed"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2600:34
	makeExtern< bool (*)(struct SDL_Window *,bool) , SDL_SetWindowMouseGrab , SimNode_ExtFuncCall >(lib,"SDL_SetWindowMouseGrab","SDL_SetWindowMouseGrab")
		->args({"window","grabbed"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2614:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_GetWindowKeyboardGrab , SimNode_ExtFuncCall >(lib,"SDL_GetWindowKeyboardGrab","SDL_GetWindowKeyboardGrab")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2631:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_GetWindowMouseGrab , SimNode_ExtFuncCall >(lib,"SDL_GetWindowMouseGrab","SDL_GetWindowMouseGrab")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2645:42
	makeExtern< struct SDL_Window * (*)() , SDL_GetGrabbedWindow , SimNode_ExtFuncCall >(lib,"SDL_GetGrabbedWindow","SDL_GetGrabbedWindow")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2667:34
	makeExtern< bool (*)(struct SDL_Window *,const struct SDL_Rect *) , SDL_SetWindowMouseRect , SimNode_ExtFuncCall >(lib,"SDL_SetWindowMouseRect","SDL_SetWindowMouseRect")
		->args({"window","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2684:46
	makeExtern< const struct SDL_Rect * (*)(struct SDL_Window *) , SDL_GetWindowMouseRect , SimNode_ExtFuncCall >(lib,"SDL_GetWindowMouseRect","SDL_GetWindowMouseRect")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2705:34
	makeExtern< bool (*)(struct SDL_Window *,float) , SDL_SetWindowOpacity , SimNode_ExtFuncCall >(lib,"SDL_SetWindowOpacity","SDL_SetWindowOpacity")
		->args({"window","opacity"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2723:35
	makeExtern< float (*)(struct SDL_Window *) , SDL_GetWindowOpacity , SimNode_ExtFuncCall >(lib,"SDL_GetWindowOpacity","SDL_GetWindowOpacity")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2757:34
	makeExtern< bool (*)(struct SDL_Window *,struct SDL_Window *) , SDL_SetWindowParent , SimNode_ExtFuncCall >(lib,"SDL_SetWindowParent","SDL_SetWindowParent")
		->args({"window","parent"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2777:34
	makeExtern< bool (*)(struct SDL_Window *,bool) , SDL_SetWindowModal , SimNode_ExtFuncCall >(lib,"SDL_SetWindowModal","SDL_SetWindowModal")
		->args({"window","modal"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2791:34
	makeExtern< bool (*)(struct SDL_Window *,bool) , SDL_SetWindowFocusable , SimNode_ExtFuncCall >(lib,"SDL_SetWindowFocusable","SDL_SetWindowFocusable")
		->args({"window","focusable"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2817:34
	makeExtern< bool (*)(struct SDL_Window *,int,int) , SDL_ShowWindowSystemMenu , SimNode_ExtFuncCall >(lib,"SDL_ShowWindowSystemMenu","SDL_ShowWindowSystemMenu")
		->args({"window","x","y"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_SetWindowHitTest), SDL_SetWindowHitTest, SimNode_ExtFuncCall>(lib,"SDL_SetWindowHitTest","SDL_SetWindowHitTestAddress")->args({"window","callback","callback_data"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2926:34
	makeExtern< bool (*)(struct SDL_Window *,struct SDL_Surface *) , SDL_SetWindowShape , SimNode_ExtFuncCall >(lib,"SDL_SetWindowShape","SDL_SetWindowShape")
		->args({"window","shape"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:2940:34
	makeExtern< bool (*)(struct SDL_Window *,enum SDL_FlashOperation) , SDL_FlashWindow , SimNode_ExtFuncCall >(lib,"SDL_FlashWindow","SDL_FlashWindow")
		->args({"window","operation"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:3018:34
	makeExtern< void (*)(struct SDL_Window *) , SDL_DestroyWindow , SimNode_ExtFuncCall >(lib,"SDL_DestroyWindow","SDL_DestroyWindow")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:3037:34
	makeExtern< bool (*)() , SDL_ScreenSaverEnabled , SimNode_ExtFuncCall >(lib,"SDL_ScreenSaverEnabled","SDL_ScreenSaverEnabled")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:3052:34
	makeExtern< bool (*)() , SDL_EnableScreenSaver , SimNode_ExtFuncCall >(lib,"SDL_EnableScreenSaver","SDL_EnableScreenSaver")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_video.h:3073:34
	makeExtern< bool (*)() , SDL_DisableScreenSaver , SimNode_ExtFuncCall >(lib,"SDL_DisableScreenSaver","SDL_DisableScreenSaver")
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_ShowOpenFileDialog), SDL_ShowOpenFileDialog, SimNode_ExtFuncCall>(lib,"SDL_ShowOpenFileDialog","SDL_ShowOpenFileDialogAddress")->args({"callback","userdata","window","filters","nfilters","default_location","allow_many"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_ShowSaveFileDialog), SDL_ShowSaveFileDialog, SimNode_ExtFuncCall>(lib,"SDL_ShowSaveFileDialog","SDL_ShowSaveFileDialogAddress")->args({"callback","userdata","window","filters","nfilters","default_location"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_ShowOpenFolderDialog), SDL_ShowOpenFolderDialog, SimNode_ExtFuncCall>(lib,"SDL_ShowOpenFolderDialog","SDL_ShowOpenFolderDialogAddress")->args({"callback","userdata","window","default_location","allow_many"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_ShowFileDialogWithProperties), SDL_ShowFileDialogWithProperties, SimNode_ExtFuncCall>(lib,"SDL_ShowFileDialogWithProperties","SDL_ShowFileDialogWithPropertiesAddress")->args({"type","callback","userdata","props"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_power.h:100:44
	makeExtern< enum SDL_PowerState (*)(int *,int *) , SDL_GetPowerInfo , SimNode_ExtFuncCall >(lib,"SDL_GetPowerInfo","SDL_GetPowerInfo")
		->args({"seconds","percent"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:159:44
	makeExtern< unsigned int * (*)(int *) , SDL_GetSensors , SimNode_ExtFuncCall >(lib,"SDL_GetSensors","SDL_GetSensors")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:171:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetSensorNameForID , SimNode_ExtFuncCall >(lib,"SDL_GetSensorNameForID","SDL_GetSensorNameForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:184:44
	makeExtern< enum SDL_SensorType (*)(unsigned int) , SDL_GetSensorTypeForID , SimNode_ExtFuncCall >(lib,"SDL_GetSensorTypeForID","SDL_GetSensorTypeForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:197:33
	makeExtern< int (*)(unsigned int) , SDL_GetSensorNonPortableTypeForID , SimNode_ExtFuncCall >(lib,"SDL_GetSensorNonPortableTypeForID","SDL_GetSensorNonPortableTypeForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:208:42
	makeExtern< struct SDL_Sensor * (*)(unsigned int) , SDL_OpenSensor , SimNode_ExtFuncCall >(lib,"SDL_OpenSensor","SDL_OpenSensor")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:219:42
	makeExtern< struct SDL_Sensor * (*)(unsigned int) , SDL_GetSensorFromID , SimNode_ExtFuncCall >(lib,"SDL_GetSensorFromID","SDL_GetSensorFromID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:230:46
	makeExtern< unsigned int (*)(struct SDL_Sensor *) , SDL_GetSensorProperties , SimNode_ExtFuncCall >(lib,"SDL_GetSensorProperties","SDL_GetSensorProperties")
		->args({"sensor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:241:42
	makeExtern< const char * (*)(struct SDL_Sensor *) , SDL_GetSensorName , SimNode_ExtFuncCall >(lib,"SDL_GetSensorName","SDL_GetSensorName")
		->args({"sensor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:252:44
	makeExtern< enum SDL_SensorType (*)(struct SDL_Sensor *) , SDL_GetSensorType , SimNode_ExtFuncCall >(lib,"SDL_GetSensorType","SDL_GetSensorType")
		->args({"sensor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:262:33
	makeExtern< int (*)(struct SDL_Sensor *) , SDL_GetSensorNonPortableType , SimNode_ExtFuncCall >(lib,"SDL_GetSensorNonPortableType","SDL_GetSensorNonPortableType")
		->args({"sensor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:273:42
	makeExtern< unsigned int (*)(struct SDL_Sensor *) , SDL_GetSensorID , SimNode_ExtFuncCall >(lib,"SDL_GetSensorID","SDL_GetSensorID")
		->args({"sensor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:288:34
	makeExtern< bool (*)(struct SDL_Sensor *,float *,int) , SDL_GetSensorData , SimNode_ExtFuncCall >(lib,"SDL_GetSensorData","SDL_GetSensorData")
		->args({"sensor","data","num_values"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:297:34
	makeExtern< void (*)(struct SDL_Sensor *) , SDL_CloseSensor , SimNode_ExtFuncCall >(lib,"SDL_CloseSensor","SDL_CloseSensor")
		->args({"sensor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_sensor.h:310:34
	makeExtern< void (*)() , SDL_UpdateSensors , SimNode_ExtFuncCall >(lib,"SDL_UpdateSensors","SDL_UpdateSensors")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:189:34
	makeExtern< void (*)() , SDL_LockJoysticks , SimNode_ExtFuncCall >(lib,"SDL_LockJoysticks","SDL_LockJoysticks")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:199:34
	makeExtern< void (*)() , SDL_UnlockJoysticks , SimNode_ExtFuncCall >(lib,"SDL_UnlockJoysticks","SDL_UnlockJoysticks")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:212:34
	makeExtern< bool (*)() , SDL_HasJoystick , SimNode_ExtFuncCall >(lib,"SDL_HasJoystick","SDL_HasJoystick")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:230:46
	makeExtern< unsigned int * (*)(int *) , SDL_GetJoysticks , SimNode_ExtFuncCall >(lib,"SDL_GetJoysticks","SDL_GetJoysticks")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:248:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetJoystickNameForID , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickNameForID","SDL_GetJoystickNameForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:266:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetJoystickPathForID , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickPathForID","SDL_GetJoystickPathForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:283:33
	makeExtern< int (*)(unsigned int) , SDL_GetJoystickPlayerIndexForID , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickPlayerIndexForID","SDL_GetJoystickPlayerIndexForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:301:38
	makeExtern< struct SDL_GUID (*)(unsigned int) , SDL_GetJoystickGUIDForID , SimNode_ExtFuncCallAndCopyOrMove >(lib,"SDL_GetJoystickGUIDForID","SDL_GetJoystickGUIDForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:320:36
	makeExtern< unsigned short (*)(unsigned int) , SDL_GetJoystickVendorForID , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickVendorForID","SDL_GetJoystickVendorForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:339:36
	makeExtern< unsigned short (*)(unsigned int) , SDL_GetJoystickProductForID , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickProductForID","SDL_GetJoystickProductForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:358:36
	makeExtern< unsigned short (*)(unsigned int) , SDL_GetJoystickProductVersionForID , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickProductVersionForID","SDL_GetJoystickProductVersionForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:377:46
	makeExtern< enum SDL_JoystickType (*)(unsigned int) , SDL_GetJoystickTypeForID , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickTypeForID","SDL_GetJoystickTypeForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:395:44
	makeExtern< struct SDL_Joystick * (*)(unsigned int) , SDL_OpenJoystick , SimNode_ExtFuncCall >(lib,"SDL_OpenJoystick","SDL_OpenJoystick")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:408:44
	makeExtern< struct SDL_Joystick * (*)(unsigned int) , SDL_GetJoystickFromID , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickFromID","SDL_GetJoystickFromID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:424:44
	makeExtern< struct SDL_Joystick * (*)(int) , SDL_GetJoystickFromPlayerIndex , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickFromPlayerIndex","SDL_GetJoystickFromPlayerIndex")
		->args({"player_index"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:539:44
	makeExtern< unsigned int (*)(const struct SDL_VirtualJoystickDesc *) , SDL_AttachVirtualJoystick , SimNode_ExtFuncCall >(lib,"SDL_AttachVirtualJoystick","SDL_AttachVirtualJoystick")
		->args({"desc"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:555:34
	makeExtern< bool (*)(unsigned int) , SDL_DetachVirtualJoystick , SimNode_ExtFuncCall >(lib,"SDL_DetachVirtualJoystick","SDL_DetachVirtualJoystick")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:567:34
	makeExtern< bool (*)(unsigned int) , SDL_IsJoystickVirtual , SimNode_ExtFuncCall >(lib,"SDL_IsJoystickVirtual","SDL_IsJoystickVirtual")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:598:34
	makeExtern< bool (*)(struct SDL_Joystick *,int,short) , SDL_SetJoystickVirtualAxis , SimNode_ExtFuncCall >(lib,"SDL_SetJoystickVirtualAxis","SDL_SetJoystickVirtualAxis")
		->args({"joystick","axis","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:626:34
	makeExtern< bool (*)(struct SDL_Joystick *,int,short,short) , SDL_SetJoystickVirtualBall , SimNode_ExtFuncCall >(lib,"SDL_SetJoystickVirtualBall","SDL_SetJoystickVirtualBall")
		->args({"joystick","ball","xrel","yrel"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:653:34
	makeExtern< bool (*)(struct SDL_Joystick *,int,bool) , SDL_SetJoystickVirtualButton , SimNode_ExtFuncCall >(lib,"SDL_SetJoystickVirtualButton","SDL_SetJoystickVirtualButton")
		->args({"joystick","button","down"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:680:34
	makeExtern< bool (*)(struct SDL_Joystick *,int,unsigned char) , SDL_SetJoystickVirtualHat , SimNode_ExtFuncCall >(lib,"SDL_SetJoystickVirtualHat","SDL_SetJoystickVirtualHat")
		->args({"joystick","hat","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:714:34
	makeExtern< bool (*)(struct SDL_Joystick *,int,int,bool,float,float,float) , SDL_SetJoystickVirtualTouchpad , SimNode_ExtFuncCall >(lib,"SDL_SetJoystickVirtualTouchpad","SDL_SetJoystickVirtualTouchpad")
		->args({"joystick","touchpad","finger","down","x","y","pressure"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:744:34
	makeExtern< bool (*)(struct SDL_Joystick *,enum SDL_SensorType,Uint64,const float *,int) , SDL_SendJoystickVirtualSensorData , SimNode_ExtFuncCall >(lib,"SDL_SendJoystickVirtualSensorData","SDL_SendJoystickVirtualSensorData")
		->args({"joystick","type","sensor_timestamp","data","num_values"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:770:46
	makeExtern< unsigned int (*)(struct SDL_Joystick *) , SDL_GetJoystickProperties , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickProperties","SDL_GetJoystickProperties")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:791:42
	makeExtern< const char * (*)(struct SDL_Joystick *) , SDL_GetJoystickName , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickName","SDL_GetJoystickName")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:806:42
	makeExtern< const char * (*)(struct SDL_Joystick *) , SDL_GetJoystickPath , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickPath","SDL_GetJoystickPath")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:823:33
	makeExtern< int (*)(struct SDL_Joystick *) , SDL_GetJoystickPlayerIndex , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickPlayerIndex","SDL_GetJoystickPlayerIndex")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:840:34
	makeExtern< bool (*)(struct SDL_Joystick *,int) , SDL_SetJoystickPlayerIndex , SimNode_ExtFuncCall >(lib,"SDL_SetJoystickPlayerIndex","SDL_SetJoystickPlayerIndex")
		->args({"joystick","player_index"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:859:38
	makeExtern< struct SDL_GUID (*)(struct SDL_Joystick *) , SDL_GetJoystickGUID , SimNode_ExtFuncCallAndCopyOrMove >(lib,"SDL_GetJoystickGUID","SDL_GetJoystickGUID")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:875:36
	makeExtern< unsigned short (*)(struct SDL_Joystick *) , SDL_GetJoystickVendor , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickVendor","SDL_GetJoystickVendor")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:891:36
	makeExtern< unsigned short (*)(struct SDL_Joystick *) , SDL_GetJoystickProduct , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickProduct","SDL_GetJoystickProduct")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:907:36
	makeExtern< unsigned short (*)(struct SDL_Joystick *) , SDL_GetJoystickProductVersion , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickProductVersion","SDL_GetJoystickProductVersion")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:922:36
	makeExtern< unsigned short (*)(struct SDL_Joystick *) , SDL_GetJoystickFirmwareVersion , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickFirmwareVersion","SDL_GetJoystickFirmwareVersion")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:937:42
	makeExtern< const char * (*)(struct SDL_Joystick *) , SDL_GetJoystickSerial , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickSerial","SDL_GetJoystickSerial")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:951:46
	makeExtern< enum SDL_JoystickType (*)(struct SDL_Joystick *) , SDL_GetJoystickType , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickType","SDL_GetJoystickType")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:972:34
	makeExtern< void (*)(struct SDL_GUID,unsigned short *,unsigned short *,unsigned short *,unsigned short *) , SDL_GetJoystickGUIDInfo , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickGUIDInfo","SDL_GetJoystickGUIDInfo")
		->args({"guid","vendor","product","version","crc16"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:985:34
	makeExtern< bool (*)(struct SDL_Joystick *) , SDL_JoystickConnected , SimNode_ExtFuncCall >(lib,"SDL_JoystickConnected","SDL_JoystickConnected")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:998:44
	makeExtern< unsigned int (*)(struct SDL_Joystick *) , SDL_GetJoystickID , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickID","SDL_GetJoystickID")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1020:33
	makeExtern< int (*)(struct SDL_Joystick *) , SDL_GetNumJoystickAxes , SimNode_ExtFuncCall >(lib,"SDL_GetNumJoystickAxes","SDL_GetNumJoystickAxes")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1043:33
	makeExtern< int (*)(struct SDL_Joystick *) , SDL_GetNumJoystickBalls , SimNode_ExtFuncCall >(lib,"SDL_GetNumJoystickBalls","SDL_GetNumJoystickBalls")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1061:33
	makeExtern< int (*)(struct SDL_Joystick *) , SDL_GetNumJoystickHats , SimNode_ExtFuncCall >(lib,"SDL_GetNumJoystickHats","SDL_GetNumJoystickHats")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1079:33
	makeExtern< int (*)(struct SDL_Joystick *) , SDL_GetNumJoystickButtons , SimNode_ExtFuncCall >(lib,"SDL_GetNumJoystickButtons","SDL_GetNumJoystickButtons")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1097:34
	makeExtern< void (*)(bool) , SDL_SetJoystickEventsEnabled , SimNode_ExtFuncCall >(lib,"SDL_SetJoystickEventsEnabled","SDL_SetJoystickEventsEnabled")
		->args({"enabled"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1114:34
	makeExtern< bool (*)() , SDL_JoystickEventsEnabled , SimNode_ExtFuncCall >(lib,"SDL_JoystickEventsEnabled","SDL_JoystickEventsEnabled")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1126:34
	makeExtern< void (*)() , SDL_UpdateJoysticks , SimNode_ExtFuncCall >(lib,"SDL_UpdateJoysticks","SDL_UpdateJoysticks")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1152:36
	makeExtern< short (*)(struct SDL_Joystick *,int) , SDL_GetJoystickAxis , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickAxis","SDL_GetJoystickAxis")
		->args({"joystick","axis"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1170:34
	makeExtern< bool (*)(struct SDL_Joystick *,int,short *) , SDL_GetJoystickAxisInitialState , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickAxisInitialState","SDL_GetJoystickAxisInitialState")
		->args({"joystick","axis","state"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1193:34
	makeExtern< bool (*)(struct SDL_Joystick *,int,int *,int *) , SDL_GetJoystickBall , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickBall","SDL_GetJoystickBall")
		->args({"joystick","ball","dx","dy"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1210:35
	makeExtern< unsigned char (*)(struct SDL_Joystick *,int) , SDL_GetJoystickHat , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickHat","SDL_GetJoystickHat")
		->args({"joystick","hat"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1236:34
	makeExtern< bool (*)(struct SDL_Joystick *,int) , SDL_GetJoystickButton , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickButton","SDL_GetJoystickButton")
		->args({"joystick","button"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1259:34
	makeExtern< bool (*)(struct SDL_Joystick *,unsigned short,unsigned short,unsigned int) , SDL_RumbleJoystick , SimNode_ExtFuncCall >(lib,"SDL_RumbleJoystick","SDL_RumbleJoystick")
		->args({"joystick","low_frequency_rumble","high_frequency_rumble","duration_ms"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1290:34
	makeExtern< bool (*)(struct SDL_Joystick *,unsigned short,unsigned short,unsigned int) , SDL_RumbleJoystickTriggers , SimNode_ExtFuncCall >(lib,"SDL_RumbleJoystickTriggers","SDL_RumbleJoystickTriggers")
		->args({"joystick","left_rumble","right_rumble","duration_ms"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1312:34
	makeExtern< bool (*)(struct SDL_Joystick *,unsigned char,unsigned char,unsigned char) , SDL_SetJoystickLED , SimNode_ExtFuncCall >(lib,"SDL_SetJoystickLED","SDL_SetJoystickLED")
		->args({"joystick","red","green","blue"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1327:34
	makeExtern< bool (*)(struct SDL_Joystick *,const void *,int) , SDL_SendJoystickEffect , SimNode_ExtFuncCall >(lib,"SDL_SendJoystickEffect","SDL_SendJoystickEffect")
		->args({"joystick","data","size"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1340:34
	makeExtern< void (*)(struct SDL_Joystick *) , SDL_CloseJoystick , SimNode_ExtFuncCall >(lib,"SDL_CloseJoystick","SDL_CloseJoystick")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1354:57
	makeExtern< enum SDL_JoystickConnectionState (*)(struct SDL_Joystick *) , SDL_GetJoystickConnectionState , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickConnectionState","SDL_GetJoystickConnectionState")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_joystick.h:1377:44
	makeExtern< enum SDL_PowerState (*)(struct SDL_Joystick *,int *) , SDL_GetJoystickPowerInfo , SimNode_ExtFuncCall >(lib,"SDL_GetJoystickPowerInfo","SDL_GetJoystickPowerInfo")
		->args({"joystick","percent"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:346:33
	makeExtern< int (*)(const char *) , SDL_AddGamepadMapping , SimNode_ExtFuncCall >(lib,"SDL_AddGamepadMapping","SDL_AddGamepadMapping")
		->args({"mapping"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:386:33
	makeExtern< int (*)(struct SDL_IOStream *,bool) , SDL_AddGamepadMappingsFromIO , SimNode_ExtFuncCall >(lib,"SDL_AddGamepadMappingsFromIO","SDL_AddGamepadMappingsFromIO")
		->args({"src","closeio"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:420:33
	makeExtern< int (*)(const char *) , SDL_AddGamepadMappingsFromFile , SimNode_ExtFuncCall >(lib,"SDL_AddGamepadMappingsFromFile","SDL_AddGamepadMappingsFromFile")
		->args({"file"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:434:34
	makeExtern< bool (*)() , SDL_ReloadGamepadMappings , SimNode_ExtFuncCall >(lib,"SDL_ReloadGamepadMappings","SDL_ReloadGamepadMappings")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:450:37
	makeExtern< char ** (*)(int *) , SDL_GetGamepadMappings , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadMappings","SDL_GetGamepadMappings")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:467:36
	makeExtern< char * (*)(struct SDL_GUID) , SDL_GetGamepadMappingForGUID , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadMappingForGUID","SDL_GetGamepadMappingForGUID")
		->args({"guid"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:488:36
	makeExtern< char * (*)(struct SDL_Gamepad *) , SDL_GetGamepadMapping , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadMapping","SDL_GetGamepadMapping")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:508:34
	makeExtern< bool (*)(unsigned int,const char *) , SDL_SetGamepadMapping , SimNode_ExtFuncCall >(lib,"SDL_SetGamepadMapping","SDL_SetGamepadMapping")
		->args({"instance_id","mapping"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:521:34
	makeExtern< bool (*)() , SDL_HasGamepad , SimNode_ExtFuncCall >(lib,"SDL_HasGamepad","SDL_HasGamepad")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:539:46
	makeExtern< unsigned int * (*)(int *) , SDL_GetGamepads , SimNode_ExtFuncCall >(lib,"SDL_GetGamepads","SDL_GetGamepads")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:555:34
	makeExtern< bool (*)(unsigned int) , SDL_IsGamepad , SimNode_ExtFuncCall >(lib,"SDL_IsGamepad","SDL_IsGamepad")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:573:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetGamepadNameForID , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadNameForID","SDL_GetGamepadNameForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:591:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetGamepadPathForID , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadPathForID","SDL_GetGamepadPathForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:608:33
	makeExtern< int (*)(unsigned int) , SDL_GetGamepadPlayerIndexForID , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadPlayerIndexForID","SDL_GetGamepadPlayerIndexForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:626:38
	makeExtern< struct SDL_GUID (*)(unsigned int) , SDL_GetGamepadGUIDForID , SimNode_ExtFuncCallAndCopyOrMove >(lib,"SDL_GetGamepadGUIDForID","SDL_GetGamepadGUIDForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:645:36
	makeExtern< unsigned short (*)(unsigned int) , SDL_GetGamepadVendorForID , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadVendorForID","SDL_GetGamepadVendorForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:664:36
	makeExtern< unsigned short (*)(unsigned int) , SDL_GetGamepadProductForID , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadProductForID","SDL_GetGamepadProductForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:683:36
	makeExtern< unsigned short (*)(unsigned int) , SDL_GetGamepadProductVersionForID , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadProductVersionForID","SDL_GetGamepadProductVersionForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:701:45
	makeExtern< enum SDL_GamepadType (*)(unsigned int) , SDL_GetGamepadTypeForID , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadTypeForID","SDL_GetGamepadTypeForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:719:45
	makeExtern< enum SDL_GamepadType (*)(unsigned int) , SDL_GetRealGamepadTypeForID , SimNode_ExtFuncCall >(lib,"SDL_GetRealGamepadTypeForID","SDL_GetRealGamepadTypeForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:737:36
	makeExtern< char * (*)(unsigned int) , SDL_GetGamepadMappingForID , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadMappingForID","SDL_GetGamepadMappingForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:753:43
	makeExtern< struct SDL_Gamepad * (*)(unsigned int) , SDL_OpenGamepad , SimNode_ExtFuncCall >(lib,"SDL_OpenGamepad","SDL_OpenGamepad")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:767:43
	makeExtern< struct SDL_Gamepad * (*)(unsigned int) , SDL_GetGamepadFromID , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadFromID","SDL_GetGamepadFromID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:782:43
	makeExtern< struct SDL_Gamepad * (*)(int) , SDL_GetGamepadFromPlayerIndex , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadFromPlayerIndex","SDL_GetGamepadFromPlayerIndex")
		->args({"player_index"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:811:46
	makeExtern< unsigned int (*)(struct SDL_Gamepad *) , SDL_GetGamepadProperties , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadProperties","SDL_GetGamepadProperties")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:831:44
	makeExtern< unsigned int (*)(struct SDL_Gamepad *) , SDL_GetGamepadID , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadID","SDL_GetGamepadID")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:847:42
	makeExtern< const char * (*)(struct SDL_Gamepad *) , SDL_GetGamepadName , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadName","SDL_GetGamepadName")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:863:42
	makeExtern< const char * (*)(struct SDL_Gamepad *) , SDL_GetGamepadPath , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadPath","SDL_GetGamepadPath")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:878:45
	makeExtern< enum SDL_GamepadType (*)(struct SDL_Gamepad *) , SDL_GetGamepadType , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadType","SDL_GetGamepadType")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:893:45
	makeExtern< enum SDL_GamepadType (*)(struct SDL_Gamepad *) , SDL_GetRealGamepadType , SimNode_ExtFuncCall >(lib,"SDL_GetRealGamepadType","SDL_GetRealGamepadType")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:909:33
	makeExtern< int (*)(struct SDL_Gamepad *) , SDL_GetGamepadPlayerIndex , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadPlayerIndex","SDL_GetGamepadPlayerIndex")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:926:34
	makeExtern< bool (*)(struct SDL_Gamepad *,int) , SDL_SetGamepadPlayerIndex , SimNode_ExtFuncCall >(lib,"SDL_SetGamepadPlayerIndex","SDL_SetGamepadPlayerIndex")
		->args({"gamepad","player_index"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:942:36
	makeExtern< unsigned short (*)(struct SDL_Gamepad *) , SDL_GetGamepadVendor , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadVendor","SDL_GetGamepadVendor")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:958:36
	makeExtern< unsigned short (*)(struct SDL_Gamepad *) , SDL_GetGamepadProduct , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadProduct","SDL_GetGamepadProduct")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:974:36
	makeExtern< unsigned short (*)(struct SDL_Gamepad *) , SDL_GetGamepadProductVersion , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadProductVersion","SDL_GetGamepadProductVersion")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:988:36
	makeExtern< unsigned short (*)(struct SDL_Gamepad *) , SDL_GetGamepadFirmwareVersion , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadFirmwareVersion","SDL_GetGamepadFirmwareVersion")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1002:42
	makeExtern< const char * (*)(struct SDL_Gamepad *) , SDL_GetGamepadSerial , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadSerial","SDL_GetGamepadSerial")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1017:36
	makeExtern< Uint64 (*)(struct SDL_Gamepad *) , SDL_GetGamepadSteamHandle , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadSteamHandle","SDL_GetGamepadSteamHandle")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1031:57
	makeExtern< enum SDL_JoystickConnectionState (*)(struct SDL_Gamepad *) , SDL_GetGamepadConnectionState , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadConnectionState","SDL_GetGamepadConnectionState")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1053:44
	makeExtern< enum SDL_PowerState (*)(struct SDL_Gamepad *,int *) , SDL_GetGamepadPowerInfo , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadPowerInfo","SDL_GetGamepadPowerInfo")
		->args({"gamepad","percent"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1067:34
	makeExtern< bool (*)(struct SDL_Gamepad *) , SDL_GamepadConnected , SimNode_ExtFuncCall >(lib,"SDL_GamepadConnected","SDL_GamepadConnected")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1089:44
	makeExtern< struct SDL_Joystick * (*)(struct SDL_Gamepad *) , SDL_GetGamepadJoystick , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadJoystick","SDL_GetGamepadJoystick")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1106:34
	makeExtern< void (*)(bool) , SDL_SetGamepadEventsEnabled , SimNode_ExtFuncCall >(lib,"SDL_SetGamepadEventsEnabled","SDL_SetGamepadEventsEnabled")
		->args({"enabled"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1122:34
	makeExtern< bool (*)() , SDL_GamepadEventsEnabled , SimNode_ExtFuncCall >(lib,"SDL_GamepadEventsEnabled","SDL_GamepadEventsEnabled")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1138:51
	makeExtern< struct SDL_GamepadBinding ** (*)(struct SDL_Gamepad *,int *) , SDL_GetGamepadBindings , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadBindings","SDL_GetGamepadBindings")
		->args({"gamepad","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1151:34
	makeExtern< void (*)() , SDL_UpdateGamepads , SimNode_ExtFuncCall >(lib,"SDL_UpdateGamepads","SDL_UpdateGamepads")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1171:45
	makeExtern< enum SDL_GamepadType (*)(const char *) , SDL_GetGamepadTypeFromString , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadTypeFromString","SDL_GetGamepadTypeFromString")
		->args({"str"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1187:42
	makeExtern< const char * (*)(enum SDL_GamepadType) , SDL_GetGamepadStringForType , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadStringForType","SDL_GetGamepadStringForType")
		->args({"type"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1211:45
	makeExtern< enum SDL_GamepadAxis (*)(const char *) , SDL_GetGamepadAxisFromString , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadAxisFromString","SDL_GetGamepadAxisFromString")
		->args({"str"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1227:42
	makeExtern< const char * (*)(enum SDL_GamepadAxis) , SDL_GetGamepadStringForAxis , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadStringForAxis","SDL_GetGamepadStringForAxis")
		->args({"axis"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1246:34
	makeExtern< bool (*)(struct SDL_Gamepad *,enum SDL_GamepadAxis) , SDL_GamepadHasAxis , SimNode_ExtFuncCall >(lib,"SDL_GamepadHasAxis","SDL_GamepadHasAxis")
		->args({"gamepad","axis"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1274:36
	makeExtern< short (*)(struct SDL_Gamepad *,enum SDL_GamepadAxis) , SDL_GetGamepadAxis , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadAxis","SDL_GetGamepadAxis")
		->args({"gamepad","axis"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1294:47
	makeExtern< enum SDL_GamepadButton (*)(const char *) , SDL_GetGamepadButtonFromString , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadButtonFromString","SDL_GetGamepadButtonFromString")
		->args({"str"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1310:42
	makeExtern< const char * (*)(enum SDL_GamepadButton) , SDL_GetGamepadStringForButton , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadStringForButton","SDL_GetGamepadStringForButton")
		->args({"button"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1328:34
	makeExtern< bool (*)(struct SDL_Gamepad *,enum SDL_GamepadButton) , SDL_GamepadHasButton , SimNode_ExtFuncCall >(lib,"SDL_GamepadHasButton","SDL_GamepadHasButton")
		->args({"gamepad","button"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1344:34
	makeExtern< bool (*)(struct SDL_Gamepad *,enum SDL_GamepadButton) , SDL_GetGamepadButton , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadButton","SDL_GetGamepadButton")
		->args({"gamepad","button"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1359:52
	makeExtern< enum SDL_GamepadButtonLabel (*)(enum SDL_GamepadType,enum SDL_GamepadButton) , SDL_GetGamepadButtonLabelForType , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadButtonLabelForType","SDL_GetGamepadButtonLabelForType")
		->args({"type","button"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1374:52
	makeExtern< enum SDL_GamepadButtonLabel (*)(struct SDL_Gamepad *,enum SDL_GamepadButton) , SDL_GetGamepadButtonLabel , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadButtonLabel","SDL_GetGamepadButtonLabel")
		->args({"gamepad","button"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1388:33
	makeExtern< int (*)(struct SDL_Gamepad *) , SDL_GetNumGamepadTouchpads , SimNode_ExtFuncCall >(lib,"SDL_GetNumGamepadTouchpads","SDL_GetNumGamepadTouchpads")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1405:33
	makeExtern< int (*)(struct SDL_Gamepad *,int) , SDL_GetNumGamepadTouchpadFingers , SimNode_ExtFuncCall >(lib,"SDL_GetNumGamepadTouchpadFingers","SDL_GetNumGamepadTouchpadFingers")
		->args({"gamepad","touchpad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1429:34
	makeExtern< bool (*)(struct SDL_Gamepad *,int,int,bool *,float *,float *,float *) , SDL_GetGamepadTouchpadFinger , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadTouchpadFinger","SDL_GetGamepadTouchpadFinger")
		->args({"gamepad","touchpad","finger","down","x","y","pressure"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1446:34
	makeExtern< bool (*)(struct SDL_Gamepad *,enum SDL_SensorType) , SDL_GamepadHasSensor , SimNode_ExtFuncCall >(lib,"SDL_GamepadHasSensor","SDL_GamepadHasSensor")
		->args({"gamepad","type"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1464:34
	makeExtern< bool (*)(struct SDL_Gamepad *,enum SDL_SensorType,bool) , SDL_SetGamepadSensorEnabled , SimNode_ExtFuncCall >(lib,"SDL_SetGamepadSensorEnabled","SDL_SetGamepadSensorEnabled")
		->args({"gamepad","type","enabled"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1479:34
	makeExtern< bool (*)(struct SDL_Gamepad *,enum SDL_SensorType) , SDL_GamepadSensorEnabled , SimNode_ExtFuncCall >(lib,"SDL_GamepadSensorEnabled","SDL_GamepadSensorEnabled")
		->args({"gamepad","type"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1492:35
	makeExtern< float (*)(struct SDL_Gamepad *,enum SDL_SensorType) , SDL_GetGamepadSensorDataRate , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadSensorDataRate","SDL_GetGamepadSensorDataRate")
		->args({"gamepad","type"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1511:34
	makeExtern< bool (*)(struct SDL_Gamepad *,enum SDL_SensorType,float *,int) , SDL_GetGamepadSensorData , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadSensorData","SDL_GetGamepadSensorData")
		->args({"gamepad","type","data","num_values"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1535:34
	makeExtern< bool (*)(struct SDL_Gamepad *,unsigned short,unsigned short,unsigned int) , SDL_RumbleGamepad , SimNode_ExtFuncCall >(lib,"SDL_RumbleGamepad","SDL_RumbleGamepad")
		->args({"gamepad","low_frequency_rumble","high_frequency_rumble","duration_ms"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1565:34
	makeExtern< bool (*)(struct SDL_Gamepad *,unsigned short,unsigned short,unsigned int) , SDL_RumbleGamepadTriggers , SimNode_ExtFuncCall >(lib,"SDL_RumbleGamepadTriggers","SDL_RumbleGamepadTriggers")
		->args({"gamepad","left_rumble","right_rumble","duration_ms"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1587:34
	makeExtern< bool (*)(struct SDL_Gamepad *,unsigned char,unsigned char,unsigned char) , SDL_SetGamepadLED , SimNode_ExtFuncCall >(lib,"SDL_SetGamepadLED","SDL_SetGamepadLED")
		->args({"gamepad","red","green","blue"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1602:34
	makeExtern< bool (*)(struct SDL_Gamepad *,const void *,int) , SDL_SendGamepadEffect , SimNode_ExtFuncCall >(lib,"SDL_SendGamepadEffect","SDL_SendGamepadEffect")
		->args({"gamepad","data","size"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1616:34
	makeExtern< void (*)(struct SDL_Gamepad *) , SDL_CloseGamepad , SimNode_ExtFuncCall >(lib,"SDL_CloseGamepad","SDL_CloseGamepad")
		->args({"gamepad"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1632:42
	makeExtern< const char * (*)(struct SDL_Gamepad *,enum SDL_GamepadButton) , SDL_GetGamepadAppleSFSymbolsNameForButton , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadAppleSFSymbolsNameForButton","SDL_GetGamepadAppleSFSymbolsNameForButton")
		->args({"gamepad","button"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gamepad.h:1647:42
	makeExtern< const char * (*)(struct SDL_Gamepad *,enum SDL_GamepadAxis) , SDL_GetGamepadAppleSFSymbolsNameForAxis , SimNode_ExtFuncCall >(lib,"SDL_GetGamepadAppleSFSymbolsNameForAxis","SDL_GetGamepadAppleSFSymbolsNameForAxis")
		->args({"gamepad","axis"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:75:34
	makeExtern< bool (*)() , SDL_HasKeyboard , SimNode_ExtFuncCall >(lib,"SDL_HasKeyboard","SDL_HasKeyboard")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:98:46
	makeExtern< unsigned int * (*)(int *) , SDL_GetKeyboards , SimNode_ExtFuncCall >(lib,"SDL_GetKeyboards","SDL_GetKeyboards")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:115:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetKeyboardNameForID , SimNode_ExtFuncCall >(lib,"SDL_GetKeyboardNameForID","SDL_GetKeyboardNameForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:126:42
	makeExtern< struct SDL_Window * (*)() , SDL_GetKeyboardFocus , SimNode_ExtFuncCall >(lib,"SDL_GetKeyboardFocus","SDL_GetKeyboardFocus")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:159:42
	makeExtern< const bool * (*)(int *) , SDL_GetKeyboardState , SimNode_ExtFuncCall >(lib,"SDL_GetKeyboardState","SDL_GetKeyboardState")
		->args({"numkeys"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:172:34
	makeExtern< void (*)() , SDL_ResetKeyboard , SimNode_ExtFuncCall >(lib,"SDL_ResetKeyboard","SDL_ResetKeyboard")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:186:40
	makeExtern< unsigned short (*)() , SDL_GetModState , SimNode_ExtFuncCall >(lib,"SDL_GetModState","SDL_GetModState")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:207:34
	makeExtern< void (*)(unsigned short) , SDL_SetModState , SimNode_ExtFuncCall >(lib,"SDL_SetModState","SDL_SetModState")
		->args({"modstate"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:231:41
	makeExtern< unsigned int (*)(enum SDL_Scancode,unsigned short,bool) , SDL_GetKeyFromScancode , SimNode_ExtFuncCall >(lib,"SDL_GetKeyFromScancode","SDL_GetKeyFromScancode")
		->args({"scancode","modstate","key_event"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:252:42
	makeExtern< enum SDL_Scancode (*)(unsigned int,unsigned short *) , SDL_GetScancodeFromKey , SimNode_ExtFuncCall >(lib,"SDL_GetScancodeFromKey","SDL_GetScancodeFromKey")
		->args({"key","modstate"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:270:34
	makeExtern< bool (*)(enum SDL_Scancode,const char *) , SDL_SetScancodeName , SimNode_ExtFuncCall >(lib,"SDL_SetScancodeName","SDL_SetScancodeName")
		->args({"scancode","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:296:42
	makeExtern< const char * (*)(enum SDL_Scancode) , SDL_GetScancodeName , SimNode_ExtFuncCall >(lib,"SDL_GetScancodeName","SDL_GetScancodeName")
		->args({"scancode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:313:42
	makeExtern< enum SDL_Scancode (*)(const char *) , SDL_GetScancodeFromName , SimNode_ExtFuncCall >(lib,"SDL_GetScancodeFromName","SDL_GetScancodeFromName")
		->args({"name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:333:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetKeyName , SimNode_ExtFuncCall >(lib,"SDL_GetKeyName","SDL_GetKeyName")
		->args({"key"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:350:41
	makeExtern< unsigned int (*)(const char *) , SDL_GetKeyFromName , SimNode_ExtFuncCall >(lib,"SDL_GetKeyFromName","SDL_GetKeyFromName")
		->args({"name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:378:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_StartTextInput , SimNode_ExtFuncCall >(lib,"SDL_StartTextInput","SDL_StartTextInput")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:473:34
	makeExtern< bool (*)(struct SDL_Window *,unsigned int) , SDL_StartTextInputWithProperties , SimNode_ExtFuncCall >(lib,"SDL_StartTextInputWithProperties","SDL_StartTextInputWithProperties")
		->args({"window","props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:493:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_TextInputActive , SimNode_ExtFuncCall >(lib,"SDL_TextInputActive","SDL_TextInputActive")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:511:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_StopTextInput , SimNode_ExtFuncCall >(lib,"SDL_StopTextInput","SDL_StopTextInput")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:527:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_ClearComposition , SimNode_ExtFuncCall >(lib,"SDL_ClearComposition","SDL_ClearComposition")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:550:34
	makeExtern< bool (*)(struct SDL_Window *,const struct SDL_Rect *,int) , SDL_SetTextInputArea , SimNode_ExtFuncCall >(lib,"SDL_SetTextInputArea","SDL_SetTextInputArea")
		->args({"window","rect","cursor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:571:34
	makeExtern< bool (*)(struct SDL_Window *,struct SDL_Rect *,int *) , SDL_GetTextInputArea , SimNode_ExtFuncCall >(lib,"SDL_GetTextInputArea","SDL_GetTextInputArea")
		->args({"window","rect","cursor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:586:34
	makeExtern< bool (*)() , SDL_HasScreenKeyboardSupport , SimNode_ExtFuncCall >(lib,"SDL_HasScreenKeyboardSupport","SDL_HasScreenKeyboardSupport")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_keyboard.h:600:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_ScreenKeyboardShown , SimNode_ExtFuncCall >(lib,"SDL_ScreenKeyboardShown","SDL_ScreenKeyboardShown")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:226:34
	makeExtern< bool (*)() , SDL_HasMouse , SimNode_ExtFuncCall >(lib,"SDL_HasMouse","SDL_HasMouse")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:249:43
	makeExtern< unsigned int * (*)(int *) , SDL_GetMice , SimNode_ExtFuncCall >(lib,"SDL_GetMice","SDL_GetMice")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:266:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetMouseNameForID , SimNode_ExtFuncCall >(lib,"SDL_GetMouseNameForID","SDL_GetMouseNameForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:277:42
	makeExtern< struct SDL_Window * (*)() , SDL_GetMouseFocus , SimNode_ExtFuncCall >(lib,"SDL_GetMouseFocus","SDL_GetMouseFocus")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:310:50
	makeExtern< unsigned int (*)(float *,float *) , SDL_GetMouseState , SimNode_ExtFuncCall >(lib,"SDL_GetMouseState","SDL_GetMouseState")
		->args({"x","y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:347:50
	makeExtern< unsigned int (*)(float *,float *) , SDL_GetGlobalMouseState , SimNode_ExtFuncCall >(lib,"SDL_GetGlobalMouseState","SDL_GetGlobalMouseState")
		->args({"x","y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:382:50
	makeExtern< unsigned int (*)(float *,float *) , SDL_GetRelativeMouseState , SimNode_ExtFuncCall >(lib,"SDL_GetRelativeMouseState","SDL_GetRelativeMouseState")
		->args({"x","y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:405:34
	makeExtern< void (*)(struct SDL_Window *,float,float) , SDL_WarpMouseInWindow , SimNode_ExtFuncCall >(lib,"SDL_WarpMouseInWindow","SDL_WarpMouseInWindow")
		->args({"window","x","y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:430:34
	makeExtern< bool (*)(float,float) , SDL_WarpMouseGlobal , SimNode_ExtFuncCall >(lib,"SDL_WarpMouseGlobal","SDL_WarpMouseGlobal")
		->args({"x","y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:476:34
	makeExtern< bool (*)(struct SDL_Window *,bool) , SDL_SetWindowRelativeMouseMode , SimNode_ExtFuncCall >(lib,"SDL_SetWindowRelativeMouseMode","SDL_SetWindowRelativeMouseMode")
		->args({"window","enabled"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:490:34
	makeExtern< bool (*)(struct SDL_Window *) , SDL_GetWindowRelativeMouseMode , SimNode_ExtFuncCall >(lib,"SDL_GetWindowRelativeMouseMode","SDL_GetWindowRelativeMouseMode")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:538:34
	makeExtern< bool (*)(bool) , SDL_CaptureMouse , SimNode_ExtFuncCall >(lib,"SDL_CaptureMouse","SDL_CaptureMouse")
		->args({"enabled"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:585:42
	makeExtern< struct SDL_Cursor * (*)(const unsigned char *,const unsigned char *,int,int,int,int) , SDL_CreateCursor , SimNode_ExtFuncCall >(lib,"SDL_CreateCursor","SDL_CreateCursor")
		->args({"data","mask","w","h","hot_x","hot_y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:622:42
	makeExtern< struct SDL_Cursor * (*)(struct SDL_Surface *,int,int) , SDL_CreateColorCursor , SimNode_ExtFuncCall >(lib,"SDL_CreateColorCursor","SDL_CreateColorCursor")
		->args({"surface","hot_x","hot_y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:690:42
	makeExtern< struct SDL_Cursor * (*)(enum SDL_SystemCursor) , SDL_CreateSystemCursor , SimNode_ExtFuncCall >(lib,"SDL_CreateSystemCursor","SDL_CreateSystemCursor")
		->args({"id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:710:34
	makeExtern< bool (*)(struct SDL_Cursor *) , SDL_SetCursor , SimNode_ExtFuncCall >(lib,"SDL_SetCursor","SDL_SetCursor")
		->args({"cursor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:726:42
	makeExtern< struct SDL_Cursor * (*)() , SDL_GetCursor , SimNode_ExtFuncCall >(lib,"SDL_GetCursor","SDL_GetCursor")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:741:42
	makeExtern< struct SDL_Cursor * (*)() , SDL_GetDefaultCursor , SimNode_ExtFuncCall >(lib,"SDL_GetDefaultCursor","SDL_GetDefaultCursor")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:760:34
	makeExtern< void (*)(struct SDL_Cursor *) , SDL_DestroyCursor , SimNode_ExtFuncCall >(lib,"SDL_DestroyCursor","SDL_DestroyCursor")
		->args({"cursor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:775:34
	makeExtern< bool (*)() , SDL_ShowCursor , SimNode_ExtFuncCall >(lib,"SDL_ShowCursor","SDL_ShowCursor")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:790:34
	makeExtern< bool (*)() , SDL_HideCursor , SimNode_ExtFuncCall >(lib,"SDL_HideCursor","SDL_HideCursor")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_mouse.h:805:34
	makeExtern< bool (*)() , SDL_CursorVisible , SimNode_ExtFuncCall >(lib,"SDL_CursorVisible","SDL_CursorVisible")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_touch.h:140:43
	makeExtern< SDL_TouchID * (*)(int *) , SDL_GetTouchDevices , SimNode_ExtFuncCall >(lib,"SDL_GetTouchDevices","SDL_GetTouchDevices")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_touch.h:151:42
	makeExtern< const char * (*)(SDL_TouchID) , SDL_GetTouchDeviceName , SimNode_ExtFuncCall >(lib,"SDL_GetTouchDeviceName","SDL_GetTouchDeviceName")
		->args({"touchID"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_touch.h:161:49
	makeExtern< enum SDL_TouchDeviceType (*)(SDL_TouchID) , SDL_GetTouchDeviceType , SimNode_ExtFuncCall >(lib,"SDL_GetTouchDeviceType","SDL_GetTouchDeviceType")
		->args({"touchID"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_touch.h:176:43
	makeExtern< struct SDL_Finger ** (*)(SDL_TouchID,int *) , SDL_GetTouchFingers , SimNode_ExtFuncCall >(lib,"SDL_GetTouchFingers","SDL_GetTouchFingers")
		->args({"touchID","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1101:34
	makeExtern< void (*)() , SDL_PumpEvents , SimNode_ExtFuncCall >(lib,"SDL_PumpEvents","SDL_PumpEvents")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1159:33
	makeExtern< int (*)(union SDL_Event *,int,enum SDL_EventAction,unsigned int,unsigned int) , SDL_PeepEvents , SimNode_ExtFuncCall >(lib,"SDL_PeepEvents","SDL_PeepEvents")
		->args({"events","numevents","action","minType","maxType"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1178:34
	makeExtern< bool (*)(unsigned int) , SDL_HasEvent , SimNode_ExtFuncCall >(lib,"SDL_HasEvent","SDL_HasEvent")
		->args({"type"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1199:34
	makeExtern< bool (*)(unsigned int,unsigned int) , SDL_HasEvents , SimNode_ExtFuncCall >(lib,"SDL_HasEvents","SDL_HasEvents")
		->args({"minType","maxType"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1227:34
	makeExtern< void (*)(unsigned int) , SDL_FlushEvent , SimNode_ExtFuncCall >(lib,"SDL_FlushEvent","SDL_FlushEvent")
		->args({"type"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1254:34
	makeExtern< void (*)(unsigned int,unsigned int) , SDL_FlushEvents , SimNode_ExtFuncCall >(lib,"SDL_FlushEvents","SDL_FlushEvents")
		->args({"minType","maxType"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1305:34
	makeExtern< bool (*)(union SDL_Event *) , SDL_PollEvent , SimNode_ExtFuncCall >(lib,"SDL_PollEvent","SDL_PollEvent")
		->args({"event"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1329:34
	makeExtern< bool (*)(union SDL_Event *) , SDL_WaitEvent , SimNode_ExtFuncCall >(lib,"SDL_WaitEvent","SDL_WaitEvent")
		->args({"event"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1359:34
	makeExtern< bool (*)(union SDL_Event *,int) , SDL_WaitEventTimeout , SimNode_ExtFuncCall >(lib,"SDL_WaitEventTimeout","SDL_WaitEventTimeout")
		->args({"event","timeoutMS"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1393:34
	makeExtern< bool (*)(union SDL_Event *) , SDL_PushEvent , SimNode_ExtFuncCall >(lib,"SDL_PushEvent","SDL_PushEvent")
		->args({"event"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_SetEventFilter), SDL_SetEventFilter, SimNode_ExtFuncCall>(lib,"SDL_SetEventFilter","SDL_SetEventFilterAddress")->args({"filter","userdata"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_GetEventFilter), SDL_GetEventFilter, SimNode_ExtFuncCall>(lib,"SDL_GetEventFilter","SDL_GetEventFilterAddress")->args({"filter","userdata"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_AddEventWatch), SDL_AddEventWatch, SimNode_ExtFuncCall>(lib,"SDL_AddEventWatch","SDL_AddEventWatchAddress")->args({"filter","userdata"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_RemoveEventWatch), SDL_RemoveEventWatch, SimNode_ExtFuncCall>(lib,"SDL_RemoveEventWatch","SDL_RemoveEventWatchAddress")->args({"filter","userdata"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_FilterEvents), SDL_FilterEvents, SimNode_ExtFuncCall>(lib,"SDL_FilterEvents","SDL_FilterEventsAddress")->args({"filter","userdata"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1560:34
	makeExtern< void (*)(unsigned int,bool) , SDL_SetEventEnabled , SimNode_ExtFuncCall >(lib,"SDL_SetEventEnabled","SDL_SetEventEnabled")
		->args({"type","enabled"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1574:34
	makeExtern< bool (*)(unsigned int) , SDL_EventEnabled , SimNode_ExtFuncCall >(lib,"SDL_EventEnabled","SDL_EventEnabled")
		->args({"type"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1590:36
	makeExtern< unsigned int (*)(int) , SDL_RegisterEvents , SimNode_ExtFuncCall >(lib,"SDL_RegisterEvents","SDL_RegisterEvents")
		->args({"numevents"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_events.h:1606:42
	makeExtern< struct SDL_Window * (*)(const union SDL_Event *) , SDL_GetWindowFromEvent , SimNode_ExtFuncCall >(lib,"SDL_GetWindowFromEvent","SDL_GetWindowFromEvent")
		->args({"event"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:101:42
	makeExtern< const char * (*)() , SDL_GetBasePath , SimNode_ExtFuncCall >(lib,"SDL_GetBasePath","SDL_GetBasePath")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:164:36
	makeExtern< char * (*)(const char *,const char *) , SDL_GetPrefPath , SimNode_ExtFuncCall >(lib,"SDL_GetPrefPath","SDL_GetPrefPath")
		->args({"org","app"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:236:42
	makeExtern< const char * (*)(enum SDL_Folder) , SDL_GetUserFolder , SimNode_ExtFuncCall >(lib,"SDL_GetUserFolder","SDL_GetUserFolder")
		->args({"folder"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:304:34
	makeExtern< bool (*)(const char *) , SDL_CreateDirectory , SimNode_ExtFuncCall >(lib,"SDL_CreateDirectory","SDL_CreateDirectory")
		->args({"path"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_EnumerateDirectory), SDL_EnumerateDirectory, SimNode_ExtFuncCall>(lib,"SDL_EnumerateDirectory","SDL_EnumerateDirectoryAddress")->args({"path","callback","userdata"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:385:34
	makeExtern< bool (*)(const char *) , SDL_RemovePath , SimNode_ExtFuncCall >(lib,"SDL_RemovePath","SDL_RemovePath")
		->args({"path"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:410:34
	makeExtern< bool (*)(const char *,const char *) , SDL_RenamePath , SimNode_ExtFuncCall >(lib,"SDL_RenamePath","SDL_RenamePath")
		->args({"oldpath","newpath"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:454:34
	makeExtern< bool (*)(const char *,const char *) , SDL_CopyFile , SimNode_ExtFuncCall >(lib,"SDL_CopyFile","SDL_CopyFile")
		->args({"oldpath","newpath"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:473:34
	makeExtern< bool (*)(const char *,struct SDL_PathInfo *) , SDL_GetPathInfo , SimNode_ExtFuncCall >(lib,"SDL_GetPathInfo","SDL_GetPathInfo")
		->args({"path","info"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:506:37
	makeExtern< char ** (*)(const char *,const char *,unsigned int,int *) , SDL_GlobDirectory , SimNode_ExtFuncCall >(lib,"SDL_GlobDirectory","SDL_GlobDirectory")
		->args({"path","pattern","flags","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_filesystem.h:529:36
	makeExtern< char * (*)() , SDL_GetCurrentDirectory , SimNode_ExtFuncCall >(lib,"SDL_GetCurrentDirectory","SDL_GetCurrentDirectory")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2213:34
	makeExtern< bool (*)(unsigned int,const char *) , SDL_GPUSupportsShaderFormats , SimNode_ExtFuncCall >(lib,"SDL_GPUSupportsShaderFormats","SDL_GPUSupportsShaderFormats")
		->args({"format_flags","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2227:34
	makeExtern< bool (*)(unsigned int) , SDL_GPUSupportsProperties , SimNode_ExtFuncCall >(lib,"SDL_GPUSupportsProperties","SDL_GPUSupportsProperties")
		->args({"props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2256:45
	makeExtern< struct SDL_GPUDevice * (*)(unsigned int,bool,const char *) , SDL_CreateGPUDevice , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUDevice","SDL_CreateGPUDevice")
		->args({"format_flags","debug_mode","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2373:45
	makeExtern< struct SDL_GPUDevice * (*)(unsigned int) , SDL_CreateGPUDeviceWithProperties , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUDeviceWithProperties","SDL_CreateGPUDeviceWithProperties")
		->args({"props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2435:34
	makeExtern< void (*)(struct SDL_GPUDevice *) , SDL_DestroyGPUDevice , SimNode_ExtFuncCall >(lib,"SDL_DestroyGPUDevice","SDL_DestroyGPUDevice")
		->args({"device"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2446:33
	makeExtern< int (*)() , SDL_GetNumGPUDrivers , SimNode_ExtFuncCall >(lib,"SDL_GetNumGPUDrivers","SDL_GetNumGPUDrivers")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2465:42
	makeExtern< const char * (*)(int) , SDL_GetGPUDriver , SimNode_ExtFuncCall >(lib,"SDL_GetGPUDriver","SDL_GetGPUDriver")
		->args({"index"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2475:42
	makeExtern< const char * (*)(struct SDL_GPUDevice *) , SDL_GetGPUDeviceDriver , SimNode_ExtFuncCall >(lib,"SDL_GetGPUDeviceDriver","SDL_GetGPUDeviceDriver")
		->args({"device"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2486:49
	makeExtern< unsigned int (*)(struct SDL_GPUDevice *) , SDL_GetGPUShaderFormats , SimNode_ExtFuncCall >(lib,"SDL_GetGPUShaderFormats","SDL_GetGPUShaderFormats")
		->args({"device"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2590:46
	makeExtern< unsigned int (*)(struct SDL_GPUDevice *) , SDL_GetGPUDeviceProperties , SimNode_ExtFuncCall >(lib,"SDL_GetGPUDeviceProperties","SDL_GetGPUDeviceProperties")
		->args({"device"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2645:54
	makeExtern< struct SDL_GPUComputePipeline * (*)(struct SDL_GPUDevice *,const struct SDL_GPUComputePipelineCreateInfo *) , SDL_CreateGPUComputePipeline , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUComputePipeline","SDL_CreateGPUComputePipeline")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2672:55
	makeExtern< struct SDL_GPUGraphicsPipeline * (*)(struct SDL_GPUDevice *,const struct SDL_GPUGraphicsPipelineCreateInfo *) , SDL_CreateGPUGraphicsPipeline , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUGraphicsPipeline","SDL_CreateGPUGraphicsPipeline")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2699:46
	makeExtern< struct SDL_GPUSampler * (*)(struct SDL_GPUDevice *,const struct SDL_GPUSamplerCreateInfo *) , SDL_CreateGPUSampler , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUSampler","SDL_CreateGPUSampler")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2778:45
	makeExtern< struct SDL_GPUShader * (*)(struct SDL_GPUDevice *,const struct SDL_GPUShaderCreateInfo *) , SDL_CreateGPUShader , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUShader","SDL_CreateGPUShader")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2842:46
	makeExtern< struct SDL_GPUTexture * (*)(struct SDL_GPUDevice *,const struct SDL_GPUTextureCreateInfo *) , SDL_CreateGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUTexture","SDL_CreateGPUTexture")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2898:45
	makeExtern< struct SDL_GPUBuffer * (*)(struct SDL_GPUDevice *,const struct SDL_GPUBufferCreateInfo *) , SDL_CreateGPUBuffer , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUBuffer","SDL_CreateGPUBuffer")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2931:53
	makeExtern< struct SDL_GPUTransferBuffer * (*)(struct SDL_GPUDevice *,const struct SDL_GPUTransferBufferCreateInfo *) , SDL_CreateGPUTransferBuffer , SimNode_ExtFuncCall >(lib,"SDL_CreateGPUTransferBuffer","SDL_CreateGPUTransferBuffer")
		->args({"device","createinfo"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2956:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUBuffer *,const char *) , SDL_SetGPUBufferName , SimNode_ExtFuncCall >(lib,"SDL_SetGPUBufferName","SDL_SetGPUBufferName")
		->args({"device","buffer","text"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:2979:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUTexture *,const char *) , SDL_SetGPUTextureName , SimNode_ExtFuncCall >(lib,"SDL_SetGPUTextureName","SDL_SetGPUTextureName")
		->args({"device","texture","text"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3000:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,const char *) , SDL_InsertGPUDebugLabel , SimNode_ExtFuncCall >(lib,"SDL_InsertGPUDebugLabel","SDL_InsertGPUDebugLabel")
		->args({"command_buffer","text"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3030:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,const char *) , SDL_PushGPUDebugGroup , SimNode_ExtFuncCall >(lib,"SDL_PushGPUDebugGroup","SDL_PushGPUDebugGroup")
		->args({"command_buffer","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3048:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *) , SDL_PopGPUDebugGroup , SimNode_ExtFuncCall >(lib,"SDL_PopGPUDebugGroup","SDL_PopGPUDebugGroup")
		->args({"command_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3063:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUTexture *) , SDL_ReleaseGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUTexture","SDL_ReleaseGPUTexture")
		->args({"device","texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3077:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUSampler *) , SDL_ReleaseGPUSampler , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUSampler","SDL_ReleaseGPUSampler")
		->args({"device","sampler"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3091:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUBuffer *) , SDL_ReleaseGPUBuffer , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUBuffer","SDL_ReleaseGPUBuffer")
		->args({"device","buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3105:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUTransferBuffer *) , SDL_ReleaseGPUTransferBuffer , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUTransferBuffer","SDL_ReleaseGPUTransferBuffer")
		->args({"device","transfer_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3119:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUComputePipeline *) , SDL_ReleaseGPUComputePipeline , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUComputePipeline","SDL_ReleaseGPUComputePipeline")
		->args({"device","compute_pipeline"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3133:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUShader *) , SDL_ReleaseGPUShader , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUShader","SDL_ReleaseGPUShader")
		->args({"device","shader"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3147:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUGraphicsPipeline *) , SDL_ReleaseGPUGraphicsPipeline , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUGraphicsPipeline","SDL_ReleaseGPUGraphicsPipeline")
		->args({"device","graphics_pipeline"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3175:52
	makeExtern< struct SDL_GPUCommandBuffer * (*)(struct SDL_GPUDevice *) , SDL_AcquireGPUCommandBuffer , SimNode_ExtFuncCall >(lib,"SDL_AcquireGPUCommandBuffer","SDL_AcquireGPUCommandBuffer")
		->args({"device"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3199:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,unsigned int,const void *,unsigned int) , SDL_PushGPUVertexUniformData , SimNode_ExtFuncCall >(lib,"SDL_PushGPUVertexUniformData","SDL_PushGPUVertexUniformData")
		->args({"command_buffer","slot_index","data","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3221:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,unsigned int,const void *,unsigned int) , SDL_PushGPUFragmentUniformData , SimNode_ExtFuncCall >(lib,"SDL_PushGPUFragmentUniformData","SDL_PushGPUFragmentUniformData")
		->args({"command_buffer","slot_index","data","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3243:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,unsigned int,const void *,unsigned int) , SDL_PushGPUComputeUniformData , SimNode_ExtFuncCall >(lib,"SDL_PushGPUComputeUniformData","SDL_PushGPUComputeUniformData")
		->args({"command_buffer","slot_index","data","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3284:49
	makeExtern< struct SDL_GPURenderPass * (*)(struct SDL_GPUCommandBuffer *,const struct SDL_GPUColorTargetInfo *,unsigned int,const struct SDL_GPUDepthStencilTargetInfo *) , SDL_BeginGPURenderPass , SimNode_ExtFuncCall >(lib,"SDL_BeginGPURenderPass","SDL_BeginGPURenderPass")
		->args({"command_buffer","color_target_infos","num_color_targets","depth_stencil_target_info"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3300:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,struct SDL_GPUGraphicsPipeline *) , SDL_BindGPUGraphicsPipeline , SimNode_ExtFuncCall >(lib,"SDL_BindGPUGraphicsPipeline","SDL_BindGPUGraphicsPipeline")
		->args({"render_pass","graphics_pipeline"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3312:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,const struct SDL_GPUViewport *) , SDL_SetGPUViewport , SimNode_ExtFuncCall >(lib,"SDL_SetGPUViewport","SDL_SetGPUViewport")
		->args({"render_pass","viewport"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3324:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,const struct SDL_Rect *) , SDL_SetGPUScissor , SimNode_ExtFuncCall >(lib,"SDL_SetGPUScissor","SDL_SetGPUScissor")
		->args({"render_pass","scissor"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3339:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,struct SDL_FColor) , SDL_SetGPUBlendConstants , SimNode_ExtFuncCall >(lib,"SDL_SetGPUBlendConstants","SDL_SetGPUBlendConstants")
		->args({"render_pass","blend_constants"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3351:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned char) , SDL_SetGPUStencilReference , SimNode_ExtFuncCall >(lib,"SDL_SetGPUStencilReference","SDL_SetGPUStencilReference")
		->args({"render_pass","reference"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3367:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,const struct SDL_GPUBufferBinding *,unsigned int) , SDL_BindGPUVertexBuffers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUVertexBuffers","SDL_BindGPUVertexBuffers")
		->args({"render_pass","first_slot","bindings","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3384:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,const struct SDL_GPUBufferBinding *,enum SDL_GPUIndexElementSize) , SDL_BindGPUIndexBuffer , SimNode_ExtFuncCall >(lib,"SDL_BindGPUIndexBuffer","SDL_BindGPUIndexBuffer")
		->args({"render_pass","binding","index_element_size"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3408:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,const struct SDL_GPUTextureSamplerBinding *,unsigned int) , SDL_BindGPUVertexSamplers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUVertexSamplers","SDL_BindGPUVertexSamplers")
		->args({"render_pass","first_slot","texture_sampler_bindings","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3432:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,struct SDL_GPUTexture *const *,unsigned int) , SDL_BindGPUVertexStorageTextures , SimNode_ExtFuncCall >(lib,"SDL_BindGPUVertexStorageTextures","SDL_BindGPUVertexStorageTextures")
		->args({"render_pass","first_slot","storage_textures","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3456:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,struct SDL_GPUBuffer *const *,unsigned int) , SDL_BindGPUVertexStorageBuffers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUVertexStorageBuffers","SDL_BindGPUVertexStorageBuffers")
		->args({"render_pass","first_slot","storage_buffers","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3481:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,const struct SDL_GPUTextureSamplerBinding *,unsigned int) , SDL_BindGPUFragmentSamplers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUFragmentSamplers","SDL_BindGPUFragmentSamplers")
		->args({"render_pass","first_slot","texture_sampler_bindings","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3505:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,struct SDL_GPUTexture *const *,unsigned int) , SDL_BindGPUFragmentStorageTextures , SimNode_ExtFuncCall >(lib,"SDL_BindGPUFragmentStorageTextures","SDL_BindGPUFragmentStorageTextures")
		->args({"render_pass","first_slot","storage_textures","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3529:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,struct SDL_GPUBuffer *const *,unsigned int) , SDL_BindGPUFragmentStorageBuffers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUFragmentStorageBuffers","SDL_BindGPUFragmentStorageBuffers")
		->args({"render_pass","first_slot","storage_buffers","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3560:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,unsigned int,unsigned int,int,unsigned int) , SDL_DrawGPUIndexedPrimitives , SimNode_ExtFuncCall >(lib,"SDL_DrawGPUIndexedPrimitives","SDL_DrawGPUIndexedPrimitives")
		->args({"render_pass","num_indices","num_instances","first_index","vertex_offset","first_instance"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3588:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,unsigned int,unsigned int,unsigned int,unsigned int) , SDL_DrawGPUPrimitives , SimNode_ExtFuncCall >(lib,"SDL_DrawGPUPrimitives","SDL_DrawGPUPrimitives")
		->args({"render_pass","num_vertices","num_instances","first_vertex","first_instance"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3611:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,struct SDL_GPUBuffer *,unsigned int,unsigned int) , SDL_DrawGPUPrimitivesIndirect , SimNode_ExtFuncCall >(lib,"SDL_DrawGPUPrimitivesIndirect","SDL_DrawGPUPrimitivesIndirect")
		->args({"render_pass","buffer","offset","draw_count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3633:34
	makeExtern< void (*)(struct SDL_GPURenderPass *,struct SDL_GPUBuffer *,unsigned int,unsigned int) , SDL_DrawGPUIndexedPrimitivesIndirect , SimNode_ExtFuncCall >(lib,"SDL_DrawGPUIndexedPrimitivesIndirect","SDL_DrawGPUIndexedPrimitivesIndirect")
		->args({"render_pass","buffer","offset","draw_count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3649:34
	makeExtern< void (*)(struct SDL_GPURenderPass *) , SDL_EndGPURenderPass , SimNode_ExtFuncCall >(lib,"SDL_EndGPURenderPass","SDL_EndGPURenderPass")
		->args({"render_pass"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3691:50
	makeExtern< struct SDL_GPUComputePass * (*)(struct SDL_GPUCommandBuffer *,const struct SDL_GPUStorageTextureReadWriteBinding *,unsigned int,const struct SDL_GPUStorageBufferReadWriteBinding *,unsigned int) , SDL_BeginGPUComputePass , SimNode_ExtFuncCall >(lib,"SDL_BeginGPUComputePass","SDL_BeginGPUComputePass")
		->args({"command_buffer","storage_texture_bindings","num_storage_texture_bindings","storage_buffer_bindings","num_storage_buffer_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3706:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,struct SDL_GPUComputePipeline *) , SDL_BindGPUComputePipeline , SimNode_ExtFuncCall >(lib,"SDL_BindGPUComputePipeline","SDL_BindGPUComputePipeline")
		->args({"compute_pass","compute_pipeline"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3729:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,unsigned int,const struct SDL_GPUTextureSamplerBinding *,unsigned int) , SDL_BindGPUComputeSamplers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUComputeSamplers","SDL_BindGPUComputeSamplers")
		->args({"compute_pass","first_slot","texture_sampler_bindings","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3753:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,unsigned int,struct SDL_GPUTexture *const *,unsigned int) , SDL_BindGPUComputeStorageTextures , SimNode_ExtFuncCall >(lib,"SDL_BindGPUComputeStorageTextures","SDL_BindGPUComputeStorageTextures")
		->args({"compute_pass","first_slot","storage_textures","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3777:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,unsigned int,struct SDL_GPUBuffer *const *,unsigned int) , SDL_BindGPUComputeStorageBuffers , SimNode_ExtFuncCall >(lib,"SDL_BindGPUComputeStorageBuffers","SDL_BindGPUComputeStorageBuffers")
		->args({"compute_pass","first_slot","storage_buffers","num_bindings"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3803:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,unsigned int,unsigned int,unsigned int) , SDL_DispatchGPUCompute , SimNode_ExtFuncCall >(lib,"SDL_DispatchGPUCompute","SDL_DispatchGPUCompute")
		->args({"compute_pass","groupcount_x","groupcount_y","groupcount_z"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3827:34
	makeExtern< void (*)(struct SDL_GPUComputePass *,struct SDL_GPUBuffer *,unsigned int) , SDL_DispatchGPUComputeIndirect , SimNode_ExtFuncCall >(lib,"SDL_DispatchGPUComputeIndirect","SDL_DispatchGPUComputeIndirect")
		->args({"compute_pass","buffer","offset"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3842:34
	makeExtern< void (*)(struct SDL_GPUComputePass *) , SDL_EndGPUComputePass , SimNode_ExtFuncCall >(lib,"SDL_EndGPUComputePass","SDL_EndGPUComputePass")
		->args({"compute_pass"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3862:36
	makeExtern< void * (*)(struct SDL_GPUDevice *,struct SDL_GPUTransferBuffer *,bool) , SDL_MapGPUTransferBuffer , SimNode_ExtFuncCall >(lib,"SDL_MapGPUTransferBuffer","SDL_MapGPUTransferBuffer")
		->args({"device","transfer_buffer","cycle"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3875:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUTransferBuffer *) , SDL_UnmapGPUTransferBuffer , SimNode_ExtFuncCall >(lib,"SDL_UnmapGPUTransferBuffer","SDL_UnmapGPUTransferBuffer")
		->args({"device","transfer_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3895:47
	makeExtern< struct SDL_GPUCopyPass * (*)(struct SDL_GPUCommandBuffer *) , SDL_BeginGPUCopyPass , SimNode_ExtFuncCall >(lib,"SDL_BeginGPUCopyPass","SDL_BeginGPUCopyPass")
		->args({"command_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3915:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUTextureTransferInfo *,const struct SDL_GPUTextureRegion *,bool) , SDL_UploadToGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_UploadToGPUTexture","SDL_UploadToGPUTexture")
		->args({"copy_pass","source","destination","cycle"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3935:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUTransferBufferLocation *,const struct SDL_GPUBufferRegion *,bool) , SDL_UploadToGPUBuffer , SimNode_ExtFuncCall >(lib,"SDL_UploadToGPUBuffer","SDL_UploadToGPUBuffer")
		->args({"copy_pass","source","destination","cycle"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3962:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUTextureLocation *,const struct SDL_GPUTextureLocation *,unsigned int,unsigned int,unsigned int,bool) , SDL_CopyGPUTextureToTexture , SimNode_ExtFuncCall >(lib,"SDL_CopyGPUTextureToTexture","SDL_CopyGPUTextureToTexture")
		->args({"copy_pass","source","destination","w","h","d","cycle"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:3986:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUBufferLocation *,const struct SDL_GPUBufferLocation *,unsigned int,bool) , SDL_CopyGPUBufferToBuffer , SimNode_ExtFuncCall >(lib,"SDL_CopyGPUBufferToBuffer","SDL_CopyGPUBufferToBuffer")
		->args({"copy_pass","source","destination","size","cycle"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4006:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUTextureRegion *,const struct SDL_GPUTextureTransferInfo *) , SDL_DownloadFromGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_DownloadFromGPUTexture","SDL_DownloadFromGPUTexture")
		->args({"copy_pass","source","destination"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4023:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *,const struct SDL_GPUBufferRegion *,const struct SDL_GPUTransferBufferLocation *) , SDL_DownloadFromGPUBuffer , SimNode_ExtFuncCall >(lib,"SDL_DownloadFromGPUBuffer","SDL_DownloadFromGPUBuffer")
		->args({"copy_pass","source","destination"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4035:34
	makeExtern< void (*)(struct SDL_GPUCopyPass *) , SDL_EndGPUCopyPass , SimNode_ExtFuncCall >(lib,"SDL_EndGPUCopyPass","SDL_EndGPUCopyPass")
		->args({"copy_pass"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4048:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,struct SDL_GPUTexture *) , SDL_GenerateMipmapsForGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_GenerateMipmapsForGPUTexture","SDL_GenerateMipmapsForGPUTexture")
		->args({"command_buffer","texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4062:34
	makeExtern< void (*)(struct SDL_GPUCommandBuffer *,const struct SDL_GPUBlitInfo *) , SDL_BlitGPUTexture , SimNode_ExtFuncCall >(lib,"SDL_BlitGPUTexture","SDL_BlitGPUTexture")
		->args({"command_buffer","info"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4082:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_Window *,enum SDL_GPUSwapchainComposition) , SDL_WindowSupportsGPUSwapchainComposition , SimNode_ExtFuncCall >(lib,"SDL_WindowSupportsGPUSwapchainComposition","SDL_WindowSupportsGPUSwapchainComposition")
		->args({"device","window","swapchain_composition"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4101:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_Window *,enum SDL_GPUPresentMode) , SDL_WindowSupportsGPUPresentMode , SimNode_ExtFuncCall >(lib,"SDL_WindowSupportsGPUPresentMode","SDL_WindowSupportsGPUPresentMode")
		->args({"device","window","present_mode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4133:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_Window *) , SDL_ClaimWindowForGPUDevice , SimNode_ExtFuncCall >(lib,"SDL_ClaimWindowForGPUDevice","SDL_ClaimWindowForGPUDevice")
		->args({"device","window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4147:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_Window *) , SDL_ReleaseWindowFromGPUDevice , SimNode_ExtFuncCall >(lib,"SDL_ReleaseWindowFromGPUDevice","SDL_ReleaseWindowFromGPUDevice")
		->args({"device","window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4174:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_Window *,enum SDL_GPUSwapchainComposition,enum SDL_GPUPresentMode) , SDL_SetGPUSwapchainParameters , SimNode_ExtFuncCall >(lib,"SDL_SetGPUSwapchainParameters","SDL_SetGPUSwapchainParameters")
		->args({"device","window","swapchain_composition","present_mode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4205:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,unsigned int) , SDL_SetGPUAllowedFramesInFlight , SimNode_ExtFuncCall >(lib,"SDL_SetGPUAllowedFramesInFlight","SDL_SetGPUAllowedFramesInFlight")
		->args({"device","allowed_frames_in_flight"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4220:50
	makeExtern< enum SDL_GPUTextureFormat (*)(struct SDL_GPUDevice *,struct SDL_Window *) , SDL_GetGPUSwapchainTextureFormat , SimNode_ExtFuncCall >(lib,"SDL_GetGPUSwapchainTextureFormat","SDL_GetGPUSwapchainTextureFormat")
		->args({"device","window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4272:34
	makeExtern< bool (*)(struct SDL_GPUCommandBuffer *,struct SDL_Window *,struct SDL_GPUTexture **,unsigned int *,unsigned int *) , SDL_AcquireGPUSwapchainTexture , SimNode_ExtFuncCall >(lib,"SDL_AcquireGPUSwapchainTexture","SDL_AcquireGPUSwapchainTexture")
		->args({"command_buffer","window","swapchain_texture","swapchain_texture_width","swapchain_texture_height"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4296:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_Window *) , SDL_WaitForGPUSwapchain , SimNode_ExtFuncCall >(lib,"SDL_WaitForGPUSwapchain","SDL_WaitForGPUSwapchain")
		->args({"device","window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4342:34
	makeExtern< bool (*)(struct SDL_GPUCommandBuffer *,struct SDL_Window *,struct SDL_GPUTexture **,unsigned int *,unsigned int *) , SDL_WaitAndAcquireGPUSwapchainTexture , SimNode_ExtFuncCall >(lib,"SDL_WaitAndAcquireGPUSwapchainTexture","SDL_WaitAndAcquireGPUSwapchainTexture")
		->args({"command_buffer","window","swapchain_texture","swapchain_texture_width","swapchain_texture_height"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4370:34
	makeExtern< bool (*)(struct SDL_GPUCommandBuffer *) , SDL_SubmitGPUCommandBuffer , SimNode_ExtFuncCall >(lib,"SDL_SubmitGPUCommandBuffer","SDL_SubmitGPUCommandBuffer")
		->args({"command_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4397:44
	makeExtern< struct SDL_GPUFence * (*)(struct SDL_GPUCommandBuffer *) , SDL_SubmitGPUCommandBufferAndAcquireFence , SimNode_ExtFuncCall >(lib,"SDL_SubmitGPUCommandBufferAndAcquireFence","SDL_SubmitGPUCommandBufferAndAcquireFence")
		->args({"command_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4422:34
	makeExtern< bool (*)(struct SDL_GPUCommandBuffer *) , SDL_CancelGPUCommandBuffer , SimNode_ExtFuncCall >(lib,"SDL_CancelGPUCommandBuffer","SDL_CancelGPUCommandBuffer")
		->args({"command_buffer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4436:34
	makeExtern< bool (*)(struct SDL_GPUDevice *) , SDL_WaitForGPUIdle , SimNode_ExtFuncCall >(lib,"SDL_WaitForGPUIdle","SDL_WaitForGPUIdle")
		->args({"device"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4455:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,bool,struct SDL_GPUFence *const *,unsigned int) , SDL_WaitForGPUFences , SimNode_ExtFuncCall >(lib,"SDL_WaitForGPUFences","SDL_WaitForGPUFences")
		->args({"device","wait_all","fences","num_fences"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4472:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,struct SDL_GPUFence *) , SDL_QueryGPUFence , SimNode_ExtFuncCall >(lib,"SDL_QueryGPUFence","SDL_QueryGPUFence")
		->args({"device","fence"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4488:34
	makeExtern< void (*)(struct SDL_GPUDevice *,struct SDL_GPUFence *) , SDL_ReleaseGPUFence , SimNode_ExtFuncCall >(lib,"SDL_ReleaseGPUFence","SDL_ReleaseGPUFence")
		->args({"device","fence"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4504:36
	makeExtern< unsigned int (*)(enum SDL_GPUTextureFormat) , SDL_GPUTextureFormatTexelBlockSize , SimNode_ExtFuncCall >(lib,"SDL_GPUTextureFormatTexelBlockSize","SDL_GPUTextureFormatTexelBlockSize")
		->args({"format"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4519:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,enum SDL_GPUTextureFormat,enum SDL_GPUTextureType,unsigned int) , SDL_GPUTextureSupportsFormat , SimNode_ExtFuncCall >(lib,"SDL_GPUTextureSupportsFormat","SDL_GPUTextureSupportsFormat")
		->args({"device","format","type","usage"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4535:34
	makeExtern< bool (*)(struct SDL_GPUDevice *,enum SDL_GPUTextureFormat,enum SDL_GPUSampleCount) , SDL_GPUTextureSupportsSampleCount , SimNode_ExtFuncCall >(lib,"SDL_GPUTextureSupportsSampleCount","SDL_GPUTextureSupportsSampleCount")
		->args({"device","format","sample_count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4551:36
	makeExtern< unsigned int (*)(enum SDL_GPUTextureFormat,unsigned int,unsigned int,unsigned int) , SDL_CalculateGPUTextureFormatSize , SimNode_ExtFuncCall >(lib,"SDL_CalculateGPUTextureFormatSize","SDL_CalculateGPUTextureFormatSize")
		->args({"format","width","height","depth_or_layer_count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4566:45
	makeExtern< enum SDL_PixelFormat (*)(enum SDL_GPUTextureFormat) , SDL_GetPixelFormatFromGPUTextureFormat , SimNode_ExtFuncCall >(lib,"SDL_GetPixelFormatFromGPUTextureFormat","SDL_GetPixelFormatFromGPUTextureFormat")
		->args({"format"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_gpu.h:4578:50
	makeExtern< enum SDL_GPUTextureFormat (*)(enum SDL_PixelFormat) , SDL_GetGPUTextureFormatFromPixelFormat , SimNode_ExtFuncCall >(lib,"SDL_GetGPUTextureFormatFromPixelFormat","SDL_GetGPUTextureFormatFromPixelFormat")
		->args({"format"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:975:44
	makeExtern< unsigned int * (*)(int *) , SDL_GetHaptics , SimNode_ExtFuncCall >(lib,"SDL_GetHaptics","SDL_GetHaptics")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:992:42
	makeExtern< const char * (*)(unsigned int) , SDL_GetHapticNameForID , SimNode_ExtFuncCall >(lib,"SDL_GetHapticNameForID","SDL_GetHapticNameForID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1017:42
	makeExtern< struct SDL_Haptic * (*)(unsigned int) , SDL_OpenHaptic , SimNode_ExtFuncCall >(lib,"SDL_OpenHaptic","SDL_OpenHaptic")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1029:42
	makeExtern< struct SDL_Haptic * (*)(unsigned int) , SDL_GetHapticFromID , SimNode_ExtFuncCall >(lib,"SDL_GetHapticFromID","SDL_GetHapticFromID")
		->args({"instance_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1040:42
	makeExtern< unsigned int (*)(struct SDL_Haptic *) , SDL_GetHapticID , SimNode_ExtFuncCall >(lib,"SDL_GetHapticID","SDL_GetHapticID")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1054:42
	makeExtern< const char * (*)(struct SDL_Haptic *) , SDL_GetHapticName , SimNode_ExtFuncCall >(lib,"SDL_GetHapticName","SDL_GetHapticName")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1065:34
	makeExtern< bool (*)() , SDL_IsMouseHaptic , SimNode_ExtFuncCall >(lib,"SDL_IsMouseHaptic","SDL_IsMouseHaptic")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1078:42
	makeExtern< struct SDL_Haptic * (*)() , SDL_OpenHapticFromMouse , SimNode_ExtFuncCall >(lib,"SDL_OpenHapticFromMouse","SDL_OpenHapticFromMouse")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1090:34
	makeExtern< bool (*)(struct SDL_Joystick *) , SDL_IsJoystickHaptic , SimNode_ExtFuncCall >(lib,"SDL_IsJoystickHaptic","SDL_IsJoystickHaptic")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1112:42
	makeExtern< struct SDL_Haptic * (*)(struct SDL_Joystick *) , SDL_OpenHapticFromJoystick , SimNode_ExtFuncCall >(lib,"SDL_OpenHapticFromJoystick","SDL_OpenHapticFromJoystick")
		->args({"joystick"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1123:34
	makeExtern< void (*)(struct SDL_Haptic *) , SDL_CloseHaptic , SimNode_ExtFuncCall >(lib,"SDL_CloseHaptic","SDL_CloseHaptic")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1141:33
	makeExtern< int (*)(struct SDL_Haptic *) , SDL_GetMaxHapticEffects , SimNode_ExtFuncCall >(lib,"SDL_GetMaxHapticEffects","SDL_GetMaxHapticEffects")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1157:33
	makeExtern< int (*)(struct SDL_Haptic *) , SDL_GetMaxHapticEffectsPlaying , SimNode_ExtFuncCall >(lib,"SDL_GetMaxHapticEffectsPlaying","SDL_GetMaxHapticEffectsPlaying")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1171:36
	makeExtern< unsigned int (*)(struct SDL_Haptic *) , SDL_GetHapticFeatures , SimNode_ExtFuncCall >(lib,"SDL_GetHapticFeatures","SDL_GetHapticFeatures")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1185:33
	makeExtern< int (*)(struct SDL_Haptic *) , SDL_GetNumHapticAxes , SimNode_ExtFuncCall >(lib,"SDL_GetNumHapticAxes","SDL_GetNumHapticAxes")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1199:34
	makeExtern< bool (*)(struct SDL_Haptic *,const union SDL_HapticEffect *) , SDL_HapticEffectSupported , SimNode_ExtFuncCall >(lib,"SDL_HapticEffectSupported","SDL_HapticEffectSupported")
		->args({"haptic","effect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1216:48
	makeExtern< int (*)(struct SDL_Haptic *,const union SDL_HapticEffect *) , SDL_CreateHapticEffect , SimNode_ExtFuncCall >(lib,"SDL_CreateHapticEffect","SDL_CreateHapticEffect")
		->args({"haptic","effect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1238:34
	makeExtern< bool (*)(struct SDL_Haptic *,int,const union SDL_HapticEffect *) , SDL_UpdateHapticEffect , SimNode_ExtFuncCall >(lib,"SDL_UpdateHapticEffect","SDL_UpdateHapticEffect")
		->args({"haptic","effect","data"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1262:34
	makeExtern< bool (*)(struct SDL_Haptic *,int,unsigned int) , SDL_RunHapticEffect , SimNode_ExtFuncCall >(lib,"SDL_RunHapticEffect","SDL_RunHapticEffect")
		->args({"haptic","effect","iterations"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1277:34
	makeExtern< bool (*)(struct SDL_Haptic *,int) , SDL_StopHapticEffect , SimNode_ExtFuncCall >(lib,"SDL_StopHapticEffect","SDL_StopHapticEffect")
		->args({"haptic","effect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1292:34
	makeExtern< void (*)(struct SDL_Haptic *,int) , SDL_DestroyHapticEffect , SimNode_ExtFuncCall >(lib,"SDL_DestroyHapticEffect","SDL_DestroyHapticEffect")
		->args({"haptic","effect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1308:34
	makeExtern< bool (*)(struct SDL_Haptic *,int) , SDL_GetHapticEffectStatus , SimNode_ExtFuncCall >(lib,"SDL_GetHapticEffectStatus","SDL_GetHapticEffectStatus")
		->args({"haptic","effect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1330:34
	makeExtern< bool (*)(struct SDL_Haptic *,int) , SDL_SetHapticGain , SimNode_ExtFuncCall >(lib,"SDL_SetHapticGain","SDL_SetHapticGain")
		->args({"haptic","gain"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1349:34
	makeExtern< bool (*)(struct SDL_Haptic *,int) , SDL_SetHapticAutocenter , SimNode_ExtFuncCall >(lib,"SDL_SetHapticAutocenter","SDL_SetHapticAutocenter")
		->args({"haptic","autocenter"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1368:34
	makeExtern< bool (*)(struct SDL_Haptic *) , SDL_PauseHaptic , SimNode_ExtFuncCall >(lib,"SDL_PauseHaptic","SDL_PauseHaptic")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1383:34
	makeExtern< bool (*)(struct SDL_Haptic *) , SDL_ResumeHaptic , SimNode_ExtFuncCall >(lib,"SDL_ResumeHaptic","SDL_ResumeHaptic")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1397:34
	makeExtern< bool (*)(struct SDL_Haptic *) , SDL_StopHapticEffects , SimNode_ExtFuncCall >(lib,"SDL_StopHapticEffects","SDL_StopHapticEffects")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1409:34
	makeExtern< bool (*)(struct SDL_Haptic *) , SDL_HapticRumbleSupported , SimNode_ExtFuncCall >(lib,"SDL_HapticRumbleSupported","SDL_HapticRumbleSupported")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1424:34
	makeExtern< bool (*)(struct SDL_Haptic *) , SDL_InitHapticRumble , SimNode_ExtFuncCall >(lib,"SDL_InitHapticRumble","SDL_InitHapticRumble")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1440:34
	makeExtern< bool (*)(struct SDL_Haptic *,float,unsigned int) , SDL_PlayHapticRumble , SimNode_ExtFuncCall >(lib,"SDL_PlayHapticRumble","SDL_PlayHapticRumble")
		->args({"haptic","strength","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_haptic.h:1453:34
	makeExtern< bool (*)(struct SDL_Haptic *) , SDL_StopHapticRumble , SimNode_ExtFuncCall >(lib,"SDL_StopHapticRumble","SDL_StopHapticRumble")
		->args({"haptic"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:177:33
	makeExtern< int (*)() , SDL_hid_init , SimNode_ExtFuncCall >(lib,"SDL_hid_init","SDL_hid_init")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:192:33
	makeExtern< int (*)() , SDL_hid_exit , SimNode_ExtFuncCall >(lib,"SDL_hid_exit","SDL_hid_exit")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:213:36
	makeExtern< unsigned int (*)() , SDL_hid_device_change_count , SimNode_ExtFuncCall >(lib,"SDL_hid_device_change_count","SDL_hid_device_change_count")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:241:51
	makeExtern< struct SDL_hid_device_info * (*)(unsigned short,unsigned short) , SDL_hid_enumerate , SimNode_ExtFuncCall >(lib,"SDL_hid_enumerate","SDL_hid_enumerate")
		->args({"vendor_id","product_id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:253:34
	makeExtern< void (*)(struct SDL_hid_device_info *) , SDL_hid_free_enumeration , SimNode_ExtFuncCall >(lib,"SDL_hid_free_enumeration","SDL_hid_free_enumeration")
		->args({"devs"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_hid_open), SDL_hid_open, SimNode_ExtFuncCall>(lib,"SDL_hid_open","SDL_hid_openWide")->args({"vendor_id","product_id","serial_number"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:285:46
	makeExtern< struct SDL_hid_device * (*)(const char *) , SDL_hid_open_path , SimNode_ExtFuncCall >(lib,"SDL_hid_open_path","SDL_hid_open_path")
		->args({"path"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:330:33
	makeExtern< int (*)(struct SDL_hid_device *,const unsigned char *,size_t) , SDL_hid_write , SimNode_ExtFuncCall >(lib,"SDL_hid_write","SDL_hid_write")
		->args({"dev","data","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:351:33
	makeExtern< int (*)(struct SDL_hid_device *,unsigned char *,size_t,int) , SDL_hid_read_timeout , SimNode_ExtFuncCall >(lib,"SDL_hid_read_timeout","SDL_hid_read_timeout")
		->args({"dev","data","length","milliseconds"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:372:33
	makeExtern< int (*)(struct SDL_hid_device *,unsigned char *,size_t) , SDL_hid_read , SimNode_ExtFuncCall >(lib,"SDL_hid_read","SDL_hid_read")
		->args({"dev","data","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:391:33
	makeExtern< int (*)(struct SDL_hid_device *,int) , SDL_hid_set_nonblocking , SimNode_ExtFuncCall >(lib,"SDL_hid_set_nonblocking","SDL_hid_set_nonblocking")
		->args({"dev","nonblock"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:416:33
	makeExtern< int (*)(struct SDL_hid_device *,const unsigned char *,size_t) , SDL_hid_send_feature_report , SimNode_ExtFuncCall >(lib,"SDL_hid_send_feature_report","SDL_hid_send_feature_report")
		->args({"dev","data","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:439:33
	makeExtern< int (*)(struct SDL_hid_device *,unsigned char *,size_t) , SDL_hid_get_feature_report , SimNode_ExtFuncCall >(lib,"SDL_hid_get_feature_report","SDL_hid_get_feature_report")
		->args({"dev","data","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:462:33
	makeExtern< int (*)(struct SDL_hid_device *,unsigned char *,size_t) , SDL_hid_get_input_report , SimNode_ExtFuncCall >(lib,"SDL_hid_get_input_report","SDL_hid_get_input_report")
		->args({"dev","data","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:473:33
	makeExtern< int (*)(struct SDL_hid_device *) , SDL_hid_close , SimNode_ExtFuncCall >(lib,"SDL_hid_close","SDL_hid_close")
		->args({"dev"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_hid_get_manufacturer_string), SDL_hid_get_manufacturer_string, SimNode_ExtFuncCall>(lib,"SDL_hid_get_manufacturer_string","SDL_hid_get_manufacturer_stringWide")->args({"dev","string","maxlen"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_hid_get_product_string), SDL_hid_get_product_string, SimNode_ExtFuncCall>(lib,"SDL_hid_get_product_string","SDL_hid_get_product_stringWide")->args({"dev","string","maxlen"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_hid_get_serial_number_string), SDL_hid_get_serial_number_string, SimNode_ExtFuncCall>(lib,"SDL_hid_get_serial_number_string","SDL_hid_get_serial_number_stringWide")->args({"dev","string","maxlen"})->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_hid_get_indexed_string), SDL_hid_get_indexed_string, SimNode_ExtFuncCall>(lib,"SDL_hid_get_indexed_string","SDL_hid_get_indexed_stringWide")->args({"dev","string_index","string","maxlen"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:538:51
	makeExtern< struct SDL_hid_device_info * (*)(struct SDL_hid_device *) , SDL_hid_get_device_info , SimNode_ExtFuncCall >(lib,"SDL_hid_get_device_info","SDL_hid_get_device_info")
		->args({"dev"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:554:33
	makeExtern< int (*)(struct SDL_hid_device *,unsigned char *,size_t) , SDL_hid_get_report_descriptor , SimNode_ExtFuncCall >(lib,"SDL_hid_get_report_descriptor","SDL_hid_get_report_descriptor")
		->args({"dev","buf","buf_size"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hidapi.h:563:34
	makeExtern< void (*)(bool) , SDL_hid_ble_scan , SimNode_ExtFuncCall >(lib,"SDL_hid_ble_scan","SDL_hid_ble_scan")
		->args({"active"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hints.h:4870:34
	makeExtern< bool (*)(const char *,const char *,enum SDL_HintPriority) , SDL_SetHintWithPriority , SimNode_ExtFuncCall >(lib,"SDL_SetHintWithPriority","SDL_SetHintWithPriority")
		->args({"name","value","priority"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hints.h:4892:34
	makeExtern< bool (*)(const char *,const char *) , SDL_SetHint , SimNode_ExtFuncCall >(lib,"SDL_SetHint","SDL_SetHint")
		->args({"name","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hints.h:4912:34
	makeExtern< bool (*)(const char *) , SDL_ResetHint , SimNode_ExtFuncCall >(lib,"SDL_ResetHint","SDL_ResetHint")
		->args({"name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hints.h:4927:34
	makeExtern< void (*)() , SDL_ResetHints , SimNode_ExtFuncCall >(lib,"SDL_ResetHints","SDL_ResetHints")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hints.h:4942:41
	makeExtern< const char * (*)(const char *) , SDL_GetHint , SimNode_ExtFuncCall >(lib,"SDL_GetHint","SDL_GetHint")
		->args({"name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_hints.h:4959:34
	makeExtern< bool (*)(const char *,bool) , SDL_GetHintBoolean , SimNode_ExtFuncCall >(lib,"SDL_GetHintBoolean","SDL_GetHintBoolean")
		->args({"name","default_value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:238:34
	makeExtern< bool (*)(unsigned int) , SDL_Init , SimNode_ExtFuncCall >(lib,"SDL_Init","SDL_Init")
		->args({"flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:257:34
	makeExtern< bool (*)(unsigned int) , SDL_InitSubSystem , SimNode_ExtFuncCall >(lib,"SDL_InitSubSystem","SDL_InitSubSystem")
		->args({"flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:274:34
	makeExtern< void (*)(unsigned int) , SDL_QuitSubSystem , SimNode_ExtFuncCall >(lib,"SDL_QuitSubSystem","SDL_QuitSubSystem")
		->args({"flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:290:43
	makeExtern< unsigned int (*)(unsigned int) , SDL_WasInit , SimNode_ExtFuncCall >(lib,"SDL_WasInit","SDL_WasInit")
		->args({"flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:310:34
	makeExtern< void (*)() , SDL_Quit , SimNode_ExtFuncCall >(lib,"SDL_Quit","SDL_Quit")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:330:34
	makeExtern< bool (*)() , SDL_IsMainThread , SimNode_ExtFuncCall >(lib,"SDL_IsMainThread","SDL_IsMainThread")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:405:34
	makeExtern< bool (*)(const char *,const char *,const char *) , SDL_SetAppMetadata , SimNode_ExtFuncCall >(lib,"SDL_SetAppMetadata","SDL_SetAppMetadata")
		->args({"appname","appversion","appidentifier"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:468:34
	makeExtern< bool (*)(const char *,const char *) , SDL_SetAppMetadataProperty , SimNode_ExtFuncCall >(lib,"SDL_SetAppMetadataProperty","SDL_SetAppMetadataProperty")
		->args({"name","value"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_init.h:499:42
	makeExtern< const char * (*)(const char *) , SDL_GetAppMetadataProperty , SimNode_ExtFuncCall >(lib,"SDL_GetAppMetadataProperty","SDL_GetAppMetadataProperty")
		->args({"name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_loadso.h:93:48
	makeExtern< struct SDL_SharedObject * (*)(const char *) , SDL_LoadObject , SimNode_ExtFuncCall >(lib,"SDL_LoadObject","SDL_LoadObject")
		->args({"sofile"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_LoadFunction), SDL_LoadFunction, SimNode_ExtFuncCall>(lib,"SDL_LoadFunction","SDL_LoadFunctionAddress")->args({"handle","name"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_loadso.h:137:34
	makeExtern< void (*)(struct SDL_SharedObject *) , SDL_UnloadObject , SimNode_ExtFuncCall >(lib,"SDL_UnloadObject","SDL_UnloadObject")
		->args({"handle"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_locale.h:109:43
	makeExtern< struct SDL_Locale ** (*)(int *) , SDL_GetPreferredLocales , SimNode_ExtFuncCall >(lib,"SDL_GetPreferredLocales","SDL_GetPreferredLocales")
		->args({"count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_log.h:156:34
	makeExtern< void (*)(enum SDL_LogPriority) , SDL_SetLogPriorities , SimNode_ExtFuncCall >(lib,"SDL_SetLogPriorities","SDL_SetLogPriorities")
		->args({"priority"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_log.h:172:34
	makeExtern< void (*)(int,enum SDL_LogPriority) , SDL_SetLogPriority , SimNode_ExtFuncCall >(lib,"SDL_SetLogPriority","SDL_SetLogPriority")
		->args({"category","priority"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_log.h:186:45
	makeExtern< enum SDL_LogPriority (*)(int) , SDL_GetLogPriority , SimNode_ExtFuncCall >(lib,"SDL_GetLogPriority","SDL_GetLogPriority")
		->args({"category"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_log.h:200:34
	makeExtern< void (*)() , SDL_ResetLogPriorities , SimNode_ExtFuncCall >(lib,"SDL_ResetLogPriorities","SDL_ResetLogPriorities")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_log.h:225:34
	makeExtern< bool (*)(enum SDL_LogPriority,const char *) , SDL_SetLogPriorityPrefix , SimNode_ExtFuncCall >(lib,"SDL_SetLogPriorityPrefix","SDL_SetLogPriorityPrefix")
		->args({"priority","prefix"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_process.h:106:43
	makeExtern< struct SDL_Process * (*)(const char *const *,bool) , SDL_CreateProcess , SimNode_ExtFuncCall >(lib,"SDL_CreateProcess","SDL_CreateProcess")
		->args({"args","pipe_stdio"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_process.h:227:43
	makeExtern< struct SDL_Process * (*)(unsigned int) , SDL_CreateProcessWithProperties , SimNode_ExtFuncCall >(lib,"SDL_CreateProcessWithProperties","SDL_CreateProcessWithProperties")
		->args({"props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_process.h:271:46
	makeExtern< unsigned int (*)(struct SDL_Process *) , SDL_GetProcessProperties , SimNode_ExtFuncCall >(lib,"SDL_GetProcessProperties","SDL_GetProcessProperties")
		->args({"process"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_process.h:308:36
	makeExtern< void * (*)(struct SDL_Process *,size_t *,int *) , SDL_ReadProcess , SimNode_ExtFuncCall >(lib,"SDL_ReadProcess","SDL_ReadProcess")
		->args({"process","datasize","exitcode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_process.h:334:44
	makeExtern< struct SDL_IOStream * (*)(struct SDL_Process *) , SDL_GetProcessInput , SimNode_ExtFuncCall >(lib,"SDL_GetProcessInput","SDL_GetProcessInput")
		->args({"process"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_process.h:358:44
	makeExtern< struct SDL_IOStream * (*)(struct SDL_Process *) , SDL_GetProcessOutput , SimNode_ExtFuncCall >(lib,"SDL_GetProcessOutput","SDL_GetProcessOutput")
		->args({"process"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_process.h:381:34
	makeExtern< bool (*)(struct SDL_Process *,bool) , SDL_KillProcess , SimNode_ExtFuncCall >(lib,"SDL_KillProcess","SDL_KillProcess")
		->args({"process","force"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_process.h:414:34
	makeExtern< bool (*)(struct SDL_Process *,bool,int *) , SDL_WaitProcess , SimNode_ExtFuncCall >(lib,"SDL_WaitProcess","SDL_WaitProcess")
		->args({"process","block","exitcode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_process.h:433:34
	makeExtern< void (*)(struct SDL_Process *) , SDL_DestroyProcess , SimNode_ExtFuncCall >(lib,"SDL_DestroyProcess","SDL_DestroyProcess")
		->args({"process"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:192:33
	makeExtern< int (*)() , SDL_GetNumRenderDrivers , SimNode_ExtFuncCall >(lib,"SDL_GetNumRenderDrivers","SDL_GetNumRenderDrivers")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:216:42
	makeExtern< const char * (*)(int) , SDL_GetRenderDriver , SimNode_ExtFuncCall >(lib,"SDL_GetRenderDriver","SDL_GetRenderDriver")
		->args({"index"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:238:34
	makeExtern< bool (*)(const char *,int,int,SDL_WindowFlags,struct SDL_Window **,struct SDL_Renderer **) , SDL_CreateWindowAndRenderer , SimNode_ExtFuncCall >(lib,"SDL_CreateWindowAndRenderer","SDL_CreateWindowAndRenderer")
		->args({"title","width","height","window_flags","window","renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:273:44
	makeExtern< struct SDL_Renderer * (*)(struct SDL_Window *,const char *) , SDL_CreateRenderer , SimNode_ExtFuncCall >(lib,"SDL_CreateRenderer","SDL_CreateRenderer")
		->args({"window","name"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:337:44
	makeExtern< struct SDL_Renderer * (*)(unsigned int) , SDL_CreateRendererWithProperties , SimNode_ExtFuncCall >(lib,"SDL_CreateRendererWithProperties","SDL_CreateRendererWithProperties")
		->args({"props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:421:44
	makeExtern< struct SDL_Renderer * (*)(struct SDL_Surface *) , SDL_CreateSoftwareRenderer , SimNode_ExtFuncCall >(lib,"SDL_CreateSoftwareRenderer","SDL_CreateSoftwareRenderer")
		->args({"surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:434:44
	makeExtern< struct SDL_Renderer * (*)(struct SDL_Window *) , SDL_GetRenderer , SimNode_ExtFuncCall >(lib,"SDL_GetRenderer","SDL_GetRenderer")
		->args({"window"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:447:42
	makeExtern< struct SDL_Window * (*)(struct SDL_Renderer *) , SDL_GetRenderWindow , SimNode_ExtFuncCall >(lib,"SDL_GetRenderWindow","SDL_GetRenderWindow")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:463:42
	makeExtern< const char * (*)(struct SDL_Renderer *) , SDL_GetRendererName , SimNode_ExtFuncCall >(lib,"SDL_GetRendererName","SDL_GetRendererName")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:551:46
	makeExtern< unsigned int (*)(struct SDL_Renderer *) , SDL_GetRendererProperties , SimNode_ExtFuncCall >(lib,"SDL_GetRendererProperties","SDL_GetRendererProperties")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:600:34
	makeExtern< bool (*)(struct SDL_Renderer *,int *,int *) , SDL_GetRenderOutputSize , SimNode_ExtFuncCall >(lib,"SDL_GetRenderOutputSize","SDL_GetRenderOutputSize")
		->args({"renderer","w","h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:623:34
	makeExtern< bool (*)(struct SDL_Renderer *,int *,int *) , SDL_GetCurrentRenderOutputSize , SimNode_ExtFuncCall >(lib,"SDL_GetCurrentRenderOutputSize","SDL_GetCurrentRenderOutputSize")
		->args({"renderer","w","h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:648:43
	makeExtern< struct SDL_Texture * (*)(struct SDL_Renderer *,enum SDL_PixelFormat,enum SDL_TextureAccess,int,int) , SDL_CreateTexture , SimNode_ExtFuncCall >(lib,"SDL_CreateTexture","SDL_CreateTexture")
		->args({"renderer","format","access","w","h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:676:43
	makeExtern< struct SDL_Texture * (*)(struct SDL_Renderer *,struct SDL_Surface *) , SDL_CreateTextureFromSurface , SimNode_ExtFuncCall >(lib,"SDL_CreateTextureFromSurface","SDL_CreateTextureFromSurface")
		->args({"renderer","surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:804:43
	makeExtern< struct SDL_Texture * (*)(struct SDL_Renderer *,unsigned int) , SDL_CreateTextureWithProperties , SimNode_ExtFuncCall >(lib,"SDL_CreateTextureWithProperties","SDL_CreateTextureWithProperties")
		->args({"renderer","props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:933:46
	makeExtern< unsigned int (*)(struct SDL_Texture *) , SDL_GetTextureProperties , SimNode_ExtFuncCall >(lib,"SDL_GetTextureProperties","SDL_GetTextureProperties")
		->args({"texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:977:44
	makeExtern< struct SDL_Renderer * (*)(struct SDL_Texture *) , SDL_GetRendererFromTexture , SimNode_ExtFuncCall >(lib,"SDL_GetRendererFromTexture","SDL_GetRendererFromTexture")
		->args({"texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:994:34
	makeExtern< bool (*)(struct SDL_Texture *,float *,float *) , SDL_GetTextureSize , SimNode_ExtFuncCall >(lib,"SDL_GetTextureSize","SDL_GetTextureSize")
		->args({"texture","w","h"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1060:34
	makeExtern< bool (*)(struct SDL_Texture *,unsigned char,unsigned char,unsigned char) , SDL_SetTextureColorMod , SimNode_ExtFuncCall >(lib,"SDL_SetTextureColorMod","SDL_SetTextureColorMod")
		->args({"texture","r","g","b"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1090:34
	makeExtern< bool (*)(struct SDL_Texture *,float,float,float) , SDL_SetTextureColorModFloat , SimNode_ExtFuncCall >(lib,"SDL_SetTextureColorModFloat","SDL_SetTextureColorModFloat")
		->args({"texture","r","g","b"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1111:34
	makeExtern< bool (*)(struct SDL_Texture *,unsigned char *,unsigned char *,unsigned char *) , SDL_GetTextureColorMod , SimNode_ExtFuncCall >(lib,"SDL_GetTextureColorMod","SDL_GetTextureColorMod")
		->args({"texture","r","g","b"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1131:34
	makeExtern< bool (*)(struct SDL_Texture *,float *,float *,float *) , SDL_GetTextureColorModFloat , SimNode_ExtFuncCall >(lib,"SDL_GetTextureColorModFloat","SDL_GetTextureColorModFloat")
		->args({"texture","r","g","b"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1157:34
	makeExtern< bool (*)(struct SDL_Texture *,unsigned char) , SDL_SetTextureAlphaMod , SimNode_ExtFuncCall >(lib,"SDL_SetTextureAlphaMod","SDL_SetTextureAlphaMod")
		->args({"texture","alpha"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1183:34
	makeExtern< bool (*)(struct SDL_Texture *,float) , SDL_SetTextureAlphaModFloat , SimNode_ExtFuncCall >(lib,"SDL_SetTextureAlphaModFloat","SDL_SetTextureAlphaModFloat")
		->args({"texture","alpha"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1201:34
	makeExtern< bool (*)(struct SDL_Texture *,unsigned char *) , SDL_GetTextureAlphaMod , SimNode_ExtFuncCall >(lib,"SDL_GetTextureAlphaMod","SDL_GetTextureAlphaMod")
		->args({"texture","alpha"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1219:34
	makeExtern< bool (*)(struct SDL_Texture *,float *) , SDL_GetTextureAlphaModFloat , SimNode_ExtFuncCall >(lib,"SDL_GetTextureAlphaModFloat","SDL_GetTextureAlphaModFloat")
		->args({"texture","alpha"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1241:34
	makeExtern< bool (*)(struct SDL_Texture *,unsigned int) , SDL_SetTextureBlendMode , SimNode_ExtFuncCall >(lib,"SDL_SetTextureBlendMode","SDL_SetTextureBlendMode")
		->args({"texture","blendMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1257:34
	makeExtern< bool (*)(struct SDL_Texture *,unsigned int *) , SDL_GetTextureBlendMode , SimNode_ExtFuncCall >(lib,"SDL_GetTextureBlendMode","SDL_GetTextureBlendMode")
		->args({"texture","blendMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1277:34
	makeExtern< bool (*)(struct SDL_Texture *,enum SDL_ScaleMode) , SDL_SetTextureScaleMode , SimNode_ExtFuncCall >(lib,"SDL_SetTextureScaleMode","SDL_SetTextureScaleMode")
		->args({"texture","scaleMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1293:34
	makeExtern< bool (*)(struct SDL_Texture *,enum SDL_ScaleMode *) , SDL_GetTextureScaleMode , SimNode_ExtFuncCall >(lib,"SDL_GetTextureScaleMode","SDL_GetTextureScaleMode")
		->args({"texture","scaleMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1327:34
	makeExtern< bool (*)(struct SDL_Texture *,const struct SDL_Rect *,const void *,int) , SDL_UpdateTexture , SimNode_ExtFuncCall >(lib,"SDL_UpdateTexture","SDL_UpdateTexture")
		->args({"texture","rect","pixels","pitch"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1359:34
	makeExtern< bool (*)(struct SDL_Texture *,const struct SDL_Rect *,const unsigned char *,int,const unsigned char *,int,const unsigned char *,int) , SDL_UpdateYUVTexture , SimNode_ExtFuncCall >(lib,"SDL_UpdateYUVTexture","SDL_UpdateYUVTexture")
		->args({"texture","rect","Yplane","Ypitch","Uplane","Upitch","Vplane","Vpitch"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1391:34
	makeExtern< bool (*)(struct SDL_Texture *,const struct SDL_Rect *,const unsigned char *,int,const unsigned char *,int) , SDL_UpdateNVTexture , SimNode_ExtFuncCall >(lib,"SDL_UpdateNVTexture","SDL_UpdateNVTexture")
		->args({"texture","rect","Yplane","Ypitch","UVplane","UVpitch"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1426:34
	makeExtern< bool (*)(struct SDL_Texture *,const struct SDL_Rect *,void **,int *) , SDL_LockTexture , SimNode_ExtFuncCall >(lib,"SDL_LockTexture","SDL_LockTexture")
		->args({"texture","rect","pixels","pitch"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1464:34
	makeExtern< bool (*)(struct SDL_Texture *,const struct SDL_Rect *,struct SDL_Surface **) , SDL_LockTextureToSurface , SimNode_ExtFuncCall >(lib,"SDL_LockTextureToSurface","SDL_LockTextureToSurface")
		->args({"texture","rect","surface"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1485:34
	makeExtern< void (*)(struct SDL_Texture *) , SDL_UnlockTexture , SimNode_ExtFuncCall >(lib,"SDL_UnlockTexture","SDL_UnlockTexture")
		->args({"texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1512:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *) , SDL_SetRenderTarget , SimNode_ExtFuncCall >(lib,"SDL_SetRenderTarget","SDL_SetRenderTarget")
		->args({"renderer","texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1529:43
	makeExtern< struct SDL_Texture * (*)(struct SDL_Renderer *) , SDL_GetRenderTarget , SimNode_ExtFuncCall >(lib,"SDL_GetRenderTarget","SDL_GetRenderTarget")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1576:34
	makeExtern< bool (*)(struct SDL_Renderer *,int,int,enum SDL_RendererLogicalPresentation) , SDL_SetRenderLogicalPresentation , SimNode_ExtFuncCall >(lib,"SDL_SetRenderLogicalPresentation","SDL_SetRenderLogicalPresentation")
		->args({"renderer","w","h","mode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1601:34
	makeExtern< bool (*)(struct SDL_Renderer *,int *,int *,enum SDL_RendererLogicalPresentation *) , SDL_GetRenderLogicalPresentation , SimNode_ExtFuncCall >(lib,"SDL_GetRenderLogicalPresentation","SDL_GetRenderLogicalPresentation")
		->args({"renderer","w","h","mode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1626:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_FRect *) , SDL_GetRenderLogicalPresentationRect , SimNode_ExtFuncCall >(lib,"SDL_GetRenderLogicalPresentationRect","SDL_GetRenderLogicalPresentationRect")
		->args({"renderer","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1653:34
	makeExtern< bool (*)(struct SDL_Renderer *,float,float,float *,float *) , SDL_RenderCoordinatesFromWindow , SimNode_ExtFuncCall >(lib,"SDL_RenderCoordinatesFromWindow","SDL_RenderCoordinatesFromWindow")
		->args({"renderer","window_x","window_y","x","y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1683:34
	makeExtern< bool (*)(struct SDL_Renderer *,float,float,float *,float *) , SDL_RenderCoordinatesToWindow , SimNode_ExtFuncCall >(lib,"SDL_RenderCoordinatesToWindow","SDL_RenderCoordinatesToWindow")
		->args({"renderer","x","y","window_x","window_y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1719:34
	makeExtern< bool (*)(struct SDL_Renderer *,union SDL_Event *) , SDL_ConvertEventToRenderCoordinates , SimNode_ExtFuncCall >(lib,"SDL_ConvertEventToRenderCoordinates","SDL_ConvertEventToRenderCoordinates")
		->args({"renderer","event"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1746:34
	makeExtern< bool (*)(struct SDL_Renderer *,const struct SDL_Rect *) , SDL_SetRenderViewport , SimNode_ExtFuncCall >(lib,"SDL_SetRenderViewport","SDL_SetRenderViewport")
		->args({"renderer","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1766:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Rect *) , SDL_GetRenderViewport , SimNode_ExtFuncCall >(lib,"SDL_GetRenderViewport","SDL_GetRenderViewport")
		->args({"renderer","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1788:34
	makeExtern< bool (*)(struct SDL_Renderer *) , SDL_RenderViewportSet , SimNode_ExtFuncCall >(lib,"SDL_RenderViewportSet","SDL_RenderViewportSet")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1810:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Rect *) , SDL_GetRenderSafeArea , SimNode_ExtFuncCall >(lib,"SDL_GetRenderSafeArea","SDL_GetRenderSafeArea")
		->args({"renderer","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1831:34
	makeExtern< bool (*)(struct SDL_Renderer *,const struct SDL_Rect *) , SDL_SetRenderClipRect , SimNode_ExtFuncCall >(lib,"SDL_SetRenderClipRect","SDL_SetRenderClipRect")
		->args({"renderer","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1852:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Rect *) , SDL_GetRenderClipRect , SimNode_ExtFuncCall >(lib,"SDL_GetRenderClipRect","SDL_GetRenderClipRect")
		->args({"renderer","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1871:34
	makeExtern< bool (*)(struct SDL_Renderer *) , SDL_RenderClipEnabled , SimNode_ExtFuncCall >(lib,"SDL_RenderClipEnabled","SDL_RenderClipEnabled")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1899:34
	makeExtern< bool (*)(struct SDL_Renderer *,float,float) , SDL_SetRenderScale , SimNode_ExtFuncCall >(lib,"SDL_SetRenderScale","SDL_SetRenderScale")
		->args({"renderer","scaleX","scaleY"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1919:34
	makeExtern< bool (*)(struct SDL_Renderer *,float *,float *) , SDL_GetRenderScale , SimNode_ExtFuncCall >(lib,"SDL_GetRenderScale","SDL_GetRenderScale")
		->args({"renderer","scaleX","scaleY"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1944:34
	makeExtern< bool (*)(struct SDL_Renderer *,unsigned char,unsigned char,unsigned char,unsigned char) , SDL_SetRenderDrawColor , SimNode_ExtFuncCall >(lib,"SDL_SetRenderDrawColor","SDL_SetRenderDrawColor")
		->args({"renderer","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1969:34
	makeExtern< bool (*)(struct SDL_Renderer *,float,float,float,float) , SDL_SetRenderDrawColorFloat , SimNode_ExtFuncCall >(lib,"SDL_SetRenderDrawColorFloat","SDL_SetRenderDrawColorFloat")
		->args({"renderer","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:1993:34
	makeExtern< bool (*)(struct SDL_Renderer *,unsigned char *,unsigned char *,unsigned char *,unsigned char *) , SDL_GetRenderDrawColor , SimNode_ExtFuncCall >(lib,"SDL_GetRenderDrawColor","SDL_GetRenderDrawColor")
		->args({"renderer","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2017:34
	makeExtern< bool (*)(struct SDL_Renderer *,float *,float *,float *,float *) , SDL_GetRenderDrawColorFloat , SimNode_ExtFuncCall >(lib,"SDL_GetRenderDrawColorFloat","SDL_GetRenderDrawColorFloat")
		->args({"renderer","r","g","b","a"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2041:34
	makeExtern< bool (*)(struct SDL_Renderer *,float) , SDL_SetRenderColorScale , SimNode_ExtFuncCall >(lib,"SDL_SetRenderColorScale","SDL_SetRenderColorScale")
		->args({"renderer","scale"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2057:34
	makeExtern< bool (*)(struct SDL_Renderer *,float *) , SDL_GetRenderColorScale , SimNode_ExtFuncCall >(lib,"SDL_GetRenderColorScale","SDL_GetRenderColorScale")
		->args({"renderer","scale"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2078:34
	makeExtern< bool (*)(struct SDL_Renderer *,unsigned int) , SDL_SetRenderDrawBlendMode , SimNode_ExtFuncCall >(lib,"SDL_SetRenderDrawBlendMode","SDL_SetRenderDrawBlendMode")
		->args({"renderer","blendMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2094:34
	makeExtern< bool (*)(struct SDL_Renderer *,unsigned int *) , SDL_GetRenderDrawBlendMode , SimNode_ExtFuncCall >(lib,"SDL_GetRenderDrawBlendMode","SDL_GetRenderDrawBlendMode")
		->args({"renderer","blendMode"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2114:34
	makeExtern< bool (*)(struct SDL_Renderer *) , SDL_RenderClear , SimNode_ExtFuncCall >(lib,"SDL_RenderClear","SDL_RenderClear")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2131:34
	makeExtern< bool (*)(struct SDL_Renderer *,float,float) , SDL_RenderPoint , SimNode_ExtFuncCall >(lib,"SDL_RenderPoint","SDL_RenderPoint")
		->args({"renderer","x","y"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2148:34
	makeExtern< bool (*)(struct SDL_Renderer *,const struct SDL_FPoint *,int) , SDL_RenderPoints , SimNode_ExtFuncCall >(lib,"SDL_RenderPoints","SDL_RenderPoints")
		->args({"renderer","points","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2167:34
	makeExtern< bool (*)(struct SDL_Renderer *,float,float,float,float) , SDL_RenderLine , SimNode_ExtFuncCall >(lib,"SDL_RenderLine","SDL_RenderLine")
		->args({"renderer","x1","y1","x2","y2"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2185:34
	makeExtern< bool (*)(struct SDL_Renderer *,const struct SDL_FPoint *,int) , SDL_RenderLines , SimNode_ExtFuncCall >(lib,"SDL_RenderLines","SDL_RenderLines")
		->args({"renderer","points","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2202:34
	makeExtern< bool (*)(struct SDL_Renderer *,const struct SDL_FRect *) , SDL_RenderRect , SimNode_ExtFuncCall >(lib,"SDL_RenderRect","SDL_RenderRect")
		->args({"renderer","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2220:34
	makeExtern< bool (*)(struct SDL_Renderer *,const struct SDL_FRect *,int) , SDL_RenderRects , SimNode_ExtFuncCall >(lib,"SDL_RenderRects","SDL_RenderRects")
		->args({"renderer","rects","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2238:34
	makeExtern< bool (*)(struct SDL_Renderer *,const struct SDL_FRect *) , SDL_RenderFillRect , SimNode_ExtFuncCall >(lib,"SDL_RenderFillRect","SDL_RenderFillRect")
		->args({"renderer","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2256:34
	makeExtern< bool (*)(struct SDL_Renderer *,const struct SDL_FRect *,int) , SDL_RenderFillRects , SimNode_ExtFuncCall >(lib,"SDL_RenderFillRects","SDL_RenderFillRects")
		->args({"renderer","rects","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2278:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *,const struct SDL_FRect *,const struct SDL_FRect *) , SDL_RenderTexture , SimNode_ExtFuncCall >(lib,"SDL_RenderTexture","SDL_RenderTexture")
		->args({"renderer","texture","srcrect","dstrect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2306:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *,const struct SDL_FRect *,const struct SDL_FRect *,double,const struct SDL_FPoint *,enum SDL_FlipMode) , SDL_RenderTextureRotated , SimNode_ExtFuncCall >(lib,"SDL_RenderTextureRotated","SDL_RenderTextureRotated")
		->args({"renderer","texture","srcrect","dstrect","angle","center","flip"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2337:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *,const struct SDL_FRect *,const struct SDL_FPoint *,const struct SDL_FPoint *,const struct SDL_FPoint *) , SDL_RenderTextureAffine , SimNode_ExtFuncCall >(lib,"SDL_RenderTextureAffine","SDL_RenderTextureAffine")
		->args({"renderer","texture","srcrect","origin","right","down"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2366:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *,const struct SDL_FRect *,float,const struct SDL_FRect *) , SDL_RenderTextureTiled , SimNode_ExtFuncCall >(lib,"SDL_RenderTextureTiled","SDL_RenderTextureTiled")
		->args({"renderer","texture","srcrect","scale","dstrect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2401:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *,const struct SDL_FRect *,float,float,float,float,float,const struct SDL_FRect *) , SDL_RenderTexture9Grid , SimNode_ExtFuncCall >(lib,"SDL_RenderTexture9Grid","SDL_RenderTexture9Grid")
		->args({"renderer","texture","srcrect","left_width","right_width","top_height","bottom_height","scale","dstrect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2464:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *,const struct SDL_Vertex *,int,const int *,int) , SDL_RenderGeometry , SimNode_ExtFuncCall >(lib,"SDL_RenderGeometry","SDL_RenderGeometry")
		->args({"renderer","texture","vertices","num_vertices","indices","num_indices"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2497:34
	makeExtern< bool (*)(struct SDL_Renderer *,struct SDL_Texture *,const float *,int,const struct SDL_FColor *,int,const float *,int,int,const void *,int,int) , SDL_RenderGeometryRaw , SimNode_ExtFuncCall >(lib,"SDL_RenderGeometryRaw","SDL_RenderGeometryRaw")
		->args({"renderer","texture","xy","xy_stride","color","color_stride","uv","uv_stride","num_vertices","indices","num_indices","size_indices"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2572:43
	makeExtern< struct SDL_Surface * (*)(struct SDL_Renderer *,const struct SDL_Rect *) , SDL_RenderReadPixels , SimNode_ExtFuncCall >(lib,"SDL_RenderReadPixels","SDL_RenderReadPixels")
		->args({"renderer","rect"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2621:34
	makeExtern< bool (*)(struct SDL_Renderer *) , SDL_RenderPresent , SimNode_ExtFuncCall >(lib,"SDL_RenderPresent","SDL_RenderPresent")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2638:34
	makeExtern< void (*)(struct SDL_Texture *) , SDL_DestroyTexture , SimNode_ExtFuncCall >(lib,"SDL_DestroyTexture","SDL_DestroyTexture")
		->args({"texture"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2654:34
	makeExtern< void (*)(struct SDL_Renderer *) , SDL_DestroyRenderer , SimNode_ExtFuncCall >(lib,"SDL_DestroyRenderer","SDL_DestroyRenderer")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2687:34
	makeExtern< bool (*)(struct SDL_Renderer *) , SDL_FlushRenderer , SimNode_ExtFuncCall >(lib,"SDL_FlushRenderer","SDL_FlushRenderer")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2705:36
	makeExtern< void * (*)(struct SDL_Renderer *) , SDL_GetRenderMetalLayer , SimNode_ExtFuncCall >(lib,"SDL_GetRenderMetalLayer","SDL_GetRenderMetalLayer")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2728:36
	makeExtern< void * (*)(struct SDL_Renderer *) , SDL_GetRenderMetalCommandEncoder , SimNode_ExtFuncCall >(lib,"SDL_GetRenderMetalCommandEncoder","SDL_GetRenderMetalCommandEncoder")
		->args({"renderer"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2759:34
	makeExtern< bool (*)(struct SDL_Renderer *,unsigned int,Sint64,Sint64) , SDL_AddVulkanRenderSemaphores , SimNode_ExtFuncCall >(lib,"SDL_AddVulkanRenderSemaphores","SDL_AddVulkanRenderSemaphores")
		->args({"renderer","wait_stage_mask","wait_semaphore","signal_semaphore"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2784:34
	makeExtern< bool (*)(struct SDL_Renderer *,int) , SDL_SetRenderVSync , SimNode_ExtFuncCall >(lib,"SDL_SetRenderVSync","SDL_SetRenderVSync")
		->args({"renderer","vsync"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2804:34
	makeExtern< bool (*)(struct SDL_Renderer *,int *) , SDL_GetRenderVSync , SimNode_ExtFuncCall >(lib,"SDL_GetRenderVSync","SDL_GetRenderVSync")
		->args({"renderer","vsync"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_render.h:2856:34
	makeExtern< bool (*)(struct SDL_Renderer *,float,float,const char *) , SDL_RenderDebugText , SimNode_ExtFuncCall >(lib,"SDL_RenderDebugText","SDL_RenderDebugText")
		->args({"renderer","x","y","str"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:353:43
	makeExtern< struct SDL_Storage * (*)(const char *,unsigned int) , SDL_OpenTitleStorage , SimNode_ExtFuncCall >(lib,"SDL_OpenTitleStorage","SDL_OpenTitleStorage")
		->args({"override","props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:379:43
	makeExtern< struct SDL_Storage * (*)(const char *,const char *,unsigned int) , SDL_OpenUserStorage , SimNode_ExtFuncCall >(lib,"SDL_OpenUserStorage","SDL_OpenUserStorage")
		->args({"org","app","props"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:403:43
	makeExtern< struct SDL_Storage * (*)(const char *) , SDL_OpenFileStorage , SimNode_ExtFuncCall >(lib,"SDL_OpenFileStorage","SDL_OpenFileStorage")
		->args({"path"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:432:43
	makeExtern< struct SDL_Storage * (*)(const struct SDL_StorageInterface *,void *) , SDL_OpenStorage , SimNode_ExtFuncCall >(lib,"SDL_OpenStorage","SDL_OpenStorage")
		->args({"iface","userdata"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:450:34
	makeExtern< bool (*)(struct SDL_Storage *) , SDL_CloseStorage , SimNode_ExtFuncCall >(lib,"SDL_CloseStorage","SDL_CloseStorage")
		->args({"storage"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:465:34
	makeExtern< bool (*)(struct SDL_Storage *) , SDL_StorageReady , SimNode_ExtFuncCall >(lib,"SDL_StorageReady","SDL_StorageReady")
		->args({"storage"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:481:34
	makeExtern< bool (*)(struct SDL_Storage *,const char *,Uint64 *) , SDL_GetStorageFileSize , SimNode_ExtFuncCall >(lib,"SDL_GetStorageFileSize","SDL_GetStorageFileSize")
		->args({"storage","path","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:504:34
	makeExtern< bool (*)(struct SDL_Storage *,const char *,void *,Uint64) , SDL_ReadStorageFile , SimNode_ExtFuncCall >(lib,"SDL_ReadStorageFile","SDL_ReadStorageFile")
		->args({"storage","path","destination","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:522:34
	makeExtern< bool (*)(struct SDL_Storage *,const char *,const void *,Uint64) , SDL_WriteStorageFile , SimNode_ExtFuncCall >(lib,"SDL_WriteStorageFile","SDL_WriteStorageFile")
		->args({"storage","path","source","length"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:536:34
	makeExtern< bool (*)(struct SDL_Storage *,const char *) , SDL_CreateStorageDirectory , SimNode_ExtFuncCall >(lib,"SDL_CreateStorageDirectory","SDL_CreateStorageDirectory")
		->args({"storage","path"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_EnumerateStorageDirectory), SDL_EnumerateStorageDirectory, SimNode_ExtFuncCall>(lib,"SDL_EnumerateStorageDirectory","SDL_EnumerateStorageDirectoryAddress")->args({"storage","path","callback","userdata"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:579:34
	makeExtern< bool (*)(struct SDL_Storage *,const char *) , SDL_RemoveStoragePath , SimNode_ExtFuncCall >(lib,"SDL_RemoveStoragePath","SDL_RemoveStoragePath")
		->args({"storage","path"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:594:34
	makeExtern< bool (*)(struct SDL_Storage *,const char *,const char *) , SDL_RenameStoragePath , SimNode_ExtFuncCall >(lib,"SDL_RenameStoragePath","SDL_RenameStoragePath")
		->args({"storage","oldpath","newpath"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:609:34
	makeExtern< bool (*)(struct SDL_Storage *,const char *,const char *) , SDL_CopyStorageFile , SimNode_ExtFuncCall >(lib,"SDL_CopyStorageFile","SDL_CopyStorageFile")
		->args({"storage","oldpath","newpath"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:625:34
	makeExtern< bool (*)(struct SDL_Storage *,const char *,struct SDL_PathInfo *) , SDL_GetStoragePathInfo , SimNode_ExtFuncCall >(lib,"SDL_GetStoragePathInfo","SDL_GetStoragePathInfo")
		->args({"storage","path","info"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:638:36
	makeExtern< Uint64 (*)(struct SDL_Storage *) , SDL_GetStorageSpaceRemaining , SimNode_ExtFuncCall >(lib,"SDL_GetStorageSpaceRemaining","SDL_GetStorageSpaceRemaining")
		->args({"storage"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_storage.h:678:37
	makeExtern< char ** (*)(struct SDL_Storage *,const char *,const char *,unsigned int,int *) , SDL_GlobStorageDirectory , SimNode_ExtFuncCall >(lib,"SDL_GlobStorageDirectory","SDL_GlobStorageDirectory")
		->args({"storage","path","pattern","flags","count"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_SetWindowsMessageHook), SDL_SetWindowsMessageHook, SimNode_ExtFuncCall>(lib,"SDL_SetWindowsMessageHook","SDL_SetWindowsMessageHookAddress")->args({"callback","userdata"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_system.h:114:33
	makeExtern< int (*)(unsigned int) , SDL_GetDirect3D9AdapterIndex , SimNode_ExtFuncCall >(lib,"SDL_GetDirect3D9AdapterIndex","SDL_GetDirect3D9AdapterIndex")
		->args({"displayID"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_system.h:131:34
	makeExtern< bool (*)(unsigned int,int *,int *) , SDL_GetDXGIOutputInfo , SimNode_ExtFuncCall >(lib,"SDL_GetDXGIOutputInfo","SDL_GetDXGIOutputInfo")
		->args({"displayID","adapterIndex","outputIndex"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_SetX11EventHook), SDL_SetX11EventHook, SimNode_ExtFuncCall>(lib,"SDL_SetX11EventHook","SDL_SetX11EventHookAddress")->args({"callback","userdata"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_system.h:630:34
	makeExtern< bool (*)() , SDL_IsTablet , SimNode_ExtFuncCall >(lib,"SDL_IsTablet","SDL_IsTablet")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_system.h:643:34
	makeExtern< bool (*)() , SDL_IsTV , SimNode_ExtFuncCall >(lib,"SDL_IsTV","SDL_IsTV")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_system.h:667:41
	makeExtern< enum SDL_Sandbox (*)() , SDL_GetSandbox , SimNode_ExtFuncCall >(lib,"SDL_GetSandbox","SDL_GetSandbox")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_system.h:687:34
	makeExtern< void (*)() , SDL_OnApplicationWillTerminate , SimNode_ExtFuncCall >(lib,"SDL_OnApplicationWillTerminate","SDL_OnApplicationWillTerminate")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_system.h:704:34
	makeExtern< void (*)() , SDL_OnApplicationDidReceiveMemoryWarning , SimNode_ExtFuncCall >(lib,"SDL_OnApplicationDidReceiveMemoryWarning","SDL_OnApplicationDidReceiveMemoryWarning")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_system.h:721:34
	makeExtern< void (*)() , SDL_OnApplicationWillEnterBackground , SimNode_ExtFuncCall >(lib,"SDL_OnApplicationWillEnterBackground","SDL_OnApplicationWillEnterBackground")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_system.h:738:34
	makeExtern< void (*)() , SDL_OnApplicationDidEnterBackground , SimNode_ExtFuncCall >(lib,"SDL_OnApplicationDidEnterBackground","SDL_OnApplicationDidEnterBackground")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_system.h:755:34
	makeExtern< void (*)() , SDL_OnApplicationWillEnterForeground , SimNode_ExtFuncCall >(lib,"SDL_OnApplicationWillEnterForeground","SDL_OnApplicationWillEnterForeground")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_system.h:772:34
	makeExtern< void (*)() , SDL_OnApplicationDidEnterForeground , SimNode_ExtFuncCall >(lib,"SDL_OnApplicationDidEnterForeground","SDL_OnApplicationDidEnterForeground")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_time.h:113:34
	makeExtern< bool (*)(enum SDL_DateFormat *,enum SDL_TimeFormat *) , SDL_GetDateTimeLocalePreferences , SimNode_ExtFuncCall >(lib,"SDL_GetDateTimeLocalePreferences","SDL_GetDateTimeLocalePreferences")
		->args({"dateFormat","timeFormat"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_time.h:127:34
	makeExtern< bool (*)(SDL_Time *) , SDL_GetCurrentTime , SimNode_ExtFuncCall >(lib,"SDL_GetCurrentTime","SDL_GetCurrentTime")
		->args({"ticks"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_time.h:145:34
	makeExtern< bool (*)(SDL_Time,struct SDL_DateTime *,bool) , SDL_TimeToDateTime , SimNode_ExtFuncCall >(lib,"SDL_TimeToDateTime","SDL_TimeToDateTime")
		->args({"ticks","dt","localTime"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_time.h:162:34
	makeExtern< bool (*)(const struct SDL_DateTime *,SDL_Time *) , SDL_DateTimeToTime , SimNode_ExtFuncCall >(lib,"SDL_DateTimeToTime","SDL_DateTimeToTime")
		->args({"dt","ticks"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_time.h:180:34
	makeExtern< void (*)(SDL_Time,unsigned int *,unsigned int *) , SDL_TimeToWindows , SimNode_ExtFuncCall >(lib,"SDL_TimeToWindows","SDL_TimeToWindows")
		->args({"ticks","dwLowDateTime","dwHighDateTime"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_time.h:197:38
	makeExtern< SDL_Time (*)(unsigned int,unsigned int) , SDL_TimeFromWindows , SimNode_ExtFuncCall >(lib,"SDL_TimeFromWindows","SDL_TimeFromWindows")
		->args({"dwLowDateTime","dwHighDateTime"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_time.h:211:33
	makeExtern< int (*)(int,int) , SDL_GetDaysInMonth , SimNode_ExtFuncCall >(lib,"SDL_GetDaysInMonth","SDL_GetDaysInMonth")
		->args({"year","month"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_time.h:226:33
	makeExtern< int (*)(int,int,int) , SDL_GetDayOfYear , SimNode_ExtFuncCall >(lib,"SDL_GetDayOfYear","SDL_GetDayOfYear")
		->args({"year","month","day"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_time.h:241:33
	makeExtern< int (*)(int,int,int) , SDL_GetDayOfWeek , SimNode_ExtFuncCall >(lib,"SDL_GetDayOfWeek","SDL_GetDayOfWeek")
		->args({"year","month","day"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:201:36
	makeExtern< Uint64 (*)() , SDL_GetTicks , SimNode_ExtFuncCall >(lib,"SDL_GetTicks","SDL_GetTicks")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:213:36
	makeExtern< Uint64 (*)() , SDL_GetTicksNS , SimNode_ExtFuncCall >(lib,"SDL_GetTicksNS","SDL_GetTicksNS")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:232:36
	makeExtern< Uint64 (*)() , SDL_GetPerformanceCounter , SimNode_ExtFuncCall >(lib,"SDL_GetPerformanceCounter","SDL_GetPerformanceCounter")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:245:36
	makeExtern< Uint64 (*)() , SDL_GetPerformanceFrequency , SimNode_ExtFuncCall >(lib,"SDL_GetPerformanceFrequency","SDL_GetPerformanceFrequency")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:263:34
	makeExtern< void (*)(unsigned int) , SDL_Delay , SimNode_ExtFuncCall >(lib,"SDL_Delay","SDL_Delay")
		->args({"ms"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:281:34
	makeExtern< void (*)(Uint64) , SDL_DelayNS , SimNode_ExtFuncCall >(lib,"SDL_DelayNS","SDL_DelayNS")
		->args({"ns"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:299:34
	makeExtern< void (*)(Uint64) , SDL_DelayPrecise , SimNode_ExtFuncCall >(lib,"SDL_DelayPrecise","SDL_DelayPrecise")
		->args({"ns"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_timer.h:445:34
	makeExtern< bool (*)(unsigned int) , SDL_RemoveTimer , SimNode_ExtFuncCall >(lib,"SDL_RemoveTimer","SDL_RemoveTimer")
		->args({"id"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:121:40
	makeExtern< struct SDL_Tray * (*)(struct SDL_Surface *,const char *) , SDL_CreateTray , SimNode_ExtFuncCall >(lib,"SDL_CreateTray","SDL_CreateTray")
		->args({"icon","tooltip"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:136:34
	makeExtern< void (*)(struct SDL_Tray *,struct SDL_Surface *) , SDL_SetTrayIcon , SimNode_ExtFuncCall >(lib,"SDL_SetTrayIcon","SDL_SetTrayIcon")
		->args({"tray","icon"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:151:34
	makeExtern< void (*)(struct SDL_Tray *,const char *) , SDL_SetTrayTooltip , SimNode_ExtFuncCall >(lib,"SDL_SetTrayTooltip","SDL_SetTrayTooltip")
		->args({"tray","tooltip"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:175:44
	makeExtern< struct SDL_TrayMenu * (*)(struct SDL_Tray *) , SDL_CreateTrayMenu , SimNode_ExtFuncCall >(lib,"SDL_CreateTrayMenu","SDL_CreateTrayMenu")
		->args({"tray"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:199:44
	makeExtern< struct SDL_TrayMenu * (*)(struct SDL_TrayEntry *) , SDL_CreateTraySubmenu , SimNode_ExtFuncCall >(lib,"SDL_CreateTraySubmenu","SDL_CreateTraySubmenu")
		->args({"entry"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:223:44
	makeExtern< struct SDL_TrayMenu * (*)(struct SDL_Tray *) , SDL_GetTrayMenu , SimNode_ExtFuncCall >(lib,"SDL_GetTrayMenu","SDL_GetTrayMenu")
		->args({"tray"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:247:44
	makeExtern< struct SDL_TrayMenu * (*)(struct SDL_TrayEntry *) , SDL_GetTraySubmenu , SimNode_ExtFuncCall >(lib,"SDL_GetTraySubmenu","SDL_GetTraySubmenu")
		->args({"entry"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:267:52
	makeExtern< const struct SDL_TrayEntry ** (*)(struct SDL_TrayMenu *,int *) , SDL_GetTrayEntries , SimNode_ExtFuncCall >(lib,"SDL_GetTrayEntries","SDL_GetTrayEntries")
		->args({"menu","count"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:282:34
	makeExtern< void (*)(struct SDL_TrayEntry *) , SDL_RemoveTrayEntry , SimNode_ExtFuncCall >(lib,"SDL_RemoveTrayEntry","SDL_RemoveTrayEntry")
		->args({"entry"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:310:45
	makeExtern< struct SDL_TrayEntry * (*)(struct SDL_TrayMenu *,int,const char *,unsigned int) , SDL_InsertTrayEntryAt , SimNode_ExtFuncCall >(lib,"SDL_InsertTrayEntryAt","SDL_InsertTrayEntryAt")
		->args({"menu","pos","label","flags"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:332:34
	makeExtern< void (*)(struct SDL_TrayEntry *,const char *) , SDL_SetTrayEntryLabel , SimNode_ExtFuncCall >(lib,"SDL_SetTrayEntryLabel","SDL_SetTrayEntryLabel")
		->args({"entry","label"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:351:42
	makeExtern< const char * (*)(struct SDL_TrayEntry *) , SDL_GetTrayEntryLabel , SimNode_ExtFuncCall >(lib,"SDL_GetTrayEntryLabel","SDL_GetTrayEntryLabel")
		->args({"entry"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:370:34
	makeExtern< void (*)(struct SDL_TrayEntry *,bool) , SDL_SetTrayEntryChecked , SimNode_ExtFuncCall >(lib,"SDL_SetTrayEntryChecked","SDL_SetTrayEntryChecked")
		->args({"entry","checked"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:389:34
	makeExtern< bool (*)(struct SDL_TrayEntry *) , SDL_GetTrayEntryChecked , SimNode_ExtFuncCall >(lib,"SDL_GetTrayEntryChecked","SDL_GetTrayEntryChecked")
		->args({"entry"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:406:34
	makeExtern< void (*)(struct SDL_TrayEntry *,bool) , SDL_SetTrayEntryEnabled , SimNode_ExtFuncCall >(lib,"SDL_SetTrayEntryEnabled","SDL_SetTrayEntryEnabled")
		->args({"entry","enabled"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:423:34
	makeExtern< bool (*)(struct SDL_TrayEntry *) , SDL_GetTrayEntryEnabled , SimNode_ExtFuncCall >(lib,"SDL_GetTrayEntryEnabled","SDL_GetTrayEntryEnabled")
		->args({"entry"})
		->addToModule(*this, SideEffects::worstDefault);
makeExtern<decltype(&SDL_SetTrayEntryCallback), SDL_SetTrayEntryCallback, SimNode_ExtFuncCall>(lib,"SDL_SetTrayEntryCallback","SDL_SetTrayEntryCallbackAddress")->args({"entry","callback","userdata"})->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:453:34
	makeExtern< void (*)(struct SDL_TrayEntry *) , SDL_ClickTrayEntry , SimNode_ExtFuncCall >(lib,"SDL_ClickTrayEntry","SDL_ClickTrayEntry")
		->args({"entry"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:469:34
	makeExtern< void (*)(struct SDL_Tray *) , SDL_DestroyTray , SimNode_ExtFuncCall >(lib,"SDL_DestroyTray","SDL_DestroyTray")
		->args({"tray"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:484:44
	makeExtern< struct SDL_TrayMenu * (*)(struct SDL_TrayEntry *) , SDL_GetTrayEntryParent , SimNode_ExtFuncCall >(lib,"SDL_GetTrayEntryParent","SDL_GetTrayEntryParent")
		->args({"entry"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:504:45
	makeExtern< struct SDL_TrayEntry * (*)(struct SDL_TrayMenu *) , SDL_GetTrayMenuParentEntry , SimNode_ExtFuncCall >(lib,"SDL_GetTrayMenuParentEntry","SDL_GetTrayMenuParentEntry")
		->args({"menu"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:524:40
	makeExtern< struct SDL_Tray * (*)(struct SDL_TrayMenu *) , SDL_GetTrayMenuParentTray , SimNode_ExtFuncCall >(lib,"SDL_GetTrayMenuParentTray","SDL_GetTrayMenuParentTray")
		->args({"menu"})
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_tray.h:536:34
	makeExtern< void (*)() , SDL_UpdateTrays , SimNode_ExtFuncCall >(lib,"SDL_UpdateTrays","SDL_UpdateTrays")
		->addToModule(*this, SideEffects::worstDefault);
// from SDL3/SDL_version.h:160:33
	makeExtern< int (*)() , SDL_GetVersion , SimNode_ExtFuncCall >(lib,"SDL_GetVersion","SDL_GetVersion")
		->addToModule(*this, SideEffects::worstDefault);
