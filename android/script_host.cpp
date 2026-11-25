#include "script_host.h"
#include "script_lifecycle.h"
#include <cstring>

namespace android_host {
using namespace das;

bool Script::load(const char *path, bool aot, bool expectMissingAot, bool fromSource) {
    auto access = make_smart<dassdl3_mobile::BundleAccess>();
    access->addFileSystem(new dassdl3_mobile::BundleScripts("app/"), true, false);
    access->addFsRoot("dassdl3", "app/dassdl3");
    if (fromSource) {
        if (source.size() > UINT32_MAX) return SDL_SetError("Script is too large");
        access->setFileInfo(path, std::make_unique<TextFileInfo>(source.c_str(), uint32_t(source.size()), false));
    }
#ifdef DASSDL3_WITH_IMGUI
    access->addFsRoot("imgui", "app/imgui");
#endif
    CodeOfPolicies policy;
    policy.aot = policy.fail_on_no_aot = policy.tune_frozen = aot;
    program = compileDaScript(path, access, log, modules, policy);
    if (!program->failed()) {
        context = std::make_unique<Context>(program->getContextStackSize());
        const bool ready = program->simulate(*context, log);
        if (ready && !expectMissingAot) return true;
        if (expectMissingAot && !ready && !program->errors.empty()) {
            bool missing = true;
            for (const auto &e : program->errors) missing &= e.cerr == CompilationError::missing_aot;
            if (missing) return true;
        }
    }
    for (const auto &e : program->errors)
        log << reportError(e.at, e.what, e.extra, e.fixme, e.cerr);
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s: %s", path, log.str().c_str());
    return false;
}

static bool runMain(const char *path, bool aot, bool argument) {
    Script script;
    if (!script.load(path, aot)) return false;
    auto *entry = script.context->findFunction("main");
    if (!entry || (aot && !entry->aot) || !verifyCall<int32_t, bool>(entry->debugInfo, script.modules))
        return SDL_SetError("Invalid script main in %s", path);
    vec4f args[] = {cast<bool>::from(argument)};
    const auto value = script.context->evalWithCatch(entry, args);
    if (const char *error = script.context->getException()) return SDL_SetError("%s", error);
    const int code = cast<int32_t>::to(value);
    if (code) return SDL_SetError("%s returned %d (AOT=%d)", path, code, aot);
    SDL_Log("dasSDL3 Android %s %s PASS", path, aot ? "strict AOT" : "interpreter");
    return true;
}

static bool checkScripts(std::initializer_list<const char *> scripts, const char *gpuDriver = nullptr) {
    for (auto path : scripts) {
        for (bool aot : {false, true}) {
            if (gpuDriver && !SDL_SetHintWithPriority(SDL_HINT_GPU_DRIVER, gpuDriver, SDL_HINT_OVERRIDE)) return false;
            if (!runMain(path, aot, true)) return false;
        }
    }
    return true;
}

struct Visibility {
    SDL_AtomicInt active{1};
    SDL_AtomicInt resumes{0};
};

static bool SDLCALL watchVisibility(void *userdata, SDL_Event *event) {
    auto &visibility = *static_cast<Visibility *>(userdata);
    if (event->type == SDL_EVENT_WILL_ENTER_BACKGROUND) {
        SDL_SetAtomicInt(&visibility.active, 0);
    } else if (event->type == SDL_EVENT_DID_ENTER_FOREGROUND &&
               SDL_SetAtomicInt(&visibility.active, 1) == 0) {
        SDL_AddAtomicInt(&visibility.resumes, 1);
    }
    return true;
}

static bool runSquare(bool aot) {
    Script script;
    if (!script.load("app/examples/lifecycle/01_square.das", aot)) return false;
    dassdl3_host::Lifecycle lifecycle(*script.context, script.modules, *script.program->getThisModule(), script.log, aot);
    Visibility visibility;
    bool ok = lifecycle.start();
    const bool watching = ok && SDL_AddEventWatch(watchVisibility, &visibility);
    int count = 0;
    std::unique_ptr<SDL_Window *, decltype(&SDL_free)> windows(
        watching ? SDL_GetWindows(&count) : nullptr, SDL_free);
    ok = watching && windows && count == 1;
    int previousWidth = 0, previousHeight = 0, previousResumes = -1;
    unsigned frames = 0;
    // The square owns polling, rendering and shutdown. The watcher may run on
    // the Java activity thread and only updates native atomic state.
    while (ok) {
        SDL_PumpEvents();
        if (!SDL_GetAtomicInt(&visibility.active)) {
            SDL_Delay(16);
            continue;
        }
        if (!lifecycle.tick()) break;
        ++frames;
        int width, height;
        if (!SDL_GetWindowSizeInPixels(windows.get()[0], &width, &height)) { ok = false; break; }
        const int resumes = SDL_GetAtomicInt(&visibility.resumes);
        if (width != previousWidth || height != previousHeight || resumes != previousResumes) {
            SDL_Log("dasSDL3 Android square %s frame=%u pixels=%dx%d resumes=%d",
                    aot ? "strict AOT" : "interpreter", frames, width, height, resumes);
            previousWidth = width;
            previousHeight = height;
            previousResumes = resumes;
        }
        SDL_Delay(16);
    }
    if (watching) SDL_RemoveEventWatch(watchVisibility, &visibility);
    const int exitCode = lifecycle.finish();
    if (!ok || exitCode || !frames) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "square: %s", script.log.str().c_str());
        return false;
    }
    SDL_Log("dasSDL3 Android square shutdown PASS frames=%u", frames);
    return true;
}

