#pragma once
#include "daScript/daScript.h"

// Context::invoke in the pinned interpreter does not restore BlockArguments
// when a callback throws. Recovering inside an outer block then reads stale
// callback arguments. Keep this workaround local; do not patch the submodule.
inline void SDL_InvokeProtected(const das::Block & block, vec4f * args,
                                das::Context * context, das::LineInfoArg * at) {
    auto * savedThis = context->abiThisBlockArg;
    auto * slot = block.argumentsOffset
        ? reinterpret_cast<das::BlockArguments *>(context->stack.bottom() + block.argumentsOffset)
        : nullptr;
    das::BlockArguments saved{};
    if (slot) saved = *slot;
    const bool ok = context->runWithCatch([&] { context->invoke(block, args, nullptr, at); });
    if (slot) *slot = saved;
    context->abiThisBlockArg = savedThis;
    if (!ok) context->rethrow();
}
template <typename T>
inline void SDL_InvokeResource(const das::TBlock<void, T * const> & block, T * resource,
                               das::Context * context, das::LineInfoArg * at) {
    vec4f args[] = {das::cast<T *>::from(resource)};
    SDL_InvokeProtected(block, args, context, at);
}
inline void SDL_InvokeScope(const das::TBlock<void> & block,
                            das::Context * context, das::LineInfoArg * at) {
    SDL_InvokeProtected(block, nullptr, context, at);
}
