// On-device host for the existing Metal pixel, compute and strict AOT tests.
#include "daScript/daScript.h"
#include "daScript/simulate/fs_file_info.h"
#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <filesystem>
#include <limits>
#include <memory>
#include <utility>
#include <cerrno>
#include <cstring>
#include <unistd.h>

DECLARE_MODULE(Module_dasSDL3);
MAKE_TYPE_FACTORY(SDL_GPUDevice, SDL_GPUDevice);
MAKE_TYPE_FACTORY(SDL_Window, SDL_Window);
MAKE_TYPE_FACTORY(SDL_GPUGraphicsPipeline, SDL_GPUGraphicsPipeline);

namespace {
class BundleAccess final : public das::FsFileAccess {
public:
    das::ModuleInfo getModuleInfo(const das::string &request, const das::string &from) const override {
        // The SDK's no-file-I/O build omits source-relative import resolution.
        const std::filesystem::path path(request.c_str());
        if (request.compare(0, 2, "./") == 0 && path.extension() == ".das") {
            const auto file = (std::filesystem::path(from.c_str()).parent_path() / path).lexically_normal();
            das::ModuleInfo info;
            info.fileName = file.generic_string().c_str();
            info.moduleName = info.importName = file.stem().generic_string().c_str();
            return info;
        }
        return FsFileAccess::getModuleInfo(request, from);
    }
};

class BundleScripts final : public das::AnyFileSystem {
public:
    explicit BundleScripts(das::string root) : root_(std::move(root)) {}
    das::FileInfo *tryOpenFile(const das::string &name) override {
        // Only packaged .das files, through the module resolver's absolute paths.
        if (name.compare(0, root_.size(), root_) != 0 || name.find("..") != das::string::npos ||
            name.size() < 4 || name.compare(name.size() - 4, 4, ".das") != 0) return nullptr;
        size_t length = 0;
        std::unique_ptr<void, decltype(&SDL_free)> bytes(SDL_LoadFile(name.c_str(), &length), SDL_free);
        if (!bytes || length > std::numeric_limits<uint32_t>::max()) return nullptr;
        auto *source = static_cast<char *>(das_aligned_alloc16(length + 1));
        if (!source) return nullptr;
        SDL_memcpy(source, bytes.get(), length + 1); // SDL_LoadFile appends NUL.
        return new das::TextFileInfo(source, static_cast<uint32_t>(length), true);
    }
private:
    das::string root_;
};

enum class Check { Normal, MissingAot, ReadSavedData };

bool run(const das::string &root, const char *path, bool aot, Check check = Check::Normal) {
    using namespace das;
    TextWriter diagnostics;
    ModuleGroup modules;
    auto access = make_smart<BundleAccess>();
    access->addFileSystem(new BundleScripts(root), true, false);
    access->addFsRoot("dassdl3", root + "dassdl3");
    CodeOfPolicies policy;
    policy.aot = aot;
    policy.fail_on_no_aot = aot;
    policy.tune_frozen = aot;
    auto program = compileDaScript(root + path, access, diagnostics, modules, policy);
    auto report = [&] {
        for (auto &error : program->errors)
            diagnostics << reportError(error.at, error.what, error.extra, error.fixme, error.cerr);
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s (%s): %s",
                     path, aot ? "strict AOT" : "interpreter", diagnostics.str().c_str());
        return false;
    };
    if (program->failed()) return report();
    Context context(program->getContextStackSize());
    const bool simulated = program->simulate(context, diagnostics);
    if (check == Check::MissingAot) {
        bool expectedFailure = !simulated && !program->errors.empty();
        for (const auto &error : program->errors)
            expectedFailure = expectedFailure && error.cerr == CompilationError::missing_aot;
        if (!expectedFailure) return report();
        SDL_Log("dasSDL3 iPhone missing AOT rejected PASS");
        return true; // Never invoke the negative fixture.
    }
    if (!simulated) return report();
    auto *entry = context.findFunction("main");
    if (!entry || !verifyCall<int32_t, bool>(entry->debugInfo, modules) || (aot && !entry->aot)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Incorrect or missing smoke entry (AOT=%d)", aot);
        return false;
    }
    vec4f args[] = {cast<bool>::from(check != Check::ReadSavedData)};
    auto value = context.evalWithCatch(entry, args);
    if (auto *error = context.getException()) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s (%s) exception: %s",
                     path, aot ? "strict AOT" : "interpreter", error);
        return false;
    }
    const int code = cast<int32_t>::to(value);
    if (code != 0) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s failed (code=%d, AOT=%d)", path, code, aot);
        return false;
    }
    SDL_Log("dasSDL3 iPhone %s PASS (%s)", path, aot ? "strict AOT" : "interpreter");
    return true;
}

