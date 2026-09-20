# Renderer queries and logical presentation

Ten generated functions: SDL_GetNumRenderDrivers, SDL_GetRenderDriver,
SDL_GetRendererName, SDL_GetRendererProperties, SDL_GetRenderSafeArea,
SDL_SetRenderLogicalPresentation, SDL_GetRenderLogicalPresentation,
SDL_GetRenderLogicalPresentationRect, SDL_RenderCoordinatesFromWindow,
SDL_RenderCoordinatesToWindow; all five SDL_RendererLogicalPresentation values.

Driver/renderer name adapters copy SDL strings to daScript storage; NULL results
remain NULL. Renderer properties are borrowed: do not destroy the group, which
belongs to the renderer. Raw string pointers retain SDL's native lifetime.
Ref adapters only pass output addresses synchronously. No registry, implicit
state restoration, panic or exception bridge. Preserve SDL bool/error results.
Logical query failure resets size/mode as SDL does; coordinate failure leaves
output scalars unchanged. Callers must check bool before using outputs.

Logical presentation is SDL's own mapping from a logical canvas to output pixels:
stretch, letterbox, overscan or integer scale. Disabled mode removes this mapping.
Use positive logical dimensions for enabled modes. SDL stores presentation per
target; coordinate conversion explicitly uses the main window view even while a
texture target is selected. It accounts for DPI, logical presentation, scale and
viewport, and can produce coordinates outside the logical canvas in black bars.
Safe area is returned in renderer coordinates; it is not an input clipping rule.
Pointers must remain live and renderer operations follow SDL main-thread rules.

[Example 59](../examples/59_renderer_presentation.das) presents a logical square
with letterboxing and prints its center in window coordinates. It is a short
rendering demonstration, not an event-loop template.
[Tests](../tests/renderer_presentation.das) execute all ten raw functions, copied
names and ref adapters, all presentation modes, full-image software pixel checks,
window-coordinate round trips with DPI/scale/viewport and target-local state.
Pixel tests do not claim all-backend presentation or high-DPI hardware coverage.

Local Windows x64 validation: package test/example in baseline, CppGenBind and
AOT plus metadata 7/7; generation/inventory/boundary gates 6/6 and standalone
clangbind 4/4. Main suite: 133/134 on the initial run; the existing D3D12 raw test
failed its SDL_GPUSupportsShaderFormats probe, then passed on an isolated rerun.
The transient failure's cause is not established; no assertion was relaxed.
Consumer with LLVM/Clang/Python package discovery disabled built and ran the
fixture-free test, example (local direct3d11 renderer), and API boundary check.
Full AOT runner rebuilt; unrelated GPU parity runtime cases were not rerun.
Task-local logs: `work/renderer-presentation-*.log` (not repo artifacts).
