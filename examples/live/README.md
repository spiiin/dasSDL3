# SDL widgets in daslang-live

This Windows/MSVC pilot builds the unmodified upstream daslang-live source as
`dasSDL3_live.exe` and loads the SDL/ImGui bindings dynamically. It is separate
from the ordinary desktop and Web lifecycle hosts.

## Build and run

Configure your existing dependency-ready Ninja build with
`-DDASSDL3_WITH_IMGUI=ON -DDASSDL3_WITH_LIVE=ON`, then, from a VS developer shell:

```powershell
cmake --build build/ninja --target dasSDL3_live --parallel 6
.\build\ninja\live\dasSDL3_live.exe -dasroot third_party/daScript -load_module build/ninja/live/module -no-module-cache examples/live/01_widgets.das
```

Edit the script and click **Reload script**. The pilot deliberately uses an
explicit reload so the same command is reproducible in tests. `init`, `update`
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
pauses the previous context; repair the source and request another reload.
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
server. HTTP and integration with the upstream MCP adapter are a later step.

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
