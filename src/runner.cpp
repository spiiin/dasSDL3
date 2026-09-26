#include "daScript/daScript.h"
#include "daScript/misc/sysos.h"
#include <SDL3/SDL.h>
#define SDL_MAIN_HANDLED
#include <SDL3/SDL_main.h>
#include <cstring>
#include <iostream>
#include <string>

DECLARE_MODULE(Module_dasSDL3);
#ifdef DASSDL3_WITH_TTF
DECLARE_MODULE(Module_sdl3_ttf);
#endif
#ifdef DASSDL3_WITH_IMAGE
DECLARE_MODULE(Module_sdl3_image);
#endif
#ifdef DASSDL3_WITH_IMGUI
DECLARE_MODULE(Module_dasIMGUI);
DECLARE_MODULE(Module_Clipboard);
DECLARE_MODULE(Module_imgui_sdl3);
#endif

static int run_script(const char * path, bool smoke) {
    using namespace das;
    TextPrinter out;
    ModuleGroup modules;
    auto access = make_smart<FsFileAccess>();
    access->addFsRoot("dassdl3", DASSDL3_MODULE_ROOT);
    auto program = compileDaScript(path, access, out, modules);
    auto print_errors = [&] {
        for (const auto & err : program->errors)
            out << reportError(err.at, err.what, err.extra, err.fixme, err.cerr);
    };
    if (program->failed()) { print_errors(); return 1; }
    Context context(program->getContextStackSize());
    if (!program->simulate(context, out)) { print_errors(); return 1; }
    auto entry = context.findFunction("main");
    if (!entry || !verifyCall<int32_t, bool>(entry->debugInfo, modules)) {
        out << "Expected [export] def main(smoke : bool) : int\n";
        return 1;
    }
    vec4f args[] = {cast<bool>::from(smoke)};
    auto value = context.evalWithCatch(entry, args);
    if (const char * error = context.getException()) {
        out << "Script exception: " << error << "\n";
        return 1;
    }
    return cast<int32_t>::to(value);
}

int main(int argc, char ** argv) {
    bool smoke = false;
    std::string disabledLayers;
    const char * layerOption = "--disable-vulkan-layer=";
    bool valid = argc >= 2;
    for (int i = 2; i < argc; ++i) {
        if (!std::strcmp(argv[i], "--smoke-test")) smoke = true;
        else if (!std::strncmp(argv[i], layerOption, std::strlen(layerOption)) && argv[i][std::strlen(layerOption)]) {
            if (!disabledLayers.empty()) disabledLayers += ',';
            disabledLayers += argv[i] + std::strlen(layerOption);
        } else valid = false;
    }
    if (!valid) {
        std::cerr << "Usage: dasSDL3_runner script.das [--smoke-test] [--disable-vulkan-layer=NAME]\n";
        return 2;
    }
    if (!disabledLayers.empty()) {
        if (const char * existing = SDL_getenv_unsafe("VK_LOADER_LAYERS_DISABLE"); existing && *existing)
            disabledLayers = std::string(existing) + ',' + disabledLayers;
        if (SDL_setenv_unsafe("VK_LOADER_LAYERS_DISABLE", disabledLayers.c_str(), 1) != 0) {
            std::cerr << "Could not set per-process Vulkan layer filter\n"; return 2;
        }
        std::cerr << "Vulkan layers disabled for this process: " << disabledLayers << '\n';
    }
    SDL_SetMainReady();
    das::setDasRoot(DASSDL3_DAS_ROOT);
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_dasSDL3);
#ifdef DASSDL3_WITH_TTF
    NEED_MODULE(Module_sdl3_ttf);
#endif
#ifdef DASSDL3_WITH_IMAGE
    NEED_MODULE(Module_sdl3_image);
#endif
#ifdef DASSDL3_WITH_IMGUI
    NEED_MODULE(Module_Clipboard);
    NEED_MODULE(Module_dasIMGUI);
    NEED_MODULE(Module_imgui_sdl3);
#endif
    das::Module::Initialize();
    int status = run_script(argv[1], smoke);
    SDL_Quit(); // Also clean up SDL after a script error.
    das::Module::Shutdown();
    return status;
}
