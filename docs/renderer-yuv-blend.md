# Renderer YUV planes, color and custom blend

Ten generated functions: SDL_UpdateYUVTexture, SDL_UpdateNVTexture,
SDL_SetRenderDrawColorFloat, SDL_GetRenderDrawColorFloat, SDL_GetRenderDrawColor,
SDL_SetRenderColorScale, SDL_GetRenderColorScale, SDL_SetRenderDrawBlendMode,
SDL_GetRenderDrawBlendMode, SDL_ComposeCustomBlendMode. All pinned BlendFactor
and BlendOperation enum values are exposed.

Whole-texture array adapters support IYUV/YV12 (separate Y,U,V arguments) and
NV12/NV21 (interleaved UV/VU bytes as specified by the format). They borrow arrays
only for synchronous native calls. Each pitch and byte capacity is checked using
64-bit arithmetic, capped at INT_MAX. Chroma dimensions use ceil(width/2) and
ceil(height/2), including odd sizes; final-row padding is not required. Negative
or short pitches, wrong formats, insufficient planes and oversized layouts return
SDL errors without calling the update. No conversion or retained-buffer system. SDL defaults these textures to
JPEG/full-range; different video ranges require explicit creation colorspace.
Native region updates remain raw and retain native alignment/lifetime constraints.

Renderer float and blend getters use direct references; byte output widens Uint8
into uint explicitly. Native default output values and bool/error results remain
intact. Composing a mode does not promise renderer support: check the setter's
result. No state stack, exception bridge or panic conversion. Color scale affects
renderer output according to backend/colorspace capability; scalar round trips
are not proof of HDR rendering support.

[Example 62](../examples/62_renderer_yuv_blend.das) uploads a planar YUV checker.
[Tests](../tests/renderer_yuv_blend.das) execute all new raw functions and adapters,
all four YUV formats with odd 5x3 dimensions/padded rows, default JPEG/full-range
black/white/red pixels (tolerance 4), invalid pitches/capacities, renderer color
round trips and alpha blend pixels. A composed standard mode succeeds; a genuinely
custom mode is rejected by the pinned software renderer without changing state.
Other colorspaces, HDR, hardware YUV pixels and custom hardware equations need
separate coverage. Live texture/renderer and main-thread rules remain native SDL.

MSVC library builds now use /bigobj: generated registrations exceed the standard
COFF section limit. Parity targets already used this flag.

Local Windows x64 validation: main suite 140/140; package test/example through
baseline, CppGenBind and AOT plus metadata 7/7; generation/inventory/boundary
gates 6/6 and standalone clangbind 4/4. Consumer with LLVM/Clang/Python discovery
disabled built with /bigobj and ran the fixture-free test, example and API boundary
check. Full AOT runner rebuilt; unrelated GPU parity runtime cases were not rerun.
Task-local logs: `work/renderer-yuv-blend-*.log` (not repo artifacts).
