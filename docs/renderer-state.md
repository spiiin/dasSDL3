# Renderer state

Ten generated SDL 3.2.18 functions: SDL_GetRenderOutputSize,
SDL_GetCurrentRenderOutputSize, SDL_SetRenderViewport, SDL_GetRenderViewport,
SDL_RenderViewportSet, SDL_SetRenderClipRect, SDL_GetRenderClipRect,
SDL_RenderClipEnabled, SDL_SetRenderScale and SDL_GetRenderScale.

Ref adapters pass addresses of borrowed rects/scalars only during SDL calls.
Scalar boost outputs use explicit daScript references, including on failure;
native zero/default output values and bool/error results remain intact.
SDL_ResetRenderViewport and SDL_DisableRenderClip pass NULL to the corresponding
SDL setters. No state stack, automatic restoration, panic or exception bridge.

The documented output size is the renderer's original output; current output
size accounts for the selected target. **Pinned software backend exception:**
SDL_GetRenderOutputSize uses SW_GetOutputSize, which reads the active surface,
so it also reports the selected texture's size. The binding preserves this native
behavior. Tests separately confirm the documented distinction on the local default
window renderer and the exception on the software renderer. Viewport, clip and scale are target-local SDL state. Clip
coordinates are relative to the viewport; scale affects viewport and clipping.
RenderClear ignores clipping/viewport. Reset viewport selects the full target;
a disabled clip returns a zero rect. False from the state predicates also means
normal unset/disabled state, not necessarily an error.

The pinned SDL rejects negative viewport dimensions, but negative clip dimensions
disable clipping. Adapters do not replace these native rules. Use sensible finite,
positive scales; pinned setters do not validate arbitrary floating-point values.
All pointers must be live and SDL renderer threading requirements still apply.

[Example 58](../examples/58_renderer_state.das) uses a software renderer on a
borrowed window surface, with scaled viewport and clipping. The renderer dies
before the window; there is no surface ownership transfer or resize in the block.
[Tests](../tests/renderer_state.das) execute all new raw functions, test ref outputs,
invalid renderer results, full-image CPU pixel oracles, and target-local state
across target switches. Pixel validation uses the local software backend; output-size queries also run
on the default window renderer. This does not validate all GPU rasterizers or platforms.

Local Windows x64 validation: main suite 132/132; package test/example in
baseline, CppGenBind and AOT plus metadata 7/7; generation/inventory/boundary
gates 6/6 and standalone clangbind 4/4. A consumer built with LLVM/Clang/Python
package discovery disabled ran the example, fixture-free state test and API
boundary check. Full AOT runner rebuilt; unrelated GPU parity runtime cases
were not rerun. Task-local logs: `work/renderer-state-*.log` (not repo artifacts).
