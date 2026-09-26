#include "daScript/daScript.h"
#include "daScript/ast/ast_interop.h"
#include "daScript/ast/ast_handle.h"
#include "sound.h"
MAKE_TYPE_FACTORY(SDL_IOStream,SDL_IOStream);
MAKE_TYPE_FACTORY(SDL_AudioStream,SDL_AudioStream);
MAKE_TYPE_FACTORY(SDL_AudioSpec,SDL_AudioSpec);
#include "generated/sound_types.inc"
namespace das {
class Module_sdl3_sound : public Module {
    bool initialized=false;
public:
    Module_sdl3_sound():Module("sdl3_sound") {}
    bool initDependencies() override {
        if (initialized) return true;
        auto sdl=Module::require("sdl3");
        if (!sdl || !sdl->initDependencies()) return false;
        initialized=true;
        ModuleLibrary lib(this); lib.addBuiltInModule(); lib.addModule(sdl);
#define BIND(F) addExtern<DAS_BIND_FUN(F)>(*this,lib,#F,SideEffects::worstDefault,#F)
#include "generated/sound_functions.inc"
        BIND(Sound_GetSampleFlags);
        BIND(Sound_GetSampleBufferSize);
        BIND(Sound_GetSampleActualRef);
        BIND(Sound_GetSampleDesiredRef);
        BIND(Sound_GetSampleDecoder);
        BIND(Sound_GetDecoderDescriptionCopy);
        BIND(Sound_GetErrorCopy);
        BIND(Sound_NewSampleFromFileRef);
        BIND(Sound_CopySampleBytes);
        BIND(Sound_ValidateSampleRequest);
        BIND(Sound_GetDecoderCount);
        BIND(Sound_GetDecoderAt);
        BIND(Sound_GetDecoderAuthorCopy);
        BIND(Sound_GetDecoderUrlCopy);
        BIND(Sound_GetDecoderExtensionCopy);
#undef BIND
        verifyAotReady(); return true;
    }
    ModuleAotType aotRequire(TextWriter& tw) const override {
        tw << "#include \"libraries/sound.h\"\n"; return ModuleAotType::cpp;
    }
};
}
REGISTER_MODULE_IN_NAMESPACE(Module_sdl3_sound,das);
