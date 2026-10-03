# SDL widgets in daslang-live

This macOS and Windows/MSVC pilot builds the unmodified upstream daslang-live source
as `dasSDL3_live` (`dasSDL3_live.exe` on Windows) and loads the SDL/ImGui bindings dynamically. It is separate
from the ordinary desktop and Web lifecycle hosts.


## macOS build and run

From the repository root, with Apple Command Line Tools, CMake, Ninja and Python 3:

```sh
cmake -S . -B build/macos-live -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DDASSDL3_WITH_IMGUI=ON -DDASSDL3_WITH_LIVE=ON
cmake --build build/macos-live --target dasSDL3_live daslang --parallel 6
cmake -S src/live/http -B build/macos-live-http -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build/macos-live-http --parallel 6
./build/macos-live/live/dasSDL3_live -dasroot third_party/daScript \
  -load_module build/macos-live/live/module -load_module build/macos-live-http/dasHV \
  -no-module-cache examples/live/02_widgets_http.das --live-port 9090
```

Run from a normal Terminal in a GUI login session. The host links Foundation for
upstream NoAppNap and loads native `.shared_module` libraries with the saved Mac
binding snapshot. The dynamic daScript SDK and modules must come from the same
build profile. Configure/build SDK profiles sequentially: the pinned SDK writes
shared configuration, libraries and executables into its source tree.

For one-command APNG recording, close the demo on port 9090 and run:

```sh
python3 tools/record_live.py
python3 tools/record_live.py --output "build/my recording"
```

The Python launcher selects Mac build paths and verifies the owning process's
loopback listener with macOS `lsof`. Custom builds can pass `--host`, `--module`,
`--http-module`, `--stb-module` and `--daslang`. No extra Python packages are needed.

```sh
ctest --test-dir build/macos-live -R '^sdl3_live_widgets$' --output-on-failure
ctest --test-dir build/macos-live-http -R '^sdl3_live_' --output-on-failure
```

These checks cover stdio reload, HTTP/MCP commands, file watching, error recovery,
GUI pixel changes, the upstream playwright driver and APNG finalization. The
`recording_port` and `visual_aids` checks use disposable copies with the proposed
upstream changes described below; normal recording uses the pinned SDK unchanged.
`SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy` permits headless checks, but does not
verify native Cocoa rendering. Audio is not part of this live pilot.

## One-command recording (Windows)

After building the native live host and live-http/STB profile, run from the
repository root in cmd.exe or PowerShell:

```powershell
.\examples\live\record.cmd
```

The launcher starts example 03, waits for its own loopback listener and rendered
frames, runs the upstream recording scenario, validates finalization/frame count,
and closes only the host it started. It prints the APNG and log paths. Outputs
are stored under a new timestamped `build/recordings` directory. Python 3 must be
available as `python`; no extra Python packages are required.

Choose a new or empty destination (paths with spaces are supported):

```powershell
.\examples\live\record.cmd --output "C:\src\dasSDL3\build\my recording"
```

Port 9090 must be free with the pinned upstream driver. An occupied/unavailable
port, missing build files or nonempty destination produces an error without
attaching to another app or overwriting recordings. Your example on 9091 may
remain open. The launcher does not apply proposed upstream patches, so it uses
the standard software cursor, not the experimental visual-aids test copy.

On driver failure/timeout, it attempts record_stop and shutdown for its own host;
if graceful shutdown times out, it terminates that process and reports it. Forced
termination cannot guarantee a finalized APNG. Inspect app.log and driver.log in
the destination on failure. It never modifies dependency sources or commits files.

## Build and run

Configure your existing dependency-ready Ninja build with
`-DDASSDL3_WITH_IMGUI=ON -DDASSDL3_WITH_LIVE=ON`, then, from a VS developer shell:

