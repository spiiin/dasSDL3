# Result/Option: full boost migration

P2 declarations remain connected. The remaining 20 GL/EGL Video functions are
assigned to P8. P3 Events/input and P4 subsequently progressed; see the
[current roadmap](full-binding-roadmap.md) for remaining work and the P5 queue.
Result/Option migration preserves raw SDL signatures.

## Current API

Opt-in [`sdl_try`](sdl-try.md) now provides ordinary early error returns for
Result-valued statements and single-variable initializers. It preserves the
existing scope cleanup policy and leaves raw SDL signatures unchanged.

Standard containers are re-exported from `dassdl3/sdl3_result` through the usual
boost modules. The experimental `sdl3_result_boost` module and suffixed function
names were removed. Every fallible boost operation now returns Result; absence
uses Option, or Result<Option<T>> where absence and error can coexist. Pure value
construction, predicates and void destruction/logging stay unwrapped.

All with_* blocks return Result<T,SdlError>; void bodies must explicitly finish
with sdl_ok(). There is one scope form, without result/status suffixes. Ordinary
scopes return the body Result after defer; swapchain scope additionally returns
Option<T> because SDL may successfully acquire no texture.

| Operation | Contract |
| --- | --- |
| texture_size, window_size, renderer queries | Result<value,SdlError>; explicit ref/out forms return Result<SdlUnit,SdlError> |
| creation | Result<resource,SdlError>, manual pointer ownership |
| clear/draw/present/set_title, transfers | Result<SdlUnit,SdlError> |
| hint_string, typed event readers | Option<copied value>; ref event polling retains borrowed SDL_Event |
| surface_color_key, app_metadata_string | Result<Option<value>,SdlError> |
| clipped surface intersection | Result<bool,SdlError>; empty intersection is Ok(false) |
| checked GPU support, gpu_poll_readback | Result<bool,SdlError>; false is unsupported/pending |
| native_gpu_swapchain | Result<Option<SdlSwapchainTexture>,SdlError> |
| with_native_gpu_swapchain | Result<Option<T>,SdlError> |
| push_event | acceptance bool: SDL does not distinguish filtering from queue failure |

Value overloads return scalar/vector/struct/array results. Buffer-mutating
operations keep explicit buffers and capacities. The low-level ref/out adapters
are not removed or rewritten. No scene/mesh/material or rendering-plan objects
were introduced.

## Error and cleanup policy

Capture owned operation/message immediately after failure; never use stale
SDL_GetError as a success test. Defer runs on ordinary and early return.
Cleanup failure becomes Err when the body succeeded; otherwise the body error
wins. Secondary cleanup errors are discarded. After acquiring a swapchain texture,
submit is mandatory even on a body error; cancellation is only used before
acquisition or on None. Arbitrary panic still bypasses pinned runtime finally.

## Language findings retained for other sessions

- Void and Result block overloads compete during inference: the void form is gone.
- Explicit nested block types, including var for mutable native GPU handles,
  are needed in some generic cases.
- Prefer binding the scope Result, or checking it with a trailing pipe.
- Arrays move through scopes. Standard ok/some/unwrap may clone noncopyable values;
  nested mutable pointers require move constructors/extraction due const rules.
- SdlUnit carries one padding byte, not an extra success flag. A truly empty
  structure breaks pinned AOT Option<Unit> layout (C++ empty structs have size 1).
- Windows COM THIS/THIS_ macros are isolated in the hit-test fixture before
  standard template/AOT AST imports. Upstream daScript is unchanged.

## Verification and remaining binding work

The main interpreter suite, legacy/CppGenBind/AOT suites and no-LLVM consumer
are required for this breaking migration. Tests include early return and arrays,
error snapshots, stale-error success, absence/empty/zero, body versus cleanup
failure, readback states and swapchain body failure followed by another frame.
Test-only switches exercise deterministic pending/unavailable results; they do
not replace raw GPU execution tests and do not exist in consumer builds.
A real minimized Vulkan window in the pinned local build still returned a
texture; the API therefore preserves both Some and None instead of assuming
minimization guarantees None.

Owned input/window [event variants](event-variants.md) are now available separately.
Other event payloads, further raw P3 coverage, P8 GL/EGL and companion
libraries remain separate binding work. They are not reasons to retain the old
bool/void boost API. See [error handling](error-handling.md) and
[complete contract inventory](boost-contracts.json).

## Local validation — 2026-09-21

Windows x64/MSVC, pinned SDL 3.2.18 and daScript; Vulkan and D3D12.

- Main suite: all 152 selected SDL tests pass after fixes and affected-test reruns.
  The two new GPU array-scope checks initially created a device after SDL_Quit;
  the test now owns a second SDL session. Later example edits were checked separately.
- Legacy/CppGenBind: 240/240, plus 48 affected example reruns after error-path cleanup.
- Strict AOT and remaining parity gates: 197/197 (437 parity tests in total).
- Main generation/inventory/boundary gates: 6/6; standalone clangbind: 4/4.
- BUILD_TESTING=OFF consumer with LLVM, Clang and Python package discovery disabled:
  build, Result example, all 35 boost module imports and public API boundary pass.
  SDLTestResultStates is unavailable in that consumer.
- Documentation links and whitespace checks pass. Production generator configuration
  is restored after the consumer build.

The inventory lists 621 public boost overloads, including pure helpers,
[event variants](event-variants.md) and [GPU Result factories](gpu-factories.md). This is
an API migration, not additional raw SDL declaration coverage. No cross-platform,
JIT or arbitrary-panic cleanup guarantee is implied.

Event list payloads make SdlEvent (and its standard Option/Result) move-only.
Use `<-` and guarded move_unwrap in event loops; copying is explicit via standard
clone helpers. See [event list ownership](event-list-payloads.md). Raw event and
user-pointer ownership is unchanged.
