#include "daScript/daScript.h"
#include "libraries/imgui_sdl.h"
#include <iostream>
#define SDL_MAIN_HANDLED
#include <SDL3/SDL_main.h>
DECLARE_MODULE(Module_dasIMGUI);
DECLARE_MODULE(Module_Clipboard);

static bool test() {
    using namespace das;
    TextPrinter out;
    ModuleGroup modules;
    auto program = compileDaScript(DASSDL3_IMGUI_INPUT_SCRIPT, make_smart<FsFileAccess>(), out, modules);
    if (program->failed()) {
        for (auto& e : program->errors) out << reportError(e.at,e.what,e.extra,e.fixme,e.cerr);
        return false;
    }
    Context context(program->getContextStackSize());
    if (!program->simulate(context,out)) return false;
    auto draw = context.findFunction("draw");
    if (!draw || !verifyCall<bool>(draw->debugInfo,modules)) return false;
    auto window = SDL_CreateWindow("Input test",320,240,SDL_WINDOW_HIDDEN);
    auto renderer = window ? SDL_CreateRenderer(window,"software") : nullptr;
    auto gui = ImGui::CreateContext();
    bool passed = false;
    if (renderer && ImGui_SDL3_Init(window,renderer)) {
        ImGui::GetIO().IniFilename = nullptr;
        ImGui::GetIO().ConfigInputTrickleEventQueue = false;
        // Disable OS polling/warping; input under test enters solely as SDL events.
        ImGui::GetIO().ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange;
        auto frame = [&]() {
            ImGui_ImplSDLRenderer3_NewFrame(); ImGui_ImplSDL3_NewFrame();
            ImGui::NewFrame();
            const bool clicked = cast<bool>::to(context.evalWithCatch(draw,nullptr));
            ImGui::Render();
            ImGui_SDL3_Render(renderer);
            SDL_RenderPresent(renderer);
            return clicked;
        };
        frame();
        SDL_Event motion{};
        motion.type = SDL_EVENT_MOUSE_MOTION; motion.motion.windowID = SDL_GetWindowID(window);
        motion.motion.x = 50; motion.motion.y = 50;
        ImGui_SDL3_ProcessEvent(motion);
        frame();
        SDL_Event button{};
        button.type = SDL_EVENT_MOUSE_BUTTON_DOWN; button.button.windowID = SDL_GetWindowID(window);
        button.button.button = SDL_BUTTON_LEFT; button.button.down = true;
        button.button.x = 50; button.button.y = 50;
        ImGui_SDL3_ProcessEvent(button);
        frame();
        button.type = SDL_EVENT_MOUSE_BUTTON_UP; button.button.down = false;
        ImGui_SDL3_ProcessEvent(button);
        const bool clicked = frame();
        const bool captured = ImGui_SDL3_WantCaptureMouse();
        SDL_Event key{};
        key.type = SDL_EVENT_KEY_DOWN; key.key.windowID = SDL_GetWindowID(window);
        key.key.scancode = SDL_SCANCODE_A; key.key.key = SDLK_A; key.key.down = true;
        ImGui_SDL3_ProcessEvent(key);
        SDL_Event text{};
        text.type = SDL_EVENT_TEXT_INPUT; text.text.windowID = SDL_GetWindowID(window);
        text.text.text = "A\xc3\xa9";
        ImGui_SDL3_ProcessEvent(text);
        ImGui_ImplSDLRenderer3_NewFrame(); ImGui_ImplSDL3_NewFrame(); ImGui::NewFrame();
        const auto& io = ImGui::GetIO();
        passed = clicked && captured && ImGui::IsKeyDown(ImGuiKey_A) && io.InputQueueCharacters.Size == 2
            && io.InputQueueCharacters[0] == 'A' && io.InputQueueCharacters[1] == 0xe9
            && !context.getException();
        ImGui::EndFrame();
        if (!SDL_SetWindowSize(window,640,480)) passed = false;
        SDL_PumpEvents();
        SDL_Event resized{};
        while (SDL_PollEvent(&resized)) ImGui_SDL3_ProcessEvent(resized);
        frame();
        passed = passed && ImGui::GetIO().DisplaySize.x == 640 && ImGui::GetIO().DisplaySize.y == 480;
        ImGui_ImplSDLRenderer3_Shutdown(); ImGui_ImplSDL3_Shutdown();
    }
    ImGui::DestroyContext(gui);
    SDL_DestroyRenderer(renderer); SDL_DestroyWindow(window);
    return passed;
}
int main() {
    SDL_SetMainReady();
    if (!SDL_Init(SDL_INIT_VIDEO)) return 1;
    das::setDasRoot(DASSDL3_DAS_ROOT);
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_Clipboard); NEED_MODULE(Module_dasIMGUI);
    das::Module::Initialize();
    bool passed = test();
    das::Module::Shutdown(); SDL_Quit();
    std::cout << "SDL events -> ImGui: script button click, capture, key, UTF-8 and resize: " << (passed ? "PASS" : "FAIL") << '\n';
    return passed ? 0 : 1;
}
