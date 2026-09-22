#include "daScript/daScript.h"
#include "daScript/das_project_specific.h"
#include "daScript/misc/sysos.h"
#include "daScript/simulate/aot_builtin.h"
#include <cstring>
#include <iostream>

DECLARE_MODULE(Module_dasSDL3);

// The extension creates its own FileAccess for each document. Register the root
// here as well as for the validator so nested compilation sees the same modules.
static das::FileAccessPtr project_file_access(char * project) {
    using namespace das;
    auto access = make_smart<FsFileAccess>();
    access->addFsRoot("dassdl3", DASSDL3_MODULE_ROOT);
    if (project && *project) {
        TextPrinter out;
        ModuleGroup modules;
        auto program = compileDaScript(project, access, out, modules);
        access = make_smart<FsFileAccess>(project, program);
        access->addFsRoot("dassdl3", DASSDL3_MODULE_ROOT);
    }
    return access;
}

static int run_validator(const char * file) {
    using namespace das;
    TextPrinter out;
    ModuleGroup modules;
    auto access = project_file_access(nullptr);
    auto program = compileDaScript(file, access, out, modules);
    auto errors = [&] {
        for (const auto & err : program->errors)
            out << reportError(err.at, err.what, err.extra, err.fixme, err.cerr);
    };
    if (program->failed()) { errors(); return 1; }
    Context context(program->getContextStackSize());
    if (!program->simulate(context, out)) { errors(); return 1; }
    auto entry = context.findFunction("main");
    if (!entry || !verifyCall<void>(entry->debugInfo, modules)) {
        out << "Expected [export] def main() in the editor validation script\n";
        return 1;
    }
    context.evalWithCatch(entry, nullptr);
    if (const char * error = context.getException()) {
        out << "Validator exception: " << error << "\n";
        return 1;
    }
    return 0;
}

int main(int argc, char ** argv) {
    if (argc == 2 && std::strcmp(argv[1], "--version") == 0) {
        std::cout << DAS_VERSION_MAJOR << '.' << DAS_VERSION_MINOR << '.' << DAS_VERSION_PATCH << '\n';
        return 0;
    }
    if (argc < 2 || (argc > 2 && std::strcmp(argv[2], "--") != 0)) {
        std::cerr << "Usage: dasSDL3_language_server validator.das [-- validator arguments]\n";
        return 2;
    }
    das::setDasRoot(DASSDL3_DAS_ROOT);
    das::setCommandLineArguments(argc, argv);
    das::set_project_specific_fs_callbacks(project_file_access);
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_dasSDL3);
    das::Module::Initialize();
    const int status = run_validator(argv[1]);
    das::Module::Shutdown();
    return status;
}
