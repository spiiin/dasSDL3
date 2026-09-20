# Hints and initialization

Pinned SDL 3.2.18: Hints has 6 generated functions of 8; Init has 9 of 10.
The three pending functions are SDL_AddHintCallback, SDL_RemoveHintCallback and
SDL_RunOnMainThread. Retained callbacks require rooting, thread affinity and
shutdown rules. SDL hint callbacks can run on the setter thread, under SDL locks.
Startup AppInit/Iterate/Event/Quit host integration is separate.

`dassdl3/sdl3_init_boost.das` provides with_sdl_subsystems(flags), hint_string(name)
and app_metadata_string(name). The subsystem scope balances one successful
InitSubSystem with QuitSubSystem using defer, including ordinary early return.
Nested acquisition preserves earlier references. Failure skips the block; SDL
rolls back partial acquisition. The block must not consume its scope's reference
with Quit/QuitSubSystem. Prefer an outer with_sdl for global shutdown. Panic cleanup
is not guaranteed by the pinned daScript runtime.

Raw getters borrow SDL storage. Copy getters preserve null and allocate daScript
strings, which survive subsequent changes. Callers must serialize concurrent
writers with the entire lookup/copy operation: copying does not make lookup atomic.
SDL_ClearAppMetadataProperty passes native NULL, preserving the difference from an
empty string. Metadata should be set before initializing subsystems.

SDL_HintPriority and all eight initialization flags are generated. String macro
constants are not exported yet; pass SDL hint names (such as SDL_AUDIO_DRIVER) and
metadata keys (such as SDL.app.metadata.name) literally. No with_hint restoration
scope: SDL cannot query the previous priority. ResetHint resets to the environment,
not the previous explicit setting; ResetHints changes all hints in this process.
Environment values take override priority. A rejected lower-priority setter returns
false. ResetHint returns false when no hint record exists.

Example: [52_init_hints.das](../examples/52_init_hints.das).
Tests: [init_hints.das](../tests/init_hints.das), including all 12 newly generated
functions, priority rejection, copied UTF-8, metadata removal, nested references,
early return and partial rollback with an intentionally unavailable audio driver.
No physical audio device is used.

## Local validation (Windows x64/MSVC, 2026-09-20)

- Main regression suite: 120/120.
- Package interpreter (baseline and CppGenBind), AOT and metadata parity: 7/7.
- Generation/freshness/inventory/boundary gates: 6/6; standalone clangbind: 4/4.
- Consumer configured without LLVM/Clang/Python discovery: build, example 52,
  init_hints test and public API boundary check passed.
- Documentation links and diff whitespace checks passed.

The entire GPU parity runtime suite was not rerun for this package; the full AOT
runner was rebuilt, and the new package plus metadata were executed.
