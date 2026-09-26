#include "daScript/daScript.h"
#include "daScript/ast/ast_interop.h"
#include "daScript/ast/ast_handle.h"
#include "shadercross.h"
MAKE_TYPE_FACTORY(SDL_GPUDevice,SDL_GPUDevice);
MAKE_TYPE_FACTORY(SDL_GPUShader,SDL_GPUShader);
MAKE_TYPE_FACTORY(SDL_GPUComputePipeline,SDL_GPUComputePipeline);
#include "generated/shadercross_types.inc"
namespace das {
class Module_sdl3_shadercross : public Module {
    bool initialized=false;
public:
    Module_sdl3_shadercross():Module("sdl3_shadercross") {}
    bool initDependencies() override {
        if(initialized) return true;
        auto sdl=Module::require("sdl3");
        if(!sdl || !sdl->initDependencies()) return false;
        initialized=true;
        ModuleLibrary lib(this);lib.addBuiltInModule();lib.addModule(sdl);
#define BIND(F) addExtern<DAS_BIND_FUN(F)>(*this,lib,#F,SideEffects::worstDefault,#F)
#include "generated/shadercross_functions.inc"
        BIND(SDL_ShaderCross_CompileSPIRVFromHLSLBytes);
        BIND(SDL_ShaderCross_CompileDXILFromHLSLBytes);
        BIND(SDL_ShaderCross_CompileDXBCFromHLSLBytes);
        BIND(SDL_ShaderCross_CompileDXILFromSPIRVBytes);
        BIND(SDL_ShaderCross_CompileDXBCFromSPIRVBytes);
        BIND(SDL_ShaderCross_TranspileMSLFromSPIRVCopy);
        BIND(SDL_ShaderCross_TranspileHLSLFromSPIRVCopy);
        BIND(SDL_ShaderCross_ReflectGraphicsBytes);
        BIND(SDL_ShaderCross_ReflectComputeBytes);
        BIND(SDL_ShaderCross_CompileGraphicsShaderBytes);
        BIND(SDL_ShaderCross_CompileComputePipelineBytes);
#undef BIND
        verifyAotReady();return true;
    }
    ModuleAotType aotRequire(TextWriter& tw) const override {
        tw << "#include \"libraries/shadercross.h\"\n";return ModuleAotType::cpp;
    }
};
}
REGISTER_MODULE_IN_NAMESPACE(Module_sdl3_shadercross,das);
