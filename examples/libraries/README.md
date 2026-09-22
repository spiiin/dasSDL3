# Library integration examples

This directory has its own numbering. Optional libraries do not change core SDL
binding coverage.

## 01 — daScript ImGui with SDL3

`01_imgui.das` uses the existing daScript `imgui` module and Dear ImGui's official
SDL3 platform / SDLRenderer3 rendering backends. No GLFW window or OpenGL context
is used by this example. Click the counter button, open the standard ImGui demo,
drag the panel, or resize the SDL window. Escape exits when ImGui does not capture
keyboard input; closing the SDL window always exits.

From a Visual Studio x64 developer shell, configure the existing build and build
the optional host:

```powershell
cmake -S . -B build/ninja -DDASSDL3_WITH_IMGUI=ON
cmake --build build/ninja --target dasSDL3_libraries_runner --parallel 6
.\build\ninja\bin\dasSDL3_libraries_runner.exe .\examples\libraries\01_imgui.das
```

The option defaults to OFF. Initial configuration downloads the dependencies
pinned by daScript's dasImgui CMake: Dear ImGui 1.92.6-docking, FreeType 2.14.3,
MD4C 0.5.3 and GLFW 3.4, with SHA256 checks. Upstream currently requires the GLFW
and clipboard modules to enable its ImGui build; our host links the core ImGui
library and SDL backends, not `imgui_app`. The normal `dasSDL3_runner` remains
unchanged and cannot load this optional example.

```powershell
cmake --build build/ninja --target dasSDL3_imgui_input_test --parallel 6
ctest --test-dir build/ninja -R '^sdl3_imgui_' --output-on-failure
```

`--smoke-test` runs three hidden frames and checks rendered pixels before present.
CTest uses software rendering for reproducibility. The native input fixture feeds
SDL mouse, keyboard and UTF-8 events into the actual backend and verifies a button
implemented in daScript, capture flags and window resizing. Lifetime tests cover initialization failure, body errors,
repeated scopes and restoration of an existing context.

### Ownership and frame order

`with_imgui(window, renderer)` creates a context and initializes both backends.
The body borrows them and must not switch/destroy the context or release its SDL
owners. On normal return or Result error, cleanup runs in this order: renderer
backend, platform backend, context, then the outer SDL renderer/window scopes.
An earlier ImGui context is restored. Application panic is not a cleanup contract.

Each frame forwards **all** raw SDL events before application input handling,
calls both backend `NewFrame` functions, then ImGui `NewFrame`, widgets, `Render`,
SDL clear, `ImGui_SDL3_Render`, and SDL present. `ProcessEvent`'s bool means the
backend recognizes an event; use `WantCaptureMouse/Keyboard` to decide whether
the application should also act on input. Quit must not be blocked by capture.
Backend void functions retain their upstream contracts; a stale SDL error string
is not interpreted as rendering failure.

### Limits and AOT

Validated on Windows with SDL 3.2.18. SDLRenderer3 does not support ImGui multiple
platform viewports. SDLGPU3, browser ImGui, mixed-DPI monitors, IME composition and
physical gamepads are follow-ups; this example does not establish their support.
No script callback is retained by the integration. Widget APIs come from upstream
dasImgui; this is not a second widget binding.

The parity project has an optional `-DDASSDL3_TEST_IMGUI=ON` switch after the main
library build. It adds legacy/CppGenBind interpreter tests and `imgui_aot_runner`
with interpreter fallback disabled. All six tests passed locally. The integration
header supplies the missing upstream AOT declaration for
`das::DisableIniPersistence` without editing daScript.
The example and lifetime tests also pass in a consumer build with LLVM, Clang and
Python discovery disabled and binding generators OFF.
