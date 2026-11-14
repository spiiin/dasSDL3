// On-device host for the existing Metal pixel, compute and strict AOT tests.
#include "bundle_scripts.h"
#include "capture_permission.h"
#include "sensor_dashboard.h"
#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cerrno>
#include <initializer_list>
#include <cstring>
#include <unistd.h>

DECLARE_MODULE(Module_dasSDL3);
#ifdef DASSDL3_WITH_IMGUI
DECLARE_MODULE(Module_dasIMGUI);
DECLARE_MODULE(Module_imgui_sdl3);
DECLARE_MODULE(Module_LiveHost);
#endif
#ifdef DASSDL3_WITH_NET
DECLARE_MODULE(Module_sdl3_net);
#endif
#ifdef DASSDL3_WITH_MIXER
DECLARE_MODULE(Module_sdl3_mixer);
#endif
#ifdef DASSDL3_WITH_SOUND
DECLARE_MODULE(Module_sdl3_sound);
#endif
#ifdef DASSDL3_WITH_TTF
DECLARE_MODULE(Module_sdl3_ttf);
#endif
#ifdef DASSDL3_WITH_IMAGE
DECLARE_MODULE(Module_sdl3_image);
#endif
MAKE_TYPE_FACTORY(SDL_GPUDevice, SDL_GPUDevice);
MAKE_TYPE_FACTORY(SDL_Window, SDL_Window);
MAKE_TYPE_FACTORY(SDL_Renderer, SDL_Renderer);
MAKE_TYPE_FACTORY(SDL_Event, SDL_Event);
MAKE_TYPE_FACTORY(SDL_GPUGraphicsPipeline, SDL_GPUGraphicsPipeline);

#ifdef DASSDL3_IOS_IMGUI_INPUT
#include "imgui_input.h"
#ifdef DASSDL3_WITH_IMGUI
MAKE_TYPE_FACTORY(SDL_FRect, SDL_FRect);
#endif
#endif

