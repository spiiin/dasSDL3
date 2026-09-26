#include "daScript/daScript.h"
#include "daScript/ast/ast_handle.h"
#include "sdl3_adapters.h"
#include "sdl3_input.h"
#include "sdl3_diagnostics.h"
#include "sdl3_texture_load.h"
#include "sdl3_pixels.h"
#include "sdl3_geometry.h"
#include "sdl3_audio.h"
#include "sdl3_video.h"
#include "generated/sdl3_types.inc"
static_assert(sizeof(void*)==4, "Web profile requires wasm32");
static_assert(SDL_VERSION==3004016, "Revalidate Web profile on SDL update");
namespace das {
class Module_dasSDL3 : public Module {
public:
    Module_dasSDL3() : Module("sdl3") {
        ModuleLibrary lib(this);
        lib.addBuiltInModule();
        #include "generated/sdl3_functions.inc"
        addExtern<DAS_BIND_FUN(SDL_EventIsEscape)>(*this,lib,"SDL_EventIsEscape",SideEffects::worstDefault,"SDL_EventIsEscape");
        addExtern<DAS_BIND_FUN(SDL_EventIsQuit)>(*this,lib,"SDL_EventIsQuit",SideEffects::worstDefault,"SDL_EventIsQuit");
        addExtern<DAS_BIND_FUN(SDL_GetErrorCopy)>(*this,lib,"SDL_GetErrorCopy",SideEffects::worstDefault,"SDL_GetErrorCopy");
        addExtern<DAS_BIND_FUN(SDL_GetMouseStateRef)>(*this,lib,"SDL_GetMouseStateRef",SideEffects::worstDefault,"SDL_GetMouseStateRef");
        addExtern<DAS_BIND_FUN(SDL_GetTextureSizeRef)>(*this,lib,"SDL_GetTextureSizeRef",SideEffects::worstDefault,"SDL_GetTextureSizeRef");
        addExtern<DAS_BIND_FUN(SDL_InputWindowID)>(*this,lib,"SDL_InputWindowID",SideEffects::worstDefault,"SDL_InputWindowID");
        addExtern<DAS_BIND_FUN(SDL_IsScancodeDown)>(*this,lib,"SDL_IsScancodeDown",SideEffects::worstDefault,"SDL_IsScancodeDown");
        addExtern<DAS_BIND_FUN(SDL_KeyScancode)>(*this,lib,"SDL_KeyScancode",SideEffects::worstDefault,"SDL_KeyScancode");
        addExtern<DAS_BIND_FUN(SDL_MouseWheelFlipped)>(*this,lib,"SDL_MouseWheelFlipped",SideEffects::worstDefault,"SDL_MouseWheelFlipped");
        addExtern<DAS_BIND_FUN(SDL_PollEventRef)>(*this,lib,"SDL_PollEventRef",SideEffects::worstDefault,"SDL_PollEventRef");
        addExtern<DAS_BIND_FUN(SDL_PushEventRef)>(*this,lib,"SDL_PushEventRef",SideEffects::worstDefault,"SDL_PushEventRef");
        addExtern<DAS_BIND_FUN(SDL_ReadKeyEvent)>(*this,lib,"SDL_ReadKeyEvent",SideEffects::worstDefault,"SDL_ReadKeyEvent");
        addExtern<DAS_BIND_FUN(SDL_ReadMouseButtonEvent)>(*this,lib,"SDL_ReadMouseButtonEvent",SideEffects::worstDefault,"SDL_ReadMouseButtonEvent");
        addExtern<DAS_BIND_FUN(SDL_ReadMouseMotionEvent)>(*this,lib,"SDL_ReadMouseMotionEvent",SideEffects::worstDefault,"SDL_ReadMouseMotionEvent");
        addExtern<DAS_BIND_FUN(SDL_ReadMouseWheelEvent)>(*this,lib,"SDL_ReadMouseWheelEvent",SideEffects::worstDefault,"SDL_ReadMouseWheelEvent");
        addExtern<DAS_BIND_FUN(SDL_ReadTextEditing)>(*this,lib,"SDL_ReadTextEditing",SideEffects::worstDefault,"SDL_ReadTextEditing");
        addExtern<DAS_BIND_FUN(SDL_ReadTextInput)>(*this,lib,"SDL_ReadTextInput",SideEffects::worstDefault,"SDL_ReadTextInput");
        addExtern<DAS_BIND_FUN(SDL_RenderFillRectRef)>(*this,lib,"SDL_RenderFillRectRef",SideEffects::worstDefault,"SDL_RenderFillRectRef");
        addExtern<DAS_BIND_FUN(SDL_RenderTextureRects)>(*this,lib,"SDL_RenderTextureRects",SideEffects::worstDefault,"SDL_RenderTextureRects");
        addExtern<DAS_BIND_FUN(SDL_RenderTextureToRect)>(*this,lib,"SDL_RenderTextureToRect",SideEffects::worstDefault,"SDL_RenderTextureToRect");
        addExtern<DAS_BIND_FUN(SDL_SetErrorMessage)>(*this,lib,"SDL_SetErrorMessage",SideEffects::worstDefault,"SDL_SetErrorMessage");
        addExtern<DAS_BIND_FUN(SDL_MakeEvent), SimNode_ExtFuncCallAndCopyOrMove>(*this,lib,"SDL_MakeEvent",SideEffects::worstDefault,"SDL_MakeEvent");
        addExtern<DAS_BIND_FUN(SDL_MakeFRect), SimNode_ExtFuncCallAndCopyOrMove>(*this,lib,"SDL_MakeFRect",SideEffects::worstDefault,"SDL_MakeFRect");
        addExtern<DAS_BIND_FUN(SDL_MakeKeyEvent), SimNode_ExtFuncCallAndCopyOrMove>(*this,lib,"SDL_MakeKeyEvent",SideEffects::worstDefault,"SDL_MakeKeyEvent");
        addExtern<DAS_BIND_FUN(SDL_RGBA8BufferSize)>(*this,lib,"SDL_RGBA8BufferSize",SideEffects::worstDefault,"SDL_RGBA8BufferSize");
        addExtern<DAS_BIND_FUN(SDL_CreateRGBA8Texture)>(*this,lib,"SDL_CreateRGBA8Texture",SideEffects::worstDefault,"SDL_CreateRGBA8Texture");
        addExtern<DAS_BIND_FUN(SDL_UploadRGBA8)>(*this,lib,"SDL_UploadRGBA8",SideEffects::worstDefault,"SDL_UploadRGBA8");
        addExtern<DAS_BIND_FUN(SDL_ReadPixelsOwned)>(*this,lib,"SDL_ReadPixelsOwned",SideEffects::worstDefault,"SDL_ReadPixelsOwned");
        addExtern<DAS_BIND_FUN(SDL_SurfaceSizeRef)>(*this,lib,"SDL_SurfaceSizeRef",SideEffects::worstDefault,"SDL_SurfaceSizeRef");
        addExtern<DAS_BIND_FUN(SDL_CopySurfaceRGBA8)>(*this,lib,"SDL_CopySurfaceRGBA8",SideEffects::worstDefault,"SDL_CopySurfaceRGBA8");
        addExtern<DAS_BIND_FUN(SDL_RenderGeometryVertices)>(*this,lib,"SDL_RenderGeometryVertices",SideEffects::worstDefault,"SDL_RenderGeometryVertices");
        addExtern<DAS_BIND_FUN(SDL_RenderGeometryIndices)>(*this,lib,"SDL_RenderGeometryIndices",SideEffects::worstDefault,"SDL_RenderGeometryIndices");
        addExtern<DAS_BIND_FUN(SDL_LoadWavOwned)>(*this,lib,"SDL_LoadWavOwned",SideEffects::worstDefault,"SDL_LoadWavOwned");
        addExtern<DAS_BIND_FUN(SDL_DestroyWav)>(*this,lib,"SDL_DestroyWav",SideEffects::worstDefault,"SDL_DestroyWav");
        addExtern<DAS_BIND_FUN(SDL_WavSize)>(*this,lib,"SDL_WavSize",SideEffects::worstDefault,"SDL_WavSize");
        addExtern<DAS_BIND_FUN(SDL_AudioSpecFormat)>(*this,lib,"SDL_AudioSpecFormat",SideEffects::worstDefault,"SDL_AudioSpecFormat");
        addExtern<DAS_BIND_FUN(SDL_CreateAudioStreamRef)>(*this,lib,"SDL_CreateAudioStreamRef",SideEffects::worstDefault,"SDL_CreateAudioStreamRef");
        addExtern<DAS_BIND_FUN(SDL_OpenPlaybackStream)>(*this,lib,"SDL_OpenPlaybackStream",SideEffects::worstDefault,"SDL_OpenPlaybackStream");
        addExtern<DAS_BIND_FUN(SDL_QueueWav)>(*this,lib,"SDL_QueueWav",SideEffects::worstDefault,"SDL_QueueWav");
        addExtern<DAS_BIND_FUN(SDL_PutAudioBytes)>(*this,lib,"SDL_PutAudioBytes",SideEffects::worstDefault,"SDL_PutAudioBytes");
        addExtern<DAS_BIND_FUN(SDL_GetAudioBytes)>(*this,lib,"SDL_GetAudioBytes",SideEffects::worstDefault,"SDL_GetAudioBytes");
        addExtern<DAS_BIND_FUN(SDL_SetErrorText)>(*this,lib,"SDL_SetErrorText",SideEffects::worstDefault,"SDL_SetErrorText");
        addExtern<DAS_BIND_FUN(SDL_MakeVertex), SimNode_ExtFuncCallAndCopyOrMove>(*this,lib,"SDL_MakeVertex",SideEffects::worstDefault,"SDL_MakeVertex");
        addExtern<DAS_BIND_FUN(SDL_WavSpec), SimNode_ExtFuncCallAndCopyOrMove>(*this,lib,"SDL_WavSpec",SideEffects::worstDefault,"SDL_WavSpec");
        addExtern<DAS_BIND_FUN(SDL_MakeAudioSpec), SimNode_ExtFuncCallAndCopyOrMove>(*this,lib,"SDL_MakeAudioSpec",SideEffects::worstDefault,"SDL_MakeAudioSpec");
        addExtern<DAS_BIND_FUN(SDL_GetWindowSizeInPixelsRef)>(*this,lib,"SDL_GetWindowSizeInPixelsRef",SideEffects::worstDefault,"SDL_GetWindowSizeInPixelsRef");
        for(auto & fn:functions.each())for(auto & arg:fn->arguments)
            if(arg->type->isSimpleType(Type::tUInt8) || arg->type->isSimpleType(Type::tUInt16))arg->type->baseType=Type::tUInt;
    }
};
}
REGISTER_MODULE_IN_NAMESPACE(Module_dasSDL3, das);
