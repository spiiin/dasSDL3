# dasSDL3 project guide

## Architectural boundary (current user requirement)

Read docs/gpu-api-boundary.md before changing public API. The task is SDL bindings,
not a renderer framework. Mesh/material/scene/batching/culling and command/render
plans were removed, including native exports. Do not restore them as optional APIs
or compatibility facades. This supersedes all historical instructions to preserve
those APIs. Application algorithms belong in examples, after direct SDL access exists.

Keep generated SDL declarations, necessary language/lifetime/array adapters, and
small defaults/with_* boost helpers. Do not add new composite GPU objects to bypass
missing SDL functions. Current transfer/readback helpers are partial adapters, not
proof of complete direct transfer/fence access. Count exported contracts, not internal
calls, helper names, examples or native test fixtures. P6 GPU API is the user's priority;
Properties, shader DSL and companion libraries follow separately. Current queue:
docs/gpu-roadmap.md. The user has now authorized the combined test run after
adding all native GPU declarations. Run main, parity/AOT and consumer checks;
after fixes repeat affected tests rather than every suite without a reason.
no repeated go-ahead requests. No commit or publication without a user request.

## Sources and generation

SDL 3.2.18 and daScript 35bf260c0d8a79b94c64005bd3d2435adcf7e261 are pinned.
Do not edit their source to fix the binding. Inventory counts use pinned headers,
not the moving SDL wiki. Read docs/bgfx-idioms.md and docs/sdl3-boost.md for language
idioms. docs/full-binding-roadmap.md and binding-design-review.md preserve research;
current boundary overrides old implementation/engine suggestions there.

Generated files in src/generated and docs/generated must never be edited by hand.
Edit tools/bindings.json, tools/api-policy.json or the generators, then regenerate.
CppGenBind saved snapshots are the default on Windows x64/MSVC; normal consumers
must build without LLVM or a shader compiler. Preserve legacy/CppGenBind metadata
parity, deterministic generation, preprocessor checks and missing-AOT negative tests.
Setup/gates: docs/clangbind-setup.md, clangbind-production.md, clangbind-types-aot.md.
Nested type annotations must register in field dependency order, not policy order.

## Runtime and language contracts

SDL errors are return values, never panic/verify in boost wrappers. No script
try/recover or native protected invocation/cleanup bridge. Read docs/error-handling.md.
Use daslib/defer and direct block calls. Enter a nested cleanup scope AFTER a
successful acquisition: defer is hoisted into the enclosing finally section.
with_* returns acquisition success and skips its void block on failure. Preserve
bool/null/zero/error sentinels and output references; check results at call sites.
Pinned panic skips defer/finally: do not promise cleanup after application panic.
Test normal/early returns, SDL error results, partial initialization and cleanup order.
Use trailing gen2 blocks: with_sdl() { ... }, with_window(...) $(window) { ... }.
Prefer receiver-first pipes. Scalar out parameters require explicit references;
managed structs differ. `pass`, `block` and `variant` are reserved identifiers.
Keep public examples free of unsafe/address expressions; never relax language pointer
checking to make them compile. A hidden unsafe operation is not an ownership proof.

GPU checked IDs are monotonic, separate by native kind, device-specific and currently
main-thread-only. Direct recording is src/sdl3_gpu_recording.h and
sdl3_gpu_recording_boost; no operation list or per-draw uniform snapshots. End/submit/
cancel consume IDs. Scope cleanup ends an open offscreen pass and cancels unsubmitted
commands; future swapchain support must submit after acquiring a non-null texture.
Cancel open recordings before resource release on device teardown. Failed submission
invalidates written targets. Keep interpreter/AOT, two-device and CPU pixel tests.

Generated native SDL_GPUCommandBuffer/SDL_GPUFence pointers now have direct SDL
acquire/submit/cancel/query/wait/release access. See docs/gpu-native-fences.md and
example 47. They are NOT checked IDs and follow SDL manual ownership/thread rules.
Do not add a registry or bridge to checked IDs merely to expose the next raw API.
The wait-array adapter borrows pointer storage only for the synchronous SDL call.
All 92 active Windows GPU functions now have generated native signatures.
See docs/gpu-native-api.md for array/out adapters, raw ownership and outstanding
validation. Generation coverage is not runtime completeness; do not claim P6 done.
Raw execution: tests/gpu_raw.das, gpu_raw_coverage.json and
test_gpu_raw_execution.py exercise 92 Vulkan functions and 90 D3D12 functions
through legacy/CppGenBind/AOT. D3D12 debug groups remain explicitly excluded.
Test-only CPU fixtures must not hide GPU operations under test. Keep call receipts,
header census matching and pixel/byte oracles. See docs/gpu-raw-tests.md.

Transfer contracts: gpu-transfer.md, gpu-texture-transfer.md, gpu-volume.md,
gpu-texture-types.md, gpu-formats.md. Bound uint64 array sizes before narrowing or
pointer arithmetic; no script memory retained. Preserve row/slice pitches, block
extents, mip/layer checks and cycling validity. Pending readback release must retire
its unsignaled fence until completion: pinned Vulkan otherwise resets an in-use
fence (VUID 01123). Do not add wait-idle to normal production readback.
ASTC HDR has a pinned Vulkan false-capability guard; positive local ASTC roundtrip
is unverified. No arbitrary format support claims from generated enums alone.

Independent shaders/pipelines/samplers: gpu-shaders.md, gpu-pipelines.md,
gpu-samplers.md. Shader binaries and std140 layout are trusted inputs, not reflected.
D3D12 indexes vertex descriptions by slot: normalize dense slots before native creation.
Keep interstage DXIL signatures matching (including SV_Position). SDL handles Vulkan
viewport Y; never insert another shader flip. Do not disable validation. FPS Monitor
layer filtering is optional and process-local, not a global single-device restriction.

Non-GPU contracts: pixels.md, geometry.md, input.md, audio.md. Preserve ref/out and
array bounds, renderer/texture ownership, render-target restore, event union-tag checks,
UTF-8 copying, SDL allocator matching and main-thread calls. No audio-thread script
callbacks. Dummy audio tests do not verify physical playback. SDL scopes are not
ref-counted sessions; prefer one outer with_sdl and nested resource owners.

## Work and verification

Use git --no-optional-locks for read-only status: index refresh may recreate index
with sandbox ownership and break Windows ACL setup. Preserve unrelated changes.
Ninja with vcvars64 works; build with 6 parallel jobs. Run the project's CTest filter,
standalone clangbind checks, interpreter/AOT parity and no-LLVM consumer as appropriate.
Run tests/test_gpu_api_boundary.py against runners to prevent engine API reintroduction.
Keep example numbers stable; removed numbers are documented in examples/README.md.
Historical GPU engine documents are explicitly marked and are not current instructions.
