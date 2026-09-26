#include "daScript/daScript.h"
#include "daScript/ast/ast_interop.h"
#include "daScript/ast/ast_handle.h"
#include "ttf.h"
MAKE_TYPE_FACTORY(SDL_Surface,SDL_Surface);
MAKE_TYPE_FACTORY(SDL_Renderer,SDL_Renderer);
MAKE_TYPE_FACTORY(SDL_IOStream,SDL_IOStream);
MAKE_TYPE_FACTORY(SDL_Color,SDL_Color);
MAKE_TYPE_FACTORY(SDL_Rect,SDL_Rect);
MAKE_TYPE_FACTORY(SDL_FPoint,SDL_FPoint);
MAKE_TYPE_FACTORY(SDL_GPUDevice,SDL_GPUDevice);
MAKE_TYPE_FACTORY(SDL_GPUTexture,SDL_GPUTexture);
#include "generated/ttf_types.inc"
namespace das {
class Module_sdl3_ttf : public Module {
    bool initialized=false;
public:
    Module_sdl3_ttf():Module("sdl3_ttf") {}
    bool initDependencies() override {
        if (initialized) return true;
        auto sdl=Module::require("sdl3");
        if (!sdl || !sdl->initDependencies()) return false;
        initialized=true;
        ModuleLibrary lib(this); lib.addBuiltInModule(); lib.addModule(sdl);
#define BIND(F) addExtern<DAS_BIND_FUN(F)>(*this,lib,#F,SideEffects::worstDefault,#F)
#include "generated/ttf_functions.inc"
        BIND(TTF_GetStringSizeRef);
        BIND(TTF_GetTextSizeRef);
        BIND(TTF_GetGlyphMetricsRef);
        BIND(TTF_GetGPUTextDrawDataRef);
        BIND(TTF_CopyGPUAtlasDrawSequence);
#undef BIND
        verifyAotReady(); return true;
    }
    ModuleAotType aotRequire(TextWriter& tw) const override {
        tw << "#include \"libraries/ttf.h\"\n"; return ModuleAotType::cpp;
    }
};
}
REGISTER_MODULE_IN_NAMESPACE(Module_sdl3_ttf,das);
