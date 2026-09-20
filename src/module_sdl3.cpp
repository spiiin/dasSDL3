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
#include "sdl3_gpu_commands.h"
#include "sdl3_gpu_utilities.h"
#include "sdl3_gpu_mesh.h"
#include "sdl3_gpu_3d.h"
#include "sdl3_gpu_lit.h"
#include "sdl3_gpu_scene.h"
#include "sdl3_gpu_instancing.h"
#include "sdl3_gpu_batches.h"
#ifdef DASSDL3_TYPES_INCLUDE
#include DASSDL3_TYPES_INCLUDE
#else
#include "generated/sdl3_types.inc"
#endif
#include "sdl3_scopes.h"
#include "sdl3_owned_scopes.h"
#ifdef DASSDL3_TESTING
#include "../tests/resource_probe.h"
#include "../tests/input_probe.h"
#include "../tests/audio_probe.h"
#include "../tests/geometry_probe.h"
#include "../tests/gpu_probe.h"
#include "../tests/gpu_commands_probe.h"
#include "../tests/gpu_triangle_probe.h"
#include "../tests/gpu_mesh_probe.h"
#include "../tests/gpu_3d_probe.h"
#include "../tests/gpu_lit_probe.h"
#include "../tests/gpu_scene_probe.h"
#include "../tests/gpu_instancing_probe.h"
#include "../tests/gpu_instance_colors_probe.h"
#include "../tests/gpu_batches_probe.h"
#include "../tests/gpu_culling_probe.h"
#include "../tests/gpu_resources_probe.h"
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
        constexpr auto ownedScopeEffects = SideEffects(uint32_t(SideEffects::invoke) | uint32_t(SideEffects::worstDefault));
        lib.addBuiltInModule();
        #ifdef DASSDL3_REGISTRATION_INCLUDE
        #include DASSDL3_REGISTRATION_INCLUDE
        #else
        #include "generated/sdl3_functions.inc"
        #endif
        addExtern<DAS_BIND_FUN(SDL_ScopeWindow)>(*this, lib, "SDL_ScopeWindow", ownedScopeEffects, "SDL_ScopeWindow");
        addExtern<DAS_BIND_FUN(SDL_ScopeRenderer)>(*this, lib, "SDL_ScopeRenderer", ownedScopeEffects, "SDL_ScopeRenderer");
        addExtern<DAS_BIND_FUN(SDL_ScopeSurface)>(*this, lib, "SDL_ScopeSurface", ownedScopeEffects, "SDL_ScopeSurface");
        addExtern<DAS_BIND_FUN(SDL_ScopeTexture)>(*this, lib, "SDL_ScopeTexture", ownedScopeEffects, "SDL_ScopeTexture");
        addExtern<DAS_BIND_FUN(SDL_ScopeWav)>(*this, lib, "SDL_ScopeWav", ownedScopeEffects, "SDL_ScopeWav");
        addExtern<DAS_BIND_FUN(SDL_ScopeAudioStream)>(*this, lib, "SDL_ScopeAudioStream", ownedScopeEffects, "SDL_ScopeAudioStream");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPU3DMesh)>(*this, lib, "SDL_ScopeReleaseGPU3DMesh", ownedScopeEffects, "SDL_ScopeReleaseGPU3DMesh");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPUBatchScene)>(*this, lib, "SDL_ScopeReleaseGPUBatchScene", ownedScopeEffects, "SDL_ScopeReleaseGPUBatchScene");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPUCommandPlan)>(*this, lib, "SDL_ScopeReleaseGPUCommandPlan", ownedScopeEffects, "SDL_ScopeReleaseGPUCommandPlan");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPUDataBuffer)>(*this, lib, "SDL_ScopeReleaseGPUDataBuffer", ownedScopeEffects, "SDL_ScopeReleaseGPUDataBuffer");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPUGeometry)>(*this, lib, "SDL_ScopeReleaseGPUGeometry", ownedScopeEffects, "SDL_ScopeReleaseGPUGeometry");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPULitMesh)>(*this, lib, "SDL_ScopeReleaseGPULitMesh", ownedScopeEffects, "SDL_ScopeReleaseGPULitMesh");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPULitScene)>(*this, lib, "SDL_ScopeReleaseGPULitScene", ownedScopeEffects, "SDL_ScopeReleaseGPULitScene");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPUMaterial)>(*this, lib, "SDL_ScopeReleaseGPUMaterial", ownedScopeEffects, "SDL_ScopeReleaseGPUMaterial");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPUReadback)>(*this, lib, "SDL_ScopeReleaseGPUReadback", ownedScopeEffects, "SDL_ScopeReleaseGPUReadback");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPUSharedMesh)>(*this, lib, "SDL_ScopeReleaseGPUSharedMesh", ownedScopeEffects, "SDL_ScopeReleaseGPUSharedMesh");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPUTexturedMesh)>(*this, lib, "SDL_ScopeReleaseGPUTexturedMesh", ownedScopeEffects, "SDL_ScopeReleaseGPUTexturedMesh");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPUTransferTexture)>(*this, lib, "SDL_ScopeReleaseGPUTransferTexture", ownedScopeEffects, "SDL_ScopeReleaseGPUTransferTexture");
        addExtern<DAS_BIND_FUN(SDL_ScopeReleaseGPUVertexIDPipeline)>(*this, lib, "SDL_ScopeReleaseGPUVertexIDPipeline", ownedScopeEffects, "SDL_ScopeReleaseGPUVertexIDPipeline");
        addExtern<DAS_BIND_FUN(SDL_ScopeSDL)>(*this, lib, "SDL_ScopeSDL", ownedScopeEffects, "SDL_ScopeSDL");
        addExtern<DAS_BIND_FUN(SDL_ScopeGPUDevice)>(*this, lib, "SDL_ScopeGPUDevice", ownedScopeEffects, "SDL_ScopeGPUDevice");
        addExtern<DAS_BIND_FUN(SDL_ScopeGPUWindow)>(*this, lib, "SDL_ScopeGPUWindow", ownedScopeEffects, "SDL_ScopeGPUWindow");
        addExtern<DAS_BIND_FUN(SDL_ScopeRenderTarget)>(*this, lib, "SDL_ScopeRenderTarget", ownedScopeEffects, "SDL_ScopeRenderTarget");
        addExtern<DAS_BIND_FUN(SDL_ScopeTextInput)>(*this, lib, "SDL_ScopeTextInput", ownedScopeEffects, "SDL_ScopeTextInput");
        addExtern<DAS_BIND_FUN(SDL_LoadBMPTextureOwned)>(*this, lib, "SDL_LoadBMPTextureOwned", SideEffects::worstDefault, "SDL_LoadBMPTextureOwned");
        addExtern<DAS_BIND_FUN(SDL_GPUPlanDebugGroupsSupported)>(*this, lib, "SDL_GPUPlanDebugGroupsSupported", SideEffects::worstDefault, "SDL_GPUPlanDebugGroupsSupported");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUCommandPlan)>(*this, lib, "SDL_CreateGPUCommandPlan", SideEffects::worstDefault, "SDL_CreateGPUCommandPlan");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUCommandPlan)>(*this, lib, "SDL_ReleaseGPUCommandPlan", SideEffects::worstDefault, "SDL_ReleaseGPUCommandPlan");
        addExtern<DAS_BIND_FUN(SDL_GPUPlanCopyBuffer)>(*this, lib, "SDL_GPUPlanCopyBuffer", SideEffects::worstDefault, "SDL_GPUPlanCopyBuffer");
        addExtern<DAS_BIND_FUN(SDL_GPUPlanCopyTexture)>(*this, lib, "SDL_GPUPlanCopyTexture", SideEffects::worstDefault, "SDL_GPUPlanCopyTexture");
        addExtern<DAS_BIND_FUN(SDL_GPUPlanMipmaps)>(*this, lib, "SDL_GPUPlanMipmaps", SideEffects::worstDefault, "SDL_GPUPlanMipmaps");
        addExtern<DAS_BIND_FUN(SDL_GPUPlanBlit)>(*this, lib, "SDL_GPUPlanBlit", SideEffects::worstDefault, "SDL_GPUPlanBlit");
        addExtern<DAS_BIND_FUN(SDL_GPUPlanLabel)>(*this, lib, "SDL_GPUPlanLabel", SideEffects::worstDefault, "SDL_GPUPlanLabel");
        addExtern<DAS_BIND_FUN(SDL_GPUPlanPushGroup)>(*this, lib, "SDL_GPUPlanPushGroup", SideEffects::worstDefault, "SDL_GPUPlanPushGroup");
        addExtern<DAS_BIND_FUN(SDL_GPUPlanPopGroup)>(*this, lib, "SDL_GPUPlanPopGroup", SideEffects::worstDefault, "SDL_GPUPlanPopGroup");
        addExtern<DAS_BIND_FUN(SDL_SubmitGPUCommandPlan)>(*this, lib, "SDL_SubmitGPUCommandPlan", SideEffects::worstDefault, "SDL_SubmitGPUCommandPlan");
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
        addExtern<DAS_BIND_FUN(SDL_UpdateGPUColoredInstances)>(*this, lib, "SDL_UpdateGPUColoredInstances", SideEffects::worstDefault, "SDL_UpdateGPUColoredInstances");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUColoredInstancedMesh)>(*this, lib, "SDL_CreateGPUColoredInstancedMesh", SideEffects::worstDefault, "SDL_CreateGPUColoredInstancedMesh");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUGeometry)>(*this, lib, "SDL_CreateGPUGeometry", SideEffects::worstDefault, "SDL_CreateGPUGeometry");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUGeometry)>(*this, lib, "SDL_ReleaseGPUGeometry", SideEffects::worstDefault, "SDL_ReleaseGPUGeometry");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUMaterial)>(*this, lib, "SDL_CreateGPUMaterial", SideEffects::worstDefault, "SDL_CreateGPUMaterial");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUMaterial)>(*this, lib, "SDL_ReleaseGPUMaterial", SideEffects::worstDefault, "SDL_ReleaseGPUMaterial");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUSharedMesh)>(*this, lib, "SDL_CreateGPUSharedMesh", SideEffects::worstDefault, "SDL_CreateGPUSharedMesh");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUSharedMesh)>(*this, lib, "SDL_ReleaseGPUSharedMesh", SideEffects::worstDefault, "SDL_ReleaseGPUSharedMesh");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUBatchScene)>(*this, lib, "SDL_CreateGPUBatchScene", SideEffects::worstDefault, "SDL_CreateGPUBatchScene");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUBatchScene)>(*this, lib, "SDL_ReleaseGPUBatchScene", SideEffects::worstDefault, "SDL_ReleaseGPUBatchScene");
        addExtern<DAS_BIND_FUN(SDL_DrawGPUBatches)>(*this, lib, "SDL_DrawGPUBatches", SideEffects::worstDefault, "SDL_DrawGPUBatches");
        addExtern<DAS_BIND_FUN(SDL_UpdateGPUInstances)>(*this, lib, "SDL_UpdateGPUInstances", SideEffects::worstDefault, "SDL_UpdateGPUInstances");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUInstancedMesh)>(*this, lib, "SDL_CreateGPUInstancedMesh", SideEffects::worstDefault, "SDL_CreateGPUInstancedMesh");
        addExtern<DAS_BIND_FUN(SDL_DrawGPUInstancedMesh)>(*this, lib, "SDL_DrawGPUInstancedMesh", SideEffects::worstDefault, "SDL_DrawGPUInstancedMesh");
        addExtern<DAS_BIND_FUN(SDL_CreateGPULitScene)>(*this, lib, "SDL_CreateGPULitScene", SideEffects::worstDefault, "SDL_CreateGPULitScene");
        addExtern<DAS_BIND_FUN(SDL_DrawGPULitScene)>(*this, lib, "SDL_DrawGPULitScene", SideEffects::worstDefault, "SDL_DrawGPULitScene");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPULitScene)>(*this, lib, "SDL_ReleaseGPULitScene", SideEffects::worstDefault, "SDL_ReleaseGPULitScene");
        addExtern<DAS_BIND_FUN(SDL_CreateGPULitMesh)>(*this, lib, "SDL_CreateGPULitMesh", SideEffects::worstDefault, "SDL_CreateGPULitMesh");
        addExtern<DAS_BIND_FUN(SDL_DrawGPULitMesh)>(*this, lib, "SDL_DrawGPULitMesh", SideEffects::worstDefault, "SDL_DrawGPULitMesh");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPULitMesh)>(*this, lib, "SDL_ReleaseGPULitMesh", SideEffects::worstDefault, "SDL_ReleaseGPULitMesh");
        addExtern<DAS_BIND_FUN(SDL_CreateGPU3DMesh)>(*this, lib, "SDL_CreateGPU3DMesh", SideEffects::worstDefault, "SDL_CreateGPU3DMesh");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPU3DMesh)>(*this, lib, "SDL_ReleaseGPU3DMesh", SideEffects::worstDefault, "SDL_ReleaseGPU3DMesh");
        addExtern<DAS_BIND_FUN(SDL_DrawGPU3DMesh)>(*this, lib, "SDL_DrawGPU3DMesh", SideEffects::worstDefault, "SDL_DrawGPU3DMesh");
        addExtern<DAS_BIND_FUN(SDL_GPU3DWindowAspect)>(*this, lib, "SDL_GPU3DWindowAspect", SideEffects::worstDefault, "SDL_GPU3DWindowAspect");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUTexturedMesh)>(*this, lib, "SDL_CreateGPUTexturedMesh", SideEffects::worstDefault, "SDL_CreateGPUTexturedMesh");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUTransformMesh)>(*this, lib, "SDL_CreateGPUTransformMesh", SideEffects::worstDefault, "SDL_CreateGPUTransformMesh");
        addExtern<DAS_BIND_FUN(SDL_DrawGPUTransformMesh)>(*this, lib, "SDL_DrawGPUTransformMesh", SideEffects::worstDefault, "SDL_DrawGPUTransformMesh");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUIndexedTexturedMesh)>(*this, lib, "SDL_CreateGPUIndexedTexturedMesh", SideEffects::worstDefault, "SDL_CreateGPUIndexedTexturedMesh");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUTexturedMesh)>(*this, lib, "SDL_ReleaseGPUTexturedMesh", SideEffects::worstDefault, "SDL_ReleaseGPUTexturedMesh");
        addExtern<DAS_BIND_FUN(SDL_DrawGPUTexturedMesh)>(*this, lib, "SDL_DrawGPUTexturedMesh", SideEffects::worstDefault, "SDL_DrawGPUTexturedMesh");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUVertexIDPipeline)>(*this, lib, "SDL_CreateGPUVertexIDPipeline", SideEffects::worstDefault, "SDL_CreateGPUVertexIDPipeline");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUVertexIDPipeline)>(*this, lib, "SDL_ReleaseGPUVertexIDPipeline", SideEffects::worstDefault, "SDL_ReleaseGPUVertexIDPipeline");
        addExtern<DAS_BIND_FUN(SDL_DrawGPUVertexIDTriangle)>(*this, lib, "SDL_DrawGPUVertexIDTriangle", SideEffects::worstDefault, "SDL_DrawGPUVertexIDTriangle");
        addExtern<DAS_BIND_FUN(SDL_InvokeGPUHandle)>(*this, lib, "SDL_InvokeGPUHandle", SideEffects::invoke, "SDL_InvokeGPUHandle");
        addExtern<DAS_BIND_FUN(SDL_DestroyGPUDeviceScoped)>(*this, lib, "SDL_DestroyGPUDeviceScoped", SideEffects::worstDefault, "SDL_DestroyGPUDeviceScoped");
        addExtern<DAS_BIND_FUN(SDL_ClaimGPUWindowScoped)>(*this, lib, "SDL_ClaimGPUWindowScoped", SideEffects::worstDefault, "SDL_ClaimGPUWindowScoped");
        addExtern<DAS_BIND_FUN(SDL_ReleaseGPUWindowScoped)>(*this, lib, "SDL_ReleaseGPUWindowScoped", SideEffects::worstDefault, "SDL_ReleaseGPUWindowScoped");
        addExtern<DAS_BIND_FUN(SDL_GPUWindowClaimedBy)>(*this, lib, "SDL_GPUWindowClaimedBy", SideEffects::worstDefault, "SDL_GPUWindowClaimedBy");
        addExtern<DAS_BIND_FUN(SDL_ClearGPUWindow)>(*this, lib, "SDL_ClearGPUWindow", SideEffects::worstDefault, "SDL_ClearGPUWindow");
        addExtern<DAS_BIND_FUN(SDL_InvokeResource<SDL_GPUDevice>)>(*this, lib, "SDL_InvokeGPUDevice", SideEffects::invoke, "SDL_InvokeResource<SDL_GPUDevice>");
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
        addExtern<DAS_BIND_FUN(SDL_InvokeResource<SDL_Wav>)>(*this, lib, "SDL_InvokeWav", SideEffects::invoke, "SDL_InvokeResource<SDL_Wav>");
        addExtern<DAS_BIND_FUN(SDL_InvokeResource<SDL_AudioStream>)>(*this, lib, "SDL_InvokeAudioStream", SideEffects::invoke, "SDL_InvokeResource<SDL_AudioStream>");
        addExtern<DAS_BIND_FUN(SDL_InvokeScope)>(*this, lib, "SDL_InvokeScope", SideEffects::invoke, "SDL_InvokeScope")->args({"block", "context", "at"});
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
        addExtern<DAS_BIND_FUN(SDL_InvokeResource<SDL_Window>)>(*this, lib, "SDL_InvokeWindow", SideEffects::invoke, "SDL_InvokeResource<SDL_Window>")->args({"block", "window", "context", "at"});
        addExtern<DAS_BIND_FUN(SDL_InvokeResource<SDL_Renderer>)>(*this, lib, "SDL_InvokeRenderer", SideEffects::invoke, "SDL_InvokeResource<SDL_Renderer>")->args({"block", "renderer", "context", "at"});
        addExtern<DAS_BIND_FUN(SDL_InvokeResource<SDL_Surface>)>(*this, lib, "SDL_InvokeSurface", SideEffects::invoke, "SDL_InvokeResource<SDL_Surface>")->args({"block", "surface", "context", "at"});
        addExtern<DAS_BIND_FUN(SDL_InvokeResource<SDL_Texture>)>(*this, lib, "SDL_InvokeTexture", SideEffects::invoke, "SDL_InvokeResource<SDL_Texture>")->args({"block", "texture", "context", "at"});
