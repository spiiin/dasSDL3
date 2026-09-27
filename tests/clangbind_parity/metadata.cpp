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
        if (annotation->rtti_isDistinctTypeAnnotation()) {
            auto type = static_cast<das::DistinctTypeAnnotation *>(annotation);
            rows.push_back("DISTINCT\t" + type->name + "\t" + type->cppName + "\t" +
                type->underlyingType->getMangledName() + "\t" + std::to_string(type->getSizeOf()) + "\t" +
                std::to_string(type->getAlignOf()));
            continue;
        }
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
    for (auto &enumeration : module->enumerations.each()) {
        rows.push_back("ENUM\t" + enumeration->name + "\t" + enumeration->cppName + "\t" +
            std::to_string(uint32_t(enumeration->baseType)) + "\t" + std::to_string(enumeration->external));
        for (const auto &entry : enumeration->list)
            rows.push_back("ENUM_VALUE\t" + enumeration->name + "\t" + entry.name + "\t" + entry.cppName + "\t" + entry.value->describe());
    }
    for (auto &variable : module->globals.each())
        rows.push_back("CONST\t" + variable->name + "\t" + variable->type->getMangledName() + "\t" + variable->init->describe());
    for (auto &fn : module->functions.each()) {
        // Extern startup in standalone/JIT uses this lookup, not overload inference.
        if (module->findFunction(fn->getMangledName()) != fn) {
            std::cerr << "Stale function index: " << fn->getMangledName() << '\n';
            das::Module::Shutdown();
            return 2;
        }
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
