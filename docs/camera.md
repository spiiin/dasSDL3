# Camera

All 15 SDL 3.2.18 Camera functions have raw generated signatures, together with
SDL_Camera, SDL_CameraSpec (all six fields), SDL_CameraPosition and uint camera IDs.
Require `dassdl3/sdl3_camera_boost` for thin Result/Option helpers.

## Discovery, permission and format

`cameras()` and `camera_supported_formats(id)` return Result of owned arrays.
Both accept an empty successful list. Supported formats are copied by value from
SDL's single allocated pointer table; only the outer allocation is freed.
Names are copied immediately. Driver getters return Option<string>; no driver is
normal before subsystem initialization. `camera_position` preserves UNKNOWN,
which can also mean an invalid ID. It is not a validity check.

`open_camera(id[, spec])` returns Result<SDL_Camera?>; `with_camera` closes on
normal/early return including body Err, and supports move-only Result values.
Opening does not imply permission has been granted. `camera_permission_state`
preserves -1 denied, 0 pending, 1 approved (live camera required; raw NULL also
returns -1). Permission may remain pending indefinitely. Format queries return
Err while permission is pending; poll permission or process events first.
The requested format can involve SDL conversion/scaling. Frame rate is chosen by
the backend, not emulated. Properties are borrowed from the camera, not owned.

## Frames

`acquire_camera_frame` returns Result<Option<CameraFrame>>. CameraFrame is a small
borrowed surface/timestamp pair, not an owner or a pointer-liveness registry.
None means permission is pending or no new frame is available. Err is copied
before cleanup. The native adapter checks pending permission, then clears the
calling thread's SDL error before the ambiguous-null acquire operation and checks
the error only when SDL returns NULL. Successful frames ignore a stale error.
This is deliberately limited to this API, not the general Result conversion rule.
SDL 3.2.18 sets an error for permission <= 0 although the header describes pending
permission as no frame; the explicit pending check preserves the normal state.
Do not close the camera concurrently; all pointers must remain live.

`with_camera_frame(camera) $(frame) { ... }` returns Result<Option<T>> from a body
returning Result<T>. Give the block an explicit `$(frame : CameraFrame)` type
if its return type depends on frame fields and inference needs it. None skips the body; deferred release runs on success and
body Err. Do not return the borrowed frame/surface/pixel pointer from the block.
Manual acquisition requires exactly one `release_camera_frame(camera, frame)`
with the same camera before closing it. The helper clears that alias, not copies.
Never call SDL_DestroySurface on a camera frame. Copy the surface explicitly if it
must outlive the borrow. Release promptly to avoid starving the small frame queue.
Arbitrary application panic can bypass pinned daScript defer; no panic safety is
promised. Raw functions keep their original SDL sentinel/ownership behavior.

## Example and validation limits

[80_camera.das](../examples/80_camera.das) enumerates devices, and in a normal run
opens the first camera and waits up to five seconds for one frame. It prints
metadata only, does not save images, and uses sdl_scope/sdl_use and deferred frame
release. Smoke mode does not open a camera. CTests force SDL_CAMERA_DRIVER=dummy.

[Tests](../tests/camera.das) execute all 15 raw functions: available driver queries,
empty successful dummy discovery and invalid/null device paths for device/frame
operations. They verify copied error preservation, stale-error success, failed
acquisition skipping scope bodies, and instantiate unit/scalar/array scope results.
The pinned dummy backend advertises no cameras; it cannot produce synthetic frames.
Consequently successful camera opening, nonempty format copying, permission
transitions, None/frame outcomes on a live camera, timestamp values and actual
release/close order still require hardware validation. No fake private SDL camera
struct or claim of successful frame execution is used. Camera-specific owned event
variants remain a follow-up; raw event constants already exist.

Sources: pinned `SDL_camera.h`, `src/camera/SDL_camera.c` and dummy backend;
[SDL frame contract](https://wiki.libsdl.org/SDL3/SDL_AcquireCameraFrame).

Local validation: both main Camera tests, baseline/CppGenBind test and example,
metadata parity and both strict AOT tests passed (no interpreter fallback).
Generation/inventory/boundary gates and standalone clangbind checks passed.
The no-LLVM/no-generators consumer built and ran example 80 with dummy discovery;
removed framework names remain unavailable. These checks do not cover live frames.
