#include "imgui_input.h"
#include "imgui.h"
#include "imgui_impl_sdl3.h"
#include "imgui_impl_sdlrenderer3.h"
#include <memory>
#include <utility>

namespace {
// SDL_App* stays in runner.cpp. This mode owns its own SDL and ImGui resources.
struct InputProbe {
    SDL_Window *window = nullptr;
    SDL_Renderer *renderer = nullptr;
    ImGuiContext *context = nullptr;
    bool platform = false;
    bool graphics = false;
    bool focusRequested = false;
    bool keyboardSeen = false;
    bool receivedText = false;
    bool receivedReturn = false;
    bool receivedBackspace = false;
    ImGuiInputDraw draw;
    SDL_FRect field{};
    char input[128]{};

    ~InputProbe() {
        if (window && SDL_TextInputActive(window)) SDL_StopTextInput(window);
        if (graphics) ImGui_ImplSDLRenderer3_Shutdown();
        if (platform) ImGui_ImplSDL3_Shutdown();
        if (context) ImGui::DestroyContext(context);
        if (renderer) SDL_DestroyRenderer(renderer);
        if (window) SDL_DestroyWindow(window);
    }
};
std::unique_ptr<InputProbe> input;

bool matchesTestText(const char *text, bool withNewline) {
    return SDL_strcmp(text, withNewline ? "café\n" : "café") == 0 ||
           SDL_strcmp(text, withNewline ? "привет\n" : "привет") == 0 ||
           SDL_strcmp(text, withNewline ? "Привет\n" : "Привет") == 0;
}
}

bool startImGuiInput(ImGuiInputDraw draw) {
    input = std::make_unique<InputProbe>();
    input->draw = std::move(draw);
    SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS, "0");
    SDL_SetHint(SDL_HINT_RETURN_KEY_HIDES_IME, "0");
    if (!SDL_Init(SDL_INIT_VIDEO) ||
        !SDL_CreateWindowAndRenderer("ImGui UTF-8 input", 640, 480, 0, &input->window, &input->renderer))
        return false;
    input->context = ImGui::CreateContext();
    auto &io = ImGui::GetIO();
    io.IniFilename = nullptr;
    char fontPath[4096];
    const char *basePath = SDL_GetBasePath();
    if (!basePath) return false;
    const int length = SDL_snprintf(fontPath, sizeof(fontPath), "%sassets/libraries/JetBrainsMono-Regular.ttf", basePath);
    if (length < 0 || static_cast<size_t>(length) >= sizeof(fontPath))
        return SDL_SetError("ImGui font path is too long");
    io.FontDefault = io.Fonts->AddFontFromFileTTF(fontPath, 17.0f);
    if (!io.FontDefault || !io.FontDefault->IsGlyphInFont(U'é') ||
        !io.FontDefault->IsGlyphInFont(U'П') || !io.FontDefault->IsGlyphInFont(U'п') ||
        !io.FontDefault->IsGlyphInFont(U'р') ||
        !io.FontDefault->IsGlyphInFont(U'и') || !io.FontDefault->IsGlyphInFont(U'в') ||
        !io.FontDefault->IsGlyphInFont(U'е') || !io.FontDefault->IsGlyphInFont(U'т')) {
        return SDL_SetError("ImGui test font is missing Latin or Cyrillic glyphs");
    }
    input->platform = ImGui_ImplSDL3_InitForSDLRenderer(input->window, input->renderer);
    if (!input->platform) return SDL_SetError("ImGui SDL3 platform initialization failed");
    // This test owns the keyboard session for its single window. Avoid having
    // the backend start or stop it independently as keyboard focus changes.
    ImGui::GetPlatformIO().Platform_SetImeDataFn = nullptr;
    input->graphics = ImGui_ImplSDLRenderer3_Init(input->renderer);
    if (!input->graphics) return SDL_SetError("ImGui SDLRenderer3 initialization failed");
    return true;
}

bool passImGuiInputEvent(const SDL_Event &event) {
    if (!input || !input->platform) return true;
    if (event.type == SDL_EVENT_FINGER_UP &&
        event.tfinger.windowID == SDL_GetWindowID(input->window) &&
        SDL_GetTouchDeviceType(event.tfinger.touchID) == SDL_TOUCH_DEVICE_DIRECT) {
        int width, height;
        if (SDL_GetWindowSize(input->window, &width, &height)) {
            const SDL_FPoint point{event.tfinger.x * width, event.tfinger.y * height};
            if (SDL_PointInRectFloat(&point, &input->field)) {
                input->focusRequested = true;
                SDL_Log("ImGui InputText field tapped");
                const SDL_PropertiesID props = SDL_CreateProperties();
                if (!props) return false;
                const bool started =
                    SDL_SetNumberProperty(props, SDL_PROP_TEXTINPUT_TYPE_NUMBER, SDL_TEXTINPUT_TYPE_TEXT) &&
                    SDL_SetBooleanProperty(props, SDL_PROP_TEXTINPUT_AUTOCORRECT_BOOLEAN, false) &&
                    SDL_SetNumberProperty(props, SDL_PROP_TEXTINPUT_CAPITALIZATION_NUMBER, SDL_CAPITALIZE_NONE) &&
                    SDL_StartTextInputWithProperties(input->window, props);
                SDL_DestroyProperties(props);
                if (!started) return false;
                SDL_Log("ImGui requested the iPhone screen keyboard");
            }
        }
    }
    const bool handled = ImGui_ImplSDL3_ProcessEvent(&event);
    if (handled && event.type == SDL_EVENT_KEY_DOWN &&
        event.key.windowID == SDL_GetWindowID(input->window) &&
        event.key.scancode == SDL_SCANCODE_BACKSPACE && SDL_ScreenKeyboardShown(input->window))
        input->receivedBackspace = true;
    if (handled && event.type == SDL_EVENT_TEXT_INPUT &&
        event.text.windowID == SDL_GetWindowID(input->window) &&
        SDL_ScreenKeyboardShown(input->window)) input->receivedText = true;
    if (handled && event.type == SDL_EVENT_KEY_DOWN &&
        event.key.windowID == SDL_GetWindowID(input->window) &&
        event.key.scancode == SDL_SCANCODE_RETURN && SDL_ScreenKeyboardShown(input->window)) {
        input->receivedReturn = true;
        SDL_Log("ImGui received Return from the iPhone keyboard (SDL keycode %u, modifiers %#x)",
                static_cast<unsigned>(event.key.key), static_cast<unsigned>(event.key.mod));
    }
    return true;
}

