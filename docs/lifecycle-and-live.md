# Lifecycle, GC and live integration

## Shared desktop/Web lifecycle (2026-09-27)

`dasSDL3_runner` now prefers lifecycle callbacks when an `update` entry exists.
Without `update` it keeps the existing `main(smoke : bool) : int` contract.
Malformed lifecycle callbacks fail before init; they do not silently run main.

| Export | Contract |
| --- | --- |
| `init()` | Optional, void. Called once before the first update. |
| `update()` | Required. bool: false stops; int: zero stops, any nonzero value continues; void: continues until host stop. No arguments. |
| `shutdown()` | Optional, void. Called once after the init attempt, including partial initialization failure, update exception or smoke limit. |
| `exit_code() : int` | Optional SDL runner extension, read after shutdown. Use for a previously reported Result error. Defaults to zero; a host/runtime exception always returns failure even if this function returns zero. |

These update signals follow upstream daScript, NOT SDL AppResult. In particular,
negative `int update` continues. `--smoke-test` limits lifecycle execution to 60
continuing updates. It does not inject a hidden-window flag or frame pacing.
The application owns event handling, pacing and resource lifetime.
Reserve these entry names; there must be one compatible overload per name.
This pilot accepts only void init/shutdown (upstream also accepts other returns).

Run the separate, unnumbered-in-the-main-series pilot:

```powershell
.\build\ninja\bin\dasSDL3_runner.exe examples/lifecycle/01_square.das
.\build\ninja\bin\dasSDL3_runner.exe examples/lifecycle/01_square.das --smoke-test
```

The example has no main loop: resources live in script globals across updates.
Fallible work stays in Result-returning helpers using sdl_try; the example reports
an error once, stops updating and exposes the failure through exit_code.
Shutdown checks which resources were actually acquired and is idempotent.
Ordinary with_*/sdl_scope remains appropriate inside a synchronous operation,
but must not release a resource that a future update still needs.

## GC boundary

The example opts into `options gc` and `options persistent_heap`.
The host calls `Context::collectHeapIfMostlyFree()` AFTER a continuing update
has returned, with no active script frame or temporary borrowed row/array.
Without both options the runtime helper is a no-op. This uses the pinned
upstream thresholds, not a second GC policy or unconditional full collection.
No script closure is retained and no new script-facing protected-call bridge
is introduced. Host exception handling is the runner's existing evaluation boundary.

This boundary also works for native strict AOT: the host performs collection
outside the compiled update stack. AOT does not eliminate heap/string garbage.
Global roots survive collection; GC does not destroy SDL/GPU resources.
After a runtime fault the host attempts a separate shutdown call, but it cannot
promise that abandoned script defer blocks ran or that shutdown itself cannot fail.

Upstream standalone scripts instead call `live/live_gc::maybe_collect_gc()` in
their main loop; it self-disables under live. This pilot does not depend on
live_host: the desktop host provides the boundary directly. Importing live_gc
without registering/linking live_host is not sufficient to integrate live.

## Verification

- `tests/test_lifecycle.py`: lifecycle takes precedence over main, legacy main
  keeps smoke/exit status (including a private helper named update), partial init and update exceptions run shutdown once,
  shutdown errors fail, invalid signatures fail before acquisition, optional
  exit status, negative-int update semantics and the 60-tick void-update limit.
- `tests/lifecycle_gc.das`: temporary 64 KiB arrays each tick, retained global
  array/string roots, heap bounded below 1 MiB; 60 ticks in smoke/AOT and 400 in
  the interpreter. At 400 ticks the observed allocated heap was 65,600 bytes.
- Pilot and GC test pass with baseline/CppGenBind interpreters and strict AOT
  (no interpreter fallback). Existing main-based square and Result tests pass.
- Consumer without LLVM/generators also builds and runs the pilot and GC test;
  developer configuration restored afterwards.

## Web adapter

`web/runner.cpp` uses the same host lifecycle implementation. Exported update
selects this protocol; otherwise the existing app_init/app_frame/app_event/app_quit
protocol remains unchanged. Web has no main fallback. One update runs per SDL
browser iteration; returning to the browser lets it process input and paint.
Stop calls shutdown once; Restart starts a fresh WASM instance. A nonzero exit_code
or runtime/cleanup fault marks the page Failed. Validation happens before init.

SDL_AppEvent consumes events before script polling. Lifecycle scripts can export
`app_event(event : SDL_Event) : int` for synchronous borrowed event access:
negative = failure, zero = continue, positive = successful exit (legacy Web
convention, NOT the update convention). Without it the host handles SDL_EVENT_QUIT
and ignores other events. Never retain the borrowed event or requeue it. The
shared square handles Escape in app_event on Web and via polling on desktop.

The page `09_lifecycle.html` packages the exact source from
`examples/lifecycle/01_square.das`, without a second Web copy. Both host protocols
collect at the continuing-frame boundary; GC still requires gc+persistent_heap.

`tests/web/test_lifecycle.py` checks actual canvas pixels, Escape, Stop/Restart,
partial initialization, update/shutdown/event faults, invalid callbacks,
exit_code, negative-int continuation, void update with host Stop and the same
400-frame GC/global-root fixture. Run with --browser edge or --browser firefox
against the built site's local HTTP server. Existing Renderer/audio and OpenGL
browser suites remain regression checks. On 2026-09-27 all 13 lifecycle scenarios
and the existing 15 Renderer/audio + 6 OpenGL scenarios passed in both Edge and
Firefox (68 browser scenarios total).

