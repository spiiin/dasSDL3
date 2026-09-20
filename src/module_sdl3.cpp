#include "daScript/daScript.h"
#include "daScript/ast/ast_handle.h"
#include "sdl3_adapters.h"
#include "sdl3_input.h"
#include "sdl3_audio.h"
#include "sdl3_pixels.h"
#include "sdl3_geometry.h"
#include "sdl3_gpu.h"
#include "sdl3_gpu_swapchain.h"
#include "sdl3_gpu_transfer.h"
#include "sdl3_gpu_texture_transfer.h"
#include "sdl3_gpu_image.h"
#include "sdl3_gpu_recording.h"
#include "sdl3_gpu_utilities.h"
#include "sdl3_gpu_volume.h"
#include "sdl3_gpu_fences.h"
#include "sdl3_gpu_native.h"
#ifdef DASSDL3_TYPES_INCLUDE
#include DASSDL3_TYPES_INCLUDE
#else
#include "generated/sdl3_types.inc"
#endif
#include "sdl3_texture_load.h"
#ifdef DASSDL3_TESTING
#include "../tests/resource_probe.h"
#include "../tests/input_probe.h"
#include "../tests/audio_probe.h"
#include "../tests/geometry_probe.h"
#include "../tests/gpu_probe.h"
#include "../tests/gpu_native_fences_probe.h"
#include "../tests/gpu_raw_probe.h"
#include "../tests/gpu_recording_probe.h"
#include "../tests/gpu_vertex_buffers_probe.h"
#include "../tests/gpu_astc_probe.h"
#include "../tests/gpu_volume_probe.h"
#include "../tests/gpu_sampler_probe.h"
#include "../tests/gpu_shader_probe.h"
#include "../tests/gpu_pipeline_probe.h"
#include "../tests/gpu_types_probe.h"
#include "../tests/gpu_pipeline_types_probe.h"
#endif
static_assert(SDL_VERSION == 3002018, "Regenerate and test bindings when updating SDL3");

