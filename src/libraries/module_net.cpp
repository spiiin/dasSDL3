#include "daScript/daScript.h"
#include "daScript/ast/ast_interop.h"
#include "daScript/ast/ast_handle.h"
#include "net.h"
#include "generated/net_types.inc"
namespace das {
class Module_sdl3_net : public Module {
    bool initialized=false;
public:
    Module_sdl3_net():Module("sdl3_net") {}
    bool initDependencies() override {
        if (initialized) return true;
        auto sdl=Module::require("sdl3");
        if (!sdl || !sdl->initDependencies()) return false;
        initialized=true;
        ModuleLibrary lib(this); lib.addBuiltInModule(); lib.addModule(sdl);
#define BIND(F) addExtern<DAS_BIND_FUN(F)>(*this,lib,#F,SideEffects::worstDefault,#F)
#include "generated/net_functions.inc"
        BIND(NET_AcceptClientRef);
        BIND(NET_ReceiveDatagramRef);
        BIND(NET_ReadStreamBytes);
        BIND(NET_WriteStreamBytes);
        BIND(NET_SendDatagramBytes);
        BIND(NET_CopyDatagramBytes);
        BIND(NET_GetAddressStringCopy);
        BIND(NET_GetAddressBytesCopy);
        BIND(NET_WaitServerInput);
        BIND(NET_WaitStreamInput);
        BIND(NET_WaitDatagramInput);
#undef BIND
        verifyAotReady(); return true;
    }
    ModuleAotType aotRequire(TextWriter& tw) const override {
        tw << "#include \"libraries/net.h\"\n"; return ModuleAotType::cpp;
    }
};
}
REGISTER_MODULE_IN_NAMESPACE(Module_sdl3_net,das);
