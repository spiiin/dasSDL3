# Library integration examples

This directory has its own numbering. Optional libraries do not change core SDL
binding coverage.

## 02 — SDL_image

`02_image.das` displays a PNG with alpha and an SVG, loaded through SDL_image 3.2.4.
Enable independently or alongside ImGui:

```powershell
cmake -S . -B build/ninja -DDASSDL3_WITH_IMAGE=ON
cmake --build build/ninja --target dasSDL3_libraries_runner --parallel 6
.\build\ninja\bin\dasSDL3_libraries_runner.exe .\examples\libraries\02_image.das
```

The left image has opaque red and translucent cyan halves; the right is an opaque
red SVG rectangle. Escape/close exits. `--smoke-test` renders three hidden frames.
PNG/JPEG use the built-in stb backend; AVIF/JXL/TIFF/WebP are disabled in this
dependency-free codec profile. See [SDL_image API and validation](../../docs/sdl-image.md).

```powershell
cmake --build build/ninja --target dasSDL3_image_io_test --parallel 6
ctest --test-dir build/ninja -R '^sdl3_(image_io|tests_image|examples_libraries_02_image)$' --output-on-failure
```

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

## 03 — SDL_ttf

Enable `-DDASSDL3_WITH_TTF=ON`, then build `dasSDL3_libraries_runner`.
This option works independently of ImGui and SDL_image. CMake downloads pinned
SDL_ttf 3.2.2, FreeType 2.14.3 and HarfBuzz 10.4.0, reusing FreeType when ImGui is enabled.
The bundled JetBrains Mono font and license are copied beside the executable.

```powershell
.\build\ninja\bin\dasSDL3_libraries_runner.exe .\examples\libraries\03_ttf.das
```

The example renders UTF-8 text using Font, renderer TextEngine and Text scopes.
Escape closes the window; `--smoke-test` renders three frames and exits.
See [SDL_ttf contracts and limitations](../../docs/sdl-ttf.md).

```powershell
cmake --build build/ninja --target dasSDL3_ttf_io_test --parallel 6
ctest --test-dir build/ninja -R '^sdl3_(ttf_io|tests_ttf|examples_libraries_03_ttf)$' --output-on-failure
```

## 04 — SDL_ttf shaping

```powershell
.\build\ninja\bin\dasSDL3_libraries_runner.exe .\examples\libraries\04_ttf_shaping.das
```

Cyan Arabic text uses joining and diacritics with explicit RTL/Arab/ar settings.
The amber Latin specimen shows ligatures and precomposed/combining accent forms.
The Amiri 1.003 font is included under SIL OFL; no system font lookup is needed.
Escape exits; `--smoke-test` renders three hidden frames. This is run shaping,
not automatic mixed-script paragraph bidi layout.

```powershell
ctest --test-dir build/ninja -R '^sdl3_(ttf_io|tests_ttf.*|examples_libraries_0[34]_ttf.*)$' --output-on-failure
```

## 05 — SDL_ttf GPU atlas

```powershell
$env:SDL_GPU_DRIVER = "vulkan" # or "direct3d12"
.\build\ninja\bin\dasSDL3_libraries_runner.exe .\examples\libraries\05_ttf_gpu.das
```

Cyan text appears on black; it changes briefly and returns to the original line.
Escape/close exits. Geometry comes from SDL_ttf GPU TextEngine; the example uploads
vertices/indices and records native SDL GPU draw calls. No SDL_Renderer is used.
The alpha-only shader explicitly rejects SDF/color/fill sequences.

With `--smoke-test`, three frames are followed by GPU-to-CPU readback and comparison
with FreeType's CPU glyph mask. Tests also force several atlas pages and check
empty text, mutation, array ownership, winding and fills. Vulkan and Direct3D12
are registered separately and validation errors fail the run:

```powershell
ctest --test-dir build/ninja -R '^sdl3_(examples_libraries_05_ttf_gpu|tests_ttf_gpu)_' --output-on-failure
```

