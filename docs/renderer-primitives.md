# Software renderer and primitives

Ten generated SDL 3.2.18 functions: CreateSoftwareRenderer, GetRenderWindow,
FlushRenderer, RenderPoint(s), RenderLine(s), RenderRect(s), RenderFillRects.
Names retain the SDL_ prefix. RectRef and four Array adapters borrow storage
only during the synchronous call, bound byte sizes before narrowing counts, and
preserve SDL bool/error results, including empty arrays. Zero-length adapters pass a local non-null sentinel because
SDL validates the pointer before the count; no array element is read. No exception bridge.

`with_software_renderer(surface)` destroys only the renderer with defer after
successful creation. The caller must keep the supplied surface alive for the
whole block. Do not destroy the renderer inside the block. A NULL acquisition
skips the block. Early return cleans up; application panic is not covered.
GetRenderWindow returns a borrowed window or NULL (including software renderers).
SDL main-thread and live-pointer requirements remain the caller's responsibility.
In particular, pinned SDL_FlushRenderer does not validate NULL: a live renderer is
a strict precondition, not a false-return test case.

[Example 57](../examples/57_software_renderer.das) renders directly into a borrowed
window surface and explicitly flushes before UpdateWindowSurface. It never calls
CreateRenderer on that window. Do not resize/destroy the window surface while its
software renderer exists. The surface has no separate ownership in this scope.
The short example delays only outside smoke mode; it is not an event-loop template.

[Tests](../tests/renderer_primitives.das) exercise every new raw function,
array/ref variants, empty arrays, invalid renderer results, window association,
early return, and reuse of an owned surface after renderer destruction. CPU RGBA
pixels check each primitive separately. Tests do not claim hardware-backend or
all-platform rasterization coverage. Renderer state, texture operations and the
remaining Surface API are subsequent packages.

Local Windows x64 validation (SDL 3.2.18): main suite 130/130; package test and
example through baseline/CppGenBind/AOT plus metadata 7/7; generation/inventory/
boundary gates 6/6 and standalone clangbind checks 4/4. Consumer with LLVM,
Clang and Python discovery disabled built and ran the fixture-free test, example,
and API boundary check. The full AOT runner was rebuilt; unrelated GPU parity
runtime cases were not rerun for this package. Logs: `work/renderer-*.log` in the
local task workspace (not committed artifacts).
