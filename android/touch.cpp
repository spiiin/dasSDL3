#include "script_host.h"

MAKE_TYPE_FACTORY(SDL_Window, SDL_Window);
MAKE_TYPE_FACTORY(SDL_Event, SDL_Event);

namespace android_host {
namespace {
struct TouchScript : Script {
    das::SimFunction *handler = nullptr;
    bool prepare(bool aot) {
        if (!load("app/ios/input.das", aot)) return false;
        handler = context->findFunction("multi_input_event");
        if (handler && (!aot || handler->aot) &&
            das::verifyCall<int32_t, SDL_Window *, const SDL_Event &>(handler->debugInfo, modules)) return true;
        return SDL_SetError("Invalid multi_input_event (AOT=%d)", aot);
    }
    int process(SDL_Window *window, const SDL_Event &event) {
        context->restart();
        vec4f args[] = {das::cast<SDL_Window *>::from(window), das::cast<const SDL_Event &>::from(event)};
        auto result = context->evalWithCatch(handler, args);
        if (const auto *error = context->getException()) {
            SDL_SetError("%s", error);
            return -1;
        }
        return das::cast<int32_t>::to(result);
    }
};

bool startKeyboard(SDL_Window *window) {
    SDL_PropertiesID props = SDL_CreateProperties();
    if (!props) return false;
    const bool ok = SDL_SetNumberProperty(props, SDL_PROP_TEXTINPUT_TYPE_NUMBER, SDL_TEXTINPUT_TYPE_TEXT) &&
        SDL_SetBooleanProperty(props, SDL_PROP_TEXTINPUT_AUTOCORRECT_BOOLEAN, false) &&
        SDL_SetNumberProperty(props, SDL_PROP_TEXTINPUT_CAPITALIZATION_NUMBER, SDL_CAPITALIZE_NONE) &&
        SDL_StartTextInputWithProperties(window, props);
    SDL_DestroyProperties(props);
    return ok;
}

bool probe(SDL_Window *window, SDL_Renderer *renderer, bool keyboardOnly) {
    TouchScript interpreter, compiled;
    if (!interpreter.prepare(false) || !compiled.prepare(true)) return false;
    auto *progress = interpreter.context->findFunction("matched_text_bytes");
    if (!progress || !das::verifyCall<int32_t>(progress->debugInfo, interpreter.modules))
        return SDL_SetError("Invalid matched_text_bytes");
    enum Step { Gesture, Text, Hide } step = keyboardOnly ? Text : Gesture;
    if (keyboardOnly && !startKeyboard(window)) return false;
    SDL_Log("dasSDL3 Android %s ready", keyboardOnly ? "unicode-input" : "multitouch");
    int matched = 0;
    while (true) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) return SDL_SetError("Multitouch probe closed early");
            if (!(event.type >= SDL_EVENT_FINGER_DOWN && event.type <= SDL_EVENT_FINGER_CANCELED) &&
                event.type != SDL_EVENT_TEXT_INPUT) continue;
            const int result = interpreter.process(window, event);
            if (result < 0) return false;
            const int aot = compiled.process(window, event);
            if (aot < 0) return false;
            if (aot != result) return SDL_SetError("Multitouch event differed between interpreter and strict AOT");
            if (step == Text && event.type == SDL_EVENT_TEXT_INPUT) {
                interpreter.context->restart();
                matched = das::cast<int32_t>::to(interpreter.context->evalWithCatch(progress, nullptr));
                if (const char *error = interpreter.context->getException()) return SDL_SetError("%s", error);
                SDL_Log("dasSDL3 keyboard input bytes=%zu matched=%d", SDL_strlen(event.text.text), matched);
            }
            if (result == 1 && step == Gesture) {
                if (!startKeyboard(window)) return false;
                SDL_Log("dasSDL3 Android multitouch two contacts PASS; type café or Привет 👋");
                step = Text;
            } else if (result == 2 && step == Text) {
                if (!SDL_TextInputActive(window) || !SDL_ScreenKeyboardShown(window))
                    return SDL_SetError("Expected text from active screen keyboard");
                if (!SDL_StopTextInput(window)) return false;
                step = Hide;
            }
        }
        if (step == Hide && !SDL_ScreenKeyboardShown(window) && !SDL_TextInputActive(window)) return true;
        char prompt[128];
        if (step == Gesture) SDL_strlcpy(prompt, "Two fingers: lift first, slide and lift second.", sizeof(prompt));
        else SDL_snprintf(prompt, sizeof(prompt), "Type cafe with an accented e, or Privet in Cyrillic + space + waving hand. Matched: %d bytes.", matched);
        if (!SDL_SetRenderDrawColor(renderer, 16, 32, 50, 255) || !SDL_RenderClear(renderer) ||
            !SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255) ||
            !SDL_RenderDebugText(renderer, 30, 90, prompt) || !SDL_RenderPresent(renderer)) return false;
        SDL_Delay(16);
    }
}
}

bool runMultitouch(bool keyboardOnly) {
    SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS, "0");
    if (!SDL_Init(SDL_INIT_VIDEO)) return false;
    SDL_Window *window = nullptr;
    SDL_Renderer *renderer = nullptr;
    const bool ok = SDL_CreateWindowAndRenderer("dasSDL3 multitouch", 640, 480, 0, &window, &renderer) &&
                    probe(window, renderer, keyboardOnly);
    const std::string error = ok ? "" : SDL_GetError();
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return ok || SDL_SetError("%s", error.c_str());
}
}
