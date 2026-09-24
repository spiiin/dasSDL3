#include "daScript/daScript.h"
#include "daScript/ast/ast_interop.h"
#include "daScript/ast/ast_handle.h"
#include "image.h"
MAKE_TYPE_FACTORY(SDL_Surface, SDL_Surface);
MAKE_TYPE_FACTORY(SDL_Texture, SDL_Texture);
MAKE_TYPE_FACTORY(SDL_Renderer, SDL_Renderer);
MAKE_TYPE_FACTORY(SDL_IOStream, SDL_IOStream);
MAKE_TYPE_FACTORY(IMG_Animation, IMG_Animation);

namespace das {
class AnimationAnnotation : public ManagedStructureAnnotation<IMG_Animation,false> {
public:
    AnimationAnnotation(ModuleLibrary& lib) : ManagedStructureAnnotation("IMG_Animation",lib) {
        addField<DAS_BIND_MANAGED_FIELD(w)>("w");
        addField<DAS_BIND_MANAGED_FIELD(h)>("h");
        addField<DAS_BIND_MANAGED_FIELD(count)>("count");
        addField<DAS_BIND_MANAGED_FIELD(frames)>("frames");
        addField<DAS_BIND_MANAGED_FIELD(delays)>("delays");
    }
};
class Module_sdl3_image : public Module {
    bool initialized = false;
public:
    Module_sdl3_image() : Module("sdl3_image") {}
    bool initDependencies() override {
        if (initialized) return true;
        auto sdl = Module::require("sdl3");
        if (!sdl || !sdl->initDependencies()) return false;
        initialized = true;
        ModuleLibrary lib(this); lib.addBuiltInModule(); lib.addModule(sdl);
        addAnnotation(new AnimationAnnotation(lib));
#define BIND(F) addExtern<DAS_BIND_FUN(F)>(*this,lib,#F,SideEffects::worstDefault,#F)
#include "generated/image_functions.inc"
        BIND(IMG_AnimationFrame);
        BIND(IMG_AnimationDelay);
#undef BIND
        verifyAotReady();
        return true;
    }
    ModuleAotType aotRequire(TextWriter& tw) const override {
        tw << "#include \"libraries/image.h\"\n";
        return ModuleAotType::cpp;
    }
};
}
REGISTER_MODULE_IN_NAMESPACE(Module_sdl3_image,das);
