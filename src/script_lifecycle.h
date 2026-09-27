#pragma once
#include "daScript/daScript.h"
#include <optional>
#include <cstring>

// Host entry-point protocol, not an SDL resource/ownership abstraction.
// Collect only after the script stack has returned to the host.
namespace dassdl3_host {
inline das::vector<das::SimFunction *> entry_functions(das::Context & context, das::Module & entry, const char * name) {
    das::vector<das::SimFunction *> result;
    for (const auto & fn : entry.functions.each()) {
        if (fn->exports && fn->name == name) {
            if (auto sim = context.fnByMangledName(fn->getMangledNameHash())) result.push_back(sim);
        }
    }
    return result;
}
class Lifecycle {
    das::Context & context;
    das::ModuleGroup & modules;
    das::TextWriter & output;
    das::SimFunction * update = nullptr, * init = nullptr, * shutdown = nullptr, * exit_code = nullptr;
    bool started = false, finished = false, failed = false;
    int code = 0;
    bool invoke(das::SimFunction * fn, vec4f & result) {
        if (!fn) return true;
        context.restart();
        result = context.evalWithCatch(fn, nullptr);
        if (const char * error = context.getException()) {
            output << "Lifecycle exception in " << fn->name << ": " << error << "\n";
            failed = true;
            return false;
        }
        return true;
    }
public:
    bool valid = true;
    Lifecycle(das::Context & ctx, das::ModuleGroup & mods, das::Module & entry, das::TextWriter & out, bool require_aot = false)
        : context(ctx), modules(mods), output(out) {
        using namespace das;
        auto pick = [&](const char * name, bool update) -> SimFunction * {
            auto functions = entry_functions(context, entry, name);
            if (functions.empty()) return nullptr;
            SimFunction * selected = nullptr;
            for (auto fn : functions) {
                const bool signature = update
                    ? (verifyCall<void>(fn->debugInfo, modules) || verifyCall<bool>(fn->debugInfo, modules)
                        || verifyCall<int32_t>(fn->debugInfo, modules))
                    : (!std::strcmp(name, "exit_code") ? verifyCall<int32_t>(fn->debugInfo, modules)
                        : verifyCall<void>(fn->debugInfo, modules));
                if (!signature) continue;
                if (selected) { valid = false; break; }
                selected = fn;
            }
            if (!selected || (require_aot && !selected->aot)) valid = false;
            if (!valid) output << "Invalid or ambiguous lifecycle entry: " << name << "\n";
            return selected;
        };
        update = pick("update", true);
        init = pick("init", false);
        shutdown = pick("shutdown", false);
        exit_code = pick("exit_code", false);
        if (valid && require_aot) output << "lifecycle AOT=yes; fallback disabled\n";
    }
    bool start() {
        if (!valid || started) return false;
        started = true;
        auto result = v_zero();
        return invoke(init, result);
    }
    bool tick() {
        using namespace das;
        if (!started || finished || failed) return false;
        auto result = v_zero();
        if (!invoke(update, result)) return false;
        if (verifyCall<bool>(update->debugInfo, modules) && !cast<bool>::to(result)) return false;
        if (verifyCall<int32_t>(update->debugInfo, modules) && cast<int32_t>::to(result) == 0) return false;
        if (!context.runWithCatchAndClear([&] { context.collectHeapIfMostlyFree(); })) {
            output << "Lifecycle garbage collection failed\n";
            failed = true;
            return false;
        }
        return true;
    }
    int finish() {
        if (!valid) return 1;
        if (started && !finished) {
            finished = true;
            auto result = v_zero();
            invoke(shutdown, result);
            if (exit_code && invoke(exit_code, result)) code = das::cast<int32_t>::to(result);
        }
        return failed ? 1 : code;
    }
};
inline std::optional<int> run_lifecycle(das::Context & context, das::ModuleGroup & modules,
    das::Module & entry, das::TextWriter & output, bool smoke, bool require_aot = false) {
    if (entry_functions(context, entry, "update").empty()) return std::nullopt;
    Lifecycle lifecycle(context, modules, entry, output, require_aot);
    if (lifecycle.start()) {
        unsigned frames = 0;
        while (lifecycle.tick()) {
            if (smoke && ++frames >= 60) break;
        }
    }
    return lifecycle.finish();
}
} // namespace dassdl3_host