int runMode(const char *mode) {
    bool ok = false;
    if (!std::strcmp(mode, "square") || !std::strcmp(mode, "square-aot")) {
        ok = runSquare(!std::strcmp(mode, "square-aot"));
    } else if (!std::strcmp(mode, "storage-write") || !std::strcmp(mode, "storage-read")) {
        const bool write = !std::strcmp(mode, "storage-write");
        ok = runMain("app/android/storage.das", !write, write);
    } else if (!std::strcmp(mode, "multitouch") || !std::strcmp(mode, "unicode-input")) {
        ok = runMultitouch(!std::strcmp(mode, "unicode-input"));
    } else if (!std::strcmp(mode, "vulkan-screen")) {
        ok = showVulkanTriangle();
    } else if (!std::strcmp(mode, "playback")) {
        ok = checkScripts({"app/examples/08_audio.das"});
    } else if (!std::strcmp(mode, "sensors")) {
        ok = runSensors();
    } else if (!std::strcmp(mode, "camera") || !std::strcmp(mode, "camera-denied") ||
               !std::strcmp(mode, "microphone") || !std::strcmp(mode, "microphone-denied")) {
        ok = runCapture(mode[0] == 'c', std::strstr(mode, "-denied") != nullptr);
    } else if (!std::strcmp(mode, "vulkan")) {
        ok = checkScripts({"app/examples/44_gpu_render_pass.das", "app/examples/46_gpu_texture_uniform_bindings.das",
                           "app/examples/49_gpu_native_compute.das"}, "vulkan");
#ifdef DASSDL3_WITH_IMAGE
    } else if (!std::strcmp(mode, "image")) {
        ok = checkScripts({"app/tests/image.das"});
#endif
#ifdef DASSDL3_WITH_TTF
    } else if (!std::strcmp(mode, "ttf")) {
        ok = checkScripts({"app/tests/ttf.das", "app/tests/ttf_shaping.das", "app/tests/ttf_gpu.das"});
#endif
#ifdef DASSDL3_WITH_NET
    } else if (!std::strcmp(mode, "net")) {
        ok = checkScripts({"app/tests/net.das"});
#endif
#ifdef DASSDL3_WITH_MIXER
    } else if (!std::strcmp(mode, "mixer")) {
        ok = checkScripts({"app/tests/mixer.das"});
#endif
#ifdef DASSDL3_WITH_SOUND
    } else if (!std::strcmp(mode, "sound")) {
        ok = checkScripts({"app/tests/sound.das"});
#endif
#ifdef DASSDL3_WITH_IMGUI
    } else if (!std::strcmp(mode, "imgui") || !std::strcmp(mode, "imgui-v2")) {
        ok = runMain(!std::strcmp(mode, "imgui") ? "app/ui/01_imgui.das" : "app/ui/imgui_widgets.das", false, true);
    } else if (!std::strcmp(mode, "live") || !std::strcmp(mode, "live-test")) {
        ok = runLive(!std::strcmp(mode, "live-test"));
    } else if (!std::strcmp(mode, "imgui-input") || !std::strcmp(mode, "imgui-v2-input")) {
        ok = runKeyboard(!std::strcmp(mode, "imgui-v2-input"));
#endif
    } else {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Unknown Android mode %s", mode);
        return 1;
    }
    SDL_Log("dasSDL3 Android %s %s", mode, ok ? "PASS" : "FAIL");
    if (!ok) SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", SDL_GetError());
    return ok ? 0 : 1;
}
}