```powershell
cmake --build build/ninja --target dasSDL3_live --parallel 6
.\build\ninja\live\dasSDL3_live.exe -dasroot third_party/daScript -load_module build/ninja/live/module -no-module-cache examples/live/01_widgets.das
```

Save the script to reload automatically. Both examples import upstream
`live/live_watch_boost`; **Reload script** remains available for a manual reload. `init`, `update`
and `shutdown` are void callbacks for this host; `request_exit()` stops it.
Do not substitute the bool-update contract of dasSDL3_runner here.

The native `host.cpp` belongs to this example, not to the public boost API.
It owns one SDL window, renderer and ImGui context outside reloadable script
memory. `demo_open` reuses them on reload, `demo_close` releases them at final
shutdown, and module teardown supplies a final cleanup guard. Script pointers
are borrowed and must never be manually destroyed by the example. There are no
serialized raw pointers or retained script closures in this harness.

Upstream `@live` restores widget/app values on incremental reload. Full reload
resets those values while retaining the native resources. A compilation error
pauses the previous context; repair and save the source to trigger another reload.
Window/renderer changes require restarting the host in this pilot.

## Transport and tests

The example imports upstream `live/live_api_stdio`. Send one JSON-RPC request per
line to stdin; response lines appear on stdout alongside upstream startup logs:

```json
{"jsonrpc":"2.0","id":1,"method":"imgui_snapshot","params":{}}
{"jsonrpc":"2.0","id":2,"method":"reload","params":{}}
{"jsonrpc":"2.0","id":3,"method":"last_error","params":{}}
{"jsonrpc":"2.0","id":4,"method":"shutdown","params":{}}
```

A controlling client must close stdin after shutdown so the upstream blocking
reader thread can exit. This transport is JSON-RPC live commands, not an MCP
server. For the tested upstream MCP adapter, use the HTTP example below.

```powershell
python tests/test_live_widgets.py --host build/ninja/live/dasSDL3_live.exe --module build/ninja/live/module
```

The test modifies a temporary copy, not the checked-in example. It checks real
process round trips, widget telemetry, state preservation, compilation failure
and recovery, synthetic input after reload, full reload and final resource release.
This live pilot interprets the replacement scripts. Strict AOT remains covered
by the separate non-reloading widget tests; dynamic reload is not an AOT claim.

## Known upstream shutdown diagnostic

The pinned `live_api_stdio` agent reports one leaked Channel/JobStatus (and its
Feature) on process exit, even with stdin closed and the reader finished. Its
raw `inbox : Channel?` has no release in the agent class. The SDL bundle is
separately verified as released exactly once; this is not a zero-leak claim for
the upstream transport. Dependency sources have not been patched. Resolve this
upstream or select another transport before calling the stdio pilot production-ready.

## HTTP and upstream MCP

`02_widgets_http.das` uses the same native owner and widgets with an application-local
HTTP agent. It binds only to `127.0.0.1`; it does not import the upstream agent
that starts a listener on all interfaces. The agent is cleaned up on uninstall.

Build the separate Windows/MSVC HTTP profile from a VS developer shell:

```powershell
cmake -S src/live/http -B build/live-http -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build/live-http --parallel 6
.\build\ninja\live\dasSDL3_live.exe -dasroot third_party/daScript -load_module build/ninja/live/module -load_module build/live-http/dasHV -no-module-cache examples/live/02_widgets_http.das --live-port 9090
```

This requires the native live build above and existing daScript dynamic import
libraries. CMake downloads the same pinned libhv archive as upstream dasHV and
checks its SHA256. It compiles unmodified dasHV sources without TLS support;
this profile is for local HTTP. It does not reconfigure the main daScript build.

Configure an MCP client to launch `examples/live/mcp.cmd` through `cmd /c`.
The launcher runs the unmodified upstream `utils/mcp/main.das` over stdio.
Start the SDL example separately. Pass `port: "9090"` to the live tools:
`live_status`, `live_error`, `live_reload`, `live_command`, `live_commands`
and `live_shutdown`. `live_command` accepts a command name and JSON-string
`args`; for example `imgui_snapshot` with `args: "{}"`. The launcher does not
register itself with a client. Other tool families advertised by upstream MCP
have not been validated by this pilot.

