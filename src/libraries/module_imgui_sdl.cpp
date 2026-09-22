#include "daScript/daScript.h"
#include "daScript/ast/ast_interop.h"
#include "imgui_sdl.h"

MAKE_TYPE_FACTORY(SDL_Window, SDL_Window);
MAKE_TYPE_FACTORY(SDL_Renderer, SDL_Renderer);
MAKE_TYPE_FACTORY(SDL_Event, SDL_Event);

namespace das {
class Module_imgui_sdl3 : public Module {
    bool initialized = false;
public:
    Module_imgui_sdl3() : Module("imgui_sdl3") {}
    bool initDependencies() override {
        if (initialized) return true;
        auto sdl = Module::require("sdl3");
        auto imgui = Module::require("imgui");
        if (!sdl || !imgui || !sdl->initDependencies() || !imgui->initDependencies()) return false;
        initialized = true;
        ModuleLibrary lib(this);
        lib.addBuiltInModule();
        lib.addModule(sdl);
        lib.addModule(imgui);
#define BIND(F) addExtern<DAS_BIND_FUN(F)>(*this, lib, #F, SideEffects::worstDefault, #F)
        BIND(ImGui_SDL3_Init);
        BIND(ImGui_SDL3_ProcessEvent);
        BIND(ImGui_SDL3_Render);
        BIND(ImGui_SDL3_WantCaptureMouse);
        BIND(ImGui_SDL3_WantCaptureKeyboard);
        BIND(ImGui_ImplSDL3_NewFrame);
        BIND(ImGui_ImplSDL3_Shutdown);
        BIND(ImGui_ImplSDLRenderer3_NewFrame);
        BIND(ImGui_ImplSDLRenderer3_Shutdown);
#undef BIND
        verifyAotReady();
        return true;
    }
    ModuleAotType aotRequire(TextWriter& tw) const override {
        tw << "#include \"libraries/imgui_sdl.h\"\n";
        return ModuleAotType::cpp;
    }
};
}
REGISTER_MODULE_IN_NAMESPACE(Module_imgui_sdl3, das);
