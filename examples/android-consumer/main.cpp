#include "bundle_scripts.h"
#include <iostream>

DECLARE_MODULE(Module_dasSDL3);

static bool run(const das::string &root) {
    using namespace das;
    auto access = make_smart<dassdl3_mobile::BundleAccess>();
    access->addFileSystem(new dassdl3_mobile::BundleScripts(root + "/"), true, false);
    TextPrinter log;
    ModuleGroup modules;
    CodeOfPolicies policy;
    policy.aot = policy.fail_on_no_aot = policy.tune_frozen = true;
    auto program = compileDaScript(root + "/hello.das", access, log, modules, policy);
    if (!program->failed()) {
        Context context(program->getContextStackSize());
        if (program->simulate(context, log)) {
            auto *entry = context.findFunction("check_platform");
            if (!entry || !entry->aot || !verifyCall<bool>(entry->debugInfo, modules)) return false;
            auto result = context.evalWithCatch(entry, nullptr);
            if (auto *error = context.getException()) { std::cerr << error << '\n'; return false; }
            return cast<bool>::to(result);
        }
    }
    for (const auto &error : program->errors)
        log << reportError(error.at, error.what, error.extra, error.fixme, error.cerr);
    return false;
}

int main() {
    const auto root = (std::filesystem::current_path() / "app").string();
    das::setDasRoot(root);
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_dasSDL3);
    das::Module::Initialize();
    const bool ok = run(root);
    das::Module::Shutdown();
    std::cout << "Independent Android strict AOT consumer " << (ok ? "PASS" : "FAIL") << '\n';
    return ok ? 0 : 1;
}