namespace {
using dassdl3_ios::BundleAccess;
using dassdl3_ios::BundleScripts;

enum class Check { Normal, MissingAot, ReadSavedData };

bool run(const das::string &root, const char *path, bool aot, Check check = Check::Normal) {
    using namespace das;
    TextWriter diagnostics;
    ModuleGroup modules;
    auto access = make_smart<BundleAccess>();
    access->addFileSystem(new BundleScripts(root), true, false);
    access->addFsRoot("dassdl3", root + "dassdl3");
#ifdef DASSDL3_WITH_IMGUI
    access->addFsRoot("imgui", root + "imgui");
#endif
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

SDL_AppResult runSmokeTests(const das::string &root, std::initializer_list<const char *> scripts) {
    bool passed = true;
    for (const char *script : scripts) {
        // Each script owns SDL; SDL_Quit clears these hints.
        SDL_SetHintWithPriority(SDL_HINT_RENDER_DRIVER, "metal", SDL_HINT_OVERRIDE);
        SDL_SetHintWithPriority(SDL_HINT_GPU_DRIVER, "metal", SDL_HINT_OVERRIDE);
        passed = run(root, script, false) && passed;
#ifdef DASSDL3_IPHONE_STRICT_AOT
        SDL_SetHintWithPriority(SDL_HINT_RENDER_DRIVER, "metal", SDL_HINT_OVERRIDE);
        SDL_SetHintWithPriority(SDL_HINT_GPU_DRIVER, "metal", SDL_HINT_OVERRIDE);
        passed = run(root, script, true) && passed;
#endif
    }
    return passed ? SDL_APP_SUCCESS : SDL_APP_FAILURE;
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
#ifdef DASSDL3_IOS_IMGUI_INPUT
    bool imguiInput = false;
#endif
    SDL_AtomicInt active{1};
    SDL_AtomicInt resumeCount{0};
    unsigned reportedResume = 0;

    enum class InputStep { Drag, Type, Hide };
    InputStep inputStep = InputStep::Drag;
    das::SimFunction *inputEvent = nullptr;
    bool inputAot = false;
    bool multiInput = false;

    bool loadInteractive(const das::string &root, const char *path, bool aot) {
        using namespace das;
        TextWriter diagnostics;
        auto access = make_smart<BundleAccess>();
        access->addFileSystem(new BundleScripts(root), true, false);
        access->addFsRoot("dassdl3", root + "dassdl3");
#ifdef DASSDL3_WITH_IMGUI
        access->addFsRoot("imgui", root + "imgui");
#endif
        CodeOfPolicies policy;
        policy.aot = policy.fail_on_no_aot = policy.tune_frozen = aot;
        program = compileDaScript(root + path, access, diagnostics, modules, policy);
        if (!program->failed()) context = std::make_unique<Context>(program->getContextStackSize());
        if (!context || !program->simulate(*context, diagnostics)) {
            for (auto &error : program->errors)
                diagnostics << reportError(error.at, error.what, error.extra, error.fixme, error.cerr);
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s: %s", path, diagnostics.str().c_str());
            return false;
        }
        return true;
    }

#if defined(DASSDL3_IOS_IMGUI_INPUT) && defined(DASSDL3_WITH_IMGUI)
    bool startImGuiWidgetsInput(const das::string &root) {
        using namespace das;
        if (!loadInteractive(root, "ios/imgui_widgets_input.das", false)) return false;
        auto *frame = context->findFunction("input_frame");
        if (!frame || !verifyCall<int32_t, SDL_Renderer *, const SDL_FRect &, bool, SDL_FRect &>(
                          frame->debugInfo, modules)) {
            return SDL_SetError("Invalid dasImgui v2 input_frame entry point");
        }
        return startImGuiInput([this, frame](SDL_Renderer *target, const SDL_FRect &bounds,
                                            bool focus, SDL_FRect &field) {
            vec4f args[] = {cast<SDL_Renderer *>::from(target), cast<const SDL_FRect &>::from(bounds),
                            cast<bool>::from(focus), cast<SDL_FRect &>::from(field)};
            context->restart();
            const int32_t result = cast<int32_t>::to(context->evalWithCatch(frame, args));
            if (const auto *error = context->getException()) {
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "dasImgui v2 input frame: %s", error);
                return ImGuiInputFrame::Failed;
            }
            return static_cast<ImGuiInputFrame>(result);
        });
    }
#endif

    bool startInput(const das::string &root, bool aot, bool multi = false) {
        using namespace das;
        inputAot = aot;
        multiInput = multi;
        if (!loadInteractive(root, "ios/input.das", aot)) return false;
        inputEvent = context->findFunction(multi ? "multi_input_event" : "input_event");
        if (!inputEvent || (aot && !inputEvent->aot) ||
            !verifyCall<int32_t, SDL_Window *, const SDL_Event &>(inputEvent->debugInfo, modules)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Invalid input entry point (AOT=%d)", aot);
            return false;
        }
        SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS, "0");
        if (!SDL_Init(SDL_INIT_VIDEO) ||
            !SDL_CreateWindowAndRenderer("dasSDL3 iPhone input", 640, 480, 0, &window, &renderer)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Input window: %s", SDL_GetError());
            return false;
        }
        if (!SDL_HasScreenKeyboardSupport()) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Screen keyboard is unsupported");
            return false;
        }
        SDL_Log("dasSDL3 input ready (%s): %s", aot ? "strict AOT" : "interpreter",
                multi ? "place two fingers, lift the first, then move and lift the second" : "slide one finger and lift it");
        return true;
    }

    SDL_AppResult drawInput() {
        if (inputStep == InputStep::Hide && !SDL_ScreenKeyboardShown(window) && !SDL_TextInputActive(window)) {
            SDL_Log("dasSDL3 %s PASS (%s)", multiInput ? "multitouch and Unicode keyboard" : "touch and screen keyboard",
                    inputAot ? "strict AOT" : "interpreter");
            return SDL_APP_SUCCESS;
        }
        const char *prompt = inputStep == InputStep::Drag
            ? (multiInput ? "Two fingers. Lift first. Slide and lift second." : "Slide one finger and lift it")
            : (multiInput ? "Type cafe with an accented e" : "Type 42 using the screen keyboard");
        if (!SDL_SetRenderDrawColor(renderer, 16, 32, 50, 255) || !SDL_RenderClear(renderer) ||
            !SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255) ||
            !SDL_RenderDebugText(renderer, 24, 104, prompt) || !SDL_RenderPresent(renderer)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Input screen: %s", SDL_GetError());
            return SDL_APP_FAILURE;
        }
        return SDL_APP_CONTINUE;
    }

    SDL_AppResult handleInput(const SDL_Event &event) {
        using namespace das;
        if (inputStep == InputStep::Hide ||
            (inputStep == InputStep::Drag && event.type != SDL_EVENT_FINGER_DOWN &&
             event.type != SDL_EVENT_FINGER_MOTION && event.type != SDL_EVENT_FINGER_UP &&
             event.type != SDL_EVENT_FINGER_CANCELED) ||
            (inputStep == InputStep::Type && event.type != SDL_EVENT_TEXT_INPUT)) return SDL_APP_CONTINUE;
        vec4f args[] = {cast<SDL_Window *>::from(window), cast<const SDL_Event *>::from(&event)};
        context->restart();
        const int result = cast<int32_t>::to(context->evalWithCatch(inputEvent, args));
        if (const auto *error = context->getException()) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Input exception: %s", error);
            return SDL_APP_FAILURE;
        }
        if (result < 0 || !context->runWithCatchAndClear([&] { context->collectHeapIfMostlyFree(); })) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Input event validation failed");
            return SDL_APP_FAILURE;
        }
        if (result == 1 && inputStep == InputStep::Drag) {
            inputStep = InputStep::Type;
            const auto props = SDL_CreateProperties();
            if (!props) {
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Text input properties: %s", SDL_GetError());
                return SDL_APP_FAILURE;
            }
            const bool started = SDL_SetNumberProperty(props, SDL_PROP_TEXTINPUT_TYPE_NUMBER,
                                                       multiInput ? SDL_TEXTINPUT_TYPE_TEXT : SDL_TEXTINPUT_TYPE_NUMBER) &&
                                 (!multiInput ||
                                  (SDL_SetBooleanProperty(props, SDL_PROP_TEXTINPUT_AUTOCORRECT_BOOLEAN, false) &&
                                   SDL_SetNumberProperty(props, SDL_PROP_TEXTINPUT_CAPITALIZATION_NUMBER, SDL_CAPITALIZE_NONE))) &&
                                 SDL_StartTextInputWithProperties(window, props);
            if (!started) SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Start text input: %s", SDL_GetError());
            SDL_DestroyProperties(props);
            if (!started) return SDL_APP_FAILURE;
            SDL_Log("dasSDL3 gesture PASS; type %s on the iPhone keyboard", multiInput ? "café or Привет 👋" : "42");
        }
        if (result == 2 && inputStep == InputStep::Type) {
            if (!SDL_TextInputActive(window) || !SDL_ScreenKeyboardShown(window)) {
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Received text without an active screen keyboard");
                return SDL_APP_FAILURE;
            }
            SDL_Log("%s", multiInput ? "dasSDL3 received exact UTF-8 through SDL_TEXTINPUT with screen keyboard shown"
                                   : "dasSDL3 received 42 through SDL_TEXTINPUT with screen keyboard shown");
            inputStep = InputStep::Hide;
            if (!SDL_StopTextInput(window)) {
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Stop text input: %s", SDL_GetError());
                return SDL_APP_FAILURE;
            }
        }
        return SDL_APP_CONTINUE;
    }

    das::SimFunction *captureOpen = nullptr;
    das::SimFunction *captureTick = nullptr;
    das::SimFunction *captureClose = nullptr;
    Uint64 captureDeadline = 0;
    bool captureExpectDenied = false;
    bool captureOpened = false;
    dassdl3_ios::CaptureDevice captureDevice = dassdl3_ios::CaptureDevice::Camera;

    const char *captureName() const {
        return captureDevice == dassdl3_ios::CaptureDevice::Camera ? "camera" : "microphone";
    }

    bool startCapture(const das::string &root, bool aot, bool expectDenied, dassdl3_ios::CaptureDevice device) {
        using namespace das;
        captureDevice = device;
        const bool camera = device == dassdl3_ios::CaptureDevice::Camera;
        if (!loadInteractive(root, camera ? "ios/camera.das" : "ios/microphone.das", aot)) return false;
        captureOpen = context->findFunction(camera ? "camera_open" : "microphone_open");
        captureTick = context->findFunction(camera ? "camera_tick" : "microphone_tick");
        auto *close = context->findFunction(camera ? "camera_close" : "microphone_close");
        if (!captureOpen || !captureTick || !close ||
            (aot && (!captureOpen->aot || !captureTick->aot || !close->aot)) ||
            !verifyCall<int32_t, bool>(captureOpen->debugInfo, modules) ||
            !verifyCall<int32_t, bool>(captureTick->debugInfo, modules) ||
            !verifyCall<void>(close->debugInfo, modules))
            return SDL_SetError("Invalid %s entry points (AOT=%d)", captureName(), aot);
        SDL_SetHintWithPriority(camera ? SDL_HINT_CAMERA_DRIVER : SDL_HINT_AUDIO_DRIVER,
                                camera ? "coremedia" : "coreaudio", SDL_HINT_OVERRIDE);
        if (!SDL_Init(SDL_INIT_VIDEO | (camera ? SDL_INIT_CAMERA : SDL_INIT_AUDIO)) ||
            !SDL_CreateWindowAndRenderer(captureName(), 640, 480, 0, &window, &renderer)) return false;
        captureClose = close;
        captureExpectDenied = expectDenied;
        captureDeadline = SDL_GetTicks() + 45000;
        if (dassdl3_ios::capturePermission(captureDevice) == dassdl3_ios::CapturePermission::Pending)
            dassdl3_ios::requestCapturePermission(captureDevice);
        return true;
    }

    bool closeCapture() {
        if (!captureClose) return true;
        context->restart();
        context->evalWithCatch(captureClose, nullptr);
        captureClose = nullptr;
        if (const char *error = context->getException()) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s cleanup: %s", captureName(), error);
            return false;
        }
        return true;
    }

    SDL_AppResult drawCapture() {
        using namespace das;
        using dassdl3_ios::CapturePermission;
        if (SDL_GetTicks() >= captureDeadline) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Timed out waiting for %s permission or data", captureName());
            return SDL_APP_FAILURE;
        }
        const auto permission = dassdl3_ios::capturePermission(captureDevice);
        if (permission != CapturePermission::Pending) {
            if ((permission == CapturePermission::Denied) != captureExpectDenied) {
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s permission is %s; expected %s", captureName(),
                            permission == CapturePermission::Denied ? "denied" : "approved",
                            captureExpectDenied ? "denied" : "approved");
                return SDL_APP_FAILURE;
            }
            context->restart();
            vec4f args[] = {cast<bool>::from(captureExpectDenied)};
            const int result = cast<int32_t>::to(context->evalWithCatch(captureOpened ? captureTick : captureOpen, args));
            if (result < 0 || context->getException()) {
                const char *error = context->getException();
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL %s check: %s", captureName(), error ? error : "unexpected capture result");
                return SDL_APP_FAILURE;
            }
            captureOpened = true;
            if (result > 0) {
                if (!closeCapture()) return SDL_APP_FAILURE;
                const char *data = captureDevice == dassdl3_ios::CaptureDevice::Camera ? "frames" : "samples";
                SDL_Log("dasSDL3 iPhone %s %s PASS (%s)", captureName(), captureExpectDenied ? "denied" : data,
                        captureTick->aot ? "strict AOT" : "interpreter");
                return SDL_APP_SUCCESS;
            }
        }
        const char *prompt = "Waiting for permission";
        if (permission != CapturePermission::Pending) {
            prompt = captureDevice == dassdl3_ios::CaptureDevice::Camera ? "Checking SDL camera" :
                     captureExpectDenied ? "Checking microphone denial" : "Speak or clap several times";
        }
        if (!SDL_SetRenderDrawColor(renderer, 16, 32, 50, 255) || !SDL_RenderClear(renderer) ||
            !SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255) ||
            !SDL_RenderDebugText(renderer, 24, 104, prompt) || !SDL_RenderPresent(renderer)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Capture screen: %s", SDL_GetError());
            return SDL_APP_FAILURE;
        }
        return SDL_APP_CONTINUE;
    }

    das::SimFunction *motionEvent = nullptr;
    das::SimFunction *motionDone = nullptr;
    das::SimFunction *motionClose = nullptr;
    das::SimFunction *motionValues = nullptr;
    bool motionDashboardReady = false;
    Uint64 motionDeadline = 0;

    bool startMotion(const das::string &root, bool aot, bool live = false) {
        using namespace das;
        if (!loadInteractive(root, "ios/sensors.das", aot)) return false;
        auto *open = context->findFunction("motion_open");
        motionEvent = context->findFunction("motion_event");
        motionDone = context->findFunction("motion_done");
        auto *close = context->findFunction("motion_close");
        if (!open || !motionEvent || !motionDone || !close ||
            (aot && (!open->aot || !motionEvent->aot || !motionDone->aot || !close->aot)) ||
            !verifyCall<bool>(open->debugInfo, modules) ||
            !verifyCall<bool, const SDL_Event &>(motionEvent->debugInfo, modules) ||
            !verifyCall<int32_t>(motionDone->debugInfo, modules) ||
            !verifyCall<void>(close->debugInfo, modules)) {
            return SDL_SetError("Invalid motion sensor entry points (AOT=%d)", aot);
        }
        if (live) {
            motionValues = context->findFunction("motion_values");
            if (!motionValues || !verifyCall<float4, bool>(motionValues->debugInfo, modules))
                return SDL_SetError("Invalid motion dashboard entry point");
        }
        if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_SENSOR) ||
            !SDL_CreateWindowAndRenderer("dasSDL3 motion sensors", 640, 480,
                                         live ? SDL_WINDOW_HIGH_PIXEL_DENSITY : 0, &window, &renderer))
            return false;
        motionClose = close;
        const bool opened = cast<bool>::to(context->evalWithCatch(open, nullptr));
        if (const char *error = context->getException()) return SDL_SetError("%s", error);
        if (!opened) return SDL_SetError("Could not open both motion sensors");
        motionDeadline = SDL_GetTicks() + 45000;
        SDL_Log("dasSDL3 motion sensors ready (%s); tilt the phone several times", aot ? "strict AOT" : "interpreter");
        return true;
    }

    SDL_AppResult handleMotion(const SDL_Event &event) {
        using namespace das;
        context->restart();
        vec4f args[] = {cast<const SDL_Event &>::from(event)};
        const bool ok = cast<bool>::to(context->evalWithCatch(motionEvent, args));
        if (!ok || context->getException()) {
            const char *error = context->getException();
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Motion sensor event: %s", error ? error : "invalid sample or timestamp");
            return SDL_APP_FAILURE;
        }
        return SDL_APP_CONTINUE;
    }

    SDL_AppResult drawMotion() {
        using namespace das;
        if (motionValues) {
            auto latest = [&](bool gyro, float4 &sample) {
                context->restart();
                vec4f args[] = {cast<bool>::from(gyro)};
                sample = cast<float4>::to(context->evalWithCatch(motionValues, args));
                if (const char *error = context->getException()) return SDL_SetError("%s", error);
                return true;
            };
            float4 accel, gyro;
            if (!latest(false, accel) || !latest(true, gyro)) {
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Motion dashboard read: %s", SDL_GetError());
                return SDL_APP_FAILURE;
            }
            const float accelAxes[] = {accel.x, accel.y, accel.z};
            const float gyroAxes[] = {gyro.x, gyro.y, gyro.z};
            if (!dassdl3_ios::drawSensorDashboard(renderer, SDL_GetWindowPixelDensity(window),
                                                 accelAxes, accel.w > 0, gyroAxes, gyro.w > 0)) {
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Motion dashboard render: %s", SDL_GetError());
                return SDL_APP_FAILURE;
            }
            if (!motionDashboardReady && accel.w > 0 && gyro.w > 0) {
                motionDashboardReady = true;
                SDL_Log("dasSDL3 iPhone motion dashboard rendered both sensors");
            }
            return SDL_APP_CONTINUE;
        }
        context->restart();
        const int result = cast<int32_t>::to(context->evalWithCatch(motionDone, nullptr));
        if (result < 0 || context->getException()) {
            const char *error = context->getException();
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Motion sensor read: %s", error ? error : "invalid sample");
            return SDL_APP_FAILURE;
        }
        if (result > 0) {
            SDL_Log("dasSDL3 iPhone accelerometer and gyroscope PASS (%s)",
                    motionDone->aot ? "strict AOT" : "interpreter");
            return SDL_APP_SUCCESS;
        }
        if (SDL_GetTicks() >= motionDeadline) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Timed out waiting for movement from both iPhone sensors");
            return SDL_APP_FAILURE;
        }
        if (!SDL_SetRenderDrawColor(renderer, 16, 32, 50, 255) || !SDL_RenderClear(renderer) ||
            !SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255) ||
            !SDL_RenderDebugText(renderer, 24, 104, "Tilt the phone several times") || !SDL_RenderPresent(renderer)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Motion sensor screen: %s", SDL_GetError());
            return SDL_APP_FAILURE;
        }
        return SDL_APP_CONTINUE;
    }

    das::SimFunction *audioTick = nullptr;
    das::SimFunction *audioClose = nullptr;
    bool audioNeedsCleanup = false;
    unsigned audioRefills = 0;

    bool startAudio(const das::string &root, bool aot) {
        using namespace das;
        if (!loadInteractive(root, "examples/08_audio.das", aot)) return false;
        auto *open = context->findFunction("audio_open");
        audioTick = context->findFunction("audio_tick");
        audioClose = context->findFunction("audio_close");
        if (!open || !audioTick || !audioClose ||
            (aot && (!open->aot || !audioTick->aot || !audioClose->aot)) ||
            !verifyCall<bool>(open->debugInfo, modules) ||
            !verifyCall<int32_t>(audioTick->debugInfo, modules) ||
            !verifyCall<void>(audioClose->debugInfo, modules)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Invalid audio entry points (AOT=%d)", aot);
            return false;
        }

        SDL_SetHintWithPriority(SDL_HINT_AUDIO_DRIVER, "coreaudio", SDL_HINT_OVERRIDE);
        if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) ||
            !SDL_CreateWindowAndRenderer("dasSDL3 iPhone audio", 640, 480, 0, &window, &renderer)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Audio setup: %s", SDL_GetError());
            return false;
        }
        const char *driver = SDL_GetCurrentAudioDriver();
        if (!driver || SDL_strcmp(driver, "coreaudio") != 0) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Expected the CoreAudio playback driver");
            return false;
        }
        audioNeedsCleanup = true;
        const bool opened = cast<bool>::to(context->evalWithCatch(open, nullptr));
        if (const char *error = context->getException()) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Audio open exception: %s", error);
            return false;
        }
        if (!opened) return false;
        SDL_Log("dasSDL3 audio ready: coreaudio (%s)", aot ? "strict AOT" : "interpreter");
        return true;
    }

    SDL_AppResult drawAudio() {
        using namespace das;
        const unsigned resumed = SDL_GetAtomicInt(&resumeCount);
        context->restart();
        const int result = cast<int32_t>::to(context->evalWithCatch(audioTick, nullptr));
        if (const char *error = context->getException()) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Audio frame exception: %s", error);
            return SDL_APP_FAILURE;
        }
        if (result < 0 || !context->runWithCatchAndClear([&] { context->collectHeapIfMostlyFree(); })) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Audio frame failed");
            return SDL_APP_FAILURE;
        }
        if (resumed != reportedResume) {
            reportedResume = resumed;
            audioRefills = 0;
        }
        // Multiple refills prove the existing stream is consuming newly queued
        // data, rather than merely accepting a single write after foregrounding.
        if (result > 0 && ++audioRefills == 3) {
            SDL_Log("dasSDL3 audio stream consumed queued data PASS (cycle %u, %s)",
                    resumed, audioTick->aot ? "strict AOT" : "interpreter");
        }
        const char *prompt = !resumed ? "Hear the tone, then lock and unlock"
                         : audioRefills < 3 ? "Waiting for audio to resume"
                         : "Tap if you hear the tone again";
        if (!SDL_SetRenderDrawColor(renderer, 16, 32, 50, 255) || !SDL_RenderClear(renderer) ||
            !SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255) ||
            !SDL_RenderDebugText(renderer, 24, 104, prompt) || !SDL_RenderPresent(renderer)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Audio screen: %s", SDL_GetError());
            return SDL_APP_FAILURE;
        }
        return SDL_APP_CONTINUE;
    }

    das::SimFunction *rendererFrame = nullptr;
    das::SimFunction *rendererClose = nullptr;
    bool rendererNeedsCleanup = false;

    int layoutStep = 0;
    bool checkLayout = false;
    SDL_Point layoutSize{};
    SDL_FRect layoutMarker{};

    bool callRenderer(das::SimFunction *function, bool &result) {
        using namespace das;
        vec4f args[] = {cast<SDL_Renderer *>::from(renderer), cast<float>::from(layoutMarker.x),
                        cast<float>::from(layoutMarker.y), cast<float>::from(layoutMarker.w),
                        cast<float>::from(layoutMarker.h)};
        context->restart();
        const auto value = context->evalWithCatch(function, args);
        if (const auto *error = context->getException()) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s exception: %s", function->name, error);
            return false;
        }
        result = cast<bool>::to(value);
        return true;
    }

    bool startRenderer(const das::string &root, bool aot) {
        using namespace das;
        if (!loadInteractive(root, "examples/86_gpu_renderer.das", aot)) return false;
        auto *open = context->findFunction("renderer_open");
        rendererFrame = context->findFunction(checkLayout ? "renderer_layout_frame" : "renderer_frame");
        rendererClose = context->findFunction("renderer_close");
        if (!open || !rendererFrame || !rendererClose ||
            (aot && (!open->aot || !rendererFrame->aot || !rendererClose->aot)) ||
            !verifyCall<bool, SDL_Renderer *>(open->debugInfo, modules) ||
            !(checkLayout ? verifyCall<bool, SDL_Renderer *, float, float, float, float>(rendererFrame->debugInfo, modules)
                          : verifyCall<bool, SDL_Renderer *>(rendererFrame->debugInfo, modules)) ||
            !verifyCall<void, SDL_Renderer *>(rendererClose->debugInfo, modules)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Invalid GPU Renderer entry points (AOT=%d)", aot);
            return false;
        }
        SDL_SetHintWithPriority(SDL_HINT_GPU_DRIVER, "metal", SDL_HINT_OVERRIDE);
        SDL_SetHint(SDL_HINT_RENDER_GPU_DEBUG, "1");
        SDL_WindowFlags flags = SDL_WINDOW_HIGH_PIXEL_DENSITY;
        if (checkLayout) {
            SDL_SetHint(SDL_HINT_ORIENTATIONS, "Portrait LandscapeLeft LandscapeRight");
            flags |= SDL_WINDOW_RESIZABLE;
        }
        if (SDL_Init(SDL_INIT_VIDEO)) {
            window = SDL_CreateWindow("SDL GPU Renderer", 640, 480, flags);
            if (window) renderer = SDL_CreateGPURenderer(nullptr, window);
        }
        if (!renderer || !SDL_SetRenderLogicalPresentation(renderer, 640, 480, SDL_LOGICAL_PRESENTATION_LETTERBOX)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "GPU Renderer setup: %s", SDL_GetError());
            return false;
        }
        const char *driver = SDL_GetGPUDeviceDriver(SDL_GetGPURendererDevice(renderer));
        if (!driver || SDL_strcmp(driver, "metal") != 0) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "GPU Renderer requires the Metal backend");
            return false;
        }
        rendererNeedsCleanup = true;
        bool opened = false;
        return callRenderer(open, opened) && opened;
    }

    bool updateLayoutMarker() {
        layoutMarker = {};
        SDL_Point pixels;
        SDL_Point output;
        SDL_Rect safe;
        if (!SDL_GetWindowSize(window, &layoutSize.x, &layoutSize.y) ||
            !SDL_GetWindowSizeInPixels(window, &pixels.x, &pixels.y) ||
            !SDL_GetRenderOutputSize(renderer, &output.x, &output.y) ||
            !SDL_GetWindowSafeArea(window, &safe)) return false;
        const float density = SDL_GetWindowPixelDensity(window);
        const bool landscape = layoutSize.x > layoutSize.y;
        // Wait for the window and the renderer to agree during rotation.
        if (layoutSize.x == layoutSize.y || landscape != (layoutStep == 1) ||
            pixels.x != output.x || pixels.y != output.y ||
            density <= 1.0f ||
            SDL_fabsf(pixels.x - layoutSize.x * density) > 2.0f ||
            SDL_fabsf(pixels.y - layoutSize.y * density) > 2.0f ||
            safe.x < 0 || safe.y < 0 || safe.w <= 0 || safe.h <= 0 ||
            safe.x + safe.w > layoutSize.x || safe.y + safe.h > layoutSize.y ||
            (safe.w == layoutSize.x && safe.h == layoutSize.y)) return true;
        SDL_Rect renderSafe;
        if (!SDL_GetRenderSafeArea(renderer, &renderSafe)) return false;
        if (renderSafe.w < 128 || renderSafe.h < 128) return true;
        const float fraction = landscape ? 0.72f : 0.28f;
        layoutMarker = {renderSafe.x + renderSafe.w * fraction - 24.0f,
                        renderSafe.y + renderSafe.h * 0.35f - 24.0f, 48.0f, 48.0f};
        return true;
    }

    SDL_AppResult checkLayoutTouch(const SDL_Event &event) {
        if (layoutMarker.w <= 0 || event.tfinger.windowID != SDL_GetWindowID(window) ||
            SDL_GetTouchDeviceType(event.tfinger.touchID) != SDL_TOUCH_DEVICE_DIRECT)
            return SDL_APP_CONTINUE;
        int width, height;
        if (!SDL_GetWindowSize(window, &width, &height)) return SDL_APP_FAILURE;
        if (width != layoutSize.x || height != layoutSize.y) return SDL_APP_CONTINUE;
        SDL_Event converted = event;
        if (!SDL_ConvertEventToRenderCoordinates(renderer, &converted)) return SDL_APP_FAILURE;
        const SDL_FPoint touch{converted.tfinger.x, converted.tfinger.y};
        if (!SDL_PointInRectFloat(&touch, &layoutMarker)) return SDL_APP_CONTINUE;
        SDL_Log("dasSDL3 orientation step %d PASS (%s, %dx%d points, density %.2f, touch %.1f, %.1f)",
                layoutStep + 1, width > height ? "landscape" : "portrait", width, height,
                SDL_GetWindowPixelDensity(window), touch.x, touch.y);
        layoutMarker = {};
        return ++layoutStep == 3 ? SDL_APP_SUCCESS : SDL_APP_CONTINUE;
    }

    SDL_AppResult drawRenderer() {
        const unsigned resumed = SDL_GetAtomicInt(&resumeCount);
        if (checkLayout && !updateLayoutMarker()) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "GPU Renderer layout: %s", SDL_GetError());
            return SDL_APP_FAILURE;
        }
        bool drawn = false;
        if (!callRenderer(rendererFrame, drawn) || !drawn) return SDL_APP_FAILURE;
        if (!context->runWithCatchAndClear([&] { context->collectHeapIfMostlyFree(); })) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "GPU Renderer garbage collection failed");
            return SDL_APP_FAILURE;
        }
        if (firstFrame) {
            firstFrame = false;
            SDL_Log("dasSDL3 GPU Renderer first frame on Metal (%s)", rendererFrame->aot ? "strict AOT" : "interpreter");
        }
        if (resumed != reportedResume) {
            reportedResume = resumed;
            SDL_Log("dasSDL3 GPU Renderer frame after foreground (cycle %u)", resumed);
        }
        return SDL_APP_CONTINUE;
    }

    void closeRenderer() {
        context->restart();
        vec4f args[] = {das::cast<SDL_Renderer *>::from(renderer)};
        context->evalWithCatch(rendererClose, args);
        if (const auto *error = context->getException()) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "GPU Renderer cleanup exception: %s", error);
            return;
        }
        SDL_Log("dasSDL3 GPU Renderer resources released");
    }

    bool startTriangle(const das::string &root) {
        using namespace das;
        bool aot = false;
#ifdef DASSDL3_IPHONE_STRICT_AOT
        aot = true;
#endif
        if (!loadInteractive(root, "examples/48_gpu_native_graphics.das", aot)) return false;
        auto *create = context->findFunction("triangle_create");
        frame = context->findFunction("triangle_frame");
        if (!create || !frame || (aot && (!create->aot || !frame->aot)) ||
            !verifyCall<SDL_GPUGraphicsPipeline *, SDL_GPUDevice *, SDL_Window *>(create->debugInfo, modules) ||
            !verifyCall<int32_t, SDL_GPUDevice *, SDL_Window *, SDL_GPUGraphicsPipeline *>(frame->debugInfo, modules)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Invalid triangle entry points (AOT=%d)", aot);
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
#ifdef DASSDL3_WITH_IMGUI
    NEED_MODULE(Module_dasIMGUI);
    NEED_MODULE(Module_imgui_sdl3);
    NEED_MODULE(Module_LiveHost);
#endif
#ifdef DASSDL3_WITH_NET
    NEED_MODULE(Module_sdl3_net);
#endif
#ifdef DASSDL3_WITH_MIXER
    NEED_MODULE(Module_sdl3_mixer);
#endif
#ifdef DASSDL3_WITH_SOUND
    NEED_MODULE(Module_sdl3_sound);
#endif
#ifdef DASSDL3_WITH_TTF
    NEED_MODULE(Module_sdl3_ttf);
#endif
#ifdef DASSDL3_WITH_IMAGE
    NEED_MODULE(Module_sdl3_image);
#endif
    das::Module::Initialize();
    for (int i = 1; i < argc; ++i) {
        const auto isArg = [&](const char *arg) { return SDL_strcmp(argv[i], arg) == 0; };
        const bool camera = isArg("--camera-aot") || isArg("--camera-denied") || isArg("--camera-interpreter");
        const bool microphone = isArg("--microphone-aot") || isArg("--microphone-denied") || isArg("--microphone-interpreter");
        if (camera || microphone) {
            const auto device = camera ? dassdl3_ios::CaptureDevice::Camera : dassdl3_ios::CaptureDevice::Microphone;
            const bool aot = isArg("--camera-aot") || isArg("--microphone-aot");
            const bool denied = isArg("--camera-denied") || isArg("--microphone-denied");
#ifndef DASSDL3_IPHONE_STRICT_AOT
            if (aot) return SDL_APP_FAILURE;
#endif
            if (screen->startCapture(root, aot, denied, device)) return SDL_APP_CONTINUE;
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Capture setup: %s", SDL_GetError());
            return SDL_APP_FAILURE;
        }
        const bool motionAot = SDL_strcmp(argv[i], "--sensors-aot") == 0;
        const bool motionLive = SDL_strcmp(argv[i], "--sensors-live") == 0;
        if (motionAot || motionLive || SDL_strcmp(argv[i], "--sensors-interpreter") == 0) {
#ifndef DASSDL3_IPHONE_STRICT_AOT
            if (motionAot) return SDL_APP_FAILURE;
#endif
            if (screen->startMotion(root, motionAot, motionLive)) return SDL_APP_CONTINUE;
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Motion sensor setup: %s", SDL_GetError());
            return SDL_APP_FAILURE;
        }
        if (SDL_strcmp(argv[i], "--gamepad-smoke") == 0)
            return runSmokeTests(root, {"tests/joystick_gamepad.das", "tests/joystick_gamepad_scopes.das",
                                       "examples/71_virtual_gamepad.das"});
#ifdef DASSDL3_WITH_IMGUI
        if (SDL_strcmp(argv[i], "--imgui-widgets-smoke") == 0) {
            SDL_SetHintWithPriority(SDL_HINT_RENDER_DRIVER, "metal", SDL_HINT_OVERRIDE);
            return run(root, "tests/imgui_widgets.das", false) ? SDL_APP_SUCCESS : SDL_APP_FAILURE;
        }
#endif
#ifdef DASSDL3_IOS_IMGUI_INPUT
#ifdef DASSDL3_WITH_IMGUI
        if (SDL_strcmp(argv[i], "--imgui-widgets-input") == 0) {
            screen->imguiInput = true;
            SDL_SetHintWithPriority(SDL_HINT_RENDER_DRIVER, "metal", SDL_HINT_OVERRIDE);
            if (screen->startImGuiWidgetsInput(root)) return SDL_APP_CONTINUE;
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "dasImgui v2 input setup: %s", SDL_GetError());
            return SDL_APP_FAILURE;
        }
#endif
        if (SDL_strcmp(argv[i], "--imgui-input") == 0) {
            screen->imguiInput = true;
            if (startImGuiInput()) return SDL_APP_CONTINUE;
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "ImGui input setup: %s", SDL_GetError());
            return SDL_APP_FAILURE;
        }
#endif
#ifdef DASSDL3_WITH_IMAGE
        if (SDL_strcmp(argv[i], "--image-smoke") == 0)
            return runSmokeTests(root, {"tests/image.das", "examples/libraries/02_image.das"});
#endif
#ifdef DASSDL3_WITH_TTF
        if (SDL_strcmp(argv[i], "--ttf-smoke") == 0)
            return runSmokeTests(root, {"tests/ttf.das", "tests/ttf_shaping.das", "tests/ttf_gpu.das",
                                       "examples/libraries/03_ttf.das", "examples/libraries/04_ttf_shaping.das",
                                       "examples/libraries/05_ttf_gpu.das"});
#endif
#ifdef DASSDL3_WITH_MIXER
        if (SDL_strcmp(argv[i], "--mixer-smoke") == 0)
            return runSmokeTests(root, {"tests/mixer.das", "examples/libraries/07_mixer.das"});
#endif
#ifdef DASSDL3_WITH_SOUND
        if (SDL_strcmp(argv[i], "--sound-smoke") == 0)
            return runSmokeTests(root, {"tests/sound.das", "examples/libraries/08_sound.das"});
#endif
#ifdef DASSDL3_WITH_NET
        if (SDL_strcmp(argv[i], "--net-smoke") == 0)
            return runSmokeTests(root, {"tests/net.das", "examples/libraries/06_net.das"});
#endif
        if (SDL_strcmp(argv[i], "--gpu-renderer-smoke") == 0) {
            SDL_SetHintWithPriority(SDL_HINT_GPU_DRIVER, "metal", SDL_HINT_OVERRIDE);
            SDL_SetHint(SDL_HINT_RENDER_GPU_DEBUG, "1");
            bool passed = run(root, "examples/86_gpu_renderer.das", false);
#ifdef DASSDL3_IPHONE_STRICT_AOT
            SDL_SetHintWithPriority(SDL_HINT_GPU_DRIVER, "metal", SDL_HINT_OVERRIDE);
            SDL_SetHint(SDL_HINT_RENDER_GPU_DEBUG, "1");
            passed = run(root, "examples/86_gpu_renderer.das", true) && passed;
#endif
            return passed ? SDL_APP_SUCCESS : SDL_APP_FAILURE;
        }
        if (SDL_strcmp(argv[i], "--gpu-renderer") == 0 ||
            SDL_strcmp(argv[i], "--gpu-renderer-layout") == 0) {
            screen->checkLayout = SDL_strcmp(argv[i], "--gpu-renderer-layout") == 0;
            bool aot = false;
#ifdef DASSDL3_IPHONE_STRICT_AOT
            aot = true;
#endif
            return screen->startRenderer(root, aot) ? SDL_APP_CONTINUE : SDL_APP_FAILURE;
        }
        if (SDL_strcmp(argv[i], "--audio-interpreter") == 0)
            return screen->startAudio(root, false) ? SDL_APP_CONTINUE : SDL_APP_FAILURE;
#ifdef DASSDL3_IPHONE_STRICT_AOT
        if (SDL_strcmp(argv[i], "--audio-aot") == 0)
            return screen->startAudio(root, true) ? SDL_APP_CONTINUE : SDL_APP_FAILURE;
#endif
        if (SDL_strcmp(argv[i], "--multi-input-interpreter") == 0)
            return screen->startInput(root, false, true) ? SDL_APP_CONTINUE : SDL_APP_FAILURE;
        if (SDL_strcmp(argv[i], "--input-interpreter") == 0)
            return screen->startInput(root, false) ? SDL_APP_CONTINUE : SDL_APP_FAILURE;
#ifdef DASSDL3_IPHONE_STRICT_AOT
        if (SDL_strcmp(argv[i], "--multi-input-aot") == 0)
            return screen->startInput(root, true, true) ? SDL_APP_CONTINUE : SDL_APP_FAILURE;
        if (SDL_strcmp(argv[i], "--input-aot") == 0)
            return screen->startInput(root, true) ? SDL_APP_CONTINUE : SDL_APP_FAILURE;
#endif
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
#ifdef DASSDL3_IOS_IMGUI_INPUT
    if (screen.imguiInput) return drawImGuiInput();
#endif
    if (screen.audioTick) return screen.drawAudio();
    if (screen.captureTick) return screen.drawCapture();
    if (screen.motionDone) return screen.drawMotion();
    if (screen.inputEvent) return screen.drawInput();
    if (screen.rendererFrame) return screen.drawRenderer();
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
#ifdef DASSDL3_IOS_IMGUI_INPUT
    if (screen.imguiInput) {
        if (event->type == SDL_EVENT_QUIT) return SDL_APP_FAILURE;
        if (SDL_GetAtomicInt(&screen.active) && !passImGuiInputEvent(*event)) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "ImGui input event: %s", SDL_GetError());
            return SDL_APP_FAILURE;
        }
        return SDL_APP_CONTINUE;
    }
