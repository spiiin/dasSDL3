# dasImgui v2 on SDL3

The optional libraries runner now supports upstream v2 widgets with the existing
native `imgui_impl_sdl3` and `imgui_impl_sdlrenderer3` backends. Require
`dassdl3/sdl3_imgui_widgets`; the module adds frame ordering and event routing,
not a new UI framework or resource owner.

Run from the repository root:

```powershell
.\build\ninja\bin\dasSDL3_libraries_runner.exe examples/lifecycle/02_imgui_widgets.das
```

The example exports init/update/shutdown/exit_code. It needs the desktop ImGui
build profile; it is not currently included in the Web binding or standalone
wasm32 pilot. Existing example numbers are unchanged.

## Frame and ownership contract

Create the SDL window, renderer, ImGui context and SDL backends before using the
helpers. `with_imgui` remains available for block-scoped applications. The
lifecycle example owns these resources explicitly and releases initialized
backends before the context, renderer and window, including partial startup.

1. Feed polled events through `imgui_widgets_process_event`. When upstream
   synthetic control disables user input, keyboard/mouse events are withheld
   from ImGui; lifecycle/window events still reach the backend. Applications
   decide whether their own shortcuts should also be gated.
2. `imgui_widgets_new_frame` calls begin_frame, the SDL backend NewFrame functions,
   advance_coroutines, imgui_synth_tick and ImGui NewFrame in that order.
3. Build the UI with upstream window/button/slider/checkbox macros.
4. Clear the SDL renderer, call `imgui_widgets_render`, then present. The helper
   runs end_of_frame hooks, ImGui Render and SDL drawing.

These helpers assume an initialized current context and one widget registry per
script. They do not provide concurrent independent v2 contexts. SDL thread,
renderer and context ownership requirements still apply.

## Audit of the pinned upstream implementation

Upstream imgui_harness and imgui_live use GLFW/OpenGL. The latter preserves GL
renderer objects and an ImGui context across reloads. Importing that harness into
an SDL application would also import its backend and lifecycle assumptions.

The widget runtime is backend-independent and uses live_host, live_vars and
live_commands. The libraries runner registers LiveHost and resolves imgui/live
module roots. This enables local telemetry and command dispatch; it does not
start an HTTP/MCP endpoint or implement hot reload.

The existing native SDL renderer source handles clip rectangles, framebuffer
scale, vertex/index offsets, dynamic font/texture updates, and restoration of
renderer state. The platform source handles clipboard, cursors, keyboard/text,
IME and mouse capture. Reading those implementations is not physical-device,
DPI, IME or cross-platform validation. A pure-daScript renderer can be investigated
later, but replacing the working native backend is not required for v2 widgets.

## Verification

`tests/imgui_widgets.das` checks actual software-rendered pixels, a synthetic
mouse click, widget paths in imgui_snapshot, slider changes through imgui_force_set,
input gating and final context cleanup. Existing native SDL input and lifetime
tests remain separate. The new lifecycle example also has a bounded host smoke
run. All 12 reference/CppGenBind/strict-AOT ImGui checks passed. The AOT test target
force-includes `src/libraries/imgui_aot_compat.h`, which only declares existing
upstream functions missing from its AOT header. Further verification status is
recorded in [lifecycle-and-live.md](lifecycle-and-live.md).

## Native live pilot

[examples/live](../examples/live/README.md) now builds the unmodified upstream
host source and dynamically registers SDL/SDL-ImGui. Its small application-only
native owner retains the window, renderer and ImGui context across script
replacement. These are not serialized pointers and no script closure is retained.
The public boost layer keeps its existing ownership contracts.

The real-process JSON-RPC test passed incremental reload with retained widget and
application state, invalid compilation with a paused old context, recovery,
synthetic input after reload without duplicate action, full reload with reset
@live values, and final shutdown after another compile failure. The native bundle
was acquired once and released exactly once. Example formatting is verified.
The upstream stdio reader-agent still reports one leaked Channel/JobStatus and
Feature at exit; see the pilot README. This is not a zero-leak transport claim.

The pilot uses the upstream stdio transport; no HTTP server or MCP endpoint has
been added. The dynamic host interprets new scripts. Existing strict AOT widget
checks apply to the non-reloading host, not to this pilot.

## Remaining live integration

- Connect the upstream MCP adapter and, if needed, HTTP transport to the SDL
  pilot; verify actual MCP discovery, commands and diagnostics end to end.
- Add automatic file-watching/recording workflows. The current example has an
  explicit Reload button and accepts the reload JSON-RPC command.
- Exercise runtime exceptions, reset, resource-configuration changes and
  cross-platform behavior beyond the tested compile-failure recovery path.
- Decide whether the application-specific native owner should remain a demo or
  become a documented reusable host pattern. It is not part of public SDL API.
