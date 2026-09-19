#include "daScript/daScript.h"
#include "daScript/ast/ast_handle.h"
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
    for (auto &[key, annotation] : module->handleTypes) {
        if (!annotation->rtti_isHandledTypeAnnotation()) continue;
        auto type = static_cast<das::TypeAnnotation *>(annotation);
        std::ostringstream row;
        row << "TYPE\t" << type->name << '\t' << type->getSizeOf() << '\t' << type->getAlignOf()
            << '\t' << type->canCopy() << '\t' << type->hasNonTrivialCtor();
        rows.push_back(row.str());
        if (type->rtti_isBasicStructureAnnotation()) {
            auto structure = static_cast<das::BasicStructureAnnotation *>(type);
            for (auto &[name, field] : structure->fields) {
                rows.push_back("FIELD\t" + type->name + "\t" + name + "\t" + field.cppName + "\t" +
                    std::to_string(field.offset) + "\t" + field.decl->getMangledName());
            }
        }
    }
    for (auto &variable : module->globals.each())
        rows.push_back("CONST\t" + variable->name + "\t" + variable->type->getMangledName() + "\t" + variable->init->describe());
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