namespace das {
class Module_dasSDL3 : public Module {
public:
    #ifdef DASSDL3_AOT_HEADER
    ModuleAotType aotRequire(TextWriter & tw) const override {
        tw << "#include \"" << DASSDL3_AOT_HEADER << "\"\n";
        return ModuleAotType::cpp;
    }
    #endif
    Module_dasSDL3() : Module("sdl3") {
        ModuleLibrary lib(this);
        lib.addBuiltInModule();
        #ifdef DASSDL3_REGISTRATION_INCLUDE
        #include DASSDL3_REGISTRATION_INCLUDE
        #else
        #include "generated/sdl3_functions.inc"
        #endif
        addExtern<DAS_BIND_FUN(SDL_AcquireGPUSwapchainTextureRef)>(*this, lib, "SDL_AcquireGPUSwapchainTextureRef", SideEffects::worstDefault, "SDL_AcquireGPUSwapchainTextureRef");
        addExtern<DAS_BIND_FUN(SDL_WaitAndAcquireGPUSwapchainTextureRef)>(*this, lib, "SDL_WaitAndAcquireGPUSwapchainTextureRef", SideEffects::worstDefault, "SDL_WaitAndAcquireGPUSwapchainTextureRef");
        addExtern<DAS_BIND_FUN(SDL_BeginGPURenderPassArray)>(*this, lib, "SDL_BeginGPURenderPassArray", SideEffects::worstDefault, "SDL_BeginGPURenderPassArray");
        addExtern<DAS_BIND_FUN(SDL_BeginGPUComputePassArray)>(*this, lib, "SDL_BeginGPUComputePassArray", SideEffects::worstDefault, "SDL_BeginGPUComputePassArray");
        addExtern<DAS_BIND_FUN(SDL_BindGPUVertexBuffersArray)>(*this, lib, "SDL_BindGPUVertexBuffersArray", SideEffects::worstDefault, "SDL_BindGPUVertexBuffersArray");
        addExtern<DAS_BIND_FUN(SDL_BindGPUVertexSamplersArray)>(*this, lib, "SDL_BindGPUVertexSamplersArray", SideEffects::worstDefault, "SDL_BindGPUVertexSamplersArray");
        addExtern<DAS_BIND_FUN(SDL_BindGPUVertexStorageTexturesArray)>(*this, lib, "SDL_BindGPUVertexStorageTexturesArray", SideEffects::worstDefault, "SDL_BindGPUVertexStorageTexturesArray");
        addExtern<DAS_BIND_FUN(SDL_BindGPUVertexStorageBuffersArray)>(*this, lib, "SDL_BindGPUVertexStorageBuffersArray", SideEffects::worstDefault, "SDL_BindGPUVertexStorageBuffersArray");
        addExtern<DAS_BIND_FUN(SDL_BindGPUFragmentSamplersArray)>(*this, lib, "SDL_BindGPUFragmentSamplersArray", SideEffects::worstDefault, "SDL_BindGPUFragmentSamplersArray");
        addExtern<DAS_BIND_FUN(SDL_BindGPUFragmentStorageTexturesArray)>(*this, lib, "SDL_BindGPUFragmentStorageTexturesArray", SideEffects::worstDefault, "SDL_BindGPUFragmentStorageTexturesArray");
        addExtern<DAS_BIND_FUN(SDL_BindGPUFragmentStorageBuffersArray)>(*this, lib, "SDL_BindGPUFragmentStorageBuffersArray", SideEffects::worstDefault, "SDL_BindGPUFragmentStorageBuffersArray");
        addExtern<DAS_BIND_FUN(SDL_BindGPUComputeSamplersArray)>(*this, lib, "SDL_BindGPUComputeSamplersArray", SideEffects::worstDefault, "SDL_BindGPUComputeSamplersArray");
        addExtern<DAS_BIND_FUN(SDL_BindGPUComputeStorageTexturesArray)>(*this, lib, "SDL_BindGPUComputeStorageTexturesArray", SideEffects::worstDefault, "SDL_BindGPUComputeStorageTexturesArray");
        addExtern<DAS_BIND_FUN(SDL_BindGPUComputeStorageBuffersArray)>(*this, lib, "SDL_BindGPUComputeStorageBuffersArray", SideEffects::worstDefault, "SDL_BindGPUComputeStorageBuffersArray");
        addExtern<DAS_BIND_FUN(SDL_PushGPUVertexUniformDataArray)>(*this, lib, "SDL_PushGPUVertexUniformDataArray", SideEffects::worstDefault, "SDL_PushGPUVertexUniformDataArray");
        addExtern<DAS_BIND_FUN(SDL_PushGPUFragmentUniformDataArray)>(*this, lib, "SDL_PushGPUFragmentUniformDataArray", SideEffects::worstDefault, "SDL_PushGPUFragmentUniformDataArray");
        addExtern<DAS_BIND_FUN(SDL_PushGPUComputeUniformDataArray)>(*this, lib, "SDL_PushGPUComputeUniformDataArray", SideEffects::worstDefault, "SDL_PushGPUComputeUniformDataArray");
        addExtern<DAS_BIND_FUN(SDL_WaitForGPUFencesArray)>(*this, lib, "SDL_WaitForGPUFencesArray", SideEffects::worstDefault, "SDL_WaitForGPUFencesArray");
        #ifdef DASSDL3_TESTING
        addExtern<DAS_BIND_FUN(sdl3_test::raw_properties)>(*this, lib, "SDLTest_raw_properties", SideEffects::worstDefault, "sdl3_test::raw_properties");
        addExtern<DAS_BIND_FUN(sdl3_test::raw_destroy_properties)>(*this, lib, "SDLTest_raw_destroy_properties", SideEffects::worstDefault, "sdl3_test::raw_destroy_properties");
        addExtern<DAS_BIND_FUN(sdl3_test::raw_shader_info)>(*this, lib, "SDLTest_raw_shader_info", SideEffects::worstDefault, "sdl3_test::raw_shader_info");
        addExtern<DAS_BIND_FUN(sdl3_test::raw_compute_info)>(*this, lib, "SDLTest_raw_compute_info", SideEffects::worstDefault, "sdl3_test::raw_compute_info");
        addExtern<DAS_BIND_FUN(sdl3_test::raw_pipeline_info)>(*this, lib, "SDLTest_raw_pipeline_info", SideEffects::worstDefault, "sdl3_test::raw_pipeline_info");
        addExtern<DAS_BIND_FUN(sdl3_test::raw_fill_upload)>(*this, lib, "SDLTest_raw_fill_upload", SideEffects::worstDefault, "sdl3_test::raw_fill_upload");
        addExtern<DAS_BIND_FUN(sdl3_test::raw_uniform)>(*this, lib, "SDLTest_raw_uniform", SideEffects::worstDefault, "sdl3_test::raw_uniform");
        addExtern<DAS_BIND_FUN(sdl3_test::raw_check_words)>(*this, lib, "SDLTest_raw_check_words", SideEffects::worstDefault, "sdl3_test::raw_check_words");
        addExtern<DAS_BIND_FUN(sdl3_test::raw_check_pixels)>(*this, lib, "SDLTest_raw_check_pixels", SideEffects::worstDefault, "sdl3_test::raw_check_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::raw_check_copy)>(*this, lib, "SDLTest_raw_check_copy", SideEffects::worstDefault, "sdl3_test::raw_check_copy");
        addExtern<DAS_BIND_FUN(sdl3_test::native_fence_array_bounds)>(*this, lib, "SDLTestNativeFenceArrayBounds", SideEffects::worstDefault, "sdl3_test::native_fence_array_bounds");
        #endif
        addExtern<DAS_BIND_FUN(SDL_AcquireGPUCommandBufferChecked)>(*this, lib, "SDL_AcquireGPUCommandBufferChecked", SideEffects::worstDefault, "SDL_AcquireGPUCommandBufferChecked");
        addExtern<DAS_BIND_FUN(SDL_BeginGPURenderPassChecked)>(*this, lib, "SDL_BeginGPURenderPassChecked", SideEffects::worstDefault, "SDL_BeginGPURenderPassChecked");
        addExtern<DAS_BIND_FUN(SDL_EndGPURenderPassChecked)>(*this, lib, "SDL_EndGPURenderPassChecked", SideEffects::worstDefault, "SDL_EndGPURenderPassChecked");
        addExtern<DAS_BIND_FUN(SDL_CancelGPUCommandBufferChecked)>(*this, lib, "SDL_CancelGPUCommandBufferChecked", SideEffects::worstDefault, "SDL_CancelGPUCommandBufferChecked");
        addExtern<DAS_BIND_FUN(SDL_SubmitGPUCommandBufferChecked)>(*this, lib, "SDL_SubmitGPUCommandBufferChecked", SideEffects::worstDefault, "SDL_SubmitGPUCommandBufferChecked");
        addExtern<DAS_BIND_FUN(SDL_BindGPUGraphicsPipelineChecked)>(*this, lib, "SDL_BindGPUGraphicsPipelineChecked", SideEffects::worstDefault, "SDL_BindGPUGraphicsPipelineChecked");
        addExtern<DAS_BIND_FUN(SDL_SetGPUViewportChecked)>(*this, lib, "SDL_SetGPUViewportChecked", SideEffects::worstDefault, "SDL_SetGPUViewportChecked");
        addExtern<DAS_BIND_FUN(SDL_SetGPUScissorChecked)>(*this, lib, "SDL_SetGPUScissorChecked", SideEffects::worstDefault, "SDL_SetGPUScissorChecked");
        addExtern<DAS_BIND_FUN(SDL_SetGPUBlendConstantsChecked)>(*this, lib, "SDL_SetGPUBlendConstantsChecked", SideEffects::worstDefault, "SDL_SetGPUBlendConstantsChecked");
        addExtern<DAS_BIND_FUN(SDL_BindGPUVertexBuffersChecked)>(*this, lib, "SDL_BindGPUVertexBuffersChecked", SideEffects::worstDefault, "SDL_BindGPUVertexBuffersChecked");
        addExtern<DAS_BIND_FUN(SDL_BindGPUIndexBufferChecked)>(*this, lib, "SDL_BindGPUIndexBufferChecked", SideEffects::worstDefault, "SDL_BindGPUIndexBufferChecked");
        addExtern<DAS_BIND_FUN(SDL_BindGPUSamplersChecked)>(*this, lib, "SDL_BindGPUSamplersChecked", SideEffects::worstDefault, "SDL_BindGPUSamplersChecked");
        addExtern<DAS_BIND_FUN(SDL_PushGPUUniformBytesChecked)>(*this, lib, "SDL_PushGPUUniformBytesChecked", SideEffects::worstDefault, "SDL_PushGPUUniformBytesChecked");
        addExtern<DAS_BIND_FUN(SDL_PushGPUUniformVectorsChecked)>(*this, lib, "SDL_PushGPUUniformVectorsChecked", SideEffects::worstDefault, "SDL_PushGPUUniformVectorsChecked");
        addExtern<DAS_BIND_FUN(SDL_DrawGPUPrimitivesChecked)>(*this, lib, "SDL_DrawGPUPrimitivesChecked", SideEffects::worstDefault, "SDL_DrawGPUPrimitivesChecked");
        addExtern<DAS_BIND_FUN(SDL_DrawGPUIndexedPrimitivesChecked)>(*this, lib, "SDL_DrawGPUIndexedPrimitivesChecked", SideEffects::worstDefault, "SDL_DrawGPUIndexedPrimitivesChecked");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUCheckedGraphicsPipeline)>(*this, lib, "SDL_CreateGPUCheckedGraphicsPipeline", SideEffects::worstDefault, "SDL_CreateGPUCheckedGraphicsPipeline");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUCheckedGraphicsPipeline)>(*this, lib, "SDL_ReleaseGPUCheckedGraphicsPipeline", SideEffects::worstDefault, "SDL_ReleaseGPUCheckedGraphicsPipeline");
        addExtern<DAS_BIND_FUN(SDL_GetGPUCheckedGraphicsPipelineInfo)>(*this, lib, "SDL_GetGPUCheckedGraphicsPipelineInfo", SideEffects::worstDefault, "SDL_GetGPUCheckedGraphicsPipelineInfo");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUCheckedShader)>(*this, lib, "SDL_CreateGPUCheckedShader", SideEffects::worstDefault, "SDL_CreateGPUCheckedShader");
        addExtern<DAS_BIND_FUN(SDL_LoadGPUCheckedShader)>(*this, lib, "SDL_LoadGPUCheckedShader", SideEffects::worstDefault, "SDL_LoadGPUCheckedShader");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUCheckedShader)>(*this, lib, "SDL_ReleaseGPUCheckedShader", SideEffects::worstDefault, "SDL_ReleaseGPUCheckedShader");
        addExtern<DAS_BIND_FUN(SDL_GetGPUCheckedShaderInfo)>(*this, lib, "SDL_GetGPUCheckedShaderInfo", SideEffects::worstDefault, "SDL_GetGPUCheckedShaderInfo");
        addExtern<DAS_BIND_FUN(SDL_GetGPUCheckedShaderEntryPoint)>(*this, lib, "SDL_GetGPUCheckedShaderEntryPoint", SideEffects::worstDefault, "SDL_GetGPUCheckedShaderEntryPoint");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUCheckedSampler)>(*this, lib, "SDL_CreateGPUCheckedSampler", SideEffects::worstDefault, "SDL_CreateGPUCheckedSampler");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUCheckedSampler)>(*this, lib, "SDL_ReleaseGPUCheckedSampler", SideEffects::worstDefault, "SDL_ReleaseGPUCheckedSampler");
        addExtern<DAS_BIND_FUN(SDL_GetGPUCheckedSamplerInfo)>(*this, lib, "SDL_GetGPUCheckedSamplerInfo", SideEffects::worstDefault, "SDL_GetGPUCheckedSamplerInfo");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUVolume)>(*this, lib, "SDL_CreateGPUVolume", SideEffects::worstDefault, "SDL_CreateGPUVolume");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUVolume)>(*this, lib, "SDL_ReleaseGPUVolume", SideEffects::worstDefault, "SDL_ReleaseGPUVolume");
        addExtern<DAS_BIND_FUN(SDL_UploadGPUVolume)>(*this, lib, "SDL_UploadGPUVolume", SideEffects::worstDefault, "SDL_UploadGPUVolume");
        addExtern<DAS_BIND_FUN(SDL_CopyGPUVolume)>(*this, lib, "SDL_CopyGPUVolume", SideEffects::worstDefault, "SDL_CopyGPUVolume");
        addExtern<DAS_BIND_FUN(SDL_RequestGPUVolumeReadback)>(*this, lib, "SDL_RequestGPUVolumeReadback", SideEffects::worstDefault, "SDL_RequestGPUVolumeReadback");
        addExtern<DAS_BIND_FUN(SDL_SetErrorMessage)>(*this, lib, "SDL_SetErrorMessage", SideEffects::worstDefault, "SDL_SetErrorMessage");
        addExtern<DAS_BIND_FUN(SDL_GPURecordingDiscard)>(*this, lib, "SDL_GPURecordingDiscard", SideEffects::worstDefault, "SDL_GPURecordingDiscard");
        addExtern<DAS_BIND_FUN(SDL_LoadBMPTextureOwned)>(*this, lib, "SDL_LoadBMPTextureOwned", SideEffects::worstDefault, "SDL_LoadBMPTextureOwned");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUFloatVertexBuffer)>(*this, lib, "SDL_CreateGPUFloatVertexBuffer", SideEffects::worstDefault, "SDL_CreateGPUFloatVertexBuffer");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUCheckedIndexBuffer)>(*this, lib, "SDL_CreateGPUCheckedIndexBuffer", SideEffects::worstDefault, "SDL_CreateGPUCheckedIndexBuffer");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUCheckedIndexBuffer)>(*this, lib, "SDL_ReleaseGPUCheckedIndexBuffer", SideEffects::worstDefault, "SDL_ReleaseGPUCheckedIndexBuffer");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUColorTargetTexture)>(*this, lib, "SDL_CreateGPUColorTargetTexture", SideEffects::worstDefault, "SDL_CreateGPUColorTargetTexture");
        addExtern<DAS_BIND_FUN(SDL_GenerateGPUTextureMipmapsChecked)>(*this, lib, "SDL_GenerateGPUTextureMipmapsChecked", SideEffects::worstDefault, "SDL_GenerateGPUTextureMipmapsChecked");
        addExtern<DAS_BIND_FUN(SDL_BlitGPUTextureChecked)>(*this, lib, "SDL_BlitGPUTextureChecked", SideEffects::worstDefault, "SDL_BlitGPUTextureChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUWindowPresentSupported)>(*this, lib, "SDL_GPUWindowPresentSupported", SideEffects::worstDefault, "SDL_GPUWindowPresentSupported");
        addExtern<DAS_BIND_FUN(SDL_GPUWindowCompositionSupported)>(*this, lib, "SDL_GPUWindowCompositionSupported", SideEffects::worstDefault, "SDL_GPUWindowCompositionSupported");
        addExtern<DAS_BIND_FUN(SDL_GPUWindowFormatChecked)>(*this, lib, "SDL_GPUWindowFormatChecked", SideEffects::worstDefault, "SDL_GPUWindowFormatChecked");
        addExtern<DAS_BIND_FUN(SDL_ConfigureGPUSwapchainChecked)>(*this, lib, "SDL_ConfigureGPUSwapchainChecked", SideEffects::worstDefault, "SDL_ConfigureGPUSwapchainChecked");
        addExtern<DAS_BIND_FUN(SDL_SetGPUFramesInFlightChecked)>(*this, lib, "SDL_SetGPUFramesInFlightChecked", SideEffects::worstDefault, "SDL_SetGPUFramesInFlightChecked");
        addExtern<DAS_BIND_FUN(SDL_WaitGPUSwapchainChecked)>(*this, lib, "SDL_WaitGPUSwapchainChecked", SideEffects::worstDefault, "SDL_WaitGPUSwapchainChecked");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUTypedTransferTexture)>(*this, lib, "SDL_CreateGPUTypedTransferTexture", SideEffects::worstDefault, "SDL_CreateGPUTypedTransferTexture");
        addExtern<DAS_BIND_FUN(SDL_GPUDriverCountChecked)>(*this, lib, "SDL_GPUDriverCountChecked", SideEffects::worstDefault, "SDL_GPUDriverCountChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUDriverNameCopy)>(*this, lib, "SDL_GPUDriverNameCopy", SideEffects::worstDefault, "SDL_GPUDriverNameCopy");
        addExtern<DAS_BIND_FUN(SDL_GPUShaderSupportChecked)>(*this, lib, "SDL_GPUShaderSupportChecked", SideEffects::worstDefault, "SDL_GPUShaderSupportChecked");
        addExtern<DAS_BIND_FUN(SDL_SetGPUDataBufferNameChecked)>(*this, lib, "SDL_SetGPUDataBufferNameChecked", SideEffects::worstDefault, "SDL_SetGPUDataBufferNameChecked");
        addExtern<DAS_BIND_FUN(SDL_SetGPUTransferTextureNameChecked)>(*this, lib, "SDL_SetGPUTransferTextureNameChecked", SideEffects::worstDefault, "SDL_SetGPUTransferTextureNameChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUTextureTransferSupportedChecked)>(*this, lib, "SDL_GPUTextureTransferSupportedChecked", SideEffects::worstDefault, "SDL_GPUTextureTransferSupportedChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUFormatBlockExtentChecked)>(*this, lib, "SDL_GPUFormatBlockExtentChecked", SideEffects::worstDefault, "SDL_GPUFormatBlockExtentChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUFormatBlockSizeChecked)>(*this, lib, "SDL_GPUFormatBlockSizeChecked", SideEffects::worstDefault, "SDL_GPUFormatBlockSizeChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUFormatSizeChecked)>(*this, lib, "SDL_GPUFormatSizeChecked", SideEffects::worstDefault, "SDL_GPUFormatSizeChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUFormatSupportedChecked)>(*this, lib, "SDL_GPUFormatSupportedChecked", SideEffects::worstDefault, "SDL_GPUFormatSupportedChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUSampleCountSupportedChecked)>(*this, lib, "SDL_GPUSampleCountSupportedChecked", SideEffects::worstDefault, "SDL_GPUSampleCountSupportedChecked");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUColorTransferTexture)>(*this, lib, "SDL_CreateGPUColorTransferTexture", SideEffects::worstDefault, "SDL_CreateGPUColorTransferTexture");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUTransferTexture)>(*this, lib, "SDL_CreateGPUTransferTexture", SideEffects::worstDefault, "SDL_CreateGPUTransferTexture");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUTransferTexture)>(*this, lib, "SDL_ReleaseGPUTransferTexture", SideEffects::worstDefault, "SDL_ReleaseGPUTransferTexture");
        addExtern<DAS_BIND_FUN(SDL_UploadGPUTextureRegion)>(*this, lib, "SDL_UploadGPUTextureRegion", SideEffects::worstDefault, "SDL_UploadGPUTextureRegion");
        addExtern<DAS_BIND_FUN(SDL_CopyGPUTextureRegion)>(*this, lib, "SDL_CopyGPUTextureRegion", SideEffects::worstDefault, "SDL_CopyGPUTextureRegion");
        addExtern<DAS_BIND_FUN(SDL_RequestGPUTextureReadback)>(*this, lib, "SDL_RequestGPUTextureReadback", SideEffects::worstDefault, "SDL_RequestGPUTextureReadback");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUDataBuffer)>(*this, lib, "SDL_CreateGPUDataBuffer", SideEffects::worstDefault, "SDL_CreateGPUDataBuffer");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUDataBuffer)>(*this, lib, "SDL_ReleaseGPUDataBuffer", SideEffects::worstDefault, "SDL_ReleaseGPUDataBuffer");
        addExtern<DAS_BIND_FUN(SDL_UpdateGPUDataBuffer)>(*this, lib, "SDL_UpdateGPUDataBuffer", SideEffects::worstDefault, "SDL_UpdateGPUDataBuffer");
        addExtern<DAS_BIND_FUN(SDL_CopyGPUDataBuffer)>(*this, lib, "SDL_CopyGPUDataBuffer", SideEffects::worstDefault, "SDL_CopyGPUDataBuffer");
        addExtern<DAS_BIND_FUN(SDL_RequestGPUBufferReadback)>(*this, lib, "SDL_RequestGPUBufferReadback", SideEffects::worstDefault, "SDL_RequestGPUBufferReadback");
        addExtern<DAS_BIND_FUN(SDL_PollGPUReadback)>(*this, lib, "SDL_PollGPUReadback", SideEffects::worstDefault, "SDL_PollGPUReadback");
        addExtern<DAS_BIND_FUN(SDL_WaitGPUReadback)>(*this, lib, "SDL_WaitGPUReadback", SideEffects::worstDefault, "SDL_WaitGPUReadback");
        addExtern<DAS_BIND_FUN(SDL_ReadGPUReadback)>(*this, lib, "SDL_ReadGPUReadback", SideEffects::worstDefault, "SDL_ReadGPUReadback");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUReadback)>(*this, lib, "SDL_ReleaseGPUReadback", SideEffects::worstDefault, "SDL_ReleaseGPUReadback");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUDeviceScoped)>(*this, lib, "SDL_CreateGPUDeviceScoped", SideEffects::worstDefault, "SDL_CreateGPUDeviceScoped");
        addExtern<DAS_BIND_FUN(SDL_DestroyGPUDeviceScoped)>(*this, lib, "SDL_DestroyGPUDeviceScoped", SideEffects::worstDefault, "SDL_DestroyGPUDeviceScoped");
        addExtern<DAS_BIND_FUN(SDL_ClaimGPUWindowScoped)>(*this, lib, "SDL_ClaimGPUWindowScoped", SideEffects::worstDefault, "SDL_ClaimGPUWindowScoped");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUWindowScoped)>(*this, lib, "SDL_ReleaseGPUWindowScoped", SideEffects::worstDefault, "SDL_ReleaseGPUWindowScoped");
        addExtern<DAS_BIND_FUN(SDL_GPUWindowClaimedBy)>(*this, lib, "SDL_GPUWindowClaimedBy", SideEffects::worstDefault, "SDL_GPUWindowClaimedBy");
        addExtern<DAS_BIND_FUN(SDL_MakeVertex), SimNode_ExtFuncCallAndCopyOrMove>(*this, lib, "SDL_MakeVertex", SideEffects::none, "SDL_MakeVertex");
        addExtern<DAS_BIND_FUN(SDL_RenderGeometryVertices)>(*this, lib, "SDL_RenderGeometryVertices", SideEffects::worstDefault, "SDL_RenderGeometryVertices");
        addExtern<DAS_BIND_FUN(SDL_RenderGeometryIndices)>(*this, lib, "SDL_RenderGeometryIndices", SideEffects::worstDefault, "SDL_RenderGeometryIndices");
        addExtern<DAS_BIND_FUN(SDL_RGBA8BufferSize)>(*this, lib, "SDL_RGBA8BufferSize", SideEffects::worstDefault, "SDL_RGBA8BufferSize");
        addExtern<DAS_BIND_FUN(SDL_CreateRGBA8Texture)>(*this, lib, "SDL_CreateRGBA8Texture", SideEffects::worstDefault, "SDL_CreateRGBA8Texture");
        addExtern<DAS_BIND_FUN(SDL_UploadRGBA8)>(*this, lib, "SDL_UploadRGBA8", SideEffects::worstDefault, "SDL_UploadRGBA8");
        addExtern<DAS_BIND_FUN(SDL_ReadPixelsOwned)>(*this, lib, "SDL_ReadPixelsOwned", SideEffects::worstDefault, "SDL_ReadPixelsOwned");
        addExtern<DAS_BIND_FUN(SDL_SurfaceSizeRef)>(*this, lib, "SDL_SurfaceSizeRef", SideEffects::worstDefault, "SDL_SurfaceSizeRef");
        addExtern<DAS_BIND_FUN(SDL_CopySurfaceRGBA8)>(*this, lib, "SDL_CopySurfaceRGBA8", SideEffects::worstDefault, "SDL_CopySurfaceRGBA8");
        addExtern<DAS_BIND_FUN(SDL_LoadWavOwned)>(*this, lib, "SDL_LoadWavOwned", SideEffects::worstDefault, "SDL_LoadWavOwned");
        addExtern<DAS_BIND_FUN(SDL_DestroyWav)>(*this, lib, "SDL_DestroyWav", SideEffects::worstDefault, "SDL_DestroyWav");
        addExtern<DAS_BIND_FUN(SDL_WavSpec), SimNode_ExtFuncCallAndCopyOrMove>(*this, lib, "SDL_WavSpec", SideEffects::none, "SDL_WavSpec");
        addExtern<DAS_BIND_FUN(SDL_WavSize)>(*this, lib, "SDL_WavSize", SideEffects::none, "SDL_WavSize");
        addExtern<DAS_BIND_FUN(SDL_AudioSpecFormat)>(*this, lib, "SDL_AudioSpecFormat", SideEffects::none, "SDL_AudioSpecFormat");
        addExtern<DAS_BIND_FUN(SDL_MakeAudioSpec), SimNode_ExtFuncCallAndCopyOrMove>(*this, lib, "SDL_MakeAudioSpec", SideEffects::none, "SDL_MakeAudioSpec");
        addExtern<DAS_BIND_FUN(SDL_CreateAudioStreamRef)>(*this, lib, "SDL_CreateAudioStreamRef", SideEffects::worstDefault, "SDL_CreateAudioStreamRef");
        addExtern<DAS_BIND_FUN(SDL_OpenPlaybackStream)>(*this, lib, "SDL_OpenPlaybackStream", SideEffects::worstDefault, "SDL_OpenPlaybackStream");
        addExtern<DAS_BIND_FUN(SDL_QueueWav)>(*this, lib, "SDL_QueueWav", SideEffects::worstDefault, "SDL_QueueWav");
        addExtern<DAS_BIND_FUN(SDL_PutAudioBytes)>(*this, lib, "SDL_PutAudioBytes", SideEffects::worstDefault, "SDL_PutAudioBytes");
        addExtern<DAS_BIND_FUN(SDL_GetAudioBytes)>(*this, lib, "SDL_GetAudioBytes", SideEffects::worstDefault, "SDL_GetAudioBytes");
        addExtern<DAS_BIND_FUN(SDL_ReadKeyEvent)>(*this, lib, "SDL_ReadKeyEvent", SideEffects::worstDefault, "SDL_ReadKeyEvent")->args({"event", "out"});
        addExtern<DAS_BIND_FUN(SDL_KeyScancode)>(*this, lib, "SDL_KeyScancode", SideEffects::none, "SDL_KeyScancode")->args({"key"});
        addExtern<DAS_BIND_FUN(SDL_ReadMouseMotionEvent)>(*this, lib, "SDL_ReadMouseMotionEvent", SideEffects::worstDefault, "SDL_ReadMouseMotionEvent")->args({"event", "out"});
        addExtern<DAS_BIND_FUN(SDL_ReadMouseButtonEvent)>(*this, lib, "SDL_ReadMouseButtonEvent", SideEffects::worstDefault, "SDL_ReadMouseButtonEvent")->args({"event", "out"});
        addExtern<DAS_BIND_FUN(SDL_ReadMouseWheelEvent)>(*this, lib, "SDL_ReadMouseWheelEvent", SideEffects::worstDefault, "SDL_ReadMouseWheelEvent")->args({"event", "out"});
        addExtern<DAS_BIND_FUN(SDL_MouseWheelFlipped)>(*this, lib, "SDL_MouseWheelFlipped", SideEffects::none, "SDL_MouseWheelFlipped")->args({"wheel"});
        addExtern<DAS_BIND_FUN(SDL_ReadTextInput)>(*this, lib, "SDL_ReadTextInput", SideEffects::worstDefault, "SDL_ReadTextInput")->args({"event", "text", "context", "at"});
        addExtern<DAS_BIND_FUN(SDL_ReadTextEditing)>(*this, lib, "SDL_ReadTextEditing", SideEffects::worstDefault, "SDL_ReadTextEditing")->args({"event", "text", "start", "length", "context", "at"});
        addExtern<DAS_BIND_FUN(SDL_InputWindowID)>(*this, lib, "SDL_InputWindowID", SideEffects::none, "SDL_InputWindowID")->args({"event"});
        addExtern<DAS_BIND_FUN(SDL_IsScancodeDown)>(*this, lib, "SDL_IsScancodeDown", SideEffects::worstDefault, "SDL_IsScancodeDown")->args({"scancode"});
        addExtern<DAS_BIND_FUN(SDL_GetMouseStateRef)>(*this, lib, "SDL_GetMouseStateRef", SideEffects::worstDefault, "SDL_GetMouseStateRef")->args({"x", "y"});
