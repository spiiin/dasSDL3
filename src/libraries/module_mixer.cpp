#include "daScript/daScript.h"
#include "daScript/ast/ast_interop.h"
#include "daScript/ast/ast_handle.h"
#include "mixer.h"
MAKE_TYPE_FACTORY(SDL_IOStream,SDL_IOStream);
MAKE_TYPE_FACTORY(SDL_AudioStream,SDL_AudioStream);
MAKE_TYPE_FACTORY(SDL_AudioSpec,SDL_AudioSpec);
#include "generated/mixer_types.inc"
namespace das {
class Module_sdl3_mixer : public Module {
    bool initialized=false;
public:
    Module_sdl3_mixer():Module("sdl3_mixer") {}
    bool initDependencies() override {
        if (initialized) return true;
        auto sdl=Module::require("sdl3");
        if (!sdl || !sdl->initDependencies()) return false;
        initialized=true;
        ModuleLibrary lib(this); lib.addBuiltInModule(); lib.addModule(sdl);
#define BIND(F) addExtern<DAS_BIND_FUN(F)>(*this,lib,#F,SideEffects::worstDefault,#F)
#include "generated/mixer_functions.inc"
        BIND(MIX_CreateMixerRef);
        BIND(MIX_CreateMixerDeviceRef);
        BIND(MIX_GetMixerFormatRef);
        BIND(MIX_GetAudioFormatRef);
        BIND(MIX_GetAudioDecoderFormatRef);
        BIND(MIX_GetTrack3DPositionRef);
        BIND(MIX_SetTrack3DPositionRef);
        BIND(MIX_SetTrackStereoRef);
        BIND(MIX_LoadRawAudioBytes);
        BIND(MIX_LoadRawAudioFloats);
        BIND(MIX_GenerateBytes);
        BIND(MIX_GenerateFloats);
        BIND(MIX_DecodeAudioBytes);
#undef BIND
        verifyAotReady(); return true;
    }
    ModuleAotType aotRequire(TextWriter& tw) const override {
        tw << "#include \"libraries/mixer.h\"\n"; return ModuleAotType::cpp;
    }
};
}
REGISTER_MODULE_IN_NAMESPACE(Module_sdl3_mixer,das);
