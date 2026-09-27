# dasSDL3 contributor guide

## Scope

Read [API boundary](docs/gpu-api-boundary.md) before changing public API.
This is an SDL binding, not a rendering framework. Keep generated declarations,
necessary language/lifetime adapters and small boost helpers. Application algorithms
belong in examples; no public mesh/material/scene/batching or rendering plans.

## Sources and generation

- SDL 3.4.16 and daScript 35bf260c0d8a79b94c64005bd3d2435adcf7e261 are pinned.
  Do not patch dependencies to fix binding behavior.
- Never hand-edit src/generated or docs/generated. Change policies/generators and
  regenerate both Windows backends; update separate web snapshots for header changes.
- CppGenBind is primary on Windows; Python/Clang is the reference backend. Normal
  consumers build without LLVM or shader compilers. Preserve /bigobj registration.
- Keep deterministic output, calling conventions, field dependency registration order,
  ABI/metadata parity and strict AOT without interpreter fallback.
- New fields require explicit record-field policy decisions. Run
  tools/audit_record_fields.py --check. Header coverage is not hardware validation.
- See [setup](docs/clangbind-setup.md), [snapshots](docs/clangbind-production.md),
  [AOT](docs/clangbind-types-aot.md) and [inventory](docs/api-inventory.md).

## API and lifetime

- Raw signatures/sentinels stay unchanged. Boost uses standard Result/Option under
  canonical names, without *_result aliases or void scopes. SdlError has only
  operation/message; never infer categories from SDL error strings.
- Copy errors immediately after failure, before cleanup. Stale errors, pending,
  absence and unsupported states are not failures. Body errors take precedence
  over cleanup errors. push_event preserves SDL's ambiguous acceptance bool.
- No wrapper panic/verify, try/recover or native protected-call bridges. Use direct
  blocks and defer. Enter the cleanup scope AFTER successful acquisition: defer
  is hoisted. Arbitrary application panic does not guarantee cleanup.
- Scope handles are borrowed aliases, not unique ownership. Use one outer SDL
  lifetime. Native callbacks take C addresses with exact ABI and host-owned state;
  do not retain script closures or invoke script contexts on audio workers.
- Keep with_window_hit_test never_inline for AOT temporary lifetime. Clipboard
  mutation tests use the dummy video driver; network tests are bounded and loopback-only.
- Check array sizes before narrowing/pointer arithmetic. Preserve pitches, SDL
  allocator matching, event union tags and copied text. Managed pixel views must
  reject copy/move/clone; # alone does not prevent managed cloning. Borrowed arrays
  may be explicitly cloned to independent storage.
- Prefer named initialization, returned query values, receiver-first pipes and
  gen2 trailing blocks. Retain mutable buffers for in-place operations.
- Examples use sdl_try and explicitly typed sdl_use bindings inside sdl_scope.
  Report errors once at the application boundary (main or lifecycle callback);
  keep 01_results as the explicit Result comparison.
  Do not weaken pointer checks to remove unsafe syntax. Respect macro placement
  restrictions in [sdl_try](docs/sdl-try.md) and [sdl_scope](docs/sdl-scope.md).
- See [errors](docs/error-handling.md), [ergonomics](docs/api-ergonomics.md),
  [events](docs/event-variants.md) and subsystem contracts in [docs](docs/README.md).

- Shared desktop/Web lifecycle entry points and host GC are documented in
  [lifecycle/live](docs/lifecycle-and-live.md). Do not confuse bool/int update
  continuation signals with SDL_AppResult. Web also retains the legacy app_*
  protocol; SDL callback events need app_event, not only script polling.

## GPU and memory

- Checked GPU handles are native uint64-backed distinct types with runtime kind,
  liveness and device checks. Do not add uint64 overloads or a native-pointer registry.
- End/submit/cancel consume checked IDs; native ref-consuming helpers null their
  argument so defer sees consumption. Aliases retain caller preconditions.
- Acquired swapchain textures require submit even on body Err; SDL forbids cancel.
  None skips the body. Hidden windows may produce None.
- Preserve asynchronous fence retirement; do not add wait-idle to normal readback.
  Transfer capacity must match allocation size. No script memory escapes synchronous
  borrows. Keep row/slice pitches, mip/layer and block extents explicit.
- Preserve CPU pixel/byte oracles and raw call receipts. Keep validation enabled;
  machine-specific Vulkan layer filtering is explicit and process-local.
- Shader layout is a caller contract. Normalize D3D12 vertex slots, match interstage
  signatures and do not introduce an extra Vulkan Y flip.
- Vulkan options borrow native feature pointers and names synchronously. Copy
  property values by type to avoid SDL_CopyProperties' string-cache defect and
  cleanup ownership transfer; see [properties](docs/properties.md).
- See [native GPU](docs/gpu-native-boost.md), [handles](docs/gpu-handles.md),
  [raw tests](docs/gpu-raw-tests.md) and [record access](docs/record-field-accessibility.md).

## Work and verification

- Preserve unrelated changes. Use git --no-optional-locks for read-only status
  to avoid Windows index ownership refresh. No commit/publication unless requested.
- Ninja with vcvars64, 6 build jobs. Wait for builds before running executables;
  Windows linking locks are not ACL failures.
- Do not overlap SDK/no-LLVM configuration with ClangBind work: daScript shares
  generated module configuration. Restore developer configuration afterwards.
- Binding changes need affected main tests, interpreter/CppGenBind/strict-AOT parity,
  generation checks and a no-LLVM consumer. Repeat affected checks after fixes;
  follow user-specified batching instead of needless full-suite reruns.
- AOT dependencies must include imported boost modules. Do not accept stale code
  through fallback. Keep negative API-boundary and missing-AOT checks.
- Keep example numbers stable; library examples live in examples/libraries.
- Physical devices, Metal, other OS profiles and browsers require their own evidence.
  Dummy/virtual tests and Windows builds do not establish that support.

Shader DSL: reuse upstream dasSpirv annotations; see [contract](docs/shader-dsl.md).
Keep reflection validation and explicit SDL resource sets. No new shader parser,
renderer objects or automatic raw-struct-as-std140 uploads. Direct SPIR-V remains
independent of shadercross; native translation is opt-in.