```powershell
ctest --test-dir build/live-http -R sdl3_live_mcp --output-on-failure
```

The test runs the real upstream MCP server and a temporary SDL script. It checks
MCP initialization/discovery, loopback binding, snapshots, slider changes,
synthetic clicks, batch error isolation, reload/state preservation, compilation
diagnostics with HTTP 503, recovery and exactly-once SDL cleanup. The HTTP
transport exits without reported handle leaks; the stdio-agent diagnostic above
applies only to example 01. This is a native interpreted live profile, not Web
live or dynamically reloaded AOT support.


## Runtime-fault verification

The HTTP/MCP regression also injects a panic into temporary script copies:
`init` after native acquisition during reload, and `update` before starting an
ImGui frame. Both faults pause execution and expose the original marker through
`live_error`; ordinary commands are rejected. Repair and reload resume advancing
ticks and widget snapshots without acquiring another SDL bundle. Final shutdown
releases that bundle exactly once, with no reported transport handle leaks.

Initial-launch init failure, shutdown failure and native crashes remain outside
these checks. Open-frame recovery is described below. Persistent values
are not guaranteed after runtime faults: the upstream host may clear its live
store on exception. The test checks resumed execution and resource ownership,
not transactional rollback of application state. Dependency sources are unchanged.


## Interrupted ImGui frames

Both live examples track whether NewFrame has started and Render has completed.
Their shutdown callback discards an unfinished frame before reload or final close,
using the application-local `examples/live/frame_recovery.das` helper. EndFrame
invokes the pinned ImGui recovery for unmatched window/ID/style stacks. Recoverable
asserts are disabled only during this teardown, logging stays enabled, and all
four recovery settings are restored afterwards. No failed frame is presented.

Recovery is best-effort, not arbitrary native-crash handling or rollback of script
state. Normal frame assertions remain enabled according to the original settings.
The public SDL/ImGui boost layer and dependency sources are unchanged.

Validation: `sdl3_live_mcp` passed faults inside a v2 window and inside a raw
window with an unmatched PushStyleVar. Both interrupted frames were explicitly
discarded; subsequent ticks, widget snapshots, style alpha and recovery-assert
settings were checked. Final SDL release remained exactly once. The existing
`sdl3_live_widgets` stdio regression and official formatter verification also passed.
The raw API lint escape exists only in the temporary fault-injection script.


## Automatic reload

The upstream watcher polls the entry script and imported script paths supplied
by the host about every 0.5 seconds. It compares modification time and size;
compilation adds its own latency. It keeps ticking while the application is
paused after a compile/runtime error. The MCP command `cmd_watch_status` reports
the watched paths and agent presence through `live_command`.

For an already running old example, click Reload once (or restart) to import the
watcher. Later saves trigger reload without a button or MCP reload request.
Incremental reload preserves @live values and native SDL resources; runtime-fault
recovery retains the limitations documented above.

This is upstream stat polling, not a content-hash watcher or a debounced save
transaction. Equal-size edits with unchanged timestamps may be missed; file
deletion is not detected directly. The pinned watcher refreshes its cached path
list only when the number of watched files changes, so replacement of an import
with another path at the same count requires a host restart. Binary assets and
native C++ changes are not automatically rebuilt. Dependency sources are unmodified.

```powershell
ctest --test-dir build/live-http -R sdl3_live_watch --output-on-failure
```

The watch test uses temporary files and does not send reload commands. The
separate `sdl3_live_mcp` and stdio tests disable the watcher in their temporary
copies to keep explicit-reload behavior independently covered.


## End-to-end GUI scenario

```powershell
ctest --test-dir build/live-http -R '^sdl3_live_gui$' --output-on-failure
```

