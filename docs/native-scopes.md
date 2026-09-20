# Lightweight boost scopes

User-requested change: no `try/recover` in SDL boost wrappers. All **33** script
recovery blocks were removed. The public `with_*` signatures and cleanup order
are unchanged. Existing invoke-only exports remain available for compatibility.

Previously a resource scope had two exception boundaries: native
`SDL_InvokeProtected`/`runWithCatch` around the callback, then script
`try/recover` around that invocation. It also stored `failed`, copied/trimmed
the exception through RTTI and separately called the release function.

Now a scope creates its resource and calls one native owner helper in
`src/sdl3_owned_scopes.h`. The shared `SDL_InvokeWithCleanup` in
`src/sdl3_scopes.h` invokes the block with **one** native catch boundary,
restores block arguments, performs cleanup and rethrows the original exception.
No exception strings or RTTI are used on the success path. A cleanup failure
alone reports the SDL error; a simultaneous body failure retains the original
message and adds the cleanup error. Tests deliberately exercise both cases.

This boundary is once per resource block, not once per SDL function call.
Removing it too would leak resources on the pinned interpreter's panic path:
defer/finally is skipped, and its longjmp mode does not unwind C++ destructors.
The remaining boundary reuses the native protection already required to restore
outer block arguments. It is not an additional layer of script exception handling.

Other simplifications:

- Removed unused RTTI and strings_boost imports from boost modules.
- Marked the three small result checks (`check_sdl`, `check_audio`, `pixel_check`)
  inline; ordinary checked wrappers remain direct native calls plus failure checks.
- `load_texture` now loads BMP, creates texture and frees the temporary surface
  in a single native adapter, eliminating a temporary script callback/scope.
- Shared native ownership helpers cover windows, renderer, surfaces, textures,
  WAV/audio streams, SDL lifetime, input session/target restoration, GPU devices,
  window claims and all GPU handle families. No daScript submodule edits.

## Measurement and verification

Release interpreter runner, Windows x64, empty command-plan scopes (no draw or
GPU submission): four runs of 2,000,000 iterations took **259–262 ms before**
and **218–220 ms after**, approximately 16% less elapsed time. This measures
wrapper/ID-map overhead; it is not an FPS result or an AOT performance claim.
Timer granularity, compilation/CPU load and machine state affect timings.

Reproduce the old reference and current implementation in one process:

```powershell
./build/ninja/bin/dasSDL3_runner.exe tools/benchmark_scopes.das --smoke-test
```

The historical `try/recover` reference exists only in this optional benchmark,
not in production boost modules. No timing threshold is part of CTest.

Lifetime regressions cover normal/early return, nested panic/recovery, original
panic messages, partial construction, target/input restoration and CPU/GPU
resource cleanup. Full interpreter/parity/AOT/consumer results are recorded with
the command-plan batch in `gpu-command-plans.md`.
