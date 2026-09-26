#include "daScript/daScript.h"
#include <SDL3/SDL.h>
#define SDL_MAIN_HANDLED
#include <SDL3/SDL_main.h>
DECLARE_MODULE(Module_dasSDL3);
#ifdef DASSDL3_WITH_TTF
DECLARE_MODULE(Module_sdl3_ttf);
#endif
#ifdef DASSDL3_WITH_IMAGE
DECLARE_MODULE(Module_sdl3_image);
#endif
#ifdef DASSDL3_WITH_IMGUI
DECLARE_MODULE(Module_Clipboard);
DECLARE_MODULE(Module_dasIMGUI);
DECLARE_MODULE(Module_imgui_sdl3);
#endif
using namespace das;
static int run(const char *path) {
    TextPrinter out; ModuleGroup modules;
    auto access = make_smart<FsFileAccess>();
    access->addFsRoot("dassdl3", DASSDL3_MODULE_ROOT);
    CodeOfPolicies policy;
    policy.aot = true; policy.fail_on_no_aot = true; policy.tune_frozen = true;
    auto program = compileDaScript(path, access, out, modules, policy);
    auto errors = [&] { for (auto &e : program->errors) out << reportError(e.at,e.what,e.extra,e.fixme,e.cerr); };
    if (program->failed()) { errors(); return 1; }
    Context context(program->getContextStackSize());
    if (!program->simulate(context,out)) { errors(); return 2; }
    auto fn = context.findFunction("main");
    if (!fn || !fn->aot || !verifyCall<int32_t,bool>(fn->debugInfo,modules)) return 3;
    out << "main AOT=yes; fallback disabled\n";
    vec4f args[] = {cast<bool>::from(true)};
    auto value = context.evalWithCatch(fn,args);
    if (auto ex = context.getException()) { out << ex << "\n"; return 4; }
    return cast<int32_t>::to(value);
}
int main(int argc,char **argv) {
    if (argc != 2) return 5;
    SDL_SetMainReady(); setDasRoot(DASSDL3_DAS_ROOT);
    NEED_ALL_DEFAULT_MODULES; NEED_MODULE(Module_dasSDL3);
#ifdef DASSDL3_WITH_TTF
    NEED_MODULE(Module_sdl3_ttf);
#endif
#ifdef DASSDL3_WITH_IMAGE
    NEED_MODULE(Module_sdl3_image);
#endif
#ifdef DASSDL3_WITH_IMGUI
    NEED_MODULE(Module_Clipboard);
    NEED_MODULE(Module_dasIMGUI);
    NEED_MODULE(Module_imgui_sdl3);
#endif
    Module::Initialize();
    int result = run(argv[1]); SDL_Quit(); Module::Shutdown(); return result;
}
