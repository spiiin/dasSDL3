# Renderer creation, drawing and readback

Ten generated functions: SDL_CreateWindowAndRenderer, SDL_CreateRendererWithProperties,
SDL_RenderTextureRotated, SDL_RenderTextureAffine, SDL_RenderTextureTiled,
SDL_RenderTexture9Grid, SDL_RenderReadPixels, SDL_SetRenderVSync, SDL_GetRenderVSync,
SDL_RenderDebugText. ReadPixels moves from partial adapted to raw coverage.
The two SDL_RENDERER_VSYNC constants are included.

Ref adapters borrow rects/points/output storage only for each SDL call. Raw nullable
arguments retain their SDL defaults; explicit-ref drawing adapters specify all
rects and points. Angles are double; other coordinates and scales follow SDL.
No validation layer changes native sampling, geometry, errors or capabilities.

`with_window_renderer` follows SDL's paired creation: on success it destroys the
renderer before the window; native SDL cleans partial creation on failure. Do not
release or retain either handle in the block. `with_renderer_properties` owns only
the renderer; the caller keeps its window/surface alive and owns the creation
properties. Both use defer after acquisition and allow early block return; pinned
panic is not covered. No new renderer object/registry is introduced.

`with_read_pixels(renderer,rect)` owns the returned surface. SDL clips the region
to its viewport; inspect actual returned dimensions/format rather than assuming
the requested size. Read before presenting a window target. Raw returned surfaces
must be destroyed by the caller. No surface view of framebuffer memory escapes.

VSync requests/queries return SDL results, not timing guarantees. Unsupported
values/backends remain native failures. DebugText treats its string literally;
variadic DebugTextFormat is still separate. Glyph pixels are diagnostic, not a
font layout API. SDL native live-handle and main-thread requirements remain.

[Example 63](../examples/63_renderer_operations.das) uses paired creation, rotation
and debug text. [Tests](../tests/renderer_operations.das) execute all ten raw
functions, raw/ref image equality plus spatial pixel oracles for four drawing
operations, clipped readback, glyph pixels, properties creation and early cleanup.
VSync capability is queried with disable=0; refresh cadence is not measured.
Local software pixel results do not prove all-backend edge rasterization or HDR.

Local Windows x64 validation: main suite 142/142; package test/example in
baseline, CppGenBind and AOT plus metadata 7/7; generation/inventory/boundary
gates 6/6 and standalone clangbind 4/4. Consumer with LLVM/Clang/Python discovery
disabled built and ran the fixture-free test, example and API boundary check.
Full AOT runner rebuilt; unrelated GPU parity runtime cases were not rerun.
Task-local logs: `work/renderer-operations-*.log` (not repo artifacts).