The optional `ttf_aot_runner` parity host includes example 05 and these contract
tests; select `(baseline|cppgenbind|aot)_(examples_libraries_05_ttf_gpu|tests_ttf_gpu)_`
in its CTest build. See [GPU ownership contract](../../docs/sdl-ttf.md#gpu-text).

## 06 — SDL_net

Enable `DASSDL3_WITH_NET=ON` (independent of the other optional libraries). [06_net.das](06_net.das) exchanges binary TCP and UDP data over 127.0.0.1. Ports 39173/39174 must be free.

```powershell
.\build\ninja\bin\dasSDL3_libraries_runner.exe .\examples\libraries\06_net.das
```

[SDL_net contracts](../../docs/sdl-net.md) describe async readiness, ownership, array copies and loopback/parity tests.

## 07 — SDL_mixer

Enable `DASSDL3_WITH_MIXER=ON`, then build `dasSDL3_libraries_runner`.
[07_mixer.das](07_mixer.das) plays a quiet 440/660 Hz chord using two tracks and
releases track/audio/mixer resources through sdl_scope/sdl_use.

```powershell
.\build\ninja\bin\dasSDL3_libraries_runner.exe .\examples\libraries\07_mixer.das
```

CTest uses dummy audio; normal launch uses the default playback device.
[SDL_mixer contracts](../../docs/sdl-mixer.md) cover offline PCM, codecs, callbacks,
Result counts and resource/IO ownership.

## 08 — SDL_sound

Enable `DASSDL3_WITH_SOUND=ON`, then build `dasSDL3_libraries_runner`.
[08_sound.das](08_sound.das) decodes a short WAV and plays PCM through SDL audio.

```powershell
.\build\ninja\bin\dasSDL3_libraries_runner.exe .\examples\libraries\08_sound.das
```

[SDL_sound contracts](../../docs/sdl-sound.md) cover the consuming error channel,
EOF/EAGAIN, read-only sample metadata, IO lifetime and tests.

## 09 — SDL_shadercross

Enable `DASSDL3_WITH_SHADERCROSS=ON`, then build `dasSDL3_libraries_runner`.
[09_shadercross.das](09_shadercross.das) compiles HLSL to SPIR-V, reflects inputs/outputs,
and produces MSL without creating a GPU device. If HLSL compilation is unavailable,
it uses the committed SPIR-V fixture. DXIL is produced only when shadercross
advertises that capability. The default Mac profile needs no DXC:

```sh
./build/macos-libraries/bin/dasSDL3_libraries_runner examples/libraries/09_shadercross.das
```

```powershell
.\build\ninja\bin\dasSDL3_libraries_runner.exe .\examples\libraries\09_shadercross.das
```

DXC DLLs are copied beside the executable. The `shadercross` CLI and
`dassdl3_shadercross_example_assets` build target prepare assets offline.
See [dependency/ownership contracts](../../docs/sdl-shadercross.md).

## Native Mac strict AOT

After configuring the [Mac companion profile](../../docs/macos.md), build and run:

```sh
cmake --build build/macos-libraries --target dasSDL3_macos_libraries_aot_runner --parallel 6
SDL_VIDEODRIVER=dummy ctest --test-dir build/macos-libraries -L macos-libraries-aot -E ttf_gpu --output-on-failure
# Ordinary Terminal, GUI login session:
ctest --test-dir build/macos-libraries -L macos-libraries-aot --output-on-failure
```

The AOT target follows the enabled companion options and shared boost imports.
It uses the same strict generator/runner as the core checks, with interpreter
fallback disabled. Cases cover raw IO, image, TTF/shaping/GPU text, loopback net,
mixer/sound using dummy audio, ImGui lifetimes/widgets, shadercross without DXC,
and rejection of a missing AOT main. Compiler success and dummy rendering do
not establish Cocoa/Metal execution; native results are recorded separately.

The pinned ImGui click coroutine exposes a lost lexical scope in the C++ emitter:
a resume goto bypasses a local GetIO pointer initialization. Mac companion AOT
generation restores exactly that two-statement scope and rejects changed or
escaping temporaries. The widget test executes and resumes a real queued click.
Dependency sources remain unchanged; this workaround must be reviewed when the
pinned SDK changes. See [AOT compatibility](../../docs/clangbind-types-aot.md).
