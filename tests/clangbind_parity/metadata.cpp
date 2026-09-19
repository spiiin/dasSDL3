#include "daScript/daScript.h"
#include <algorithm>
#include <iostream>
#include <sstream>
DECLARE_MODULE(Module_dasSDL3);

int main() {
    das::setDasRoot(DASSDL3_DAS_ROOT);
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_dasSDL3);
    das::Module::Initialize();
    auto module = das::Module::require("sdl3");
    if (!module) return 1;
    std::vector<std::string> rows;
    for (auto &fn : module->functions.each()) {
        std::ostringstream row;
        row << fn->name << '\t' << fn->result->getMangledName()
            << '\t' << fn->sideEffectFlags << '\t' << fn->unsafeOperation;
        for (auto &arg : fn->arguments)
            row << '\t' << arg->name << ':' << arg->type->getMangledName();
        rows.push_back(row.str());
    }
    std::sort(rows.begin(), rows.end());
    for (const auto &row : rows) std::cout << row << '\n';
    das::Module::Shutdown();
    return 0;
}