static ImGuiInputFrame drawNativeInput(const SDL_FRect &bounds, bool requestFocus) {
    ImGui_ImplSDLRenderer3_NewFrame();
    ImGui_ImplSDL3_NewFrame();
    ImGui::NewFrame();
    ImGui::SetNextWindowPos(ImVec2(bounds.x, bounds.y));
    ImGui::SetNextWindowSize(ImVec2(bounds.w, bounds.h));
    ImGui::Begin("ImGui UTF-8 input", nullptr,
                 ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoCollapse);
    ImGui::TextUnformatted("Type café or привет, then press Return.");
    if (requestFocus) ImGui::SetKeyboardFocusHere();
    const bool enterPressed = ImGui::IsKeyPressed(ImGuiKey_Enter, false);
    const bool expectedTextBeforeEnter = enterPressed && matchesTestText(input->input, false);
    ImGui::InputTextMultiline("##utf8", input->input, sizeof(input->input), ImVec2(-1.0f, 64.0f));
    const bool fieldActive = ImGui::IsItemActive();
    if (enterPressed) {
        const size_t length = SDL_strlen(input->input);
        SDL_Log("ImGui field after Return: active=%d, expected text before Return=%d, "
                "UTF-8 bytes=%zu, trailing newline=%d",
                fieldActive, expectedTextBeforeEnter, length, length > 0 && input->input[length - 1] == '\n');
    }
    const ImVec2 min = ImGui::GetItemRectMin();
    const ImVec2 max = ImGui::GetItemRectMax();
    input->field = {min.x, min.y, max.x - min.x, max.y - min.y};
    ImGui::End();
    ImGui::Render();
    ImGui_ImplSDLRenderer3_RenderDrawData(ImGui::GetDrawData(), input->renderer);
    if (matchesTestText(input->input, true)) return ImGuiInputFrame::Passed;
    return fieldActive ? ImGuiInputFrame::Active : ImGuiInputFrame::Inactive;
}

SDL_AppResult drawImGuiInput() {
    SDL_Rect safe;
    const float density = SDL_GetWindowPixelDensity(input->window);
    // ImGui positions and touches use window points. SDL must scale both
    // geometry and clipping into the high-density framebuffer.
    if (!SDL_GetWindowSafeArea(input->window, &safe) ||
        !SDL_SetRenderScale(input->renderer, density, density)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "ImGui display layout: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    if (!SDL_SetRenderDrawColor(input->renderer, 16, 32, 50, 255) || !SDL_RenderClear(input->renderer))
        return SDL_APP_FAILURE;
    const SDL_FRect bounds{float(safe.x + 12), float(safe.y + 12), float(safe.w - 24), 185.0f};
    const auto frame = input->draw ? input->draw(input->renderer, bounds, input->focusRequested, input->field)
                                   : drawNativeInput(bounds, input->focusRequested);
    if (frame == ImGuiInputFrame::Failed || !SDL_RenderPresent(input->renderer)) return SDL_APP_FAILURE;
    if (input->focusRequested && frame == ImGuiInputFrame::Active) {
        input->focusRequested = false;
        SDL_Log("ImGui InputText focused and SDL text input active");
    }
    if (!input->keyboardSeen && input->receivedText) {
        input->keyboardSeen = true;
        SDL_Log("ImGui received text while SDL reports the screen keyboard shown");
    }
    if (input->keyboardSeen && input->receivedReturn && frame == ImGuiInputFrame::Passed &&
        (!input->draw || input->receivedBackspace)) {
        if (input->draw) {
            SDL_Log("dasImgui v2 InputText exact UTF-8, Backspace and newline PASS (interpreter)");
        } else {
            SDL_Log("ImGui InputText exact UTF-8 and newline PASS: %.*s",
                    static_cast<int>(SDL_strlen(input->input) - 1), input->input);
        }
        return SDL_APP_SUCCESS;
    }
    return SDL_APP_CONTINUE;
}

void stopImGuiInput() {
    input.reset();
}