This general browser runner interprets daScript inside WASM. A separate standalone
pilot now compiles the same square to wasm32 AOT; see below. Web live reload remains
unverified. Native live integration has a separate pilot described below. After the entry-module callback fix, all 14 lifecycle scenarios were
rerun successfully in each browser (28 checks); the earlier Renderer/OpenGL
results above are from the preceding stage.

## Standalone wasm32 AOT

[web/standalone](../web/standalone/README.md) builds the exact same square source
with the pinned standalone emitter running as wasm32 under SDK Node. The resulting
browser module links runtime-only libraries, with no compiler, parser or binding
module factories. Map checks and a negative no_aot fixture guard that boundary.
The host calls generated C++ methods and collects between updates; GC/root tests
include live SDL window/renderer globals. No generated-code workaround or patched
dependency was needed.

The pilot supports the square's void init/shutdown, bool update and optional
app_event/exit_code. It is not a universal dynamic lifecycle loader. Both Edge
and Firefox passed nine standalone scenarios each (pixels, input, Stop/Restart,
GC, partial acquisition, callback exceptions and exit status). Build/run/test
commands and limitations are in its README.

## Next stages

1. **Web lifecycle adapter — implemented.** Shared host lifecycle, explicit event
   delivery and legacy app_* compatibility; browser verification described above.
2. **Standalone wasm32 AOT pilot — implemented.** Same square source, target-native
   generation, runtime-only link and Edge/Firefox verification. See above.
3. **Current dasImgui SDL backend — v2 widget pilot implemented.**
   `sdl3_imgui_widgets` connects upstream widgets to the existing native SDL3 /
   SDLRenderer3 backends. A lifecycle example and pixel/synthetic-input/local
   command tests are included. See [audit and remaining work](imgui-widgets-and-live.md).
   Physical DPI/IME validation and a pure-daScript backend remain separate work.
4. **daslang-live — native pilot implemented.** The unmodified upstream host
   loads dynamic SDL bindings; [live example](../examples/live/README.md) retains
   its native resource bundle across reload. Real-process tests cover preserved
   @live values, failed compilation and recovery, synthetic input, full reload
   and exactly-once final cleanup. Its callbacks are void (unlike the desktop /
   Web bool-update protocol above). Runtime-exception recovery remains unverified.
5. **Diagnostics and MCP.** Check upstream imgui_live/commands/harness integration
   using an actual SDL tool: enumerate UI, synthesize input, read errors and
   inspect results. Do not assume the existing GLFW harness works unchanged.
6. **Automation.** Add deterministic GUI actions/recording and browser checks
   through the available upstream interfaces. Verify actual rendered results.
7. **daspkg.** Define supported install/build profiles, package dependencies and
   a fresh consumer example; publication remains a separate explicit step.

Keep existing example numbers and tests. Port further interactive examples only
after the desktop/Web/AOT lifecycle agrees; short one-shot API tests may keep main.

Lifecycle entry discovery only considers exported functions in the entry module.
Imported update/shutdown helpers cannot replace application callbacks. Desktop
regression fixtures cover both legacy main and lifecycle programs with imports.

## SDL widget pilot verification (2026-09-27)

- Main build: eight ImGui/lifecycle CTests passed (including native input,
  lifetimes, actual widget pixels, local commands and the lifecycle example).
- Reference backend, CppGenBind and strict AOT: all 12 ImGui tests passed.
  AOT uses fail_on_no_aot and checks the lifecycle callbacks; no interpreter
  fallback is accepted. The generator enables RTTI for the imported live macros.
  A local declarations-only imgui_aot_compat.h supplies exports missing from the
  pinned upstream AOT header; dependency sources remain unchanged.
- Consumer without LLVM: rebuilt the core runner and passed all 13 lifecycle
  fixtures. This is a core-profile check, not an ImGui SDK distribution claim.
- Web host rebuilt: 14 lifecycle scenarios passed in both Edge and Firefox.
- Official daScript formatter verification and record-field audit passed.

The new ImGui example is desktop-only. The native live host and reload protocol
now have a separate tested pilot, described below; HTTP/MCP integration remains a next stage.

## Native live integration

See [SDL live pilot](../examples/live/README.md) for build/run commands and
`tests/test_live_widgets.py` for real-process JSON-RPC checks. SDL resource
ownership is in the example harness, outside reloadable script memory. Seven
stages passed: startup/telemetry, incremental reload, failed compilation,
recovery, synthetic click, full reload and final cleanup after failed compilation.
No daScript dependency source was patched. HTTP/MCP, automatic file watching,
Web live support and runtime-fault recovery are not claimed by these checks.

The final main-build CTest run passed all six ImGui/live tests. The existing
non-reloading ImGui suite also passed its 12 reference/CppGenBind/strict-AOT
checks again. The pinned upstream stdio agent reports one Channel/JobStatus and
Feature leak at process exit; SDL resource cleanup is verified independently.
The upstream MCP adapter uses HTTP, so its next prerequisite is live_api/dasHV,
not merely the already-tested stdio command transport.
