# dasSDL3 project guide

## Architectural boundary (current user requirement)

Read docs/gpu-api-boundary.md before changing public API. The task is SDL bindings,
not a renderer framework. Mesh/material/scene/batching/culling and command/render
plans were removed, including native exports. Do not restore them as optional APIs
or compatibility facades. This supersedes all historical instructions to preserve
those APIs. Application algorithms belong in examples, after direct SDL access exists.

Keep generated SDL declarations, necessary language/lifetime/array adapters, and
small defaults/with_* boost helpers. Do not add new composite GPU objects to bypass
missing SDL functions. Count exported contracts, not internal calls, helper names,
examples or native test fixtures. Five native GPU follow-up steps are locally
verified; Properties now has 19 generated functions plus copied enumeration; retained
cleanup callback remains pending. Read docs/properties.md for the pinned numeric
string-cache/CopyProperties double-free defect and copied-string adapter. Hints/Init adds 12 generated functions, copied getters and subsystem defer scopes;
see docs/init-hints.md for pending callbacks and string constants. Next
library-wide queue: P4 Filesystem/Storage/IOStream/AsyncIO. P3 follow-ups include keyboard/mouse device hotplug payloads, native virtual callback fields and physical-device validation.
IME candidates and clipboard MIME lists are owned arrays; SdlEvent/Option/Result
are move-only. Use <-, move_unwrap and emplace, or explicit clone_to_move/push_clone.
See docs/event-list-payloads.md for raw borrowed user data and list validation.
Touch/Sensor/Haptic/HIDAPI have 71 raw declarations; Pen is event-only. Read
docs/peripherals.md for native HID wchar_t/AOT storage, report counts and
custom haptic pointer lifetime. Physical peripheral I/O remains unverified.
Joystick/Gamepad raw declarations are 58/58 + 73/73; see docs/joystick-gamepad.md
for retained native callback descriptors, copied configuration, GUID ABI and pinned
virtual-driver defects (one pending sensor event before Update; no virtual balls;
Uint8 update-index limit). Keyboard/Mouse is 24/24 + 22/22 raw
and Events (19/19 raw). See docs/keyboard-mouse.md for retained scancode names,
layout-aware keys, uint16 native mask storage, cursor ownership and backend limits.
See docs/event-callbacks.md for native callback addresses and synchronous filtering.
See docs/event-queue.md for timeout/error convention,
partial ADD counts, registration limits and borrowed versus copied payloads.
SdlEvent now has 53 alternatives, including all 13 Touch/Pen/Sensor and 21 Joystick/Gamepad tags, copied drop strings and user metadata;
application user pointers remain raw. Full Result/Option migration is locally validated;
see docs/result-option-plan.md for contracts and verification. P2 function declarations are connected, with
RenderDebugTextFormat limited to fixed text and 20 GL/EGL Video functions explicitly
deferred to P8. Rect/Clipboard/hit-test contracts: docs/rect-clipboard-hittest.md.
All 58 Surface and 11 Pixels functions now have raw signatures; see
docs/surface-pixels.md for memory, palette and BMP ownership limits. Surface state adds 16 raw functions and scalar/rect adapters;
see docs/surface-state.md. Choose cohesive behavioral packages, not a fixed function
count; implement a package before testing it as a whole. Render has 88 generated signatures and one fixed-text
variadic adapter; positive native Metal/Vulkan interop remains unverified.
See docs/renderer-final-api.md. Renderer operations adds 10 raw functions;
see docs/renderer-operations.md for paired creation, borrowed draw refs, owned
clipped readback and VSync capability limits. YUV/color/blend adds 10 raw functions;
see docs/renderer-yuv-blend.md for odd plane sizes, pitch/capacity checks and
backend-dependent custom blend support. Texture bytes/transfer adds 10 raw
functions; see docs/texture-transfer.md for byte refs, bounded RGBA32 updates
and borrowed write-only surface locks. Raw LockTexture requires in-bounds rects. Texture creation/state adds 10 raw
functions and defer scopes; see docs/texture-state.md. CreateTexture is now raw;
the existing RGBA8 upload adapter still supports only streaming RGBA32.
Renderer queries/logical presentation adds 10 raw functions; see
docs/renderer-presentation.md for borrowed properties, copied names, enum refs
and main-view coordinate conversion while a texture target is selected.
Renderer state adds 10 raw functions and scalar/rect ref adapters; see
docs/renderer-state.md for target-local state, NULL resets and full-image pixel tests.
Software renderer/primitives adds 10 raw functions; see docs/renderer-primitives.md
for borrowed surface lifetime, array adapters and CPU pixel tests. Window IO adds 25 Video + 3 Surface
raw functions; see docs/window-io.md for borrowed surfaces, conditional capabilities
and the pinned NULL shape-removal defect. The raw ICC getter lacks native window
validation; its copy adapter rejects NULL, while live-window/video preconditions remain. Video is 89/109; remaining GL/EGL is P8. Hit-test callbacks are lexical scopes;
Clipboard uses native-owned copied data or explicit native callback addresses.
Window creation/state adds 27 raw functions and defer scopes; parent lifetime
preconditions are documented in docs/window-state.md. Video discovery adds 31 raw
queries and copied/ref adapters; see docs/video-discovery.md for native lifetimes. Error/log/time adds 22 raw functions
and 10 fixed-text adapters; see docs/diagnostics-time.md for pending callback/va_list contracts. Shader DSL and companion libraries follow separately.
Current queue: docs/full-binding-roadmap.md; GPU limitations: docs/gpu-roadmap.md;
documentation index: docs/README.md. Run main, parity/AOT and consumer checks for
binding changes; after fixes repeat affected tests rather than every suite
without a reason. No repeated go-ahead requests. No commit or publication without
a user request.

