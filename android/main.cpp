#include "../mobile/bundle_scripts.h"
#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL_main.h>

DECLARE_MODULE(Module_dasSDL3);
MAKE_TYPE_FACTORY(SDL_Renderer, SDL_Renderer);

namespace {
struct App {
    SDL_Window *window = nullptr;
    SDL_Renderer *renderer = nullptr;
    bool checked = false;
};

enum class Mode { Interpreter, StrictAot, MissingAot };

bool checkScript(SDL_Renderer *renderer, Mode mode) {
    using namespace das;
    const bool aot = mode != Mode::Interpreter;
    const bool negative = mode == Mode::MissingAot;
    const char *path = negative ? "app/macos_missing_aot.das" : "app/smoke.das";
    auto access = make_smart<dassdl3_mobile::BundleAccess>();
    access->addFileSystem(new dassdl3_mobile::BundleScripts("app/"), true, false);
    access->addFsRoot("dassdl3", "app/dassdl3");
    ModuleGroup modules;
    TextWriter log;
    CodeOfPolicies policy;
    policy.aot = policy.fail_on_no_aot = policy.tune_frozen = aot;
    auto program = compileDaScript(path, access, log, modules, policy);
    auto report = [&] {
        for (const auto &e : program->errors)
            log << reportError(e.at, e.what, e.extra, e.fixme, e.cerr);
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s: %s", path, log.str().c_str());
        return false;
    };
    if (program->failed()) return report();
    Context context(program->getContextStackSize());
    bool ready = program->simulate(context, log);
    if (negative) {
        if (ready || program->errors.empty()) return SDL_SetError("Expected missing AOT");
        for (const auto &e : program->errors)
            if (e.cerr != CompilationError::missing_aot) return report();
        SDL_Log("dasSDL3 Android missing AOT rejected");
        return true;
    }
    if (!ready) return report();
    auto *paint = context.findFunction("paint");
    if (!paint || (aot && !paint->aot) || !verifyCall<bool, SDL_Renderer *, uint32_t>(paint->debugInfo, modules))
        return SDL_SetError("Invalid paint entry (AOT=%d)", aot);
    const Uint8 blue = aot ? 192 : 64;
    vec4f args[] = {cast<SDL_Renderer *>::from(renderer), cast<uint32_t>::from(blue)};
    const auto result = context.evalWithCatch(paint, args);
    if (auto *error = context.getException()) return SDL_SetError("%s", error);
    if (!cast<bool>::to(result)) return false;

    SDL_Rect rect{0, 0, 1, 1};
    std::unique_ptr<SDL_Surface, decltype(&SDL_DestroySurface)> pixel(SDL_RenderReadPixels(renderer, &rect), SDL_DestroySurface);
    Uint8 r, g, b, alpha;
    if (!pixel || !SDL_ReadSurfacePixel(pixel.get(), 0, 0, &r, &g, &b, &alpha)) return false;
    if (r != 24 || g != 96 || b != blue)
        return SDL_SetError("Unexpected RGB (%u, %u, %u), expected (24, 96, %u)", r, g, b, blue);
    if (!SDL_RenderPresent(renderer)) return false;
    SDL_Log("dasSDL3 Android %s RGB (%u, %u, %u) PASS", aot ? "strict AOT" : "interpreter", r, g, b);
    return true;
}
}

SDL_AppResult SDL_AppInit(void **state, int, char **) {
    auto *app = new App;
    *state = app;
    das::setDasRoot("app");
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_dasSDL3);
    das::Module::Initialize();
    SDL_SetHint(SDL_HINT_MAIN_CALLBACK_RATE, "30");
    if (!SDL_Init(SDL_INIT_VIDEO) ||
        !SDL_CreateWindowAndRenderer("dasSDL3 Android", 640, 480, 0, &app->window, &app->renderer)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    SDL_Log("dasSDL3 Android video=%s renderer=%s", SDL_GetCurrentVideoDriver(), SDL_GetRendererName(app->renderer));
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *state) {
    auto &app = *static_cast<App *>(state);
    if (!app.checked) {
        for (Mode mode : {Mode::Interpreter, Mode::StrictAot, Mode::MissingAot}) {
            if (!checkScript(app.renderer, mode)) {
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "dasSDL3 Android smoke FAIL: %s", SDL_GetError());
                return SDL_APP_FAILURE;
            }
        }
        app.checked = true;
        SDL_Log("dasSDL3 Android smoke PASS");
    }
    if (!SDL_SetRenderDrawColor(app.renderer, 24, 96, 192, 255) || !SDL_RenderClear(app.renderer) ||
        !SDL_SetRenderDrawColor(app.renderer, 255, 255, 255, 255) ||
        !SDL_RenderDebugText(app.renderer, 32, 90, "dasSDL3 Android - interpreter + strict AOT PASS") ||
        !SDL_RenderPresent(app.renderer)) return SDL_APP_FAILURE;
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
}
