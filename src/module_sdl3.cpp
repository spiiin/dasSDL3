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
#include "sdl3_gpu_native_data.h"
#include "sdl3_properties.h"
#include "sdl3_init_hints.h"
#include "sdl3_diagnostics.h"
#include "sdl3_video.h"
#include "sdl3_window.h"
#include "sdl3_window_io.h"
#include "sdl3_renderer_primitives.h"
#include "sdl3_renderer_state.h"
#include "sdl3_renderer_presentation.h"
#include "sdl3_texture_state.h"
#include "sdl3_texture_transfer.h"
#include "sdl3_renderer_yuv_blend.h"
#include "sdl3_renderer_operations.h"
#include "sdl3_renderer_final_api.h"
#include "sdl3_surface_state.h"
#include "sdl3_surface_pixels.h"
#include "sdl3_rect.h"
#include "sdl3_callback_types.h"
#ifdef DASSDL3_TYPES_INCLUDE
#include DASSDL3_TYPES_INCLUDE
#else
#include "generated/sdl3_types.inc"
#endif
#include "sdl3_texture_load.h"
#include "sdl3_clipboard_hittest.h"
#include "sdl3_result_adapters.h"
#include "generated/gpu_handle_adapters.h"
#ifdef DASSDL3_TESTING
#include "../tests/resource_probe.h"
#include "../tests/gpu_handle_probe.h"
#include "../tests/clipboard_hittest_probe.h"
#include "../tests/properties_probe.h"
#include "../tests/diagnostics_probe.h"
#include "../tests/input_probe.h"
#include "../tests/audio_probe.h"
#include "../tests/geometry_probe.h"
#include "../tests/gpu_probe.h"
#include "../tests/result_probe.h"
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
        #include "generated/gpu_handle_registration.inc"
        #ifdef DASSDL3_REGISTRATION_INCLUDE
        #include DASSDL3_REGISTRATION_INCLUDE
        #else
        #include "generated/sdl3_functions.inc"
        #endif
        addExtern<DAS_BIND_FUN(SDL_SetWindowFullscreenModeRef)>(*this, lib, "SDL_SetWindowFullscreenModeRef", SideEffects::worstDefault, "SDL_SetWindowFullscreenModeRef");
        addExtern<DAS_BIND_FUN(SDL_SetWindowDesktopFullscreenMode)>(*this, lib, "SDL_SetWindowDesktopFullscreenMode", SideEffects::worstDefault, "SDL_SetWindowDesktopFullscreenMode");
        addExtern<DAS_BIND_FUN(SDL_GetWindowFullscreenModeCopy)>(*this, lib, "SDL_GetWindowFullscreenModeCopy", SideEffects::worstDefault, "SDL_GetWindowFullscreenModeCopy");
        addExtern<DAS_BIND_FUN(SDL_SetWindowMouseRectRef)>(*this, lib, "SDL_SetWindowMouseRectRef", SideEffects::worstDefault, "SDL_SetWindowMouseRectRef");
        addExtern<DAS_BIND_FUN(SDL_ClearWindowMouseRect)>(*this, lib, "SDL_ClearWindowMouseRect", SideEffects::worstDefault, "SDL_ClearWindowMouseRect");
        addExtern<DAS_BIND_FUN(SDL_GetWindowMouseRectCopy)>(*this, lib, "SDL_GetWindowMouseRectCopy", SideEffects::worstDefault, "SDL_GetWindowMouseRectCopy");
        addExtern<DAS_BIND_FUN(SDL_GetWindowSurfaceVSyncRef)>(*this, lib, "SDL_GetWindowSurfaceVSyncRef", SideEffects::worstDefault, "SDL_GetWindowSurfaceVSyncRef");
        addExtern<DAS_BIND_FUN(SDL_UpdateWindowSurfaceRectsArray)>(*this, lib, "SDL_UpdateWindowSurfaceRectsArray", SideEffects::worstDefault, "SDL_UpdateWindowSurfaceRectsArray");
        addExtern<DAS_BIND_FUN(SDL_GetWindowICCProfileCopy)>(*this, lib, "SDL_GetWindowICCProfileCopy", SideEffects::worstDefault, "SDL_GetWindowICCProfileCopy");
        addExtern<DAS_BIND_FUN(SDL_GetRenderDriverCopy)>(*this,lib,"SDL_GetRenderDriverCopy",SideEffects::worstDefault,"SDL_GetRenderDriverCopy");
    addExtern<DAS_BIND_FUN(SDL_ConvertEventToRenderCoordinatesRef)>(*this,lib,"SDL_ConvertEventToRenderCoordinatesRef",SideEffects::worstDefault,"SDL_ConvertEventToRenderCoordinatesRef");
    addExtern<DAS_BIND_FUN(SDL_WriteMouseMotionEvent)>(*this,lib,"SDL_WriteMouseMotionEvent",SideEffects::worstDefault,"SDL_WriteMouseMotionEvent");
    addExtern<DAS_BIND_FUN(SDL_WriteMouseButtonEvent)>(*this,lib,"SDL_WriteMouseButtonEvent",SideEffects::worstDefault,"SDL_WriteMouseButtonEvent");
    addExtern<DAS_BIND_FUN(SDL_WriteMouseWheelEvent)>(*this,lib,"SDL_WriteMouseWheelEvent",SideEffects::worstDefault,"SDL_WriteMouseWheelEvent");
    addExtern<DAS_BIND_FUN(SDL_RenderDebugTextFormatText)>(*this,lib,"SDL_RenderDebugTextFormatText",SideEffects::worstDefault,"SDL_RenderDebugTextFormatText");
    addExtern<DAS_BIND_FUN(SDL_RenderGeometryRawArrays)>(*this,lib,"SDL_RenderGeometryRawArrays",SideEffects::worstDefault,"SDL_RenderGeometryRawArrays");
    addExtern<DAS_BIND_FUN(SDL_RenderGeometryRawIndexedArrays)>(*this,lib,"SDL_RenderGeometryRawIndexedArrays",SideEffects::worstDefault,"SDL_RenderGeometryRawIndexedArrays");
    addExtern<DAS_BIND_FUN(SDL_CreateWindowAndRendererRef)>(*this,lib,"SDL_CreateWindowAndRendererRef",SideEffects::worstDefault,"SDL_CreateWindowAndRendererRef");
    addExtern<DAS_BIND_FUN(SDL_GetRenderVSyncRef)>(*this,lib,"SDL_GetRenderVSyncRef",SideEffects::worstDefault,"SDL_GetRenderVSyncRef");
    addExtern<DAS_BIND_FUN(SDL_RenderReadPixelsRect)>(*this,lib,"SDL_RenderReadPixelsRect",SideEffects::worstDefault,"SDL_RenderReadPixelsRect");
    addExtern<DAS_BIND_FUN(SDL_RenderTextureRotatedRefs)>(*this,lib,"SDL_RenderTextureRotatedRefs",SideEffects::worstDefault,"SDL_RenderTextureRotatedRefs");
    addExtern<DAS_BIND_FUN(SDL_RenderTextureAffineRefs)>(*this,lib,"SDL_RenderTextureAffineRefs",SideEffects::worstDefault,"SDL_RenderTextureAffineRefs");
    addExtern<DAS_BIND_FUN(SDL_RenderTextureTiledRefs)>(*this,lib,"SDL_RenderTextureTiledRefs",SideEffects::worstDefault,"SDL_RenderTextureTiledRefs");
    addExtern<DAS_BIND_FUN(SDL_RenderTexture9GridRefs)>(*this,lib,"SDL_RenderTexture9GridRefs",SideEffects::worstDefault,"SDL_RenderTexture9GridRefs");
    addExtern<DAS_BIND_FUN(SDL_GetRenderDrawColorFloatRef)>(*this,lib,"SDL_GetRenderDrawColorFloatRef",SideEffects::worstDefault,"SDL_GetRenderDrawColorFloatRef");
    addExtern<DAS_BIND_FUN(SDL_GetRenderDrawColorRef)>(*this,lib,"SDL_GetRenderDrawColorRef",SideEffects::worstDefault,"SDL_GetRenderDrawColorRef");
    addExtern<DAS_BIND_FUN(SDL_GetRenderColorScaleRef)>(*this,lib,"SDL_GetRenderColorScaleRef",SideEffects::worstDefault,"SDL_GetRenderColorScaleRef");
    addExtern<DAS_BIND_FUN(SDL_GetMasksForPixelFormatRef)>(*this,lib,"SDL_GetMasksForPixelFormatRef",SideEffects::worstDefault,"SDL_GetMasksForPixelFormatRef");
    addExtern<DAS_BIND_FUN(SDL_GetPixelFormatDetailsCopy)>(*this,lib,"SDL_GetPixelFormatDetailsCopy",SideEffects::worstDefault,"SDL_GetPixelFormatDetailsCopy");
    addExtern<DAS_BIND_FUN(SDL_GetRGBRef)>(*this,lib,"SDL_GetRGBRef",SideEffects::worstDefault,"SDL_GetRGBRef");
    addExtern<DAS_BIND_FUN(SDL_GetRGBARef)>(*this,lib,"SDL_GetRGBARef",SideEffects::worstDefault,"SDL_GetRGBARef");
    addExtern<DAS_BIND_FUN(SDL_MapRGBRef)>(*this,lib,"SDL_MapRGBRef",SideEffects::worstDefault,"SDL_MapRGBRef");
    addExtern<DAS_BIND_FUN(SDL_MapRGBARef)>(*this,lib,"SDL_MapRGBARef",SideEffects::worstDefault,"SDL_MapRGBARef");
    addExtern<DAS_BIND_FUN(SDL_ReadSurfacePixelRef)>(*this,lib,"SDL_ReadSurfacePixelRef",SideEffects::worstDefault,"SDL_ReadSurfacePixelRef");
    addExtern<DAS_BIND_FUN(SDL_ReadSurfacePixelFloatRef)>(*this,lib,"SDL_ReadSurfacePixelFloatRef",SideEffects::worstDefault,"SDL_ReadSurfacePixelFloatRef");
    addExtern<DAS_BIND_FUN(SDL_SetPaletteColorsArray)>(*this,lib,"SDL_SetPaletteColorsArray",SideEffects::worstDefault,"SDL_SetPaletteColorsArray");
    addExtern<DAS_BIND_FUN(SDL_FillSurfaceRectsArray)>(*this,lib,"SDL_FillSurfaceRectsArray",SideEffects::worstDefault,"SDL_FillSurfaceRectsArray");
    addExtern<DAS_BIND_FUN(SDL_GetSurfaceImagesCopy)>(*this,lib,"SDL_GetSurfaceImagesCopy",SideEffects::worstDefault,"SDL_GetSurfaceImagesCopy");
    addExtern<DAS_BIND_FUN(SDL_BlitSurfaceAll)>(*this,lib,"SDL_BlitSurfaceAll",SideEffects::worstDefault,"SDL_BlitSurfaceAll");
    addExtern<DAS_BIND_FUN(SDL_BlitSurfaceRefs)>(*this,lib,"SDL_BlitSurfaceRefs",SideEffects::worstDefault,"SDL_BlitSurfaceRefs");
    addExtern<DAS_BIND_FUN(SDL_BlitSurfaceScaledRefs)>(*this,lib,"SDL_BlitSurfaceScaledRefs",SideEffects::worstDefault,"SDL_BlitSurfaceScaledRefs");
    addExtern<DAS_BIND_FUN(SDL_StretchSurfaceRefs)>(*this,lib,"SDL_StretchSurfaceRefs",SideEffects::worstDefault,"SDL_StretchSurfaceRefs");
    addExtern<DAS_BIND_FUN(SDL_BlitSurfaceTiledRefs)>(*this,lib,"SDL_BlitSurfaceTiledRefs",SideEffects::worstDefault,"SDL_BlitSurfaceTiledRefs");
    addExtern<DAS_BIND_FUN(SDL_BlitSurfaceTiledWithScaleRefs)>(*this,lib,"SDL_BlitSurfaceTiledWithScaleRefs",SideEffects::worstDefault,"SDL_BlitSurfaceTiledWithScaleRefs");
    addExtern<DAS_BIND_FUN(SDL_BlitSurface9GridRefs)>(*this,lib,"SDL_BlitSurface9GridRefs",SideEffects::worstDefault,"SDL_BlitSurface9GridRefs");
    addExtern<DAS_BIND_FUN(SDL_ConvertPixelsArray)>(*this,lib,"SDL_ConvertPixelsArray",SideEffects::worstDefault,"SDL_ConvertPixelsArray");
    addExtern<DAS_BIND_FUN(SDL_ConvertPixelsAndColorspaceArray)>(*this,lib,"SDL_ConvertPixelsAndColorspaceArray",SideEffects::worstDefault,"SDL_ConvertPixelsAndColorspaceArray");
    addExtern<DAS_BIND_FUN(SDL_PremultiplyAlphaArray)>(*this,lib,"SDL_PremultiplyAlphaArray",SideEffects::worstDefault,"SDL_PremultiplyAlphaArray");
    addExtern<DAS_BIND_FUN(SDL_HasRectIntersectionRefs)>(*this,lib,"SDL_HasRectIntersectionRefs",SideEffects::worstDefault,"SDL_HasRectIntersectionRefs");
    addExtern<DAS_BIND_FUN(SDL_RectsEqualRefs)>(*this,lib,"SDL_RectsEqualRefs",SideEffects::worstDefault,"SDL_RectsEqualRefs");
    addExtern<DAS_BIND_FUN(SDL_RectEmptyRef)>(*this,lib,"SDL_RectEmptyRef",SideEffects::worstDefault,"SDL_RectEmptyRef");
    addExtern<DAS_BIND_FUN(SDL_PointInRectRefs)>(*this,lib,"SDL_PointInRectRefs",SideEffects::worstDefault,"SDL_PointInRectRefs");
    addExtern<DAS_BIND_FUN(SDL_GetRectIntersectionRefs)>(*this,lib,"SDL_GetRectIntersectionRefs",SideEffects::worstDefault,"SDL_GetRectIntersectionRefs");
    addExtern<DAS_BIND_FUN(SDL_GetRectUnionRefs)>(*this,lib,"SDL_GetRectUnionRefs",SideEffects::worstDefault,"SDL_GetRectUnionRefs");
    addExtern<DAS_BIND_FUN(SDL_GetRectAndLineIntersectionRefs)>(*this,lib,"SDL_GetRectAndLineIntersectionRefs",SideEffects::worstDefault,"SDL_GetRectAndLineIntersectionRefs");
    addExtern<DAS_BIND_FUN(SDL_GetRectEnclosingPointsArray)>(*this,lib,"SDL_GetRectEnclosingPointsArray",SideEffects::worstDefault,"SDL_GetRectEnclosingPointsArray");
    addExtern<DAS_BIND_FUN(SDL_GetRectEnclosingPointsAll)>(*this,lib,"SDL_GetRectEnclosingPointsAll",SideEffects::worstDefault,"SDL_GetRectEnclosingPointsAll");
    addExtern<DAS_BIND_FUN(SDL_HasRectIntersectionFloatRefs)>(*this,lib,"SDL_HasRectIntersectionFloatRefs",SideEffects::worstDefault,"SDL_HasRectIntersectionFloatRefs");
    addExtern<DAS_BIND_FUN(SDL_RectsEqualFloatRefs)>(*this,lib,"SDL_RectsEqualFloatRefs",SideEffects::worstDefault,"SDL_RectsEqualFloatRefs");
    addExtern<DAS_BIND_FUN(SDL_RectEmptyFloatRef)>(*this,lib,"SDL_RectEmptyFloatRef",SideEffects::worstDefault,"SDL_RectEmptyFloatRef");
    addExtern<DAS_BIND_FUN(SDL_PointInRectFloatRefs)>(*this,lib,"SDL_PointInRectFloatRefs",SideEffects::worstDefault,"SDL_PointInRectFloatRefs");
    addExtern<DAS_BIND_FUN(SDL_GetRectIntersectionFloatRefs)>(*this,lib,"SDL_GetRectIntersectionFloatRefs",SideEffects::worstDefault,"SDL_GetRectIntersectionFloatRefs");
    addExtern<DAS_BIND_FUN(SDL_GetRectUnionFloatRefs)>(*this,lib,"SDL_GetRectUnionFloatRefs",SideEffects::worstDefault,"SDL_GetRectUnionFloatRefs");
    addExtern<DAS_BIND_FUN(SDL_GetRectAndLineIntersectionFloatRefs)>(*this,lib,"SDL_GetRectAndLineIntersectionFloatRefs",SideEffects::worstDefault,"SDL_GetRectAndLineIntersectionFloatRefs");
    addExtern<DAS_BIND_FUN(SDL_GetRectEnclosingPointsFloatArray)>(*this,lib,"SDL_GetRectEnclosingPointsFloatArray",SideEffects::worstDefault,"SDL_GetRectEnclosingPointsFloatArray");
    addExtern<DAS_BIND_FUN(SDL_GetRectEnclosingPointsFloatAll)>(*this,lib,"SDL_GetRectEnclosingPointsFloatAll",SideEffects::worstDefault,"SDL_GetRectEnclosingPointsFloatAll");
    addExtern<DAS_BIND_FUN(SDL_RectToFRectRef)>(*this,lib,"SDL_RectToFRectRef",SideEffects::worstDefault,"SDL_RectToFRectRef");
    addExtern<DAS_BIND_FUN(SDL_RectsEqualEpsilonRefs)>(*this,lib,"SDL_RectsEqualEpsilonRefs",SideEffects::worstDefault,"SDL_RectsEqualEpsilonRefs");
    addExtern<DAS_BIND_FUN(SDL_SetClipboardDataCopy)>(*this,lib,"SDL_SetClipboardDataCopy",SideEffects::worstDefault,"SDL_SetClipboardDataCopy");
    addExtern<DAS_BIND_FUN(SDL_GetClipboardTextCopy)>(*this,lib,"SDL_GetClipboardTextCopy",SideEffects::worstDefault,"SDL_GetClipboardTextCopy");
    addExtern<DAS_BIND_FUN(SDL_GetPrimarySelectionTextCopy)>(*this,lib,"SDL_GetPrimarySelectionTextCopy",SideEffects::worstDefault,"SDL_GetPrimarySelectionTextCopy");
    addExtern<DAS_BIND_FUN(SDL_GetClipboardDataCopy)>(*this,lib,"SDL_GetClipboardDataCopy",SideEffects::worstDefault,"SDL_GetClipboardDataCopy");
    addExtern<DAS_BIND_FUN(SDL_GetClipboardMimeTypesCopy)>(*this,lib,"SDL_GetClipboardMimeTypesCopy",SideEffects::worstDefault,"SDL_GetClipboardMimeTypesCopy");
    addExtern<DAS_BIND_FUN(SDL_SetWindowHitTestBlock)>(*this,lib,"SDL_SetWindowHitTestBlock",SideEffects::worstDefault,"SDL_SetWindowHitTestBlock");
    addExtern<DAS_BIND_FUN(SDL_ClearWindowHitTestBlockChecked)>(*this,lib,"SDL_ClearWindowHitTestBlockChecked",SideEffects::worstDefault,"SDL_ClearWindowHitTestBlockChecked");
    addExtern<DAS_BIND_FUN(SDL_ClearWindowHitTestBlock)>(*this,lib,"SDL_ClearWindowHitTestBlock",SideEffects::worstDefault,"SDL_ClearWindowHitTestBlock");
    addExtern<DAS_BIND_FUN(SDL_GetSurfaceColorKeyRef)>(*this,lib,"SDL_GetSurfaceColorKeyRef",SideEffects::worstDefault,"SDL_GetSurfaceColorKeyRef");
    addExtern<DAS_BIND_FUN(SDL_GetSurfaceColorModRef)>(*this,lib,"SDL_GetSurfaceColorModRef",SideEffects::worstDefault,"SDL_GetSurfaceColorModRef");
    addExtern<DAS_BIND_FUN(SDL_GetSurfaceAlphaModRef)>(*this,lib,"SDL_GetSurfaceAlphaModRef",SideEffects::worstDefault,"SDL_GetSurfaceAlphaModRef");
    addExtern<DAS_BIND_FUN(SDL_GetSurfaceBlendModeRef)>(*this,lib,"SDL_GetSurfaceBlendModeRef",SideEffects::worstDefault,"SDL_GetSurfaceBlendModeRef");
    addExtern<DAS_BIND_FUN(SDL_SetSurfaceClipRectRef)>(*this,lib,"SDL_SetSurfaceClipRectRef",SideEffects::worstDefault,"SDL_SetSurfaceClipRectRef");
    addExtern<DAS_BIND_FUN(SDL_GetSurfaceClipRectRef)>(*this,lib,"SDL_GetSurfaceClipRectRef",SideEffects::worstDefault,"SDL_GetSurfaceClipRectRef");
    addExtern<DAS_BIND_FUN(SDL_ResetSurfaceClipRect)>(*this,lib,"SDL_ResetSurfaceClipRect",SideEffects::worstDefault,"SDL_ResetSurfaceClipRect");
    addExtern<DAS_BIND_FUN(SDL_GetRenderDrawBlendModeRef)>(*this,lib,"SDL_GetRenderDrawBlendModeRef",SideEffects::worstDefault,"SDL_GetRenderDrawBlendModeRef");
    addExtern<DAS_BIND_FUN(SDL_UpdateYUVTextureArrays)>(*this,lib,"SDL_UpdateYUVTextureArrays",SideEffects::worstDefault,"SDL_UpdateYUVTextureArrays");
    addExtern<DAS_BIND_FUN(SDL_UpdateNVTextureArrays)>(*this,lib,"SDL_UpdateNVTextureArrays",SideEffects::worstDefault,"SDL_UpdateNVTextureArrays");
    addExtern<DAS_BIND_FUN(SDL_GetTextureColorModRef)>(*this,lib,"SDL_GetTextureColorModRef",SideEffects::worstDefault,"SDL_GetTextureColorModRef");
    addExtern<DAS_BIND_FUN(SDL_GetTextureAlphaModRef)>(*this,lib,"SDL_GetTextureAlphaModRef",SideEffects::worstDefault,"SDL_GetTextureAlphaModRef");
    addExtern<DAS_BIND_FUN(SDL_GetTextureBlendModeRef)>(*this,lib,"SDL_GetTextureBlendModeRef",SideEffects::worstDefault,"SDL_GetTextureBlendModeRef");
    addExtern<DAS_BIND_FUN(SDL_LockTextureToSurfaceRef)>(*this,lib,"SDL_LockTextureToSurfaceRef",SideEffects::worstDefault,"SDL_LockTextureToSurfaceRef");
    addExtern<DAS_BIND_FUN(SDL_UpdateTextureRGBA8)>(*this,lib,"SDL_UpdateTextureRGBA8",SideEffects::worstDefault,"SDL_UpdateTextureRGBA8");
    addExtern<DAS_BIND_FUN(SDL_GetTextureColorModFloatRef)>(*this,lib,"SDL_GetTextureColorModFloatRef",SideEffects::worstDefault,"SDL_GetTextureColorModFloatRef");
    addExtern<DAS_BIND_FUN(SDL_GetTextureAlphaModFloatRef)>(*this,lib,"SDL_GetTextureAlphaModFloatRef",SideEffects::worstDefault,"SDL_GetTextureAlphaModFloatRef");
    addExtern<DAS_BIND_FUN(SDL_GetTextureScaleModeRef)>(*this,lib,"SDL_GetTextureScaleModeRef",SideEffects::worstDefault,"SDL_GetTextureScaleModeRef");
    addExtern<DAS_BIND_FUN(SDL_GetRendererNameCopy)>(*this,lib,"SDL_GetRendererNameCopy",SideEffects::worstDefault,"SDL_GetRendererNameCopy");
    addExtern<DAS_BIND_FUN(SDL_GetRenderSafeAreaRef)>(*this,lib,"SDL_GetRenderSafeAreaRef",SideEffects::worstDefault,"SDL_GetRenderSafeAreaRef");
    addExtern<DAS_BIND_FUN(SDL_GetRenderLogicalPresentationRef)>(*this,lib,"SDL_GetRenderLogicalPresentationRef",SideEffects::worstDefault,"SDL_GetRenderLogicalPresentationRef");
    addExtern<DAS_BIND_FUN(SDL_GetRenderLogicalPresentationRectRef)>(*this,lib,"SDL_GetRenderLogicalPresentationRectRef",SideEffects::worstDefault,"SDL_GetRenderLogicalPresentationRectRef");
    addExtern<DAS_BIND_FUN(SDL_RenderCoordinatesFromWindowRef)>(*this,lib,"SDL_RenderCoordinatesFromWindowRef",SideEffects::worstDefault,"SDL_RenderCoordinatesFromWindowRef");
    addExtern<DAS_BIND_FUN(SDL_RenderCoordinatesToWindowRef)>(*this,lib,"SDL_RenderCoordinatesToWindowRef",SideEffects::worstDefault,"SDL_RenderCoordinatesToWindowRef");
    addExtern<DAS_BIND_FUN(SDL_GetRenderOutputSizeRef)>(*this,lib,"SDL_GetRenderOutputSizeRef",SideEffects::worstDefault,"SDL_GetRenderOutputSizeRef");
    addExtern<DAS_BIND_FUN(SDL_GetCurrentRenderOutputSizeRef)>(*this,lib,"SDL_GetCurrentRenderOutputSizeRef",SideEffects::worstDefault,"SDL_GetCurrentRenderOutputSizeRef");
    addExtern<DAS_BIND_FUN(SDL_SetRenderViewportRef)>(*this,lib,"SDL_SetRenderViewportRef",SideEffects::worstDefault,"SDL_SetRenderViewportRef");
    addExtern<DAS_BIND_FUN(SDL_GetRenderViewportRef)>(*this,lib,"SDL_GetRenderViewportRef",SideEffects::worstDefault,"SDL_GetRenderViewportRef");
    addExtern<DAS_BIND_FUN(SDL_ResetRenderViewport)>(*this,lib,"SDL_ResetRenderViewport",SideEffects::worstDefault,"SDL_ResetRenderViewport");
    addExtern<DAS_BIND_FUN(SDL_SetRenderClipRectRef)>(*this,lib,"SDL_SetRenderClipRectRef",SideEffects::worstDefault,"SDL_SetRenderClipRectRef");
    addExtern<DAS_BIND_FUN(SDL_GetRenderClipRectRef)>(*this,lib,"SDL_GetRenderClipRectRef",SideEffects::worstDefault,"SDL_GetRenderClipRectRef");
    addExtern<DAS_BIND_FUN(SDL_DisableRenderClip)>(*this,lib,"SDL_DisableRenderClip",SideEffects::worstDefault,"SDL_DisableRenderClip");
    addExtern<DAS_BIND_FUN(SDL_GetRenderScaleRef)>(*this,lib,"SDL_GetRenderScaleRef",SideEffects::worstDefault,"SDL_GetRenderScaleRef");
    addExtern<DAS_BIND_FUN(SDL_RenderPointsArray)>(*this,lib,"SDL_RenderPointsArray",SideEffects::worstDefault,"SDL_RenderPointsArray");
    addExtern<DAS_BIND_FUN(SDL_RenderLinesArray)>(*this,lib,"SDL_RenderLinesArray",SideEffects::worstDefault,"SDL_RenderLinesArray");
    addExtern<DAS_BIND_FUN(SDL_RenderRectsArray)>(*this,lib,"SDL_RenderRectsArray",SideEffects::worstDefault,"SDL_RenderRectsArray");
    addExtern<DAS_BIND_FUN(SDL_RenderFillRectsArray)>(*this,lib,"SDL_RenderFillRectsArray",SideEffects::worstDefault,"SDL_RenderFillRectsArray");
    addExtern<DAS_BIND_FUN(SDL_RenderRectRef)>(*this,lib,"SDL_RenderRectRef",SideEffects::worstDefault,"SDL_RenderRectRef");
    addExtern<DAS_BIND_FUN(SDL_FillSurfaceAll)>(*this, lib, "SDL_FillSurfaceAll", SideEffects::worstDefault, "SDL_FillSurfaceAll");
        addExtern<DAS_BIND_FUN(SDL_FillSurfaceRectRef)>(*this, lib, "SDL_FillSurfaceRectRef", SideEffects::worstDefault, "SDL_FillSurfaceRectRef");
        addExtern<DAS_BIND_FUN(SDL_GetWindowSafeAreaRef)>(*this, lib, "SDL_GetWindowSafeAreaRef", SideEffects::worstDefault, "SDL_GetWindowSafeAreaRef");
        addExtern<DAS_BIND_FUN(SDL_GetWindowAspectRatioRef)>(*this, lib, "SDL_GetWindowAspectRatioRef", SideEffects::worstDefault, "SDL_GetWindowAspectRatioRef");
        addExtern<DAS_BIND_FUN(SDL_GetWindowBordersSizeRef)>(*this, lib, "SDL_GetWindowBordersSizeRef", SideEffects::worstDefault, "SDL_GetWindowBordersSizeRef");
        addExtern<DAS_BIND_FUN(SDL_GetWindowMinimumSizeRef)>(*this, lib, "SDL_GetWindowMinimumSizeRef", SideEffects::worstDefault, "SDL_GetWindowMinimumSizeRef");
        addExtern<DAS_BIND_FUN(SDL_GetWindowMaximumSizeRef)>(*this, lib, "SDL_GetWindowMaximumSizeRef", SideEffects::worstDefault, "SDL_GetWindowMaximumSizeRef");
        addExtern<DAS_BIND_FUN(SDL_GetDisplaysCopy)>(*this, lib, "SDL_GetDisplaysCopy", SideEffects::worstDefault, "SDL_GetDisplaysCopy");
        addExtern<DAS_BIND_FUN(SDL_GetWindowsCopy)>(*this, lib, "SDL_GetWindowsCopy", SideEffects::worstDefault, "SDL_GetWindowsCopy");
        addExtern<DAS_BIND_FUN(SDL_GetFullscreenDisplayModesCopy)>(*this, lib, "SDL_GetFullscreenDisplayModesCopy", SideEffects::worstDefault, "SDL_GetFullscreenDisplayModesCopy");
        addExtern<DAS_BIND_FUN(SDL_GetDesktopDisplayModeCopy)>(*this, lib, "SDL_GetDesktopDisplayModeCopy", SideEffects::worstDefault, "SDL_GetDesktopDisplayModeCopy");
        addExtern<DAS_BIND_FUN(SDL_GetCurrentDisplayModeCopy)>(*this, lib, "SDL_GetCurrentDisplayModeCopy", SideEffects::worstDefault, "SDL_GetCurrentDisplayModeCopy");
        addExtern<DAS_BIND_FUN(SDL_GetClosestFullscreenDisplayModeRef)>(*this, lib, "SDL_GetClosestFullscreenDisplayModeRef", SideEffects::worstDefault, "SDL_GetClosestFullscreenDisplayModeRef");
        addExtern<DAS_BIND_FUN(SDL_GetDisplayForPointRef)>(*this, lib, "SDL_GetDisplayForPointRef", SideEffects::worstDefault, "SDL_GetDisplayForPointRef");
        addExtern<DAS_BIND_FUN(SDL_GetDisplayForRectRef)>(*this, lib, "SDL_GetDisplayForRectRef", SideEffects::worstDefault, "SDL_GetDisplayForRectRef");
        addExtern<DAS_BIND_FUN(SDL_GetVideoDriverCopy)>(*this, lib, "SDL_GetVideoDriverCopy", SideEffects::worstDefault, "SDL_GetVideoDriverCopy");
        addExtern<DAS_BIND_FUN(SDL_GetDisplayNameCopy)>(*this, lib, "SDL_GetDisplayNameCopy", SideEffects::worstDefault, "SDL_GetDisplayNameCopy");
        addExtern<DAS_BIND_FUN(SDL_GetWindowTitleCopy)>(*this, lib, "SDL_GetWindowTitleCopy", SideEffects::worstDefault, "SDL_GetWindowTitleCopy");
        addExtern<DAS_BIND_FUN(SDL_GetCurrentVideoDriverCopy)>(*this, lib, "SDL_GetCurrentVideoDriverCopy", SideEffects::worstDefault, "SDL_GetCurrentVideoDriverCopy");
        addExtern<DAS_BIND_FUN(SDL_GetDisplayBoundsRef)>(*this, lib, "SDL_GetDisplayBoundsRef", SideEffects::worstDefault, "SDL_GetDisplayBoundsRef");
        addExtern<DAS_BIND_FUN(SDL_GetDisplayUsableBoundsRef)>(*this, lib, "SDL_GetDisplayUsableBoundsRef", SideEffects::worstDefault, "SDL_GetDisplayUsableBoundsRef");
        addExtern<DAS_BIND_FUN(SDL_GetWindowPositionRef)>(*this, lib, "SDL_GetWindowPositionRef", SideEffects::worstDefault, "SDL_GetWindowPositionRef");
        addExtern<DAS_BIND_FUN(SDL_GetWindowSizeRef)>(*this, lib, "SDL_GetWindowSizeRef", SideEffects::worstDefault, "SDL_GetWindowSizeRef");
        addExtern<DAS_BIND_FUN(SDL_GetWindowSizeInPixelsRef)>(*this, lib, "SDL_GetWindowSizeInPixelsRef", SideEffects::worstDefault, "SDL_GetWindowSizeInPixelsRef");
        addExtern<DAS_BIND_FUN(SDL_SetErrorText)>(*this, lib, "SDL_SetErrorText", SideEffects::worstDefault, "SDL_SetErrorText");
        addExtern<DAS_BIND_FUN(SDL_GetErrorCopy)>(*this, lib, "SDL_GetErrorCopy", SideEffects::worstDefault, "SDL_GetErrorCopy");
        addExtern<DAS_BIND_FUN(SDL_GetCurrentTimeRef)>(*this, lib, "SDL_GetCurrentTimeRef", SideEffects::worstDefault, "SDL_GetCurrentTimeRef");
        addExtern<DAS_BIND_FUN(SDL_GetDateTimeLocalePreferencesRef)>(*this, lib, "SDL_GetDateTimeLocalePreferencesRef", SideEffects::worstDefault, "SDL_GetDateTimeLocalePreferencesRef");
        addExtern<DAS_BIND_FUN(SDL_TimeToDateTimeRef)>(*this, lib, "SDL_TimeToDateTimeRef", SideEffects::worstDefault, "SDL_TimeToDateTimeRef");
        addExtern<DAS_BIND_FUN(SDL_DateTimeToTimeRef)>(*this, lib, "SDL_DateTimeToTimeRef", SideEffects::worstDefault, "SDL_DateTimeToTimeRef");
        addExtern<DAS_BIND_FUN(SDL_TimeToWindowsRef)>(*this, lib, "SDL_TimeToWindowsRef", SideEffects::worstDefault, "SDL_TimeToWindowsRef");
        addExtern<DAS_BIND_FUN(SDL_LogText)>(*this, lib, "SDL_LogText", SideEffects::worstDefault, "SDL_LogText");
        addExtern<DAS_BIND_FUN(SDL_LogMessageText)>(*this, lib, "SDL_LogMessageText", SideEffects::worstDefault, "SDL_LogMessageText");
        addExtern<DAS_BIND_FUN(SDL_LogTraceText)>(*this, lib, "SDL_LogTraceText", SideEffects::worstDefault, "SDL_LogTraceText");
        addExtern<DAS_BIND_FUN(SDL_LogVerboseText)>(*this, lib, "SDL_LogVerboseText", SideEffects::worstDefault, "SDL_LogVerboseText");
        addExtern<DAS_BIND_FUN(SDL_LogDebugText)>(*this, lib, "SDL_LogDebugText", SideEffects::worstDefault, "SDL_LogDebugText");
        addExtern<DAS_BIND_FUN(SDL_LogInfoText)>(*this, lib, "SDL_LogInfoText", SideEffects::worstDefault, "SDL_LogInfoText");
        addExtern<DAS_BIND_FUN(SDL_LogWarnText)>(*this, lib, "SDL_LogWarnText", SideEffects::worstDefault, "SDL_LogWarnText");
        addExtern<DAS_BIND_FUN(SDL_LogErrorText)>(*this, lib, "SDL_LogErrorText", SideEffects::worstDefault, "SDL_LogErrorText");
        addExtern<DAS_BIND_FUN(SDL_LogCriticalText)>(*this, lib, "SDL_LogCriticalText", SideEffects::worstDefault, "SDL_LogCriticalText");
        addExtern<DAS_BIND_FUN(SDL_GetAppMetadataOptionalCopy)>(*this,lib,"SDL_GetAppMetadataOptionalCopy",SideEffects::worstDefault,"SDL_GetAppMetadataOptionalCopy");
        addExtern<DAS_BIND_FUN(SDL_GetDisplayNameValue)>(*this,lib,"SDL_GetDisplayNameValue",SideEffects::worstDefault,"SDL_GetDisplayNameValue");
        addExtern<DAS_BIND_FUN(SDL_GetWindowTitleValue)>(*this,lib,"SDL_GetWindowTitleValue",SideEffects::worstDefault,"SDL_GetWindowTitleValue");
        addExtern<DAS_BIND_FUN(SDL_GetRenderDriverValue)>(*this,lib,"SDL_GetRenderDriverValue",SideEffects::worstDefault,"SDL_GetRenderDriverValue");
        addExtern<DAS_BIND_FUN(SDL_GetRendererNameValue)>(*this,lib,"SDL_GetRendererNameValue",SideEffects::worstDefault,"SDL_GetRendererNameValue");
        addExtern<DAS_BIND_FUN(SDL_GetClipboardTextValue)>(*this,lib,"SDL_GetClipboardTextValue",SideEffects::worstDefault,"SDL_GetClipboardTextValue");
        addExtern<DAS_BIND_FUN(SDL_GetPrimarySelectionTextValue)>(*this,lib,"SDL_GetPrimarySelectionTextValue",SideEffects::worstDefault,"SDL_GetPrimarySelectionTextValue");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_GetGPUShaderEntryPointValue)>(*this,lib,"SDL_GetGPUShaderEntryPointValue",SideEffects::worstDefault,"sdl3_handles::SDL_GetGPUShaderEntryPointValue");
        addExtern<DAS_BIND_FUN(SDL_GetPropertyStringValue)>(*this,lib,"SDL_GetPropertyStringValue",SideEffects::worstDefault,"SDL_GetPropertyStringValue");
        addExtern<DAS_BIND_FUN(SDL_GetHintOptionalCopy)>(*this, lib, "SDL_GetHintOptionalCopy", SideEffects::worstDefault, "SDL_GetHintOptionalCopy");
        addExtern<DAS_BIND_FUN(SDL_GetHintCopy)>(*this, lib, "SDL_GetHintCopy", SideEffects::worstDefault, "SDL_GetHintCopy");
        addExtern<DAS_BIND_FUN(SDL_GetAppMetadataPropertyCopy)>(*this, lib, "SDL_GetAppMetadataPropertyCopy", SideEffects::worstDefault, "SDL_GetAppMetadataPropertyCopy");
        addExtern<DAS_BIND_FUN(SDL_ClearAppMetadataProperty)>(*this, lib, "SDL_ClearAppMetadataProperty", SideEffects::worstDefault, "SDL_ClearAppMetadataProperty");
        addExtern<DAS_BIND_FUN(SDL_GetStringPropertyCopy)>(*this, lib, "SDL_GetStringPropertyCopy", SideEffects::worstDefault, "SDL_GetStringPropertyCopy");
        addExtern<DAS_BIND_FUN(SDL_GetPropertyNamesCopy)>(*this, lib, "SDL_GetPropertyNamesCopy", SideEffects::worstDefault, "SDL_GetPropertyNamesCopy");
