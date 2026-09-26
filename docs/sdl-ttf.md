# SDL_ttf

Optional native module `sdl3_ttf`, boost import `dassdl3/sdl3_ttf_boost`.
Enable `DASSDL3_WITH_TTF=ON` and build `dasSDL3_libraries_runner`.
ImGui and SDL_image are independent options; they are not required for text.

## Version and dependencies

SDL_ttf **3.2.2** is pinned by URL and SHA256. It requires SDL >= 3.2.6 and
uses the existing SDL 3.2.18 target. FreeType **2.14.3** is pinned as well and
shared with ImGui when both options are enabled. No extra runtime DLL is needed
by this static profile. Sources and font are covered by their upstream licenses.
See the pinned [header](https://github.com/libsdl-org/SDL_ttf/blob/release-3.2.2/include/SDL3_ttf/SDL_ttf.h)
and [build configuration](https://github.com/libsdl-org/SDL_ttf/blob/release-3.2.2/CMakeLists.txt).

HarfBuzz **10.4.0 is enabled** and pinned by archive SHA256. Its FreeType bridge
uses the same FreeType target; FreeType's reverse dependency on HarfBuzz stays
disabled to avoid a build cycle. OpenType shaping uses HarfBuzz's built-in Unicode
data; ICU, Graphite, platform shapers, command-line tools and subset library are
not dependencies of this profile. See the pinned
[HarfBuzz source](https://github.com/harfbuzz/harfbuzz/tree/10.4.0).

Set direction, ISO 15924 script and BCP 47 language explicitly for each run.
HarfBuzz performs contextual substitutions, ligatures and mark positioning.
It **does not perform paragraph-level bidirectional analysis**: mixed Arabic,
Latin and numbers require run segmentation/reordering by the application or a
separate bidi library. Do not reverse the Unicode string manually. Font coverage
still matters. PlutoSVG remains disabled; SVG emoji and browser builds are pending.

## API and ownership

All **117 exported functions** in `SDL_ttf.h` are registered, along with five
enums, flags/properties and Text, SubString and GPUAtlasDrawSequence records.
The generator checks the pinned version and export count; C++ infers signatures.
It is a small header inventory, separate from core SDL dasclang generation:

```powershell
python tools/generate_ttf_bindings.py <SDL_ttf-source>/include/SDL3_ttf/SDL_ttf.h --check
```

Consumers use committed snapshots without Python, Clang or LLVM. `SDL_Color`
arguments preserve the native by-value API with a managed-record interpreter
adapter. Raw pointer/out parameters and ownership follow SDL_ttf documentation.
`SDL_textengine.h` custom-engine internals/callbacks are not part of this census.

| Boost API | Contract |
| --- | --- |
| `with_ttf` | Balances one successful Init with Quit; returns the body's Result |
| `open_font(path/io, size)`, `with_font` | Owned font / scoped CloseFont |
| `create_surface_text_engine`, `with_surface_text_engine` | Surface engine owner/scope |
| `create_renderer_text_engine`, `with_renderer_text_engine` | Renderer engine owner/scope |
| `create_gpu_text_engine`, `with_gpu_text_engine` | Native GPU engine owner/scope; Vulkan/D3D12 alpha-atlas example |
| `create_text`, `with_text` | Text owner/scope, DestroyText before engine/font |
| `render_text_surface`, `with_text_surface` | Blended UTF-8 rendering into an owned/scoped SDL_Surface |
| `string_size`, `text_size`, `glyph_metrics` | Result of value records; no public out parameters |
| `set_text`, `set_text_color`, `draw_text` | Result<Unit>; renderer and surface draw overloads |
| `set_font_direction`, `set_text_direction` | Result<Unit>; native TTF_Direction |
| `set_font_script`, `set_text_script` | Result<Unit>; four-character ISO 15924 tag, e.g. `Arab`, `Latn` |
| `set_font_language` | Result<Unit>; BCP 47 language, e.g. `ar`, `en` |
| `gpu_text_draw_data` | Result of an array of copied native sequences; atlas textures remain borrowed |

Use `sdl_scope`, receiver pipe `sdl_use`, and `sdl_try` as in
[03_ttf.das](../examples/libraries/03_ttf.das). Destruction is ordered:
Text → TextEngine → Font → TTF_Quit; renderer/device must outlive their engine.
Font must outlive its texts even if an engine also caches glyphs. Scopes lend
resources to their bodies; callers must not destroy or retain those resources.
Factories return pointers with manual ownership, not linear handles.

The IO font overload uses `closeio=false`: **the stream must remain valid until
CloseFont**, not just until OpenFont returns. Nest `with_font(io,...)` inside
`with_io_file`. Raw OpenFontIO retains its original closeio argument. TTF_GetGlyphImage and TTF_GetGlyphImageForIndex return newly allocated surfaces
(the pinned implementation copies glyph pixels); destroy them with SDL_DestroySurface.
Text-internal pointers and GPU atlas draw data are borrowed; do not free them
independently or use them after the owning text/engine changes or dies.
Raw substring-array queries require the SDL allocator/deallocation rules in the
header; there is no copied-array boost helper yet.

Null/false failures copy SDL_GetError immediately; successful calls ignore stale
error strings. No panic or catch wrappers are introduced. Result propagation
runs deferred cleanup; arbitrary application panic is not a cleanup guarantee.
Text operations must obey SDL_ttf thread restrictions (renderer engine on the
main thread, font/text on their creation thread as specified by each function).

## Verification and remaining work

`tests/ttf.das` covers UTF-8 measurements/glyph metrics, two font sizes, wrapping
and text updates, surface/renderer pixel oracles, borrowed IO, missing fonts,
stale/captured errors, body-error propagation and Init/Quit balance.
The sample uses the included JetBrains Mono font under SIL OFL 1.1; its license
and authors are in [assets](../examples/libraries/assets/README.md).

Optional parity switch: `DASSDL3_TEST_TTF=ON`, with
`SDL_TTF_INCLUDE=<source>/include`. Build `ttf_aot_runner`, `baseline_runner` and
`cppgenbind_runner` after the main library. AOT uses fallback-disabled execution.
`TTF_FREETYPE_LIBRARY` defaults to the main build's FreeType location (ImGui and
TTF-only builds use different output directories); override it for a custom layout.

Local Windows validation passed: five surface/renderer tests including a native fixture
observing IO close callbacks for good/bad input and both closeio values; twelve
legacy/CppGenBind/AOT example and functional checks; a TTF-only consumer with
ImGui, image, generators and LLVM/Clang/Python discovery disabled. The six existing
SDL_image/ImGui checks also passed with all three optional libraries enabled.

[04_ttf_shaping.das](../examples/libraries/04_ttf_shaping.das) uses Amiri 1.003
(SIL OFL) for an Arabic RTL run with diacritics and Latin ligatures/combining marks.
All UI labels are English; the Arabic text is the shaping specimen.
`tests/ttf_shaping.das` verifies the linked HarfBuzz version, contextual joining
versus ZWNJ, right-to-left cluster positions, added mark pixels, canonical
composition pixel equality and a multi-character ligature cluster. Raw out-pointer
queries are confined to this test; the example uses boost values and scopes.

## GPU text

[05_ttf_gpu.das](../examples/libraries/05_ttf_gpu.das) draws alpha glyphs with native
SDL GPU vertex/index buffers, an atlas sampler and ordinary draw calls. Pipeline,
packing, shaders and frame orchestration are local to the example. No public text
renderer, mesh/material layer, command plan or ownership registry is added.
Shader source, committed SPIR-V/DXIL and hashes are in
[shaders](../examples/libraries/shaders/README.md). Consumers do not need DXC.

`gpu_text_draw_data(text)` returns `Result<array<TtfGpuDrawSequence>, SdlError>`.
Each record mirrors native `TTF_GPUAtlasDrawSequence`: `xy`, `uv`, `indices`,
`image_type`, `atlas_texture`. CPU arrays are copied and move-only. Index bounds,
negative/overflowing counts and missing buffers are rejected before copying.
Fill operations (underline/strikethrough) have null atlas and empty UV; they are
preserved as `IMAGE_INVALID`, not silently removed. The example's alpha shader
explicitly rejects non-alpha sequences; SDF/color/fill shaders remain follow-ups.

Atlas textures are **borrowed**, must never be released independently, and belong
to the engine/device. Acquire fresh data after text/font changes and submit draws
before further changes to text/font/engine. Do not draw from a snapshot after its
owners are destroyed; only its copied CPU arrays remain valid then. No lifetime
registry or automatic pointer-safety guarantee is implied. Destruction order is
Text → TextEngine → Font → Device (with TTF_Quit after fonts); submit/cancel recorded
commands before releasing their resources. The example waits for GPU completion
on normal exit and uses SDL's deferred GPU resource release.

Empty text succeeds with an empty array. Since native NULL means both absence
and failure, the adapter clears the thread-local error immediately before that
specific call and checks it only on NULL. Stale errors do not turn empty success
into failure. Errors are copied before cleanup. It also rejects a text without
an engine: the pinned native getter otherwise dereferences the null engine.
Raw `TTF_GetGPUTextDrawData` remains unchanged and requires a GPU-engine text.

SDL_ttf GPU xy has **negative-down Y**; the example's shader converts that once
to screen coordinates. No backend-dependent extra Vulkan flip is applied.
The smoke run updates/restores text across submitted frames, reads an RGBA8
render target through a fence and compares the blue mask against a CPU-rendered
font surface. `tests/ttf_gpu.das` uses a 128-pixel atlas to force multiple pages
and verifies copied arrays, indices, winding, empty/update, fill records, wrong
engine/null inputs and body-error propagation. It also returns move-only geometry
through `with_text` and reads CPU arrays after DestroyText. TTF scopes explicitly
state the body's Result type to avoid resource-type inference leaking into it.

GPU tests run on Vulkan/Direct3D12 with validation failures rejected, including
legacy/CppGenBind and AOT without fallback. See the library example README for
CTest commands. Local results: four main GPU checks and twelve GPU parity checks
passed. Vulkan and Direct3D12 each produced 3561 glyph-mask pixels with zero
pixels differing from the CPU reference on the tested machine. The TTF-only
consumer also passed both GPU backends with LLVM/Clang/Python discovery and
binding generation disabled. Existing image/ImGui and CPU/shaping regressions
remain green. These local pixel counts are not cross-driver guarantees.
Metal/WebGPU/browser execution is not claimed.

Not claimed: execution of all 117 raw functions, paragraph bidi,
all-script shaping correctness, SVG/color emoji, custom engine callbacks, browser support, hostile-font
fuzzing or full borrowed-pointer safety. These remain separate follow-up work.
