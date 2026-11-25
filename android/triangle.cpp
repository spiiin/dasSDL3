#include "script_host.h"

MAKE_TYPE_FACTORY(SDL_GPUDevice, SDL_GPUDevice);
MAKE_TYPE_FACTORY(SDL_Window, SDL_Window);
MAKE_TYPE_FACTORY(SDL_GPUGraphicsPipeline, SDL_GPUGraphicsPipeline);

namespace android_host {
namespace {
bool present(Script &script, SDL_GPUDevice *device, SDL_Window *window) {
    using namespace das;
    auto &context = *script.context;
    auto *create = context.findFunction("triangle_create");
    auto *frame = context.findFunction("triangle_frame");
    if (!create || !frame || !create->aot || !frame->aot ||
        !verifyCall<SDL_GPUGraphicsPipeline *, SDL_GPUDevice *, SDL_Window *>(create->debugInfo, script.modules) ||
        !verifyCall<int32_t, SDL_GPUDevice *, SDL_Window *, SDL_GPUGraphicsPipeline *>(frame->debugInfo, script.modules))
        return SDL_SetError("Missing strict AOT triangle callbacks");
    vec4f args[] = {cast<SDL_GPUDevice *>::from(device), cast<SDL_Window *>::from(window), v_zero()};
    auto *pipeline = cast<SDL_GPUGraphicsPipeline *>::to(context.evalWithCatch(create, args));
    if (const char *error = context.getException()) return SDL_SetError("%s", error);
    if (!pipeline) return false;
    args[2] = cast<SDL_GPUGraphicsPipeline *>::from(pipeline);
    bool first = true, running = true, ok = true;
    while (running && ok) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT || event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED ||
                (event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_AC_BACK)) running = false;
        }
        if (!running) break;
        context.restart();
        const int result = cast<int32_t>::to(context.evalWithCatch(frame, args));
        if (const char *error = context.getException()) ok = SDL_SetError("%s", error);
        else if (result < 0) ok = false;
        else if (result && first) {
            SDL_Log("dasSDL3 Android vulkan-screen first frame PASS driver=%s strict AOT", SDL_GetGPUDeviceDriver(device));
            first = false;
        }
        if (ok) ok = context.runWithCatchAndClear([&] { context.collectHeapIfMostlyFree(); });
        SDL_Delay(16);
    }
    const std::string error = ok ? "" : SDL_GetError();
    SDL_ReleaseGPUGraphicsPipeline(device, pipeline);
    if (!ok) return SDL_SetError("%s", error.c_str());
    return !first || SDL_SetError("Window closed before the first frame");
}
}

bool showVulkanTriangle() {
    Script script;
    if (!script.load("app/examples/48_gpu_native_graphics.das", true) || !SDL_Init(SDL_INIT_VIDEO)) return false;
    SDL_Window *window = SDL_CreateWindow("dasSDL3 Vulkan", 640, 480, SDL_WINDOW_RESIZABLE);
    SDL_GPUDevice *device = window ? SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_SPIRV, true, "vulkan") : nullptr;
    const bool claimed = device && SDL_ClaimWindowForGPUDevice(device, window);
    const bool ok = claimed && present(script, device, window);
    const std::string error = ok ? "" : SDL_GetError();
    if (claimed) SDL_ReleaseWindowFromGPUDevice(device, window);
    if (device) SDL_DestroyGPUDevice(device);
    if (window) SDL_DestroyWindow(window);
    SDL_Quit();
    return ok || SDL_SetError("%s", error.c_str());
}
}