#ifdef DASSDL3_TESTING
        addExtern<DAS_BIND_FUN(SDLTestCreateDormantTimer)>(*this, lib, "SDLTestCreateDormantTimer", SideEffects::worstDefault, "SDLTestCreateDormantTimer");
        addExtern<DAS_BIND_FUN(SDLTestBeginLog)>(*this, lib, "SDLTestBeginLog", SideEffects::worstDefault, "SDLTestBeginLog");
        addExtern<DAS_BIND_FUN(SDLTestLogMatches)>(*this, lib, "SDLTestLogMatches", SideEffects::worstDefault, "SDLTestLogMatches");
        addExtern<DAS_BIND_FUN(SDLTestEndLog)>(*this, lib, "SDLTestEndLog", SideEffects::worstDefault, "SDLTestEndLog");
        addExtern<DAS_BIND_FUN(SDLTestThreadError)>(*this, lib, "SDLTestThreadError", SideEffects::worstDefault, "SDLTestThreadError");
        addExtern<DAS_BIND_FUN(SDLTestPropertyPointer)>(*this, lib, "SDLTestPropertyPointer", SideEffects::worstDefault, "SDLTestPropertyPointer");
        addExtern<DAS_BIND_FUN(SDLTestAttachPropertyCleanup)>(*this, lib, "SDLTestAttachPropertyCleanup", SideEffects::worstDefault, "SDLTestAttachPropertyCleanup");
        addExtern<DAS_BIND_FUN(SDLTestPropertyCleanupCount)>(*this, lib, "SDLTestPropertyCleanupCount", SideEffects::worstDefault, "SDLTestPropertyCleanupCount");
        addExtern<DAS_BIND_FUN(SDLTestPropertiesOtherThread)>(*this, lib, "SDLTestPropertiesOtherThread", SideEffects::worstDefault, "SDLTestPropertiesOtherThread");
