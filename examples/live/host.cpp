// Application-owned resources survive script replacement. Not a public SDL API.
#include "daScript/daScript.h"
#include "imgui_sdl.h"
#include <cstdio>
#define SDL_MAIN_HANDLED
#include <SDL3/SDL_main.h>
MAKE_TYPE_FACTORY(SDL_Window, SDL_Window);
MAKE_TYPE_FACTORY(SDL_Renderer, SDL_Renderer);
namespace das {
namespace {
struct DemoResources {
    SDL_Window *window = nullptr;
    SDL_Renderer *renderer = nullptr;
    ImGuiContext *imgui = nullptr;
    bool sdl = false, backend = false;
    unsigned acquisitions = 0, releases = 0;
    void close() {
        if (!sdl) return;
        ImGui::SetCurrentContext(imgui);
        if (backend) { ImGui_ImplSDLRenderer3_Shutdown(); ImGui_ImplSDL3_Shutdown(); backend = false; }
        if (imgui) { ImGui::DestroyContext(imgui); imgui = nullptr; }
        if (renderer) { SDL_DestroyRenderer(renderer); renderer = nullptr; }
        if (window) { SDL_DestroyWindow(window); window = nullptr; }
        SDL_Quit(); sdl = false;
        ++releases;
        fprintf(stderr, "SDL live released=%u acquired=%u\n", releases, acquisitions);
    }
    ~DemoResources() { close(); }
};
DemoResources resources;
bool demo_open() {
    if (resources.backend) { ImGui::SetCurrentContext(resources.imgui); return true; }
    SDL_SetMainReady();
    if (!SDL_Init(SDL_INIT_VIDEO)) return false;
    resources.sdl = true;
    resources.window = SDL_CreateWindow("SDL3 + daslang-live", 800, 600, SDL_WINDOW_RESIZABLE);
    if (resources.window) resources.renderer = SDL_CreateRenderer(resources.window, nullptr);
    if (resources.renderer) resources.imgui = ImGui::CreateContext();
    if (resources.imgui) resources.backend = ImGui_SDL3_Init(resources.window, resources.renderer);
    if (!resources.backend) {
        const std::string error = SDL_GetError();
        resources.close(); SDL_SetError("%s", error.c_str()); return false;
    }
    ImGui::GetIO().IniFilename = nullptr;
    ++resources.acquisitions;
    fprintf(stderr, "SDL live acquired=%u\n", resources.acquisitions);
    return true;
}
SDL_Window *demo_window() { return resources.window; }
SDL_Renderer *demo_renderer() { return resources.renderer; }
void demo_close() { resources.close(); }
unsigned demo_acquisitions() { return resources.acquisitions; }
}
class Module_sdl3_live_demo : public Module {
    bool initialized = false;
public:
    Module_sdl3_live_demo() : Module("sdl3_live_demo") {}
    ~Module_sdl3_live_demo() override { resources.close(); }
    bool initDependencies() override {
        if (initialized) return true;
        auto sdl = Module::require("sdl3");
        auto imgui = Module::require("imgui");
        if (!sdl || !imgui || !sdl->initDependencies() || !imgui->initDependencies()) return false;
        initialized = true;
        ModuleLibrary lib(this); lib.addBuiltInModule(); lib.addModule(sdl); lib.addModule(imgui);
#define BIND(F) addExtern<DAS_BIND_FUN(F)>(*this, lib, #F, SideEffects::worstDefault)
        BIND(demo_open); BIND(demo_window); BIND(demo_renderer); BIND(demo_close); BIND(demo_acquisitions);
#undef BIND
        return true;
    }
};
REGISTER_DYN_MODULE(Module_sdl3_live_demo, Module_sdl3_live_demo);
}
