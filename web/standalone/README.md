# Standalone wasm32 lifecycle pilot

This build compiles the unchanged `examples/lifecycle/01_square.das` to C++, then
WebAssembly. The browser calls generated C++ methods for init/update/shutdown,
app_event and exit_code. It does not compile daScript or fall back to interpreted
bodies. The small host is a pilot for this bool-update contract, not a general
replacement for the dynamic Web runner's optional callbacks/overloads.

## Build and run (Windows)

First build the existing `web/build.cmd` profile with Emscripten **5.0.3**. Its
wasm libraries and generated headers are reused; this consumer does not reconfigure
daScript or modify the developer profile. Then, from an activated SDK shell:

```bat
call C:\src\emsdk\emsdk_env.bat
call web\standalone\build.cmd
ctest --test-dir build/web-standalone --output-on-failure
python -m http.server 8766 --bind 127.0.0.1 --directory build/web-standalone/site
```

Open http://127.0.0.1:8766/. Start runs the square; Escape and Stop release its
resources, and Restart creates a fresh WASM instance. Serve the files over HTTP.
The downloadable `square.das` is documentation only, never loaded into runtime FS.
The `gc`, `sdl_gc` and `faults` bundles are test fixtures, selected by the test page's
`app` query parameter; the normal page uses `square.js`/`square.wasm`.

`build.cmd` uses Ninja from the existing Web cache and Node from `EMSDK_NODE`.
Do not substitute an older system Node: generation needs the SDK's WASM exception
support. For custom build directories, configure this CMake project directly with
emcmake, WEB_BUILD, NODE_EXECUTABLE and CMAKE_MAKE_PROGRAM.

## Generation and runtime boundary

1. `generate_aot` is a **wasm32** build-time compiler, run by SDK Node with NODEFS.
   It reads the actual project/dependency sources and uses the pinned upstream
   standalone emitter. Windows x64 generated offsets are never reused.
2. `emit.das` requests all required imported modules and emits the standalone
   context without registering compiler-side modules. Dependencies include every
   boost/daslib script, so changing imported code invalidates generated output.
3. The final programs link only daScript runtime, URI runtime and SDL. The
   generator/compiler/binding-registration library is not linked into the browser
   application. No generated source is hand-patched; no dependency is modified.
4. Post-link map checks reject compiler/parser/module factories and interpreter
   evaluation symbols. CTest also proves that a reachable no_aot function fails
   generation. A missing AOT implementation is an error, never fallback.

Runtime services still exist: Context, arrays, strings, metadata, GC and AOT call
adapters. This is not a runtime-free or daScriptNano build. The generated context
retains global root metadata; collection runs from the host after a continuing
update has returned. The script still owns SDL resources and explicit shutdown.
A failed init attempt, update/event exception, Stop or normal exit all attempt
shutdown once. Cleanup faults or nonzero exit_code mark the session Failed.

## Verification (2026-09-27)

```powershell
python tests/web/test_standalone.py --browser edge --url http://127.0.0.1:8766
python tests/web/test_standalone.py --browser firefox --url http://127.0.0.1:8766
```

Use the same Python environment with Playwright and Pillow as the other Web tests.
Both browsers passed nine scenarios each: actual canvas pixels and Escape,
Stop/Restart (including restart while running), 400-tick array/string GC,
400-tick GC with live SDL window/renderer pointers, real renderer acquisition
failure after window creation, and init/update/shutdown/event faults plus a
reported nonzero exit_code. The tests also assert absence of compiler source
folders in the runtime filesystem. No Safari/mobile support is inferred.

The square's uncompressed WASM is about **1.8 MB**, compared with **28.7 MB** for
this checkout's universal Web runner. This is a local build-size observation,
not an FPS benchmark or a guarantee for other scripts/options.