#endif
        addExtern<DAS_BIND_FUN(SDL_CreateGPUDeviceDefault)>(*this, lib, "SDL_CreateGPUDeviceDefault", SideEffects::worstDefault, "SDL_CreateGPUDeviceDefault");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUShaderBytes)>(*this, lib, "SDL_CreateGPUShaderBytes", SideEffects::worstDefault, "SDL_CreateGPUShaderBytes");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUComputePipelineBytes)>(*this, lib, "SDL_CreateGPUComputePipelineBytes", SideEffects::worstDefault, "SDL_CreateGPUComputePipelineBytes");
        addExtern<DAS_BIND_FUN(SDL_LoadGPUShaderFile)>(*this, lib, "SDL_LoadGPUShaderFile", SideEffects::worstDefault, "SDL_LoadGPUShaderFile");
        addExtern<DAS_BIND_FUN(SDL_LoadGPUComputePipelineFile)>(*this, lib, "SDL_LoadGPUComputePipelineFile", SideEffects::worstDefault, "SDL_LoadGPUComputePipelineFile");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUGraphicsPipelineArrays)>(*this, lib, "SDL_CreateGPUGraphicsPipelineArrays", SideEffects::worstDefault, "SDL_CreateGPUGraphicsPipelineArrays");
        addExtern<DAS_BIND_FUN(SDL_WriteGPUTransferBufferBytes)>(*this, lib, "SDL_WriteGPUTransferBufferBytes", SideEffects::worstDefault, "SDL_WriteGPUTransferBufferBytes");
        addExtern<DAS_BIND_FUN(SDL_ReadGPUTransferBufferBytes)>(*this, lib, "SDL_ReadGPUTransferBufferBytes", SideEffects::worstDefault, "SDL_ReadGPUTransferBufferBytes");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUBufferRef)>(*this, lib, "SDL_CreateGPUBufferRef", SideEffects::worstDefault, "SDL_CreateGPUBufferRef");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUTextureRef)>(*this, lib, "SDL_CreateGPUTextureRef", SideEffects::worstDefault, "SDL_CreateGPUTextureRef");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUTransferBufferRef)>(*this, lib, "SDL_CreateGPUTransferBufferRef", SideEffects::worstDefault, "SDL_CreateGPUTransferBufferRef");
        addExtern<DAS_BIND_FUN(SDL_CreateGPUSamplerRef)>(*this, lib, "SDL_CreateGPUSamplerRef", SideEffects::worstDefault, "SDL_CreateGPUSamplerRef");
        addExtern<DAS_BIND_FUN(SDL_SetGPUViewportRef)>(*this, lib, "SDL_SetGPUViewportRef", SideEffects::worstDefault, "SDL_SetGPUViewportRef");
        addExtern<DAS_BIND_FUN(SDL_SetGPUScissorRef)>(*this, lib, "SDL_SetGPUScissorRef", SideEffects::worstDefault, "SDL_SetGPUScissorRef");
        addExtern<DAS_BIND_FUN(SDL_BlitGPUTextureRef)>(*this, lib, "SDL_BlitGPUTextureRef", SideEffects::worstDefault, "SDL_BlitGPUTextureRef");
        addExtern<DAS_BIND_FUN(SDL_BindGPUIndexBufferRef)>(*this, lib, "SDL_BindGPUIndexBufferRef", SideEffects::worstDefault, "SDL_BindGPUIndexBufferRef");
        addExtern<DAS_BIND_FUN(SDL_UploadToGPUBufferRef)>(*this, lib, "SDL_UploadToGPUBufferRef", SideEffects::worstDefault, "SDL_UploadToGPUBufferRef");
        addExtern<DAS_BIND_FUN(SDL_UploadToGPUTextureRef)>(*this, lib, "SDL_UploadToGPUTextureRef", SideEffects::worstDefault, "SDL_UploadToGPUTextureRef");
        addExtern<DAS_BIND_FUN(SDL_DownloadFromGPUBufferRef)>(*this, lib, "SDL_DownloadFromGPUBufferRef", SideEffects::worstDefault, "SDL_DownloadFromGPUBufferRef");
        addExtern<DAS_BIND_FUN(SDL_DownloadFromGPUTextureRef)>(*this, lib, "SDL_DownloadFromGPUTextureRef", SideEffects::worstDefault, "SDL_DownloadFromGPUTextureRef");
        addExtern<DAS_BIND_FUN(SDL_CopyGPUBufferToBufferRef)>(*this, lib, "SDL_CopyGPUBufferToBufferRef", SideEffects::worstDefault, "SDL_CopyGPUBufferToBufferRef");
        addExtern<DAS_BIND_FUN(SDL_CopyGPUTextureToTextureRef)>(*this, lib, "SDL_CopyGPUTextureToTextureRef", SideEffects::worstDefault, "SDL_CopyGPUTextureToTextureRef");
        addExtern<DAS_BIND_FUN(SDL_BeginGPURenderPassDepthArray)>(*this, lib, "SDL_BeginGPURenderPassDepthArray", SideEffects::worstDefault, "SDL_BeginGPURenderPassDepthArray");
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
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_AcquireGPUCommandBufferChecked)>(*this, lib, "SDL_AcquireGPUCommandBufferChecked", SideEffects::worstDefault, "sdl3_handles::SDL_AcquireGPUCommandBufferChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_BeginGPURenderPassChecked)>(*this, lib, "SDL_BeginGPURenderPassChecked", SideEffects::worstDefault, "sdl3_handles::SDL_BeginGPURenderPassChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_EndGPURenderPassChecked)>(*this, lib, "SDL_EndGPURenderPassChecked", SideEffects::worstDefault, "sdl3_handles::SDL_EndGPURenderPassChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CancelGPUCommandBufferChecked)>(*this, lib, "SDL_CancelGPUCommandBufferChecked", SideEffects::worstDefault, "sdl3_handles::SDL_CancelGPUCommandBufferChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_SubmitGPUCommandBufferChecked)>(*this, lib, "SDL_SubmitGPUCommandBufferChecked", SideEffects::worstDefault, "sdl3_handles::SDL_SubmitGPUCommandBufferChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_BindGPUGraphicsPipelineChecked)>(*this, lib, "SDL_BindGPUGraphicsPipelineChecked", SideEffects::worstDefault, "sdl3_handles::SDL_BindGPUGraphicsPipelineChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_SetGPUViewportChecked)>(*this, lib, "SDL_SetGPUViewportChecked", SideEffects::worstDefault, "sdl3_handles::SDL_SetGPUViewportChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_SetGPUScissorChecked)>(*this, lib, "SDL_SetGPUScissorChecked", SideEffects::worstDefault, "sdl3_handles::SDL_SetGPUScissorChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_SetGPUBlendConstantsChecked)>(*this, lib, "SDL_SetGPUBlendConstantsChecked", SideEffects::worstDefault, "sdl3_handles::SDL_SetGPUBlendConstantsChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_BindGPUVertexBuffersChecked)>(*this, lib, "SDL_BindGPUVertexBuffersChecked", SideEffects::worstDefault, "sdl3_handles::SDL_BindGPUVertexBuffersChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_BindGPUIndexBufferChecked)>(*this, lib, "SDL_BindGPUIndexBufferChecked", SideEffects::worstDefault, "sdl3_handles::SDL_BindGPUIndexBufferChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_BindGPUSamplersChecked)>(*this, lib, "SDL_BindGPUSamplersChecked", SideEffects::worstDefault, "sdl3_handles::SDL_BindGPUSamplersChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_PushGPUUniformBytesChecked)>(*this, lib, "SDL_PushGPUUniformBytesChecked", SideEffects::worstDefault, "sdl3_handles::SDL_PushGPUUniformBytesChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_PushGPUUniformVectorsChecked)>(*this, lib, "SDL_PushGPUUniformVectorsChecked", SideEffects::worstDefault, "sdl3_handles::SDL_PushGPUUniformVectorsChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_DrawGPUPrimitivesChecked)>(*this, lib, "SDL_DrawGPUPrimitivesChecked", SideEffects::worstDefault, "sdl3_handles::SDL_DrawGPUPrimitivesChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_DrawGPUIndexedPrimitivesChecked)>(*this, lib, "SDL_DrawGPUIndexedPrimitivesChecked", SideEffects::worstDefault, "sdl3_handles::SDL_DrawGPUIndexedPrimitivesChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CreateGPUCheckedGraphicsPipeline)>(*this, lib, "SDL_CreateGPUCheckedGraphicsPipeline", SideEffects::worstDefault, "sdl3_handles::SDL_CreateGPUCheckedGraphicsPipeline");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_ReleaseGPUCheckedGraphicsPipeline)>(*this, lib, "SDL_ReleaseGPUCheckedGraphicsPipeline", SideEffects::worstDefault, "sdl3_handles::SDL_ReleaseGPUCheckedGraphicsPipeline");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_GetGPUCheckedGraphicsPipelineInfo)>(*this, lib, "SDL_GetGPUCheckedGraphicsPipelineInfo", SideEffects::worstDefault, "sdl3_handles::SDL_GetGPUCheckedGraphicsPipelineInfo");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CreateGPUCheckedShader)>(*this, lib, "SDL_CreateGPUCheckedShader", SideEffects::worstDefault, "sdl3_handles::SDL_CreateGPUCheckedShader");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_LoadGPUCheckedShader)>(*this, lib, "SDL_LoadGPUCheckedShader", SideEffects::worstDefault, "sdl3_handles::SDL_LoadGPUCheckedShader");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_ReleaseGPUCheckedShader)>(*this, lib, "SDL_ReleaseGPUCheckedShader", SideEffects::worstDefault, "sdl3_handles::SDL_ReleaseGPUCheckedShader");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_GetGPUCheckedShaderInfo)>(*this, lib, "SDL_GetGPUCheckedShaderInfo", SideEffects::worstDefault, "sdl3_handles::SDL_GetGPUCheckedShaderInfo");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_GetGPUCheckedShaderEntryPoint)>(*this, lib, "SDL_GetGPUCheckedShaderEntryPoint", SideEffects::worstDefault, "sdl3_handles::SDL_GetGPUCheckedShaderEntryPoint");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CreateGPUCheckedSampler)>(*this, lib, "SDL_CreateGPUCheckedSampler", SideEffects::worstDefault, "sdl3_handles::SDL_CreateGPUCheckedSampler");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_ReleaseGPUCheckedSampler)>(*this, lib, "SDL_ReleaseGPUCheckedSampler", SideEffects::worstDefault, "sdl3_handles::SDL_ReleaseGPUCheckedSampler");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_GetGPUCheckedSamplerInfo)>(*this, lib, "SDL_GetGPUCheckedSamplerInfo", SideEffects::worstDefault, "sdl3_handles::SDL_GetGPUCheckedSamplerInfo");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CreateGPUVolume)>(*this, lib, "SDL_CreateGPUVolume", SideEffects::worstDefault, "sdl3_handles::SDL_CreateGPUVolume");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_ReleaseGPUVolume)>(*this, lib, "SDL_ReleaseGPUVolume", SideEffects::worstDefault, "sdl3_handles::SDL_ReleaseGPUVolume");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_UploadGPUVolume)>(*this, lib, "SDL_UploadGPUVolume", SideEffects::worstDefault, "sdl3_handles::SDL_UploadGPUVolume");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CopyGPUVolume)>(*this, lib, "SDL_CopyGPUVolume", SideEffects::worstDefault, "sdl3_handles::SDL_CopyGPUVolume");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_RequestGPUVolumeReadback)>(*this, lib, "SDL_RequestGPUVolumeReadback", SideEffects::worstDefault, "sdl3_handles::SDL_RequestGPUVolumeReadback");
        addExtern<DAS_BIND_FUN(SDL_SetErrorMessage)>(*this, lib, "SDL_SetErrorMessage", SideEffects::worstDefault, "SDL_SetErrorMessage");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_GPURecordingDiscard)>(*this, lib, "SDL_GPURecordingDiscard", SideEffects::worstDefault, "sdl3_handles::SDL_GPURecordingDiscard");
        addExtern<DAS_BIND_FUN(SDL_LoadBMPTextureOwned)>(*this, lib, "SDL_LoadBMPTextureOwned", SideEffects::worstDefault, "SDL_LoadBMPTextureOwned");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CreateGPUFloatVertexBuffer)>(*this, lib, "SDL_CreateGPUFloatVertexBuffer", SideEffects::worstDefault, "sdl3_handles::SDL_CreateGPUFloatVertexBuffer");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CreateGPUCheckedIndexBuffer)>(*this, lib, "SDL_CreateGPUCheckedIndexBuffer", SideEffects::worstDefault, "sdl3_handles::SDL_CreateGPUCheckedIndexBuffer");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_ReleaseGPUCheckedIndexBuffer)>(*this, lib, "SDL_ReleaseGPUCheckedIndexBuffer", SideEffects::worstDefault, "sdl3_handles::SDL_ReleaseGPUCheckedIndexBuffer");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CreateGPUColorTargetTexture)>(*this, lib, "SDL_CreateGPUColorTargetTexture", SideEffects::worstDefault, "sdl3_handles::SDL_CreateGPUColorTargetTexture");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_GenerateGPUTextureMipmapsChecked)>(*this, lib, "SDL_GenerateGPUTextureMipmapsChecked", SideEffects::worstDefault, "sdl3_handles::SDL_GenerateGPUTextureMipmapsChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_BlitGPUTextureChecked)>(*this, lib, "SDL_BlitGPUTextureChecked", SideEffects::worstDefault, "sdl3_handles::SDL_BlitGPUTextureChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUWindowPresentSupported)>(*this, lib, "SDL_GPUWindowPresentSupported", SideEffects::worstDefault, "SDL_GPUWindowPresentSupported");
        addExtern<DAS_BIND_FUN(SDL_GPUWindowCompositionSupported)>(*this, lib, "SDL_GPUWindowCompositionSupported", SideEffects::worstDefault, "SDL_GPUWindowCompositionSupported");
        addExtern<DAS_BIND_FUN(SDL_GPUWindowFormatChecked)>(*this, lib, "SDL_GPUWindowFormatChecked", SideEffects::worstDefault, "SDL_GPUWindowFormatChecked");
        addExtern<DAS_BIND_FUN(SDL_ConfigureGPUSwapchainChecked)>(*this, lib, "SDL_ConfigureGPUSwapchainChecked", SideEffects::worstDefault, "SDL_ConfigureGPUSwapchainChecked");
        addExtern<DAS_BIND_FUN(SDL_SetGPUFramesInFlightChecked)>(*this, lib, "SDL_SetGPUFramesInFlightChecked", SideEffects::worstDefault, "SDL_SetGPUFramesInFlightChecked");
        addExtern<DAS_BIND_FUN(SDL_WaitGPUSwapchainChecked)>(*this, lib, "SDL_WaitGPUSwapchainChecked", SideEffects::worstDefault, "SDL_WaitGPUSwapchainChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CreateGPUTypedTransferTexture)>(*this, lib, "SDL_CreateGPUTypedTransferTexture", SideEffects::worstDefault, "sdl3_handles::SDL_CreateGPUTypedTransferTexture");
        addExtern<DAS_BIND_FUN(SDL_GPUDriverCountChecked)>(*this, lib, "SDL_GPUDriverCountChecked", SideEffects::worstDefault, "SDL_GPUDriverCountChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUDriverNameCopy)>(*this, lib, "SDL_GPUDriverNameCopy", SideEffects::worstDefault, "SDL_GPUDriverNameCopy");
        addExtern<DAS_BIND_FUN(SDL_GPUShaderSupportChecked)>(*this, lib, "SDL_GPUShaderSupportChecked", SideEffects::worstDefault, "SDL_GPUShaderSupportChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_SetGPUDataBufferNameChecked)>(*this, lib, "SDL_SetGPUDataBufferNameChecked", SideEffects::worstDefault, "sdl3_handles::SDL_SetGPUDataBufferNameChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_SetGPUTransferTextureNameChecked)>(*this, lib, "SDL_SetGPUTransferTextureNameChecked", SideEffects::worstDefault, "sdl3_handles::SDL_SetGPUTransferTextureNameChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUTextureTransferSupportedChecked)>(*this, lib, "SDL_GPUTextureTransferSupportedChecked", SideEffects::worstDefault, "SDL_GPUTextureTransferSupportedChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUFormatBlockExtentChecked)>(*this, lib, "SDL_GPUFormatBlockExtentChecked", SideEffects::worstDefault, "SDL_GPUFormatBlockExtentChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUFormatBlockSizeChecked)>(*this, lib, "SDL_GPUFormatBlockSizeChecked", SideEffects::worstDefault, "SDL_GPUFormatBlockSizeChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUFormatSizeChecked)>(*this, lib, "SDL_GPUFormatSizeChecked", SideEffects::worstDefault, "SDL_GPUFormatSizeChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUFormatSupportedChecked)>(*this, lib, "SDL_GPUFormatSupportedChecked", SideEffects::worstDefault, "SDL_GPUFormatSupportedChecked");
        addExtern<DAS_BIND_FUN(SDL_GPUSampleCountSupportedChecked)>(*this, lib, "SDL_GPUSampleCountSupportedChecked", SideEffects::worstDefault, "SDL_GPUSampleCountSupportedChecked");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CreateGPUColorTransferTexture)>(*this, lib, "SDL_CreateGPUColorTransferTexture", SideEffects::worstDefault, "sdl3_handles::SDL_CreateGPUColorTransferTexture");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CreateGPUTransferTexture)>(*this, lib, "SDL_CreateGPUTransferTexture", SideEffects::worstDefault, "sdl3_handles::SDL_CreateGPUTransferTexture");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_ReleaseGPUTransferTexture)>(*this, lib, "SDL_ReleaseGPUTransferTexture", SideEffects::worstDefault, "sdl3_handles::SDL_ReleaseGPUTransferTexture");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_UploadGPUTextureRegion)>(*this, lib, "SDL_UploadGPUTextureRegion", SideEffects::worstDefault, "sdl3_handles::SDL_UploadGPUTextureRegion");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CopyGPUTextureRegion)>(*this, lib, "SDL_CopyGPUTextureRegion", SideEffects::worstDefault, "sdl3_handles::SDL_CopyGPUTextureRegion");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_RequestGPUTextureReadback)>(*this, lib, "SDL_RequestGPUTextureReadback", SideEffects::worstDefault, "sdl3_handles::SDL_RequestGPUTextureReadback");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CreateGPUDataBuffer)>(*this, lib, "SDL_CreateGPUDataBuffer", SideEffects::worstDefault, "sdl3_handles::SDL_CreateGPUDataBuffer");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_ReleaseGPUDataBuffer)>(*this, lib, "SDL_ReleaseGPUDataBuffer", SideEffects::worstDefault, "sdl3_handles::SDL_ReleaseGPUDataBuffer");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_UpdateGPUDataBuffer)>(*this, lib, "SDL_UpdateGPUDataBuffer", SideEffects::worstDefault, "sdl3_handles::SDL_UpdateGPUDataBuffer");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_CopyGPUDataBuffer)>(*this, lib, "SDL_CopyGPUDataBuffer", SideEffects::worstDefault, "sdl3_handles::SDL_CopyGPUDataBuffer");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_RequestGPUBufferReadback)>(*this, lib, "SDL_RequestGPUBufferReadback", SideEffects::worstDefault, "sdl3_handles::SDL_RequestGPUBufferReadback");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_PollGPUReadback)>(*this, lib, "SDL_PollGPUReadback", SideEffects::worstDefault, "sdl3_handles::SDL_PollGPUReadback");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_WaitGPUReadback)>(*this, lib, "SDL_WaitGPUReadback", SideEffects::worstDefault, "sdl3_handles::SDL_WaitGPUReadback");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_ReadGPUReadback)>(*this, lib, "SDL_ReadGPUReadback", SideEffects::worstDefault, "sdl3_handles::SDL_ReadGPUReadback");
        addExtern<DAS_BIND_FUN(sdl3_handles::SDL_ReleaseGPUReadback)>(*this, lib, "SDL_ReleaseGPUReadback", SideEffects::worstDefault, "sdl3_handles::SDL_ReleaseGPUReadback");
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
        addExtern<DAS_BIND_FUN(sdl3_test::gpu_handle_echo)>(*this, lib, "SDLTestGPUHandleEcho", SideEffects::worstDefault, "sdl3_test::gpu_handle_echo");
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
        addExtern<DAS_BIND_FUN(sdl3_test::result_states)>(*this,lib,"SDLTestResultStates",SideEffects::worstDefault,"sdl3_test::result_states");
        addExtern<DAS_BIND_FUN(sdl3_test::reset)>(*this, lib, "SDLTestReset", SideEffects::worstDefault, "sdl3_test::reset");
        addExtern<DAS_BIND_FUN(sdl3_callback_test::reset)>(*this,lib,"SDLTestCallbacksReset",SideEffects::worstDefault,"sdl3_callback_test::reset");
        addExtern<DAS_BIND_FUN(sdl3_callback_test::cleanup_count)>(*this,lib,"SDLTestClipboardCleanupCount",SideEffects::worstDefault,"sdl3_callback_test::cleanup_count");
        addExtern<DAS_BIND_FUN(sdl3_callback_test::request_count)>(*this,lib,"SDLTestClipboardRequestCount",SideEffects::worstDefault,"sdl3_callback_test::request_count");
        addExtern<DAS_BIND_FUN(sdl3_callback_test::hit_count)>(*this,lib,"SDLTestHitCount",SideEffects::worstDefault,"sdl3_callback_test::hit_count");
        addExtern<DAS_BIND_FUN(sdl3_callback_test::provider)>(*this,lib,"SDLTestClipboardProvider",SideEffects::worstDefault,"sdl3_callback_test::provider");
        addExtern<DAS_BIND_FUN(sdl3_callback_test::cleaner)>(*this,lib,"SDLTestClipboardCleaner",SideEffects::worstDefault,"sdl3_callback_test::cleaner");
        addExtern<DAS_BIND_FUN(sdl3_callback_test::hitter)>(*this,lib,"SDLTestHitCallback",SideEffects::worstDefault,"sdl3_callback_test::hitter");
        addExtern<DAS_BIND_FUN(sdl3_callback_test::probe)>(*this,lib,"SDLTestWindowHit",SideEffects::worstDefault,"sdl3_callback_test::probe");
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