#ifdef DASSDL3_TESTING
        addExtern<DAS_BIND_FUN(sdl3_test::astc_footprints)>(*this, lib, "SDLTest_astc_footprints", SideEffects::worstDefault, "sdl3_test::astc_footprints");
        addExtern<DAS_BIND_FUN(sdl3_test::volume_fail_upload)>(*this, lib, "SDLTest_volume_fail_upload", SideEffects::worstDefault, "sdl3_test::volume_fail_upload");
        addExtern<DAS_BIND_FUN(sdl3_test::volume_fail_copy)>(*this, lib, "SDLTest_volume_fail_copy", SideEffects::worstDefault, "sdl3_test::volume_fail_copy");
        addExtern<DAS_BIND_FUN(sdl3_test::graphics_pipeline_count)>(*this, lib, "SDLTest_graphics_pipeline_count", SideEffects::worstDefault, "sdl3_test::graphics_pipeline_count");
        addExtern<DAS_BIND_FUN(sdl3_test::graphics_pipeline_exists)>(*this, lib, "SDLTest_graphics_pipeline_exists", SideEffects::worstDefault, "sdl3_test::graphics_pipeline_exists");
        addExtern<DAS_BIND_FUN(sdl3_test::graphics_pipeline_hidden)>(*this, lib, "SDLTest_graphics_pipeline_hidden", SideEffects::worstDefault, "sdl3_test::graphics_pipeline_hidden");
        addExtern<DAS_BIND_FUN(sdl3_test::graphics_pipeline_sorted)>(*this, lib, "SDLTest_graphics_pipeline_sorted", SideEffects::worstDefault, "sdl3_test::graphics_pipeline_sorted");
        addExtern<DAS_BIND_FUN(sdl3_test::graphics_pipeline_thread)>(*this, lib, "SDLTest_graphics_pipeline_thread", SideEffects::worstDefault, "sdl3_test::graphics_pipeline_thread");
        addExtern<DAS_BIND_FUN(sdl3_test::graphics_pipeline_triangle)>(*this, lib, "SDLTest_graphics_pipeline_triangle", SideEffects::worstDefault, "sdl3_test::graphics_pipeline_triangle");
        addExtern<DAS_BIND_FUN(sdl3_test::graphics_pipeline_validation)>(*this, lib, "SDLTest_graphics_pipeline_validation", SideEffects::worstDefault, "sdl3_test::graphics_pipeline_validation");
        addExtern<DAS_BIND_FUN(sdl3_test::shader_count)>(*this, lib, "SDLTest_shader_count", SideEffects::worstDefault, "sdl3_test::shader_count");
        addExtern<DAS_BIND_FUN(sdl3_test::shader_fill_info)>(*this, lib, "SDLTest_shader_fill_info", SideEffects::worstDefault, "sdl3_test::shader_fill_info");
        addExtern<DAS_BIND_FUN(sdl3_test::shader_check_info)>(*this, lib, "SDLTest_shader_check_info", SideEffects::worstDefault, "sdl3_test::shader_check_info");
        addExtern<DAS_BIND_FUN(sdl3_test::shader_exists)>(*this, lib, "SDLTest_shader_exists", SideEffects::worstDefault, "sdl3_test::shader_exists");
        addExtern<DAS_BIND_FUN(sdl3_test::shader_invalid_metadata)>(*this, lib, "SDLTest_shader_invalid_metadata", SideEffects::worstDefault, "sdl3_test::shader_invalid_metadata");
        addExtern<DAS_BIND_FUN(sdl3_test::shader_wrong_thread)>(*this, lib, "SDLTest_shader_wrong_thread", SideEffects::worstDefault, "sdl3_test::shader_wrong_thread");
        addExtern<DAS_BIND_FUN(sdl3_test::shader_hidden_fields_clear)>(*this, lib, "SDLTest_shader_hidden_fields_clear", SideEffects::worstDefault, "sdl3_test::shader_hidden_fields_clear");
        addExtern<DAS_BIND_FUN(sdl3_test::shader_pipeline_pixels)>(*this, lib, "SDLTest_shader_pipeline_pixels", SideEffects::worstDefault, "sdl3_test::shader_pipeline_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::sampler_count)>(*this, lib, "SDLTest_sampler_count", SideEffects::worstDefault, "sdl3_test::sampler_count");
        addExtern<DAS_BIND_FUN(sdl3_test::sampler_exists)>(*this, lib, "SDLTest_sampler_exists", SideEffects::worstDefault, "sdl3_test::sampler_exists");
        addExtern<DAS_BIND_FUN(sdl3_test::sampler_invalid_descriptors)>(*this, lib, "SDLTest_sampler_invalid_descriptors", SideEffects::worstDefault, "sdl3_test::sampler_invalid_descriptors");
        addExtern<DAS_BIND_FUN(sdl3_test::sampler_wrong_thread)>(*this, lib, "SDLTest_sampler_wrong_thread", SideEffects::worstDefault, "sdl3_test::sampler_wrong_thread");
        addExtern<DAS_BIND_FUN(sdl3_test::volume_count)>(*this, lib, "SDLTest_volume_count", SideEffects::worstDefault, "sdl3_test::volume_count");
        addExtern<DAS_BIND_FUN(sdl3_test::volume_exists)>(*this, lib, "SDLTest_volume_exists", SideEffects::worstDefault, "sdl3_test::volume_exists");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUSamplerCreateInfo)>(*this, lib, "SDLTest_fill_GPUSamplerCreateInfo", SideEffects::worstDefault, "sdl3_test::fill_GPUSamplerCreateInfo");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUSamplerCreateInfo)>(*this, lib, "SDLTest_check_GPUSamplerCreateInfo", SideEffects::worstDefault, "sdl3_test::check_GPUSamplerCreateInfo");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUStencilOpState)>(*this, lib, "SDLTest_fill_GPUStencilOpState", SideEffects::worstDefault, "sdl3_test::fill_GPUStencilOpState");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUStencilOpState)>(*this, lib, "SDLTest_check_GPUStencilOpState", SideEffects::worstDefault, "sdl3_test::check_GPUStencilOpState");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUColorTargetBlendState)>(*this, lib, "SDLTest_fill_GPUColorTargetBlendState", SideEffects::worstDefault, "sdl3_test::fill_GPUColorTargetBlendState");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUColorTargetBlendState)>(*this, lib, "SDLTest_check_GPUColorTargetBlendState", SideEffects::worstDefault, "sdl3_test::check_GPUColorTargetBlendState");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUTransferBufferCreateInfo)>(*this, lib, "SDLTest_fill_GPUTransferBufferCreateInfo", SideEffects::worstDefault, "sdl3_test::fill_GPUTransferBufferCreateInfo");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUTransferBufferCreateInfo)>(*this, lib, "SDLTest_check_GPUTransferBufferCreateInfo", SideEffects::worstDefault, "sdl3_test::check_GPUTransferBufferCreateInfo");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUDepthStencilState)>(*this, lib, "SDLTest_fill_GPUDepthStencilState", SideEffects::worstDefault, "sdl3_test::fill_GPUDepthStencilState");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUDepthStencilState)>(*this, lib, "SDLTest_check_GPUDepthStencilState", SideEffects::worstDefault, "sdl3_test::check_GPUDepthStencilState");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUColorTargetDescription)>(*this, lib, "SDLTest_fill_GPUColorTargetDescription", SideEffects::worstDefault, "sdl3_test::fill_GPUColorTargetDescription");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUColorTargetDescription)>(*this, lib, "SDLTest_check_GPUColorTargetDescription", SideEffects::worstDefault, "sdl3_test::check_GPUColorTargetDescription");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUPrimitiveType)>(*this, lib, "SDLTest_echo_SDL_GPUPrimitiveType", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUPrimitiveType");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPULoadOp)>(*this, lib, "SDLTest_echo_SDL_GPULoadOp", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPULoadOp");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUStoreOp)>(*this, lib, "SDLTest_echo_SDL_GPUStoreOp", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUStoreOp");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUIndexElementSize)>(*this, lib, "SDLTest_echo_SDL_GPUIndexElementSize", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUIndexElementSize");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUCubeMapFace)>(*this, lib, "SDLTest_echo_SDL_GPUCubeMapFace", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUCubeMapFace");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUTransferBufferUsage)>(*this, lib, "SDLTest_echo_SDL_GPUTransferBufferUsage", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUTransferBufferUsage");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUShaderStage)>(*this, lib, "SDLTest_echo_SDL_GPUShaderStage", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUShaderStage");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUCompareOp)>(*this, lib, "SDLTest_echo_SDL_GPUCompareOp", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUCompareOp");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUStencilOp)>(*this, lib, "SDLTest_echo_SDL_GPUStencilOp", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUStencilOp");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUBlendOp)>(*this, lib, "SDLTest_echo_SDL_GPUBlendOp", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUBlendOp");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUBlendFactor)>(*this, lib, "SDLTest_echo_SDL_GPUBlendFactor", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUBlendFactor");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUFilter)>(*this, lib, "SDLTest_echo_SDL_GPUFilter", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUFilter");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUSamplerMipmapMode)>(*this, lib, "SDLTest_echo_SDL_GPUSamplerMipmapMode", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUSamplerMipmapMode");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUSamplerAddressMode)>(*this, lib, "SDLTest_echo_SDL_GPUSamplerAddressMode", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUSamplerAddressMode");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUPresentMode)>(*this, lib, "SDLTest_echo_SDL_GPUPresentMode", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUPresentMode");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUSwapchainComposition)>(*this, lib, "SDLTest_echo_SDL_GPUSwapchainComposition", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUSwapchainComposition");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUViewport)>(*this, lib, "SDLTest_fill_GPUViewport", SideEffects::worstDefault, "sdl3_test::fill_GPUViewport");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUViewport)>(*this, lib, "SDLTest_check_GPUViewport", SideEffects::worstDefault, "sdl3_test::check_GPUViewport");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUIndirectDrawCommand)>(*this, lib, "SDLTest_fill_GPUIndirectDrawCommand", SideEffects::worstDefault, "sdl3_test::fill_GPUIndirectDrawCommand");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUIndirectDrawCommand)>(*this, lib, "SDLTest_check_GPUIndirectDrawCommand", SideEffects::worstDefault, "sdl3_test::check_GPUIndirectDrawCommand");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUIndexedIndirectDrawCommand)>(*this, lib, "SDLTest_fill_GPUIndexedIndirectDrawCommand", SideEffects::worstDefault, "sdl3_test::fill_GPUIndexedIndirectDrawCommand");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUIndexedIndirectDrawCommand)>(*this, lib, "SDLTest_check_GPUIndexedIndirectDrawCommand", SideEffects::worstDefault, "sdl3_test::check_GPUIndexedIndirectDrawCommand");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUIndirectDispatchCommand)>(*this, lib, "SDLTest_fill_GPUIndirectDispatchCommand", SideEffects::worstDefault, "sdl3_test::fill_GPUIndirectDispatchCommand");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUIndirectDispatchCommand)>(*this, lib, "SDLTest_check_GPUIndirectDispatchCommand", SideEffects::worstDefault, "sdl3_test::check_GPUIndirectDispatchCommand");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUBufferCreateInfo)>(*this, lib, "SDLTest_fill_GPUBufferCreateInfo", SideEffects::worstDefault, "sdl3_test::fill_GPUBufferCreateInfo");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUBufferCreateInfo)>(*this, lib, "SDLTest_check_GPUBufferCreateInfo", SideEffects::worstDefault, "sdl3_test::check_GPUBufferCreateInfo");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUTextureCreateInfo)>(*this, lib, "SDLTest_fill_GPUTextureCreateInfo", SideEffects::worstDefault, "sdl3_test::fill_GPUTextureCreateInfo");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUTextureCreateInfo)>(*this, lib, "SDLTest_check_GPUTextureCreateInfo", SideEffects::worstDefault, "sdl3_test::check_GPUTextureCreateInfo");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUVertexBufferDescription)>(*this, lib, "SDLTest_fill_GPUVertexBufferDescription", SideEffects::worstDefault, "sdl3_test::fill_GPUVertexBufferDescription");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUVertexBufferDescription)>(*this, lib, "SDLTest_check_GPUVertexBufferDescription", SideEffects::worstDefault, "sdl3_test::check_GPUVertexBufferDescription");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUVertexAttribute)>(*this, lib, "SDLTest_fill_GPUVertexAttribute", SideEffects::worstDefault, "sdl3_test::fill_GPUVertexAttribute");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUVertexAttribute)>(*this, lib, "SDLTest_check_GPUVertexAttribute", SideEffects::worstDefault, "sdl3_test::check_GPUVertexAttribute");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPURasterizerState)>(*this, lib, "SDLTest_fill_GPURasterizerState", SideEffects::worstDefault, "sdl3_test::fill_GPURasterizerState");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPURasterizerState)>(*this, lib, "SDLTest_check_GPURasterizerState", SideEffects::worstDefault, "sdl3_test::check_GPURasterizerState");
        addExtern<DAS_BIND_FUN(sdl3_test::fill_GPUMultisampleState)>(*this, lib, "SDLTest_fill_GPUMultisampleState", SideEffects::worstDefault, "sdl3_test::fill_GPUMultisampleState");
        addExtern<DAS_BIND_FUN(sdl3_test::check_GPUMultisampleState)>(*this, lib, "SDLTest_check_GPUMultisampleState", SideEffects::worstDefault, "sdl3_test::check_GPUMultisampleState");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUTextureType)>(*this, lib, "SDLTest_echo_SDL_GPUTextureType", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUTextureType");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUTextureFormat)>(*this, lib, "SDLTest_echo_SDL_GPUTextureFormat", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUTextureFormat");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUSampleCount)>(*this, lib, "SDLTest_echo_SDL_GPUSampleCount", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUSampleCount");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUVertexInputRate)>(*this, lib, "SDLTest_echo_SDL_GPUVertexInputRate", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUVertexInputRate");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUVertexElementFormat)>(*this, lib, "SDLTest_echo_SDL_GPUVertexElementFormat", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUVertexElementFormat");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUFillMode)>(*this, lib, "SDLTest_echo_SDL_GPUFillMode", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUFillMode");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUCullMode)>(*this, lib, "SDLTest_echo_SDL_GPUCullMode", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUCullMode");
        addExtern<DAS_BIND_FUN(sdl3_test::echo_SDL_GPUFrontFace)>(*this, lib, "SDLTest_echo_SDL_GPUFrontFace", SideEffects::worstDefault, "sdl3_test::echo_SDL_GPUFrontFace");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_recording_devices)>(*this, lib, "SDLTestGPURecordingDevices", SideEffects::worstDefault, "sdl3_test::gpu_recording_devices");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_vertex_pixels)>(*this, lib, "SDLTestGPUVertexPixels", SideEffects::worstDefault, "sdl3_test::gpu_vertex_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_index_buffers)>(*this, lib, "SDLTestGPUIndexBuffers", SideEffects::worstDefault, "sdl3_test::gpu_index_buffers");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_index_bad_arrays)>(*this, lib, "SDLTestGPUIndexBadArrays", SideEffects::worstDefault, "sdl3_test::gpu_index_bad_arrays");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_recordings)>(*this, lib, "SDLTestGPURecordings", SideEffects::worstDefault, "sdl3_test::gpu_recordings");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_recording_pixels)>(*this, lib, "SDLTestGPURecordingPixels", SideEffects::worstDefault, "sdl3_test::gpu_recording_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_recording_values)>(*this, lib, "SDLTestGPURecordingValues", SideEffects::worstDefault, "sdl3_test::gpu_recording_values");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_recording_failure)>(*this, lib, "SDLTestGPURecordingFailure", SideEffects::worstDefault, "sdl3_test::gpu_recording_failure");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_devices)>(*this, lib, "SDLTestGPUDevices", SideEffects::worstDefault, "sdl3_test::gpu_devices");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_claims)>(*this, lib, "SDLTestGPUClaims", SideEffects::worstDefault, "sdl3_test::gpu_claims");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_resize)>(*this, lib, "SDLTestGPUResize", SideEffects::worstDefault, "sdl3_test::gpu_resize");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_minimized)>(*this, lib, "SDLTestGPUMinimized", SideEffects::worstDefault, "sdl3_test::gpu_minimized");
        addExtern<DAS_BIND_FUN(sdl3_test::geometry_count_guards)>(*this, lib, "SDLTestGeometryCounts", SideEffects::worstDefault, "sdl3_test::geometry_count_guards");
        addExtern<DAS_BIND_FUN(sdl3_test::nonfinite_vertex), SimNode_ExtFuncCallAndCopyOrMove>(*this, lib, "SDLTestNonfiniteVertex", SideEffects::none, "sdl3_test::nonfinite_vertex");
        addExtern<DAS_BIND_FUN(sdl3_test::live_wavs)>(*this, lib, "SDLTestLiveWavs", SideEffects::worstDefault, "sdl3_test::live_wavs");
        addExtern<DAS_BIND_FUN(sdl3_test::destroyed_streams)>(*this, lib, "SDLTestDestroyedAudioStreams", SideEffects::worstDefault, "sdl3_test::destroyed_streams");
        addExtern<DAS_BIND_FUN(sdl3_test::watch_audio)>(*this, lib, "SDLTestWatchAudio", SideEffects::worstDefault, "sdl3_test::watch_audio");
        addExtern<DAS_BIND_FUN(sdl3_test::matches_wav)>(*this, lib, "SDLTestMatchesWav", SideEffects::worstDefault, "sdl3_test::matches_wav");
        addExtern<DAS_BIND_FUN(sdl3_test::stereo_float_signal)>(*this, lib, "SDLTestStereoFloatSignal", SideEffects::none, "sdl3_test::stereo_float_signal");
        addExtern<DAS_BIND_FUN(sdl3_test::device_closed)>(*this, lib, "SDLTestDeviceClosed", SideEffects::worstDefault, "sdl3_test::device_closed");
        addExtern<DAS_BIND_FUN(sdl3_test::input_event), SimNode_ExtFuncCallAndCopyOrMove>(*this, lib, "SDLTestInputEvent", SideEffects::worstDefault, "sdl3_test::input_event")->args({"type", "window_id"});
        addExtern<DAS_BIND_FUN(sdl3_test::poison_event), SimNode_ExtFuncCallAndCopyOrMove>(*this, lib, "SDLTestPoisonEvent", SideEffects::none, "sdl3_test::poison_event");
        addExtern<DAS_BIND_FUN(sdl3_test::mutate_input_text)>(*this, lib, "SDLTestMutateInputText", SideEffects::worstDefault, "sdl3_test::mutate_input_text");
        addExtern<DAS_BIND_FUN(sdl3_test::reset)>(*this, lib, "SDLTestReset", SideEffects::worstDefault, "sdl3_test::reset");
        addExtern<DAS_BIND_FUN(sdl3_test::cleanup_trace)>(*this, lib, "SDLTestCleanupTrace", SideEffects::worstDefault, "sdl3_test::cleanup_trace");
        addExtern<DAS_BIND_FUN(sdl3_test::watch_surface)>(*this, lib, "SDLTestWatchSurface", SideEffects::worstDefault, "sdl3_test::watch_surface");
        addExtern<DAS_BIND_FUN(sdl3_test::watch_texture)>(*this, lib, "SDLTestWatchTexture", SideEffects::worstDefault, "sdl3_test::watch_texture");
        addExtern<DAS_BIND_FUN(sdl3_test::check_corner)>(*this, lib, "SDLTestCheckCorner", SideEffects::worstDefault, "sdl3_test::check_corner");
