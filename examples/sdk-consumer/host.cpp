#include "daScript/daScript.h"
#include <SDL3/SDL.h>
#define SDL_MAIN_HANDLED
#include <SDL3/SDL_main.h>
DECLARE_MODULE(Module_dasSDL3);
using namespace das;
static int run(const char *path, const std::string & data, bool aot) {
    TextPrinter out; ModuleGroup modules;
    auto access = make_smart<FsFileAccess>();
    access->addFsRoot("dassdl3", data + "/dassdl3");
    CodeOfPolicies policy;
    policy.aot = aot; policy.fail_on_no_aot = aot; policy.tune_frozen = true;
    auto program = compileDaScript(path, access, out, modules, policy);
    auto errors = [&] { for (auto &e : program->errors) out << reportError(e.at,e.what,e.extra,e.fixme,e.cerr); };
    if (program->failed()) { errors(); return 1; }
    Context context(program->getContextStackSize());
    if (!program->simulate(context,out)) { errors(); return 2; }
    auto fn = context.findFunction("main");
    if (!fn || (aot && !fn->aot) || !verifyCall<int32_t,bool>(fn->debugInfo,modules)) return 3;
    out << (aot ? "main AOT=yes; fallback disabled\n" : "interpreter\n");
    vec4f args[] = {cast<bool>::from(true)};
    auto value = context.evalWithCatch(fn,args);
    if (auto ex = context.getException()) { out << ex << "\n"; return 4; }
    return cast<int32_t>::to(value);
}
int main(int argc,char **argv) {
    if (argc != 3 && argc != 4) return 5;
    SDL_SetMainReady(); setDasRoot(std::string(argv[2]) + "/dascript");
    NEED_ALL_DEFAULT_MODULES; NEED_MODULE(Module_dasSDL3);
    Module::Initialize();
    int result = run(argv[1], argv[2], argc == 4); SDL_Quit(); Module::Shutdown(); return result;
}