#endif
    if (event->type == SDL_EVENT_QUIT)
        return screen.passed || (screen.rendererFrame && !screen.checkLayout && !screen.firstFrame)
            ? SDL_APP_SUCCESS : SDL_APP_FAILURE;
    if (screen.rendererFrame && event->type == SDL_EVENT_FINGER_UP && !screen.firstFrame &&
        SDL_GetAtomicInt(&screen.active))
        return screen.checkLayout ? screen.checkLayoutTouch(*event) : SDL_APP_SUCCESS;
    if (screen.audioTick && event->type == SDL_EVENT_FINGER_UP && SDL_GetAtomicInt(&screen.active) &&
        screen.reportedResume > 0 && screen.reportedResume == unsigned(SDL_GetAtomicInt(&screen.resumeCount)) &&
        screen.audioRefills >= 3) {
        SDL_Log("dasSDL3 user confirmed audible audio after resume PASS (%s)",
                screen.audioTick->aot ? "strict AOT" : "interpreter");
        return SDL_APP_SUCCESS;
    }
    if (screen.inputEvent && SDL_GetAtomicInt(&screen.active)) return screen.handleInput(*event);
    if (screen.motionEvent && event->type == SDL_EVENT_SENSOR_UPDATE && SDL_GetAtomicInt(&screen.active))
        return screen.handleMotion(*event);
    if (screen.motionDashboardReady && event->type == SDL_EVENT_FINGER_UP && SDL_GetAtomicInt(&screen.active))
        return SDL_APP_SUCCESS;
    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *state, SDL_AppResult) {
    std::unique_ptr<Screen> screen(static_cast<Screen *>(state));
    if (screen) {
#ifdef DASSDL3_IOS_IMGUI_INPUT
        if (screen->imguiInput) stopImGuiInput();
#endif
        if (screen->motionClose) {
            screen->context->restart();
            screen->context->evalWithCatch(screen->motionClose, nullptr);
            if (const char *error = screen->context->getException())
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Motion sensor cleanup: %s", error);
        }
        screen->closeCapture();
        if (screen->audioNeedsCleanup) {
            screen->context->restart();
            screen->context->evalWithCatch(screen->audioClose, nullptr);
            if (const char *error = screen->context->getException())
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Audio cleanup exception: %s", error);
        }
        if (screen->rendererNeedsCleanup) screen->closeRenderer();
        if (screen->device) {
            if (!SDL_WaitForGPUIdle(screen->device))
                SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Triangle cleanup: %s", SDL_GetError());
            if (screen->pipeline) SDL_ReleaseGPUGraphicsPipeline(screen->device, screen->pipeline);
            if (screen->claimed) SDL_ReleaseWindowFromGPUDevice(screen->device, screen->window);
            SDL_DestroyGPUDevice(screen->device);
        }
        if (screen->window && SDL_TextInputActive(screen->window)) SDL_StopTextInput(screen->window);
        SDL_DestroyRenderer(screen->renderer);
        SDL_DestroyWindow(screen->window);
    }
    screen.reset();
    das::Module::Shutdown();
    SDL_Quit();
}