bool runFilesystem(const das::string &root) {
    using SDLString = std::unique_ptr<char, decltype(&SDL_free)>;
    SDLString previous(SDL_GetCurrentDirectory(), SDL_free);
    SDLString pref(SDL_GetPrefPath("dasSDL3", "iPhone Smoke"), SDL_free);
    // Give the test a writable working directory; the signed bundle is read-only.
    if (!previous || !pref) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Filesystem test directory: %s", SDL_GetError());
        return false;
    }
    if (chdir(pref.get()) != 0) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Enter writable app directory: %s", std::strerror(errno));
        return false;
    }
    bool passed = run(root, "tests/filesystem.das", false);
#ifdef DASSDL3_IPHONE_STRICT_AOT
    passed = run(root, "tests/filesystem.das", true) && passed;
#endif
    if (chdir(previous.get()) != 0) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Restore working directory: %s", std::strerror(errno));
        return false;
    }
    return passed;
}

struct Screen {
    das::ModuleGroup modules;
    das::ProgramPtr program;
    std::unique_ptr<das::Context> context;
    das::SimFunction *frame = nullptr;
    SDL_Window *window = nullptr;
    SDL_Renderer *renderer = nullptr;
    SDL_GPUDevice *device = nullptr;
    SDL_GPUGraphicsPipeline *pipeline = nullptr;
    bool claimed = false;
    bool passed = false;
    bool firstFrame = true;
    SDL_AtomicInt active{1};
    SDL_AtomicInt resumeCount{0};
    unsigned reportedResume = 0;

    bool startTriangle(const das::string &root) {
        using namespace das;
        TextWriter diagnostics;
        auto access = make_smart<BundleAccess>();
        access->addFileSystem(new BundleScripts(root), true, false);
        access->addFsRoot("dassdl3", root + "dassdl3");
        CodeOfPolicies policy;
#ifdef DASSDL3_IPHONE_STRICT_AOT
        policy.aot = policy.fail_on_no_aot = policy.tune_frozen = true;
#endif
        program = compileDaScript(root + "examples/48_gpu_native_graphics.das", access, diagnostics, modules, policy);
        if (!program->failed()) {
            context = std::make_unique<Context>(program->getContextStackSize());
        }
        if (!context || !program->simulate(*context, diagnostics)) {
            for (auto &error : program->errors)
                diagnostics << reportError(error.at, error.what, error.extra, error.fixme, error.cerr);
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "48_gpu_native_graphics: %s", diagnostics.str().c_str());
            return false;
        }
        auto *create = context->findFunction("triangle_create");
        frame = context->findFunction("triangle_frame");
        if (!create || !frame || (policy.aot && (!create->aot || !frame->aot)) ||
            !verifyCall<SDL_GPUGraphicsPipeline *, SDL_GPUDevice *, SDL_Window *>(create->debugInfo, modules) ||
            !verifyCall<int32_t, SDL_GPUDevice *, SDL_Window *, SDL_GPUGraphicsPipeline *>(frame->debugInfo, modules)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Invalid triangle entry points (AOT=%d)", policy.aot);
            return false;
        }

        window = SDL_CreateWindow("dasSDL3 Metal", 640, 480, SDL_WINDOW_HIGH_PIXEL_DENSITY);
        if (!window) return false;
        device = SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_MSL, true, "metal");
        if (!device) return false;
        claimed = SDL_ClaimWindowForGPUDevice(device, window);
        if (!claimed) return false;
        vec4f args[] = {cast<SDL_GPUDevice *>::from(device), cast<SDL_Window *>::from(window)};
        auto value = context->evalWithCatch(create, args);
        if (auto *error = context->getException()) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Triangle setup exception: %s", error);
            return false;
        }
        pipeline = cast<SDL_GPUGraphicsPipeline *>::to(value);
        return pipeline != nullptr;
    }

    SDL_AppResult drawTriangle() {
        using namespace das;
        const unsigned resumed = SDL_GetAtomicInt(&resumeCount);
        vec4f args[] = {cast<SDL_GPUDevice *>::from(device), cast<SDL_Window *>::from(window),
                       cast<SDL_GPUGraphicsPipeline *>::from(pipeline)};
        context->restart();
        auto value = context->evalWithCatch(frame, args);
        if (auto *error = context->getException()) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Triangle frame exception: %s", error);
            return SDL_APP_FAILURE;
        }
        const auto result = cast<int32_t>::to(value);
        if (result < 0) return SDL_APP_FAILURE;
        if (!context->runWithCatchAndClear([&] { context->collectHeapIfMostlyFree(); })) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Triangle garbage collection failed");
            return SDL_APP_FAILURE;
        }
        if (result > 0 && firstFrame) {
            firstFrame = false;
            SDL_Log("dasSDL3 iPhone swapchain first frame PASS (%s)", frame->aot ? "strict AOT" : "interpreter");
        }
        if (result > 0 && resumed != reportedResume) {
            reportedResume = resumed;
            SDL_Log("dasSDL3 iPhone swapchain resumed frame PASS (cycle %u)", resumed);
        }
        return SDL_APP_CONTINUE;
    }
};
}