Callback rules: native callback arguments are C function addresses, not script Func/Block
values. Only explicitly reviewed callback APIs bypass dasclang's callback filter.
Callback APIs use generated AOT cpp names for native address casts;
keep both generators in sync. with_window_hit_test pins the lexical block/context
until deferred unregister; keep its never_inline annotation so AOT temporaries live
through the entire scope call. Do not store arbitrary script blocks for later callbacks.
Clipboard copy data is native-owned through SDL cleanup even after backend failure.
Tests that set clipboard data must use SDL_VIDEODRIVER=dummy.

## Sources and generation

SDL 3.2.18 and daScript 35bf260c0d8a79b94c64005bd3d2435adcf7e261 are pinned.
Do not edit their source to fix the binding. Inventory counts use pinned headers,
not the moving SDL wiki. Read docs/bgfx-idioms.md and docs/sdl3-boost.md for language
idioms. docs/full-binding-roadmap.md and binding-design-review.md preserve research;
current boundary overrides old implementation/engine suggestions there.

Generated files in src/generated and docs/generated must never be edited by hand.
Edit tools/bindings.json, tools/api-policy.json or the generators, then regenerate.
CppGenBind saved snapshots are the default on Windows x64/MSVC; normal consumers
must build without LLVM or a shader compiler. MSVC module registration requires
/bigobj (set on dasSDL3), as the expanded bindings exceed standard COFF sections. Preserve legacy/CppGenBind metadata
parity, deterministic generation, preprocessor checks and missing-AOT negative tests.
Setup/gates: docs/clangbind-setup.md, clangbind-production.md, clangbind-types-aot.md.
Nested type annotations must register in field dependency order, not policy order.

## Runtime and language contracts

