#include "daScript/daScript.h"
#include "daScript/misc/sysos.h"
#include <SDL3/SDL.h>
#define SDL_MAIN_HANDLED
#include <SDL3/SDL_main.h>
#include <cstring>
#include <iostream>

DECLARE_MODULE(Module_dasSDL3);

static int run_script(const char * path, bool smoke) {
    using namespace das;
    TextPrinter out;
    ModuleGroup modules;
    auto access = make_smart<FsFileAccess>();
    access->addFsRoot("dassdl3", DASSDL3_MODULE_ROOT);
    auto program = compileDaScript(path, access, out, modules);
    auto print_errors = [&] {
        for (const auto & err : program->errors)
            out << reportError(err.at, err.what, err.extra, err.fixme, err.cerr);
    };
    if (program->failed()) { print_errors(); return 1; }
    Context context(program->getContextStackSize());
    if (!program->simulate(context, out)) { print_errors(); return 1; }
    auto entry = context.findFunction("main");
    if (!entry || !verifyCall<int32_t, bool>(entry->debugInfo, modules)) {
        out << "Expected [export] def main(smoke : bool) : int\n";
        return 1;
    }
    vec4f args[] = {cast<bool>::from(smoke)};
    auto value = context.evalWithCatch(entry, args);
    if (const char * error = context.getException()) {
        out << "Script exception: " << error << "\n";
        return 1;
    }
    return cast<int32_t>::to(value);
}

int main(int argc, char ** argv) {
    if (argc < 2 || argc > 3 || (argc == 3 && std::strcmp(argv[2], "--smoke-test"))) {
        std::cerr << "Usage: dasSDL3_runner script.das [--smoke-test]\n";
        return 2;
    }
    SDL_SetMainReady();
    das::setDasRoot(DASSDL3_DAS_ROOT);
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_dasSDL3);
    das::Module::Initialize();
    int status = run_script(argv[1], argc == 3);
    SDL_Quit(); // Also clean up SDL after a script error.
    das::Module::Shutdown();
    return status;
}
