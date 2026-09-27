# Proposed upstream: configurable recording port

`imgui-recording-port.patch` targets the pinned daScript file
`modules/dasImgui/widgets/imgui_playwright.das`. It has not been applied to
third_party/daScript, committed, published, or submitted as a PR.

Problem: with_recording_app always attaches to port 9090 and its spawn branch
does not forward a selected port. This prevents recording an existing SDL app
on another port.

The patch adds a full-form overload with `port : int` before the trailing block.
The previous overload delegates with DEFAULT_LIVE_PORT, preserving existing
call sites. The supplied port is range-checked before side effects, used in the
loopback URL, and forwarded as --live-port to the spawned host.

```daslang
with_recording_app(feature, "demo.apng", 20, 20,
                   modules, feature_root, asset_root, 9091) $(app) {
    // upstream actions
}
```

Validation in dasSDL3:

```powershell
ctest --test-dir build/live-http -R '^sdl3_live_recording(_port)?$' --output-on-failure
```

The port test copies the original module into build/live-recording-port/upstream,
applies the actual patch with git apply, and imports a temporary local copy in
the driver. It allocates a free port, records real SDL drag/click through upstream
with_recording_app, and verifies APNG CRC/frame count/timing and cleanup.
The spawn argument change is reviewed in source; spawning the upstream GLFW
recording host is not covered by this SDL attach test.

Normal examples still use the pinned upstream API on 9090. Adopting the new API
in the ordinary driver should follow an upstream update; the patch/test copy is
a reviewable proposal, not a silently patched dependency.


## Proposed upstream: backend-independent visual aids

`imgui-visual-aids-backend.patch` replaces the visual-aids import of
imgui/imgui_live (GLFW/OpenGL lifecycle) with imgui/imgui_live_core (synthetic input).
The visual aids themselves use ImGui foreground drawlists and widget runtime
hooks; they do not require the GLFW lifecycle. No drawing implementation changes.

The SDL test applies both proposed patches only to disposable module copies and
removes the local software-cursor fallback from that temporary application to
avoid duplicate imgui_cursor_sprite commands. The regular examples/dependency
remain unchanged. Existing GLFW applications should import their host/harness
explicitly rather than relying on this incidental transitive import; a GLFW
regression run is still needed before upstream merge.

```powershell
ctest --test-dir build/live-http -R '^sdl3_live_visual_aids$' --output-on-failure
```

Verified with the real upstream recording driver: slider drag, click, highlight,
magenta mouse trail, cursor sprite and narration callout. Commands must return
ok; decoded APNG frames must contain yellow/magenta overlay pixels. The final
PNG was also visually inspected for caption text and placement. APNG integrity,
frame timing, cap/reload finalization and exactly-once SDL cleanup still run.
Keyboard HUD, docking/multiple viewports and physical DPI variants are not covered.

Artifacts are in build/live-visual-aids: first.png, last.png, app.log, driver.log,
and doc/source/_static/tutorials/sdl-widgets.apng. This is a tested proposal, not
an installed dependency update or a published PR.