SDL errors are return values, never panic/verify in boost wrappers. No script
try/recover or native protected invocation/cleanup bridge. Read docs/error-handling.md.
Use daslib/defer and direct block calls. Enter a nested cleanup scope AFTER a
successful acquisition: defer is hoisted into the enclosing finally section.
Boost uses standard Result/Option under canonical names; there are no legacy bool
scopes, void-block scopes, *_result or *_status_result aliases. Scope blocks return
Result; use sdl_ok() for successful void work. Preserve primary body error if cleanup
also fails. Raw SDL signatures/sentinels stay unchanged. Optional event polling
keeps its borrowed SDL_Event out parameter. The optional sdl3_events module adds
poll_event() returning Option<SdlEvent> and decode_event(raw); see docs/event-variants.md.
Only documented variant payloads are decoded; text is copied immediately into
daScript storage, unknown events preserve type/timestamp without native pointers. Pure
predicates remain bool; push_event retains SDL's ambiguous acceptance bool.
Read docs/result-option-plan.md and docs/error-handling.md for the contract inventory.
Capture errors before cleanup; pending/absent/unsupported are not SDL failures.
Native swapchain commands with an acquired texture must submit even on body Err;
SDL forbids cancellation after swapchain acquisition. None skips the body.
Pinned panic skips defer/finally: do not promise cleanup after application panic.
Test normal/early returns, SDL error results, partial initialization and cleanup order.
Use trailing gen2 blocks: with_sdl() { ... }, with_window(...) $(window) { ... }.
Keep example acquisition callbacks short: return nested Result directly, and move
substantial loops/upload/draw/readback work into ordinary named Result-returning
functions inside the example. Borrow handles synchronously; report errors once in
main. Avoid global failure flags and blanket and_then nesting. Do not introduce
public composite scopes or a shared rendering framework just to reduce indentation.
For linear Result work, opt into dassdl3/sdl3_try; see docs/sdl-try.md. Use it only
as a standalone statement, the sole initializer of one let/var, or the entire RHS
of assignment to a variable in a Result function/block. Indexed/field targets
remain unsupported. It performs ordinary early return, preserving defer; do not use
it in cleanup, nested expressions or as a function pointer. Arrays require move
initializers. Keep an ordinary success return so the enclosing Result type is known.
Numbered examples use sdl_try; keep examples/results/01_results.das as the explicit
Result/and_then comparison to examples/results/02_sdl_try.das. Report errors in main;
retain Option defaults and normal false/pending/unsupported states.
Prefer receiver-first pipes. Scalar out parameters require explicit references;
managed structs differ. `pass`, `block` and `variant` are reserved identifiers.
For linear scoped acquisition, import dassdl3/sdl3_scope and use explicit typed
bindings such as `let vb : GpuBufferHandle = device |> with_gpu_vertex_buffer(vertices) |> sdl_use`
inside `sdl_scope() { ... }`. Zero-parameter scopes use `with_sdl() |> sdl_use`.
The macros nest existing wrappers; they introduce no ownership/cleanup mechanism.
Keep lifetime boundaries and multi-parameter callbacks explicit. See docs/sdl-scope.md
for supported placements, references and compile-time rejection rules.
Keep public examples free of unsafe/address expressions; never relax language pointer
checking to make them compile. A hidden unsafe operation is not an ownership proof.

GPU checked IDs are monotonic, separate by native kind, device-specific and
main-thread-only. They use native-registered uint64-backed distinct Gpu*Handle types; see
docs/gpu-handles.md. Keep checked scalar/array signatures nominal in native exports
and boost. Do not reintroduce uint64 overloads, enum substitutes or duplicate script
typedefs. Use explicit *handle only for diagnostics/test fixtures; runtime kind,
liveness and device checks remain necessary. Raw SDL pointers stay unchanged.
GPU Result factories use checked_handle_result (limited to the ten distinct handle
types); see docs/gpu-factories.md. Prefer these factories and sdl_try over repeated
zero/null guards in examples. They do not own resources: preserve deferred cleanup.
Direct recording is src/sdl3_gpu_recording.h and
sdl3_gpu_recording_boost; no operation list or per-draw uniform snapshots. End/submit/
cancel consume IDs. Scope cleanup ends an open offscreen pass and cancels unsubmitted
commands. Native swapchain scopes submit after acquiring a non-null texture.
Cancel open recordings before resource release on device teardown. Failed submission
invalidates written targets. Keep interpreter/AOT, two-device and CPU pixel tests.

Generated native SDL_GPUCommandBuffer/SDL_GPUFence pointers now have direct SDL
acquire/submit/cancel/query/wait/release access. See docs/gpu-native-fences.md and
example 47. They are NOT checked IDs and follow SDL manual ownership/thread rules.
Do not add a registry or bridge to checked IDs merely to expose the next raw API.
The wait-array adapter borrows pointer storage only for the synchronous SDL call.
All 92 active Windows GPU functions now have generated native signatures.
See docs/gpu-native-api.md and gpu-native-boost.md for array/out adapters and
native ownership. Five native follow-up steps have local Windows validation in
gpu-native-validation.md; do not claim all-platform GPU completion.
sdl3_gpu_native_boost uses defer and native pointers, without a registry/checked-ID
bridge. Resource callbacks must not release/retain borrowed handles; swapchain
callbacks must not consume their command. Offscreen command scopes use the
ref-consuming submit/cancel helpers. Byte transfer capacity must equal creation
size; handle validity, usage and fence completion remain caller preconditions.
Examples 48–50 are public and fixture-free. gpu_native_adapters checks advanced
attachments/lifetimes; gpu_native_array_operations covers array/ref conversions.
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
Documents for removed GPU engine APIs were deleted; do not restore them as active instructions.

Wait for parity builds to finish before executing their binaries: Windows locks
executables during linking (WinError 32 is not an ACL failure).

Do not overlap no-LLVM consumer configuration/build with clangbind-dependent
builds or tests: they share daScript generated module configuration. Restore the
production generator configuration after consumer checks before clangbind gates.
