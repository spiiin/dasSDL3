#pragma once
#include "daScript/daScript.h"

namespace das {
// Pinned daScript ebac0ffe4 (also affected in 35bf260): das_try_recover invokes catch_block before updating
// last_exception and clearing exception. Match interpreter ordering instead.
// runWithCatch restores the stack/ABI on failure. A panic in recover propagates
// directly to the outer handler, never back into this try block.
inline void SDL_AotTryRecover(Context *context, const callable<void()> &try_block,
                             const callable<void()> &catch_block) {
    if (!context->runWithCatch(try_block)) {
        context->stopFlags = 0;
        context->last_exception = context->exception;
        context->exception = nullptr;
        catch_block();
    }
}
}
