#include "bundle_scripts.h"

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL_main.h>

DECLARE_MODULE(Module_dasSDL3);

namespace {
struct App {
    SDL_Window *window = nullptr;
    SDL_Renderer *renderer = nullptr;
    Uint8 blue = 0;
};

int loadBlue() {
    using namespace das;
    const char *base = SDL_GetBasePath();
    if (!base) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", SDL_GetError());
        return -1;
    }
    const string root(base);
    setDasRoot(root.substr(0, root.size() - 1));
    auto access = make_smart<dassdl3_ios::BundleAccess>();
    access->addFileSystem(new dassdl3_ios::BundleScripts(root), true, false);
    TextWriter diagnostics;
    ModuleGroup modules;
    CodeOfPolicies policy;
    policy.aot = policy.fail_on_no_aot = policy.tune_frozen = true;
    auto program = compileDaScript(root + "scripts/hello.das", access, diagnostics, modules, policy);
    Context context(program->failed() ? 0 : program->getContextStackSize());
    if (program->failed() || !program->simulate(context, diagnostics)) {
        for (const auto &error : program->errors)
            diagnostics << reportError(error.at, error.what, error.extra, error.fixme, error.cerr);
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", diagnostics.str().c_str());
        return -1;
    }
    auto *entry = context.findFunction("app_blue");
    if (!entry || !entry->aot || !verifyCall<int32_t>(entry->debugInfo, modules)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Missing strict AOT entry app_blue");
        return -1;
    }
    const auto result = context.evalWithCatch(entry, nullptr);
    if (const auto *error = context.getException()) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", error);
        return -1;
    }
    return cast<int32_t>::to(result);
}
}

SDL_AppResult SDL_AppInit(void **state, int, char **) {
    auto *app = new App;
    *state = app;
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_dasSDL3);
    das::Module::Initialize();
    if (!SDL_Init(SDL_INIT_VIDEO) ||
        !SDL_CreateWindowAndRenderer("Hello dasSDL3", 640, 480, 0, &app->window, &app->renderer)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    const int blue = loadBlue();
    if (blue < 0 || blue > 255) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Could not read the bundled color");
        return SDL_APP_FAILURE;
    }
    app->blue = static_cast<Uint8>(blue);
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *state) {
    const auto &app = *static_cast<App *>(state);
    if (!SDL_SetRenderDrawColor(app.renderer, 20, 40, app.blue, 255) ||
        !SDL_RenderClear(app.renderer) || !SDL_RenderPresent(app.renderer)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *, SDL_Event *event) {
    return event->type == SDL_EVENT_QUIT ? SDL_APP_SUCCESS : SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *state, SDL_AppResult) {
    std::unique_ptr<App> app(static_cast<App *>(state));
    if (app) {
        if (app->renderer) SDL_DestroyRenderer(app->renderer);
        if (app->window) SDL_DestroyWindow(app->window);
        das::Module::Shutdown();
    }
    SDL_Quit();
}