#endif
        addExtern<DAS_BIND_FUN(SDL_GetTextureSizeRef)>(*this, lib, "SDL_GetTextureSizeRef",
            SideEffects::worstDefault, "SDL_GetTextureSizeRef")->args({"texture", "w", "h"});
        addExtern<DAS_BIND_FUN(SDL_RenderTextureToRect)>(*this, lib, "SDL_RenderTextureToRect",
            SideEffects::worstDefault, "SDL_RenderTextureToRect")->args({"renderer", "texture", "dst"});
        addExtern<DAS_BIND_FUN(SDL_RenderTextureRects)>(*this, lib, "SDL_RenderTextureRects",
            SideEffects::worstDefault, "SDL_RenderTextureRects")->args({"renderer", "texture", "src", "dst"});
        addExtern<DAS_BIND_FUN(SDL_PollEventRef)>(*this, lib, "SDL_PollEventRef",
            SideEffects::worstDefault, "SDL_PollEventRef")->args({"event"});
        addExtern<DAS_BIND_FUN(SDL_PushEventRef)>(*this, lib, "SDL_PushEventRef",
            SideEffects::worstDefault, "SDL_PushEventRef")->args({"event"});
        addExtern<DAS_BIND_FUN(SDL_RenderFillRectRef)>(*this, lib, "SDL_RenderFillRectRef",
            SideEffects::worstDefault, "SDL_RenderFillRectRef")->args({"renderer", "rect"});
        addExtern<DAS_BIND_FUN(SDL_MakeEvent), SimNode_ExtFuncCallAndCopyOrMove>(
            *this, lib, "SDL_MakeEvent", SideEffects::none, "SDL_MakeEvent");
        addExtern<DAS_BIND_FUN(SDL_MakeFRect), SimNode_ExtFuncCallAndCopyOrMove>(
            *this, lib, "SDL_MakeFRect", SideEffects::none, "SDL_MakeFRect")->args({"x", "y", "w", "h"});
        addExtern<DAS_BIND_FUN(SDL_EventIsQuit)>(*this, lib, "SDL_EventIsQuit",
            SideEffects::none, "SDL_EventIsQuit")->args({"event"});
        addExtern<DAS_BIND_FUN(SDL_EventIsEscape)>(*this, lib, "SDL_EventIsEscape",
            SideEffects::none, "SDL_EventIsEscape")->args({"event"});
        addExtern<DAS_BIND_FUN(SDL_MakeKeyEvent), SimNode_ExtFuncCallAndCopyOrMove>(
            *this, lib, "SDL_MakeKeyEvent", SideEffects::none, "SDL_MakeKeyEvent")->args({"type", "key"});
        // Match the BGFX binder's promotion of small C integer arguments.
        for (auto & fn : functions.each()) {
            for (auto & arg : fn->arguments) {
                if (arg->type->isSimpleType(Type::tUInt8) || arg->type->isSimpleType(Type::tUInt16))
                    arg->type->baseType = Type::tUInt;
            }
        }
    }
};
}
REGISTER_MODULE_IN_NAMESPACE(Module_dasSDL3, das);
