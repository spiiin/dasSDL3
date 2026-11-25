#include "script_host.h"
#include <optional>

MAKE_TYPE_FACTORY(SDL_Renderer, SDL_Renderer);
extern "C" void live_host_set_live_mode(bool);
extern "C" void live_host_set_is_reload(bool);
extern "C" void live_host_bump_reload_generation();

namespace android_host {
namespace {
constexpr char asset[] = "app/ui/live.das";
struct Painter : Script {
    das::SimFunction *paint = nullptr;
    bool prepare(bool replacement) {
        if (!load(asset, false, false, replacement)) return false;
        paint = context->findFunction("paint");
        return paint && das::verifyCall<bool, SDL_Renderer *>(paint->debugInfo, modules);
    }
    bool draw(SDL_Renderer *renderer) {
        context->restart();
        vec4f args[] = {das::cast<SDL_Renderer *>::from(renderer)};
        auto value = context->evalWithCatch(paint, args);
        if (auto error = context->getException()) return SDL_SetError("%s", error);
        return das::cast<bool>::to(value);
    }
};

bool runFrames(SDL_Window *window, SDL_Renderer *renderer, const std::string &path) {
    auto current = std::make_unique<Painter>();
    if (!current->prepare(false)) return false;
    std::optional<std::string> previous;
    unsigned generation = 0;
    Uint64 nextCheck = 0;
    const char *status = "initial";
    while (true) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) if (event.type == SDL_EVENT_QUIT) return true;
        const Uint64 now = SDL_GetTicks();
        if (now >= nextCheck) {
            nextCheck = now + 250;
            SDL_PathInfo info{};
            if (SDL_GetPathInfo(path.c_str(), &info) && info.type == SDL_PATHTYPE_FILE) {
                size_t length = 0;
                std::unique_ptr<void, decltype(&SDL_free)> bytes(SDL_LoadFile(path.c_str(), &length), SDL_free);
                if (!bytes) return false;
                std::string source(static_cast<const char *>(bytes.get()), length);
                if (!previous || *previous != source) {
                    previous = source;
                    auto candidate = std::make_unique<Painter>();
                    candidate->source = std::move(source);
                    live_host_set_is_reload(true);
                    if (candidate->prepare(true)) {
                        current.swap(candidate);
                        ++generation;
                        live_host_bump_reload_generation();
                        status = "loaded";
                    } else {
                        status = "rejected";
                    }
                    live_host_set_is_reload(false);
                }
            }
        }
        if (!current->draw(renderer)) return false;
        if (status) {
            SDL_Rect rect{0, 0, 1, 1};
            std::unique_ptr<SDL_Surface, decltype(&SDL_DestroySurface)> pixel(
                SDL_RenderReadPixels(renderer, &rect), SDL_DestroySurface);
            Uint8 r, g, b, a;
            if (!pixel || !SDL_ReadSurfacePixel(pixel.get(), 0, 0, &r, &g, &b, &a)) return false;
            if (!SDL_RenderPresent(renderer)) return false;
            SDL_Log("dasSDL3 Android live %s generation=%u window=%u rgb=%u,%u,%u",
                    status, generation, SDL_GetWindowID(window), r, g, b);
            status = nullptr;
        } else if (!SDL_RenderPresent(renderer)) return false;
        SDL_Delay(16);
    }
}
}

bool runLive(bool test) {
    const char *dir = SDL_GetAndroidInternalStoragePath();
    if (!dir || !SDL_Init(SDL_INIT_VIDEO)) return false;
    const std::string path = std::string(dir) + (test ? "/dassdl3-live-test.das" : "/dassdl3-live.das");
    SDL_Window *window = nullptr;
    SDL_Renderer *renderer = nullptr;
    bool ok = SDL_CreateWindowAndRenderer("dasSDL3 live", 640, 480, 0, &window, &renderer);
    if (ok) {
        live_host_set_live_mode(true);
        ok = runFrames(window, renderer, path);
        live_host_set_live_mode(false);
    }
    const std::string error = ok ? "" : SDL_GetError();
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return ok || SDL_SetError("%s", error.c_str());
}
}