#ifdef DASSDL3_TESTING
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_state_contracts)>(*this, lib, "SDLTestGPUStateContracts", SideEffects::worstDefault, "sdl3_test::gpu_state_contracts");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_meshes)>(*this, lib, "SDLTestGPUMeshes", SideEffects::worstDefault, "sdl3_test::gpu_meshes");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_instances_failed_submit)>(*this, lib, "SDLTestGPUInstancesFailedSubmit", SideEffects::worstDefault, "sdl3_test::gpu_instances_failed_submit");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_colors_offscreen)>(*this, lib, "SDLTestGPUColorsOffscreen", SideEffects::worstDefault, "sdl3_test::gpu_colors_offscreen");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_colors_pixels)>(*this, lib, "SDLTestGPUColorsPixels", SideEffects::worstDefault, "sdl3_test::gpu_colors_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_colors_pending)>(*this, lib, "SDLTestGPUColorsPending", SideEffects::worstDefault, "sdl3_test::gpu_colors_pending");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_colors_failure)>(*this, lib, "SDLTestGPUColorsFailure", SideEffects::worstDefault, "sdl3_test::gpu_colors_failure");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_colors_guards)>(*this, lib, "SDLTestGPUColorsGuards", SideEffects::worstDefault, "sdl3_test::gpu_colors_guards");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_batches_offscreen)>(*this, lib, "SDLTestGPUBatchesOffscreen", SideEffects::worstDefault, "sdl3_test::gpu_batches_offscreen");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_batches_pixels)>(*this, lib, "SDLTestGPUBatchesPixels", SideEffects::worstDefault, "sdl3_test::gpu_batches_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_batches_count)>(*this, lib, "SDLTestGPUBatchesCount", SideEffects::worstDefault, "sdl3_test::gpu_batches_count");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_batches_preflight)>(*this, lib, "SDLTestGPUBatchesPreflight", SideEffects::worstDefault, "sdl3_test::gpu_batches_preflight");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_batches_failure)>(*this, lib, "SDLTestGPUBatchesFailure", SideEffects::worstDefault, "sdl3_test::gpu_batches_failure");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_batches_pending)>(*this, lib, "SDLTestGPUBatchesPending", SideEffects::worstDefault, "sdl3_test::gpu_batches_pending");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_culling_compare)>(*this, lib, "SDLTestGPUCullingCompare", SideEffects::worstDefault, "sdl3_test::gpu_culling_compare");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_geometries_live)>(*this, lib, "SDLTestGPUGeometries", SideEffects::worstDefault, "sdl3_test::gpu_geometries_live");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_materials_live)>(*this, lib, "SDLTestGPUMaterials", SideEffects::worstDefault, "sdl3_test::gpu_materials_live");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_shared_live)>(*this, lib, "SDLTestGPUSharedMeshes", SideEffects::worstDefault, "sdl3_test::gpu_shared_live");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_material_offscreen)>(*this, lib, "SDLTestGPUMaterialOffscreen", SideEffects::worstDefault, "sdl3_test::gpu_material_offscreen");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_resources_shared)>(*this, lib, "SDLTestGPUResourcesShared", SideEffects::worstDefault, "sdl3_test::gpu_resources_shared");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_resources_pending_release)>(*this, lib, "SDLTestGPUResourcesPendingRelease", SideEffects::worstDefault, "sdl3_test::gpu_resources_pending_release");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_batches_live)>(*this, lib, "SDLTestGPUBatchesLive", SideEffects::worstDefault, "sdl3_test::gpu_batches_live");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_batches_depth)>(*this, lib, "SDLTestGPUBatchesDepth", SideEffects::worstDefault, "sdl3_test::gpu_batches_depth");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_instances_pending)>(*this, lib, "SDLTestGPUInstancesPending", SideEffects::worstDefault, "sdl3_test::gpu_instances_pending");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_instances_offscreen)>(*this, lib, "SDLTestGPUInstancesOffscreen", SideEffects::worstDefault, "sdl3_test::gpu_instances_offscreen");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_instances_pixels)>(*this, lib, "SDLTestGPUInstancesPixels", SideEffects::worstDefault, "sdl3_test::gpu_instances_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_instances_preflight)>(*this, lib, "SDLTestGPUInstancesPreflight", SideEffects::worstDefault, "sdl3_test::gpu_instances_preflight");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_scenes)>(*this, lib, "SDLTestGPUScenes", SideEffects::worstDefault, "sdl3_test::gpu_scenes");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_scene_offscreen)>(*this, lib, "SDLTestGPUSceneOffscreen", SideEffects::worstDefault, "sdl3_test::gpu_scene_offscreen");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_scene_sizes)>(*this, lib, "SDLTestGPUSceneSizes", SideEffects::worstDefault, "sdl3_test::gpu_scene_sizes");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_scene_depth)>(*this, lib, "SDLTestGPUSceneDepth", SideEffects::worstDefault, "sdl3_test::gpu_scene_depth");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_scene_depth_failure)>(*this, lib, "SDLTestGPUSceneDepthFailure", SideEffects::worstDefault, "sdl3_test::gpu_scene_depth_failure");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_scene_preflight)>(*this, lib, "SDLTestGPUScenePreflight", SideEffects::worstDefault, "sdl3_test::gpu_scene_preflight");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_scene_pixels)>(*this, lib, "SDLTestGPUScenePixels", SideEffects::worstDefault, "sdl3_test::gpu_scene_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_lit_meshes)>(*this, lib, "SDLTestGPULitMeshes", SideEffects::worstDefault, "sdl3_test::gpu_lit_meshes");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_lit_guards)>(*this, lib, "SDLTestGPULitGuards", SideEffects::worstDefault, "sdl3_test::gpu_lit_guards");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_lit_offscreen)>(*this, lib, "SDLTestGPUCreateLitOffscreen", SideEffects::worstDefault, "sdl3_test::gpu_lit_offscreen");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_lit_depth)>(*this, lib, "SDLTestGPULitDepth", SideEffects::worstDefault, "sdl3_test::gpu_lit_depth");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_lit_pixels)>(*this, lib, "SDLTestGPULitPixels", SideEffects::worstDefault, "sdl3_test::gpu_lit_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_3d_meshes)>(*this, lib, "SDLTestGPU3DMeshes", SideEffects::worstDefault, "sdl3_test::gpu_3d_meshes");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_3d_depths)>(*this, lib, "SDLTestGPU3DDepths", SideEffects::worstDefault, "sdl3_test::gpu_3d_depths");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_3d_guards)>(*this, lib, "SDLTestGPU3DGuards", SideEffects::worstDefault, "sdl3_test::gpu_3d_guards");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_3d_offscreen)>(*this, lib, "SDLTestGPUCreate3DOffscreen", SideEffects::worstDefault, "sdl3_test::gpu_3d_offscreen");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_3d_foreign)>(*this, lib, "SDLTestGPU3DForeign", SideEffects::worstDefault, "sdl3_test::gpu_3d_foreign");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_3d_depth_contracts)>(*this, lib, "SDLTestGPU3DDepthContracts", SideEffects::worstDefault, "sdl3_test::gpu_3d_depth_contracts");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_3d_depth_matches)>(*this, lib, "SDLTestGPU3DDepthMatches", SideEffects::worstDefault, "sdl3_test::gpu_3d_depth_matches");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_3d_pixels)>(*this, lib, "SDLTestGPU3DPixels", SideEffects::worstDefault, "sdl3_test::gpu_3d_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_transform_guards)>(*this, lib, "SDLTestGPUTransformGuards", SideEffects::worstDefault, "sdl3_test::gpu_transform_guards");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_transform_mesh_offscreen)>(*this, lib, "SDLTestGPUCreateTransformMeshOffscreen", SideEffects::worstDefault, "sdl3_test::gpu_transform_mesh_offscreen");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_transform_pixels)>(*this, lib, "SDLTestGPUTransformPixels", SideEffects::worstDefault, "sdl3_test::gpu_transform_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_mesh_guards)>(*this, lib, "SDLTestGPUMeshGuards", SideEffects::worstDefault, "sdl3_test::gpu_mesh_guards");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_mesh_foreign)>(*this, lib, "SDLTestGPUForeignMesh", SideEffects::worstDefault, "sdl3_test::gpu_mesh_foreign");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_mesh_offscreen)>(*this, lib, "SDLTestGPUCreateMeshOffscreen", SideEffects::worstDefault, "sdl3_test::gpu_mesh_offscreen");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_indexed_mesh_offscreen)>(*this, lib, "SDLTestGPUCreateIndexedMeshOffscreen", SideEffects::worstDefault, "sdl3_test::gpu_indexed_mesh_offscreen");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_mesh_pixels)>(*this, lib, "SDLTestGPUMeshPixels", SideEffects::worstDefault, "sdl3_test::gpu_mesh_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_pipelines)>(*this, lib, "SDLTestGPUPipelines", SideEffects::worstDefault, "sdl3_test::gpu_pipelines");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_shaders)>(*this, lib, "SDLTestGPUShaders", SideEffects::worstDefault, "sdl3_test::gpu_shaders");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_foreign_pipeline)>(*this, lib, "SDLTestGPUForeignPipeline", SideEffects::worstDefault, "sdl3_test::gpu_foreign_pipeline");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_pipeline_failure)>(*this, lib, "SDLTestGPUPipelineFailure", SideEffects::worstDefault, "sdl3_test::gpu_pipeline_failure");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_triangle_pixels)>(*this, lib, "SDLTestGPUTrianglePixels", SideEffects::worstDefault, "sdl3_test::gpu_triangle_pixels");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_plan_fail_submit)>(*this, lib, "SDLTestGPUPlanFailSubmit", SideEffects::worstDefault, "sdl3_test::gpu_plan_fail_submit");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_plans)>(*this, lib, "SDLTestGPUPlans", SideEffects::worstDefault, "sdl3_test::gpu_plans");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_plan_faults)>(*this, lib, "SDLTestGPUPlanFaults", SideEffects::worstDefault, "sdl3_test::gpu_plan_faults");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_plan_no_acquire)>(*this, lib, "SDLTestGPUPlanNoAcquire", SideEffects::worstDefault, "sdl3_test::gpu_plan_no_acquire");
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_plan_text_copy)>(*this, lib, "SDLTestGPUPlanTextCopy", SideEffects::worstDefault, "sdl3_test::gpu_plan_text_copy");
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