This scenario launches a temporary copy with the software SDL renderer, drives
it through the actual upstream MCP server, changes MAIN/SPEED to 0.75 through
imgui_force_set, clicks MAIN/INCREMENT through synthetic input, and saves a script
change to trigger automatic reload. It checks one click, retained slider state,
a changed slider image after the action, an identical slider image after reload,
and changed pixels plus telemetry for a new text label. Imported-file reload,
compile/runtime fault recovery and final resource cleanup are also exercised.

The test-only `tests/live_gui_capture.das` queues a readback for the next rendered
frame before present. It uses with_read_pixels and SDL_SaveBMP, releases the
surface, and acknowledges completion before Python reads the file. The Python
standard library converts the verified 24/32-bit BMP layout to PNG; no Pillow or
additional renderer is required. The normal examples do not enable capture or
add its test commands.

Artifacts: `build/live-gui/01-before.png`, `02-after-actions.png`, and
`03-after-reload.png`; transport logs: `build/live-mcp-gui-app.log` and
`build/live-mcp-gui-mcp.log`. Images are compared within this run, not against a
machine-specific full-screen golden image. The comparison uses the widget's
reported slider bounds. This is a repeatable scripted scenario and three still
captures, not continuous APNG/video recording or playback of recorded user input.
Upstream imgui_playwright/recording integration remains a separate step.


## Upstream imgui_playwright driver

`playwright_widgets.das` adapts the interaction approach of upstream
`tests/record_slider.das` and the state checks of `tests/record_live_reload.das`.
It attaches through upstream ImguiApp/live_api_transport to an existing SDL HTTP
example. It uses upstream drag (frame-paced synthetic mouse events), click,
wait_for_render, wait_for_mouse_idle, wait_for_int_value and reload. It does not
force-set the slider. The app stays open after the driver finishes; successful
completion returns control to physical input.

Run from the repository root with example 02 already listening on 9091:

```powershell
.\third_party\daScript\bin\daslang.exe -dasroot third_party/daScript -load_module build/live-http/dasHV -ignore-manifest examples/live/playwright_widgets.das -- --live-port 9091
```

The driver chooses the drag direction from the current slider value, so repeated
runs move it to alternating positions. It increments the button count once, requests reload
and verifies both values survived. It is intended for the fresh/default widget
layout. A driver panic can leave synthetic input enabled; restart the example or
send set_user_control with enabled=true before resuming manual use.

The isolated automated version adds framebuffer checks and fault regression:

```powershell
ctest --test-dir build/live-http -R '^sdl3_live_playwright$' --output-on-failure
```

The regression runs the driver twice against the same app and checks both state
and pixel changes; the second capture is `build/live-gui/05-playwright-repeat.png`.
Its log is `build/live-playwright-driver.log`; the first capture is
`build/live-gui/04-upstream-playwright.png`. Python only starts/checks processes
and reads SDL captures; the drag/click/reload sequence is executed by the actual
upstream daScript playwright helpers. No dependency source was modified.

The standalone playwright driver above does not record. For continuous capture
through upstream with_recording_app, use the recording profile below.


## Continuous APNG recording through upstream

Example `03_widgets_recording.das` adds the application-local `sdl_recording.das`
adapter. It implements record_start/status/stop with the unchanged dasStbImage
streaming APNG writer. Capture happens after ImGui render and before SDL present.
SDL RGBA rows are flipped for the writer's bottom-up input contract. No OpenGL,
GLFW or replacement encoder is used.

Build the additional module from a VS developer shell:

```powershell
cmake -S src/live/http -B build/live-http -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build/live-http --target dasSDL3_live_stb --parallel 6
```

Start the recording example from the repository root:

```powershell
.\build\ninja\live\dasSDL3_live.exe -dasroot third_party/daScript -load_module build/ninja/live/module -load_module build/live-http/dasHV -load_module build/live-http/dasStbImage -no-module-cache examples/live/03_widgets_recording.das --live-port 9090
```

