#include "daScript/daScript.h"
#include <emscripten.h>
DECLARE_MODULE(Module_dasSDL3);
using namespace das;
static int generate(const char * input) {
    TextPrinter log;
    ModuleGroup modules;
    auto access = make_smart<FsFileAccess>();
    access->addFsRoot("dassdl3", "/repo/dassdl3");
    CodeOfPolicies policy;
    policy.aot_module = true;
    policy.tune_frozen = true;
    policy.fail_on_lack_of_aot_export = true;
    auto program = compileDaScript(input, access, log, modules, policy);
    auto driver = compileDaScript("/repo/web/standalone/emit.das", access, log, modules, policy);
    for (auto p : {program, driver}) {
        if (p->failed()) {
            for (auto & e : p->errors) log << reportError(e.at,e.what,e.extra,e.fixme,e.cerr);
            return 1;
        }
    }
    auto context = make_smart<Context>(program->getContextStackSize());
    Context driverContext(driver->getContextStackSize());
    if (!program->simulate(*context,log) || !driver->simulate(driverContext,log)) return 2;
    auto entry = driverContext.findFunction("emit");
    if (!entry) return 3;
    vec4f args[] = {cast<Program *>::from(program.get()), cast<Context *>::from(context.get()), cast<char *>::from("/out")};
    auto result = driverContext.evalWithCatch(entry,args);
    if (const char * error = driverContext.getException()) { log << error << "\n"; return 4; }
    return cast<bool>::to(result) ? 0 : 5;
}
int main(int argc, char ** argv) {
    if (argc!=4 || sizeof(void *)!=4) return 6;
    EM_ASM({ FS.mkdir('/repo'); FS.mount(NODEFS,{root:UTF8ToString($0)},'/repo');
             FS.mkdir('/out'); FS.mount(NODEFS,{root:UTF8ToString($1)},'/out'); },argv[1],argv[3]);
    setDasRoot("/repo/third_party/daScript");
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_dasSDL3);
    Module::Initialize();
    int result = 1;
    try { result=generate(argv[2]); }
    catch (const std::exception & e) { fprintf(stderr,"AOT generation failed: %s\n",e.what()); }
    Module::Shutdown();
    return result;
}
