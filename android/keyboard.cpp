#include "script_host.h"
#include "../ios/imgui_input.h"

MAKE_TYPE_FACTORY(SDL_Renderer, SDL_Renderer);
MAKE_TYPE_FACTORY(SDL_FRect, SDL_FRect);

namespace android_host {
static SDL_AppResult pollKeyboard() {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_EVENT_QUIT) {
            SDL_SetError("Keyboard probe closed before completion");
            return SDL_APP_FAILURE;
        }
        if (!passImGuiInputEvent(event)) return SDL_APP_FAILURE;
    }
    return drawImGuiInput();
}

bool runKeyboard(bool widgets) {
    using namespace das;
    Script script;
    ImGuiInputDraw draw;
    if (widgets) {
        if (!script.load("app/ui/imgui_widgets_input.das", false)) return false;
        auto *frame = script.context->findFunction("input_frame");
        if (!frame || !verifyCall<int32_t, SDL_Renderer *, const SDL_FRect &, bool, SDL_FRect &>(
                frame->debugInfo, script.modules)) return SDL_SetError("Invalid widget input_frame");
        draw = [&script, frame](SDL_Renderer *renderer, const SDL_FRect &bounds, bool focus, SDL_FRect &field) {
            vec4f args[] = {cast<SDL_Renderer *>::from(renderer), cast<const SDL_FRect &>::from(bounds),
                            cast<bool>::from(focus), cast<SDL_FRect &>::from(field)};
            script.context->restart();
            const auto value = script.context->evalWithCatch(frame, args);
            if (const auto *error = script.context->getException()) {
                SDL_SetError("%s", error);
                return ImGuiInputFrame::Failed;
            }
            return static_cast<ImGuiInputFrame>(cast<int32_t>::to(value));
        };
    }
    SDL_AppResult result = SDL_APP_FAILURE;
    if (startImGuiInput(std::move(draw))) {
        SDL_Log("dasSDL3 Android %s keyboard ready", widgets ? "imgui-v2" : "imgui");
        do {
            result = pollKeyboard();
            SDL_Delay(16);
        } while (result == SDL_APP_CONTINUE);
    }
    const std::string error = SDL_GetError();
    stopImGuiInput();
    SDL_Quit();
    return result == SDL_APP_SUCCESS || SDL_SetError("%s", error.c_str());
}
}