In a second terminal, also at the repository root:

```powershell
New-Item -ItemType Directory -Force build/live-recording/doc/source/_static/tutorials | Out-Null
.\third_party\daScript\bin\daslang.exe -dasroot third_party/daScript -load_module build/live-http/dasHV -ignore-manifest examples/live/record_widgets.das -- --output-root C:/src/dasSDL3/build/live-recording
```

The actual upstream with_recording_app attaches, starts recording, drags the
slider via synthetic mouse events, clicks once, verifies state, waits in captured
frames, stops recording and restores user input. The host remains running.
Output: `build/live-recording/doc/source/_static/tutorials/sdl-widgets.apng`.
The upstream attach helper is fixed to port 9090 in the pinned source. Keep that
port free for this example; your existing example on 9091 may stay open. The
driver checks that a recorder is present and idle before starting. It does not
spawn a GLFW host or change dependency sources.

The SDL adapter supports a software cursor through imgui_cursor_sprite. Upstream
imgui_visual_aids imports the GLFW imgui_live host, so trails and narration
visuals from that module are not claimed. The capture is synchronous and bounded:
1..60 fps, 1..60 seconds of content, at most 16 megapixels; each rendered frame
is captured and max_seconds limits the frame count. The writer stores rounded
millisecond delays (20 fps is exact). Host fixed_dt is set for recording and
returned to wall-clock at stop; arbitrary application clocks are not rewritten.
Reload/shutdown finalizes the writer; recordings do not span reload. A resize or
readback/encode failure also stops capture and exposes an error in record_status.
A driver panic may need explicit record_stop and set_user_control(enabled=true).

```powershell
ctest --test-dir build/live-http -R '^sdl3_live_recording$' --output-on-failure
```

The bounded test uses a separate app and checks successful upstream attach,
drag/click, all PNG CRCs, APNG sequence numbers/frame counts/delays, decompression
of every frame, changing pixels, failed and duplicate starts, automatic frame
cap, active-recording finalization on reload and exactly-once SDL cleanup.
First/last PNG previews and app/driver logs are saved in `build/live-recording`.
The fixed port test fails if 9090 is occupied; it never controls that existing app.


## Proposed configurable upstream recording port

See `patches/upstream/imgui-recording-port.patch` and its README. The proposed
full-form overload adds a port before the trailing block, preserving old calls.
`sdl3_live_recording_port` exercises the actual patch in a disposable module copy
on a free port and writes its recording to build/live-recording-port. The pinned
dependency and ordinary record_widgets.das remain unchanged until upstream adoption.


## Proposed upstream visual overlays on SDL

`sdl3_live_visual_aids` applies the proposed backend-independent import patch in
a temporary copy, then records real upstream highlights, mouse trail, cursor and
caption through SDL. Run it with CTest as above using that test name. Preview:
`build/live-visual-aids/last.png`; animation:
`build/live-visual-aids/doc/source/_static/tutorials/sdl-widgets.apng`.
The patch and compatibility notes are in patches/upstream/README.md. Normal
example 03 retains its software-cursor fallback until an upstream update.


## Recording lifetime under client failure and app shutdown

The regression now starts recording from a separate client which exits with an
error before record_stop. Since HTTP requests are stateless, the recorder does
not infer a disconnect: it keeps recording until its configured content-frame
cap and finalizes a valid APNG. This is bounded capture, not a connection watchdog;
a paused/stalled app does not advance that cap. After a driver panic, synthetic
input may still need set_user_control(enabled=true), as documented above.

A separate case requests application shutdown while capture is active. The
shutdown callback finalizes the APNG before releasing the SDL bundle; the test
validates every saved frame after process exit. This covers orderly shutdown,
not TerminateProcess, power loss or a native crash. Those can leave a partial file.
