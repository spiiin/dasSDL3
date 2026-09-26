# Hints and initialization

SDL 3.4.16: Hints has 8/8 generated functions; Init has 10/10.
SDL_AddHintCallback, SDL_RemoveHintCallback and SDL_RunOnMainThread accept
native C addresses, not script blocks. See [native callback contracts](native-callbacks.md).
SDL hint callbacks can run on the setter thread, under SDL locks.
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

SDL_HintPriority and all eight initialization flags are generated. String hint/property macro
constants are exported from the pinned headers; see [the accessibility audit](script-accessibility.md).
Literal strings remain valid for dynamic/custom names. No with_hint restoration
scope: SDL cannot query the previous priority. ResetHint resets to the environment,
not the previous explicit setting; ResetHints changes all hints in this process.
Environment values take override priority. A rejected lower-priority setter returns
false. ResetHint returns false when no hint record exists.

Example: [52_init_hints.das](../examples/52_init_hints.das).
Tests: [init_hints.das](../tests/init_hints.das), including all 12 newly generated
functions, priority rejection, copied UTF-8, metadata removal, nested references,
early return and partial rollback with an intentionally unavailable audio driver.
No physical audio device is used.