SDL_AppResult SDL_AppInit(void **state, int argc, char **argv) {
    auto *screen = new Screen;
    *state = screen;
    const char *path = SDL_GetBasePath();
    if (!path) return SDL_APP_FAILURE;
    das::string root(path);
    das::setDasRoot(root.substr(0, root.size() - 1)); // SDL base path ends in '/'.
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_dasSDL3);
    das::Module::Initialize();
    for (int i = 1; i < argc; ++i) {
        const bool write = SDL_strcmp(argv[i], "--persistence-write") == 0;
        const bool read = SDL_strcmp(argv[i], "--persistence-read") == 0;
        if (!write && !read) continue;
        bool aot = false;
#ifdef DASSDL3_IPHONE_STRICT_AOT
        aot = read;
#endif
        if (!run(root, "ios/persistence.das", aot, read ? Check::ReadSavedData : Check::Normal))
            return SDL_APP_FAILURE;
        SDL_Log("dasSDL3 persistence %s PASS pid=%d mode=%s",
                write ? "write" : "read", int(getpid()), aot ? "strict-aot" : "interpreter");
        return SDL_APP_SUCCESS;
    }
    constexpr const char *scripts[] = {
        "examples/44_gpu_render_pass.das",
        "examples/46_gpu_texture_uniform_bindings.das",
        "examples/49_gpu_native_compute.das",
    };
    screen->passed = runFilesystem(root);
    for (const char *script : scripts) {
        // Each example owns its SDL scope; SDL_Quit also clears hints.
        SDL_SetHintWithPriority(SDL_HINT_GPU_DRIVER, "metal", SDL_HINT_OVERRIDE);
        screen->passed = run(root, script, false) && screen->passed;
#ifdef DASSDL3_IPHONE_STRICT_AOT
        SDL_SetHintWithPriority(SDL_HINT_GPU_DRIVER, "metal", SDL_HINT_OVERRIDE);
        screen->passed = run(root, script, true) && screen->passed;
#endif
    }
#ifdef DASSDL3_IPHONE_STRICT_AOT
    screen->passed = run(root, "tests/macos_missing_aot.das", true, Check::MissingAot) && screen->passed;
#endif
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    if (screen->passed) {
        if (!screen->startTriangle(root)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Triangle setup failed: %s", SDL_GetError());
            return SDL_APP_FAILURE;
        }
    } else if (!SDL_CreateWindowAndRenderer("dasSDL3 Metal", 640, 480, 0, &screen->window, &screen->renderer)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *state) {
    auto &screen = *static_cast<Screen *>(state);
    if (!SDL_GetAtomicInt(&screen.active)) return SDL_APP_CONTINUE;
    if (screen.pipeline) return screen.drawTriangle();
    if (!SDL_SetRenderDrawColor(screen.renderer, screen.passed ? 20 : 165, screen.passed ? 130 : 20, 40, 255) ||
        !SDL_RenderClear(screen.renderer) ||
        !SDL_SetRenderDrawColor(screen.renderer, 255, 255, 255, 255) ||
        !SDL_RenderDebugText(screen.renderer, 24, 96, screen.passed ? "dasSDL3 Metal: PASS" : "dasSDL3 Metal: FAIL") ||
        !SDL_RenderPresent(screen.renderer)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *state, SDL_Event *event) {
    auto &screen = *static_cast<Screen *>(state);
    if (event->type == SDL_EVENT_WILL_ENTER_BACKGROUND) {
        SDL_SetAtomicInt(&screen.active, 0);
        SDL_Log("dasSDL3 iPhone background: rendering paused");
    }
    if (event->type == SDL_EVENT_DID_ENTER_FOREGROUND && !SDL_GetAtomicInt(&screen.active)) {
        const int cycle = SDL_AddAtomicInt(&screen.resumeCount, 1) + 1;
        SDL_Log("dasSDL3 iPhone foreground: waiting for frame (cycle %d)", cycle);
        SDL_SetAtomicInt(&screen.active, 1);
    }
    if (event->type == SDL_EVENT_QUIT) return screen.passed ? SDL_APP_SUCCESS : SDL_APP_FAILURE;
    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *state, SDL_AppResult) {
    std::unique_ptr<Screen> screen(static_cast<Screen *>(state));
    if (screen) {
        if (screen->device) {
            if (!SDL_WaitForGPUIdle(screen->device))
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Triangle cleanup: %s", SDL_GetError());
            if (screen->pipeline) SDL_ReleaseGPUGraphicsPipeline(screen->device, screen->pipeline);
            if (screen->claimed) SDL_ReleaseWindowFromGPUDevice(screen->device, screen->window);
            SDL_DestroyGPUDevice(screen->device);
        }
        SDL_DestroyRenderer(screen->renderer);
        SDL_DestroyWindow(screen->window);
    }
    screen.reset();
    das::Module::Shutdown();
    SDL_Quit();
}
