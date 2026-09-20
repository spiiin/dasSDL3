#pragma once
#include "daScript/daScript.h"

// Context::invoke in the pinned interpreter does not restore BlockArguments
// when a callback throws. Recovering inside an outer block then reads stale
// callback arguments. Keep this workaround local; do not patch the submodule.
inline bool SDL_InvokeProtectedResult(const das::Block & block, vec4f * args,
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
    return ok;
}
inline void SDL_InvokeProtected(const das::Block & block, vec4f * args,
                                das::Context * context, das::LineInfoArg * at) {
    if (!SDL_InvokeProtectedResult(block,args,context,at)) context->rethrow();
}

// One native catch boundary for a resource block, not one per SDL operation.
// Cleanup never invokes script. No error strings/RTTI/script recover on success.
// Native destructors alone are insufficient: pinned daScript can use longjmp.
template <typename Cleanup>
inline void SDL_InvokeWithCleanup(const das::Block & block,vec4f * args,Cleanup cleanup,
                                  das::Context * context,das::LineInfoArg * at) {
    const bool ok=SDL_InvokeProtectedResult(block,args,context,at);
    const bool released=cleanup();
    if (!ok) {
        if (!released) {
            context->exceptionMessage += "; SDL scope cleanup: ";
            context->exceptionMessage += SDL_GetError();
            context->exception=context->exceptionMessage.c_str();
        }
        context->rethrow();
    }
    if (!released) context->throw_error_at(at,"SDL scope cleanup: %s",SDL_GetError());
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
inline void SDL_InvokeGPUHandle(const das::TBlock<void, uint64_t> & block, uint64_t handle,
                                das::Context * context, das::LineInfoArg * at) {
    vec4f args[] = {das::cast<uint64_t>::from(handle)};
    SDL_InvokeProtected(block, args, context, at);
}
