#include "daScript/daScript.h"
#include <fstream>
#include <iostream>
#ifdef DASSDL3_AOT_IMGUI_COROUTINE_SCOPE
#include <regex>
#endif
DECLARE_MODULE(Module_dasSDL3);
#ifdef DASSDL3_WITH_MIXER
DECLARE_MODULE(Module_sdl3_mixer);
#endif
#ifdef DASSDL3_WITH_SOUND
DECLARE_MODULE(Module_sdl3_sound);
#endif
#ifdef DASSDL3_WITH_SHADERCROSS
DECLARE_MODULE(Module_sdl3_shadercross);
#endif
#ifdef DASSDL3_WITH_NET
DECLARE_MODULE(Module_sdl3_net);
#endif
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
DECLARE_MODULE(Module_LiveHost);
#endif
using namespace das;

static int generate(const char *input, const char *output) {
    TextPrinter log;
    auto access = make_smart<FsFileAccess>();
    access->addFsRoot("dassdl3", DASSDL3_MODULE_ROOT);
#ifdef DASSDL3_WITH_IMGUI
    access->addFsRoot("imgui", std::string(DASSDL3_DAS_ROOT) + "/modules/dasImgui/widgets");
    access->addFsRoot("live", std::string(DASSDL3_DAS_ROOT) + "/modules/dasLiveHost/live");
#endif
    ModuleGroup scriptModules, compilerModules;
    CodeOfPolicies policy;
    policy.aot_module = true;
#ifdef DASSDL3_WITH_IMGUI
    // Live macro modules use ast_typedecl when generated as standalone inputs.
    policy.rtti = true;
#endif
    policy.tune_frozen = true;
    policy.fail_on_lack_of_aot_export = true;
    auto script = compileDaScript(input, access, log, scriptModules, policy);
    auto compiler = compileDaScript(getDasRoot() + "/daslib/aot_cpp.das", access, log, compilerModules, policy);
    for (auto program : {script, compiler}) {
        if (program->failed()) {
            for (auto &e : program->errors) log << reportError(e.at, e.what, e.extra, e.fixme, e.cerr);
            return 1;
        }
    }
    Context scriptContext(script->getContextStackSize()), compilerContext(compiler->getContextStackSize());
    if (!script->simulate(scriptContext, log) || !compiler->simulate(compilerContext, log)) {
        for (auto program : {script, compiler}) {
            for (auto &e : program->errors) log << reportError(e.at, e.what, e.extra, e.fixme, e.cerr);
        }
        if (auto ex = scriptContext.getException()) log << ex << "\n";
        if (auto ex = compilerContext.getException()) log << ex << "\n";
        return 2;
    }
    auto entry = compilerContext.findFunction("run_aot");
    if (!entry) return 3;
    vec4f args[] = {cast<Program *>::from(script.get()), cast<Context *>::from(&scriptContext), cast<CodeOfPolicies *>::from(&policy)};
    auto value = compilerContext.evalWithCatch(entry, args);
    if (auto ex = compilerContext.getException()) { log << ex << "\n"; return 4; }
    auto result = cast<char *>::to(value);
    if (!result || !*result) { log << "Empty AOT output\n"; return 5; }
    // Local, explicit lowering for the pinned runtime's catch-order bug.
    // Generated files are never manually patched; this is part of generation.
    std::string generated(result);
    const std::string oldCall = "das_try_recover(__context__,";
    const std::string newCall = "das::SDL_AotTryRecover(__context__,";
    for (size_t at = 0; (at = generated.find(oldCall, at)) != std::string::npos; at += newCall.size())
        generated.replace(at, oldCall.size(), newCall);
    if (generated.find("das_try_recover(") != std::string::npos) {
        log << "AOT try/recover emission changed; review pinned workaround\n";
        return 8;
    }
#ifdef DASSDL3_AOT_IMGUI_COROUTINE_SCOPE
    // Pinned emitter loses the unsafe block around a temporary GetIO reference
    // in click_at_coro. Restore that lexical scope, so resume gotos cannot cross
    // the pointer initialization. Its initializer and use stay at the same point.
    if (std::string(input).find("/dasImgui/widgets/imgui_boost_runtime.das") != std::string::npos) {
        const std::regex scope(R"((    ImGuiIO \* (__io_[A-Za-z0-9_]+) = &[^;\n]*ImGui::GetIO[^;\n]*;\n)(    [^\n]*MouseClickedTime[^\n]*;\n))");
        std::smatch match;
        if (!std::regex_search(generated, match, scope)) {
            log << "Pinned ImGui coroutine emission changed; review scope workaround\n";
            return 9;
        }
        const std::string variable = match[2];
        size_t references = 0;
        for (size_t at = 0; (at = generated.find(variable, at)) != std::string::npos; at += variable.size())
            ++references;
        if (references != 2) {
            log << "ImGui temporary escapes expected scope; review workaround\n";
            return 9;
        }
        generated.replace(size_t(match.position()), size_t(match.length()),
            "    {\n" + match[1].str() + match[3].str() + "    }\n");
    }
#endif
    std::ofstream file(output, std::ios::binary);
    file << generated;
    return file ? 0 : 6;
}
int main(int argc, char **argv) {
    if (argc != 3) return 7;
    setDasRoot(DASSDL3_DAS_ROOT);
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_dasSDL3);
#ifdef DASSDL3_WITH_MIXER
    NEED_MODULE(Module_sdl3_mixer);
#endif
#ifdef DASSDL3_WITH_SOUND
    NEED_MODULE(Module_sdl3_sound);
#endif
#ifdef DASSDL3_WITH_SHADERCROSS
    NEED_MODULE(Module_sdl3_shadercross);
#endif
#ifdef DASSDL3_WITH_NET
    NEED_MODULE(Module_sdl3_net);
#endif
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
    NEED_MODULE(Module_LiveHost);
#endif
    Module::Initialize();
    int result = generate(argv[1], argv[2]);
    Module::Shutdown();
    return result;
}
