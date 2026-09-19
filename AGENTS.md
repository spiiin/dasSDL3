# dasSDL3 project guide

Read `docs/bgfx-idioms.md` before designing or changing the daScript-facing API.
It records inspected dasBGFX/daScript revisions, source links, idioms and their
ownership limitations. Read `docs/sdl3-boost.md` for this project's API decisions
and verified behavior. Keep both documents current when behavior changes.
Track implemented scenarios and remaining subsystems in `docs/api-coverage.md`.
Audio contracts and testing limitations are in `docs/audio.md`.

- Keep generated bindings in `src/generated/`; change `tools/bindings.json` or
  `tools/generate_bindings.py`, then regenerate. Never hand-edit generated files.
- Put script helpers in `dassdl3/sdl3_boost.das` and native adapters in
  `src/sdl3_adapters.h`. Keep the raw `sdl3` module available.
- Keep `examples/square.das` free of unsafe blocks and raw address operations.
  Use value/reference helpers and scoped cleanup. Do not weaken pointer checks
  to make code compile. Hidden unsafe operations are not an ownership guarantee.
- Prefer with_sdl/with_window/with_renderer for ownership scopes. In the pinned
  interpreter, panic skips defer/finally (verified); these helpers catch locally,
  clean up, then propagate the error. Do not replace them with defer-only cleanup.
  Verify renderer -> window -> SDL_Quit order on return, panic and partial init.
- Resource blocks invoke callbacks through `src/sdl3_scopes.h`. It restores
  interpreter block arguments after panic; plain invoke can corrupt an outer
  block's arguments when it catches a nested failure. Keep the nested-recovery
  regression in tests/textures.das and recheck this workaround on daScript updates.
- Texture scopes must end before their renderer. Surface-to-texture creation
  copies pixels and does not transfer surface ownership. Keep SDL_Surface and
  SDL_Texture opaque until a separately reviewed pixel-buffer API is available.
- Prefer renderer-first functions for pipe syntax. State component ranges,
  null behavior, error policy, and whether data is borrowed or copied.
- Input adapters live in `src/sdl3_input.h`. Read the event tag before its
  union member; clear outputs on a mismatch. Copy UTF-8 text into the daScript
  heap before the next SDL poll/pump. A copied raw SDL_Event does not own text.
- Scalar output parameters in daScript require explicit references:
  `var text : string&`, `var start : int&`, `var position : float2&`.
  `var` alone makes a mutable value parameter; managed structs are different.
- `with_text_input` preserves an existing session; only the scope that started
  it stops it. Keep polling, input state queries and window operations on the
  main thread. Synthetic PushEvent input does not update keyboard/mouse state.
- Audio helpers live in `dassdl3/sdl3_audio_boost.das` and `src/sdl3_audio.h`.
  WAV buffers belong to opaque SDL_Wav objects and use SDL_free. Audio stream
  queues copy data; array adapters must handle empty arrays and reject sizes
  above INT_MAX before casting. Never retain script array pointers or invoke
  script blocks from SDL's audio thread. Destroy device streams before SDL_Quit.
  Tests use SDL_AUDIO_DRIVER=dummy only in their process environment; do not
  change the user's normal backend or claim audible output was verified.
- Prefer implicit trailing blocks in gen2 code: `with_sdl() { ... }` for a
  zero-argument block and `with_window(...) $(window) { ... }` for a block
  with arguments. Omit `<|`; omit `$()` only for a zero-argument block.
  This also works with pipes: `window |> with_renderer() $(renderer) { ... }`.
  Verified by the example and boost lifetime tests on the pinned interpreter.
- daScript is a pinned submodule. Avoid editing its source to fix our bindings.
- Build instructions are in README.md. On this machine Ninja with vcvars64 works;
  MSBuild's SDK scan previously hit sandbox permissions. Build with 6 parallel
  jobs. Run the project's CTest filter rather than all upstream tests.
- Do not commit or publish unless asked. Preserve unrelated user changes.
