#include "script_host.h"
#include "../ios/sensor_dashboard.h"

MAKE_TYPE_FACTORY(SDL_Event, SDL_Event);

namespace android_host {
namespace {
using namespace das;

struct Probe : Script {
    template<class R, class... Args> SimFunction *entry(const char *name, bool aot) {
        auto *fn = context->findFunction(name);
        if (fn && (!aot || fn->aot) && verifyCall<R, Args...>(fn->debugInfo, modules)) return fn;
        SDL_SetError("Invalid hardware probe entry %s", name);
        return nullptr;
    }
    bool call(SimFunction *fn, vec4f *args, vec4f &result) {
        context->restart();
        result = context->evalWithCatch(fn, args);
        if (const char *error = context->getException()) return SDL_SetError("%s", error);
        return true;
    }
    bool finish(bool ok, SimFunction *close) {
        const std::string error = ok ? "" : SDL_GetError();
        vec4f result;
        const bool closed = call(close, nullptr, result);
        return ok ? closed : SDL_SetError("%s", error.c_str());
    }
};

bool captureFrames(bool camera, bool aot) {
    Probe script;
    if (!script.load(camera ? "app/ios/camera.das" : "app/ios/microphone.das", aot)) return false;
    auto *open = script.entry<int32_t, bool>(camera ? "camera_open" : "microphone_open", aot);
    auto *tick = script.entry<int32_t, bool>(camera ? "camera_tick" : "microphone_tick", aot);
    auto *close = script.entry<void>(camera ? "camera_close" : "microphone_close", aot);
    if (!open || !tick || !close) return false;
    vec4f args[]{cast<bool>::from(false)}, result;
    bool ok = script.call(open, args, result);
    int state = ok ? cast<int32_t>::to(result) : -1;
    const Uint64 deadline = SDL_GetTicks() + 15000;
    while (state == 0 && SDL_GetTicks() < deadline) {
        SDL_PumpEvents();
        SDL_Delay(10);
        ok = script.call(tick, args, result);
        state = ok ? cast<int32_t>::to(result) : -1;
    }
    if (state == 0) ok = SDL_SetError("Timed out waiting for %s samples", camera ? "camera" : "microphone");
    if (state < 0 && ok) ok = SDL_SetError("Capture probe rejected the device or its data");
    if (!script.finish(ok, close)) return false;
    SDL_Log("dasSDL3 Android %s samples PASS (%s)", camera ? "camera" : "microphone", aot ? "strict AOT" : "interpreter");
    return true;
}

// A permission reply can arrive after a timeout. Give the callback process lifetime.
SDL_AtomicInt permission;
void SDLCALL permissionResult(void *, const char *, bool granted) {
    SDL_SetAtomicInt(&permission, granted ? 1 : -1);
}

bool sensorSamples(bool aot, SDL_Renderer *renderer, float density) {
    Probe script;
    if (!script.load("app/ios/sensors.das", aot)) return false;
    auto *open = script.entry<bool>("motion_open", aot);
    auto *sample = script.entry<bool, const SDL_Event &>("motion_event", aot);
    auto *done = script.entry<int32_t>("motion_done", aot);
    auto *close = script.entry<void>("motion_close", aot);
    auto *values = script.entry<float4, bool>("motion_values", aot);
    if (!open || !sample || !done || !close || !values) return false;
    vec4f result;
    bool ok = script.call(open, nullptr, result) && cast<bool>::to(result);
    const Uint64 deadline = SDL_GetTicks() + 120000;
    int state = 0;
    bool receivedBoth = false;
    if (ok) SDL_Log("dasSDL3 Android sensors ready (%s)", aot ? "strict AOT" : "interpreter");
    while (ok && !state && SDL_GetTicks() < deadline) {
        SDL_Event event;
        while (ok && SDL_PollEvent(&event)) {
            if (event.type != SDL_EVENT_SENSOR_UPDATE) continue;
            vec4f args[]{cast<const SDL_Event &>::from(event)};
            ok = script.call(sample, args, result) && cast<bool>::to(result);
        }
        if (ok) ok = script.call(done, nullptr, result);
        if (ok) state = cast<int32_t>::to(result);
        if (ok) {
            float axes[2][3]{};
            bool ready[2]{};
            for (int i = 0; i < 2; ++i) {
                vec4f args[]{cast<bool>::from(i != 0)};
                if (!script.call(values, args, result)) { ok = false; break; }
                const auto reading = cast<float4>::to(result);
                axes[i][0] = reading.x;
                axes[i][1] = reading.y;
                axes[i][2] = reading.z;
                ready[i] = reading.w > 0;
            }
            if (ok) ok = dassdl3_ios::drawSensorDashboard(renderer, density, axes[0], ready[0], axes[1], ready[1],
                aot ? "Tilt and rotate the phone (strict AOT)." : "Tilt and rotate the phone (interpreter).");
            if (ready[0] && ready[1] && !receivedBoth) {
                SDL_Log("dasSDL3 Android received accelerometer and gyroscope events (%s)", aot ? "strict AOT" : "interpreter");
                receivedBoth = true;
            }
        }
        SDL_Delay(10);
    }
    if (ok && state != 1) ok = SDL_SetError("Motion samples did not meet the accelerometer and gyroscope thresholds");
    return script.finish(ok, close);
}
}

bool runCapture(bool camera, bool denied) {
    const char *name = camera ? "android.permission.CAMERA" : "android.permission.RECORD_AUDIO";
    if (!SDL_Init(SDL_INIT_EVENTS)) return false;
    SDL_SetAtomicInt(&permission, 0);
    bool ok = SDL_RequestAndroidPermission(name, permissionResult, nullptr);
    const Uint64 deadline = SDL_GetTicks() + 60000;
    while (ok && !SDL_GetAtomicInt(&permission) && SDL_GetTicks() < deadline) {
        SDL_PumpEvents();
        SDL_Delay(20);
    }
    if (ok && SDL_GetAtomicInt(&permission) != (denied ? -1 : 1)) ok = SDL_SetError("Unexpected permission result for %s", name);
    if (ok && !denied) {
        if (!camera) SDL_SetHintWithPriority(SDL_HINT_AUDIO_DRIVER, "AAudio", SDL_HINT_OVERRIDE);
        ok = SDL_InitSubSystem(camera ? SDL_INIT_CAMERA : SDL_INIT_AUDIO) &&
             captureFrames(camera, false) && captureFrames(camera, true);
    }
    if (ok && denied) SDL_Log("dasSDL3 Android OS denied %s; capture remains closed", name);
    const std::string error = ok ? "" : SDL_GetError();
    SDL_Quit();
    return ok || SDL_SetError("%s", error.c_str());
}

bool runSensors() {
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_SENSOR)) return false;
    SDL_Window *window = nullptr;
    SDL_Renderer *renderer = nullptr;
    bool ok = SDL_CreateWindowAndRenderer("Tilt and turn the phone", 640, 480, SDL_WINDOW_RESIZABLE, &window, &renderer);
    if (ok) {
        const float density = SDL_GetWindowPixelDensity(window);
        ok = sensorSamples(false, renderer, density) && sensorSamples(true, renderer, density);
    }
    const std::string error = ok ? "" : SDL_GetError();
    if (renderer) SDL_DestroyRenderer(renderer);
    if (window) SDL_DestroyWindow(window);
    SDL_Quit();
    return ok || SDL_SetError("%s", error.c_str());
}
}
