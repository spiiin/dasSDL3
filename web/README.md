# dasSDL3 Web examples

Single-thread wasm32 interpreter profile: Hello, moving square, keyboard/mouse, BMP
textures, streaming texture, render target, indexed geometry and queued audio. Uses the same SDL boost functions and sdl_try as desktop; SDL main
callbacks replace the blocking loop. SDL 3.2.18, daScript pinned submodule,
Emscripten 5.0.3, single thread, SIMD and native Wasm exceptions.

## Build on Windows

Install emsdk separately, then in cmd.exe:

```bat
call C:\src\emsdk\emsdk_env.bat
cd /d C:\src\dasSDL3
web\build.cmd
```

CMake 3.24+, Ninja and Python are needed. If Ninja is not in PATH, pass
`-DCMAKE_MAKE_PROGRAM=C:/path/to/ninja.exe` to build.cmd. The first configure
fetches SDL release-3.2.18; an existing matching checkout can be supplied with
`-DFETCHCONTENT_SOURCE_DIR_SDL3=C:/path/to/SDL`. Windows developer binaries are
not required by the web build; LLVM/dasClangBind are not linked into the browser.
Upstream library/runtime output paths are redirected into build/web.
On Windows the post-build step resets only the generated JS file ACL to inherit
from its output directory. Emscripten moves this file from a private temporary
directory; without resetting inheritance another local HTTP-server account may
get access denied (reported as HTTP 404). Repository/source ACLs are unchanged.

```powershell
python -m http.server 8080 --bind 127.0.0.1 --directory build/web/site
```

Open http://localhost:8080/. Do not open HTML through file://. Serve .wasm as
application/wasm. Keep the JS/WASM/data files together. The first profile needs
no SharedArrayBuffer or COOP/COEP. No deployment is performed by build.cmd.

## Bindings

`tools/bindings-web.json` is an explicit subset. It does not claim coverage of
all desktop APIs or HID/GPU. Saved files are web/generated; regenerate with:

```powershell
python web/generate.py --emsdk C:/src/emsdk --sdl-include test-app/build/_deps/sdl3-src/include
python web/generate.py --emsdk C:/src/emsdk --sdl-include test-app/build/_deps/sdl3-src/include --check
```

The shared Python/Clang generator now accepts target/sysroot arguments, policy
and output paths. CppGenBind wasm support and the full platform census remain
follow-ups. The native Windows generator defaults remain unchanged.

## Lifecycle

Each script exports app_init():int, app_frame():int, app_event(event:SDL_Event):int
and app_quit():void. Integer results are host lifecycle signals: 0 continue,
positive finish, negative failure. Script work uses Result/Option; its entry
points report the error once and translate to a lifecycle signal.

The native runner owns Program/Context/ModuleGroup until SDL_AppQuit. Events are
borrowed synchronously. There are no retained stack blocks. app_quit runs also
for partial app_init failure, once valid entry points have been checked.
Resources across frames live in the example's state and are released in quit.
Defer/with_* remain valid inside synchronous operations, not across returned
callbacks. Arbitrary panic/page close is not a defer cleanup guarantee.
Stop requests SDL's next iteration to exit. Restart stops first and reloads the
page, so it creates a new WASM instance. It does not re-enter a shut-down runtime.

No SDL_GPU WebGPU backend exists in pinned SDL. These pages use SDL Renderer
through WebGL; they are not ports of the native GPU examples. Browser
filesystem persistence, full event variants, AOT and workers are future work.

## Local validation (2026-09-22)

All eight pages passed in Edge/Chromium and Firefox using Playwright: 15 scenarios
per browser (8 pages + 7 injected failures). Tests check foreground pixels,
changing streaming pixels, keyboard/mouse delivery, resize, Stop/Restart,
compile errors, missing BMP, frame errors, render-target restoration on Err,
short RGBA storage and invalid geometry indices. Audio tests inspect nonzero
PCM in the actual Web Audio output buffer, a running AudioContext, closure on
Stop and partial-init failure, and successful restart. No microphone is used.
Normal/failed initialization or frame completion calls script quit once;
compile failure before entry initialization does not call an uninitialized quit.
All four new scripts also compile with the native interpreter (no native I/O).
Firefox required an unsandboxed test launch on the development machine.
Safari/WebKit, physical speaker output, Web GPU and Web AOT remain unvalidated.

Current SDL policy: 65 generated raw functions, 7 opaque types, 11 records, five enums
and 412 constants. The upstream daScript OpenGL module is linked separately; its
GL declarations do not count as SDL coverage. Necessary ref/copy adapters reuse the desktop headers.
This is a bootstrap subset, not a complete Web declaration census.

The validated local artifact uses Release C++ compilation with the faster
`-DCMAKE_EXE_LINKER_FLAGS=-O1` link setting: approximately 28.5 MB WASM, 4.36 MB
data and 0.52 MB JS before compression. Omit/clear that cache option for the
normal Release (-O3) link; it takes much longer. Size varies with optimization. Serve gzip/Brotli for deployment. No performance
claim is made for large scripts or mobile devices.

```powershell
python -m venv build/web-tests
build/web-tests/Scripts/python -m pip install playwright pillow
build/web-tests/Scripts/python tests/web/test_browser.py --browser edge --url http://localhost:8080
build/web-tests/Scripts/python -m playwright install firefox
build/web-tests/Scripts/python tests/web/test_browser.py --browser firefox --url http://localhost:8080
```

Web source files are independent of the desktop main(smoke) entry points.
Pages 05-08 reuse the desktop pixels, geometry and audio boost modules. Textures,
renderer and playback stream belong to the example until app_quit. Page 06 uses
sdl_scope/sdl_use to restore the previous render target even on a Result error.
The streaming example copies a CPU RGBA buffer every frame; it retains no lock.

Page 08 starts audio from the Start click after the runtime finishes loading.
It queues copied mono S16LE PCM (48 kHz, quiet 440 Hz), replenishing at most once
per frame below a 0.25-second threshold. This bounds queued data even if browser
audio is suspended. No script callback runs on an audio thread. Stop destroys
the stream and closes SDL's Web Audio context; Restart creates a fresh runtime.
If browser policy suspends audio, click the canvas to give another user gesture
or allow sound for this site. The page must not claim audible playback merely
because SDL accepted the queue. Tests inspect actual nonzero Web Audio output;
physical speakers remain a manual check. Recording/microphone access is not used.

Full platform inventory/CppGenBind, AOT and remaining subsystems stay on the roadmap.

## OpenGL examples

[examples/web/opengl](../examples/web/opengl/README.md) adds two pages using the
existing pinned daScript `libDasModuleOpenGL`. The scripts `require opengl`; SDL
provides the ES 3.0 window/context and swap, while raw GL calls draw the image.
The target links with FULL_ES3 and MAX_WEBGL_VERSION=2. GLFW is not needed.
The SDL context subset here does not complete the deferred desktop GL/EGL P8.
Both GL pages and all four failure cases passed in Edge and Firefox (6 scenarios
per browser). Shader/program create/delete counts match on normal and failed
paths. The existing 15 SDL scenarios per browser are the regression suite.

```powershell
build/web-tests/Scripts/python tests/web/test_opengl.py --browser edge --url http://localhost:8080
build/web-tests/Scripts/python tests/web/test_opengl.py --browser firefox --url http://localhost:8080
```
