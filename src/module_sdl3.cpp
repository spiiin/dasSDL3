#include "daScript/daScript.h"
#include "daScript/ast/ast_handle.h"
#include "sdl3_adapters.h"
#include "sdl3_input.h"
#include "sdl3_audio.h"
#include "sdl3_pixels.h"
#include "sdl3_geometry.h"
#include "sdl3_gpu.h"
#include "sdl3_gpu_mesh.h"
#include "sdl3_gpu_3d.h"
#ifdef DASSDL3_TYPES_INCLUDE
#include DASSDL3_TYPES_INCLUDE
#else
#include "generated/sdl3_types.inc"
#endif
#include "sdl3_scopes.h"
#ifdef DASSDL3_TESTING
#include "../tests/resource_probe.h"
#include "../tests/input_probe.h"
#include "../tests/audio_probe.h"
#include "../tests/geometry_probe.h"
#include "../tests/gpu_probe.h"
#include "../tests/gpu_triangle_probe.h"
#include "../tests/gpu_mesh_probe.h"
#include "../tests/gpu_3d_probe.h"
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
        addExtern<DAS_BIND_FUN(SDL_CreateGPUDeviceScoped)>(*this, lib, "SDL_CreateGPUDeviceScoped", SideEffects::worstDefault, "SDL_CreateGPUDeviceScoped");
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
