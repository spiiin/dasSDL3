# dasSDL3

**SDL3 bindings for daScript (daslang)** — native SDL access with an idiomatic scripting layer for resource scopes, errors, events and buffers.

[Platforms](#platform-support) · [Getting started](#getting-started) · [Examples](examples/README.md) · [Documentation](docs/README.md) · [Coverage](docs/api-coverage.md) · [Roadmap](docs/full-binding-roadmap.md)

## Features

- Window management, 2D rendering, textures, surfaces, GPU, audio, input, events, files and platform services.
- Standard `Result` / `Option`, `sdl_try` for error propagation, and `sdl_scope` / `sdl_use` for resource acquisition and reverse-order cleanup.
- Owned event variants, copied text payloads and lazy `poll_events()` iteration.
- Copied query results and temporary scoped pixel views, including surface planes and row pitch.
- Interpreter and strict AOT execution, generated bindings and an installable core CMake SDK.
- [Shader DSL](docs/shader-dsl.md) using daScript's existing SPIR-V compiler, with optional shadercross translation to D3D12.
- Optional ImGui, SDL_image, SDL_ttf, SDL_net, SDL_mixer, SDL_sound and SDL_shadercross integrations.
- Web examples built with Emscripten: SDL Renderer, audio and the existing daScript OpenGL module.

The public API follows SDL objects and operations. Application rendering algorithms live in examples.

## Status

The primary validated target is **Windows x64 / MSVC**. Dependencies are pinned to **SDL 3.4.16** and daScript commit `ebac0ffe46ab30de6c9536f4b0af7a33ede45902`.

The Windows inventory records **1,062 generated functions and 13 adapted functions out of 1,263**. The remaining 188 have explicit decisions: 169 Stdinc functions and 19 host, standard-library, C ABI or deferred operations. They are not counted as implemented. All 95 active Windows SDL GPU function declarations are generated.

The record audit classifies **840 fields across 122 complete records**, with no remaining `pending` or `partial` field-access entries. Some fields deliberately remain native-only or SDL-internal; classification does not imply unrestricted script access.

The Windows validation workflow covers interpreter execution, both binding generators, strict AOT and a separate installed-SDK consumer. Linux has the narrower regression profile described below. This is not a claim of complete SDL coverage or validation on every platform/device. See [coverage](docs/api-coverage.md), [remaining API decisions](docs/remaining-api-policy.md) and [record access](docs/record-field-accessibility.md).

## Platform support

Support is specific to the build profile and runtime environment. SDL's platform
coverage does not by itself establish dasSDL3 support on those platforms.

| Platform / toolchain | Status | Validated scope and limits |
| --- | --- | --- |
| Windows x64 / MSVC (VS 2022) | Primary desktop target | Interpreter, CppGenBind and Python snapshots, strict AOT, and the core installed SDK. Optional integrations have their own requirements. See [Getting started](#getting-started) and [SDK](docs/sdk.md). |
| Linux x86-64 / GCC 13.3, Ubuntu 24.04 in WSL2 with WSLg | Core source-build profile validated | Minimal runner build without binding generators; 15 `linux-core` checks including interpreter, native-width HID Unicode, strict AOT and rejection of missing AOT code. The 2D square and Vulkan Shader DSL triangle smoke tests passed in this environment. See [Linux setup](docs/linux.md). |
| Other Linux distributions, native desktop installations, other CPU architectures / compilers | Not yet validated | The WSL2 result does not establish native-driver, device, performance or distribution compatibility. |
| Web / Emscripten 5.0.3, wasm32 | Experimental profile | Selected SDL Renderer, audio and daScript OpenGL examples. Single-threaded interpreter; no desktop API parity or SDL GPU/WebGPU backend. See [Web guide](web/README.md). |
| macOS / Metal, iOS, Android and other targets | Not yet validated | No tested dasSDL3 build/runtime profile is claimed. |

Linux currently uses separate committed bindings and a source checkout.
The installed SDK remains Windows-only; optional Linux integrations are not
covered by the core test result. Windows-only raw DXGI, Direct3D9 and message-hook
functions are absent from Linux bindings. Use `SDL_HidChar` for native HID wide
buffers (`uint16` on Windows, `int32` on Linux); copied metadata remains UTF-8.

Platform support also depends on how the project is consumed:

| Delivery path | Windows x64 | Linux |
| --- | --- | --- |
| Core runner from source | Primary profile | Validated WSL2 core profile above |
| Installed C++/AOT SDK | Windows-only profile | Not supported yet |
| daspkg repository package (`core` / `imgui`) | Declares `windows`; package build requires MSVC and a matching DLL SDK | Not supported; the source-runner port does not port the package build |

**daspkg SDK:** use the pinned daScript revision `ebac0ffe46ab30de6c9536f4b0af7a33ede45902`
and a matching validated DLL SDK fingerprint. Root and staged manifests declare
only `windows`. Older SDKs are not supported; `0.6.4` alone is not a sufficient
ABI or client-version identifier. See [package platform readiness](docs/daspkg.md#platform-readiness).

The focused Linux checks are not the full CTest suite. WSLg/Vulkan smoke success
does not establish GPU performance, hardware acceleration, physical HID device
behavior, or validation-layer coverage on other systems.

## Getting started

Requirements: Git, CMake 3.24+, Ninja, Visual Studio 2022 C++ tools and Windows SDK. Tested with MSVC 19.38. The first build downloads dependencies.

From a **VS 2022 x64 developer shell**:

```powershell
git clone --recurse-submodules https://github.com/spiiin/dasSDL3.git
cd dasSDL3
cmake -S . -B build/ninja -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build/ninja --target dasSDL3_runner --parallel 6
./build/ninja/bin/dasSDL3_runner.exe examples/02_square.das
```

For an existing checkout, run `git submodule update --init --recursive` first. CMake downloads the pinned SDL source through FetchContent. The default build uses committed binding snapshots and needs **neither LLVM nor Python**.

SDL and daScript are linked statically; no SDL3.dll is needed. The development runner uses script modules and the standard library from the source checkout. For applications outside the repository, use the [installed SDK](docs/sdk.md).

## Linux

For Ubuntu 24.04 / WSL2, see [Linux setup and tests](docs/linux.md).
The core runner uses committed Linux bindings and native-width HID strings.
Build with `-DBUILD_TESTING=OFF` for a minimal consumer, or use the documented
`linux-core` test label for interpreter and strict AOT regression checks.
The installed SDK profile remains Windows-only.

## Script API

Save this example as `hello.das` in the repository root, then run `./build/ninja/bin/dasSDL3_runner.exe hello.das`. Escape or close exits.

```das
options gen2
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_scope
require dassdl3/sdl3_events

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let flags = smoke ? SDL_WINDOW_HIDDEN : SDL_WINDOW_RESIZABLE
        let window : SDL_Window? = with_window("Hello, SDL3", 640, 480, flags) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        var running = true
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false; break }
            }
            if (!running) { break }
            renderer |> clear() |> sdl_try
            renderer |> present() |> sdl_try
            if (smoke) { break }
            SDL_Delay(16u)
        }
        return sdl_ok()
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
```

`require sdl3` exposes low-level bindings. The `dassdl3/*` modules add language and lifetime helpers. `sdl_try` returns errors to the caller; `sdl_use` nests the remaining scope inside the corresponding `with_*` call. Resources are released through `defer` on normal and early returns.

Resource pointers inside scopes are borrowed, not unique owning types: do not retain or manually destroy them. Arbitrary application panic is outside the deferred-cleanup guarantee. Native callback setters accept **C function addresses**, not retained daScript closures. See [scope macros](docs/sdl-scope.md), [errors](docs/error-handling.md) and [callbacks](docs/native-callbacks.md).

## Examples

| Area | Start here |
| --- | --- |
| 2D rendering | [Moving square](examples/02_square.das), [textures](examples/04_textures.das), [geometry](examples/07_geometry.das) |
| Result and events | [sdl_try](examples/results/02_sdl_try.das), [owned event iteration](examples/results/03_poll_events.das) |
| SDL GPU | [GPU examples](examples/gpu/README.md), including the bgfx metaballs port |
| Pixel memory | [Scoped surface bytes](examples/93_surface_bytes.das) |
| Audio | [Audio stream](examples/08_audio.das) |
| Companion libraries | [Library examples](examples/libraries/README.md) |
| Browser | [Web guide](web/README.md), [OpenGL examples](examples/web/opengl/README.md) |

Most desktop examples accept `--smoke-test` for a bounded run:

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/02_square.das --smoke-test
```

See the [example index](examples/README.md) for the complete list and runtime requirements.

## Optional libraries

All integrations are disabled by default.

| Integration | CMake option | Documentation |
| --- | --- | --- |
| daScript ImGui + SDL3 | `DASSDL3_WITH_IMGUI` | [ImGui example](examples/libraries/README.md) |
| SDL_image | `DASSDL3_WITH_IMAGE` | [Images](docs/sdl-image.md) |
| SDL_ttf | `DASSDL3_WITH_TTF` | [Fonts and text](docs/sdl-ttf.md) |
| SDL_net | `DASSDL3_WITH_NET` | [Networking](docs/sdl-net.md) |
| SDL_mixer | `DASSDL3_WITH_MIXER` | [Mixing and playback](docs/sdl-mixer.md) |
| SDL_sound | `DASSDL3_WITH_SOUND` | [Decoding](docs/sdl-sound.md) |
| SDL_shadercross | `DASSDL3_WITH_SHADERCROSS` | [Shader translation](docs/sdl-shadercross.md) |

For example:

```powershell
cmake -S . -B build/ninja -DDASSDL3_WITH_IMAGE=ON
cmake --build build/ninja --target dasSDL3_libraries_runner --parallel 6
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/libraries/02_image.das
```

Each integration has its own dependency, codec and platform requirements; see its documentation before enabling it.

## Web

The experimental web profile uses a single-threaded wasm32 interpreter and a selected SDL API subset. It supports SDL Renderer and audio examples, plus OpenGL examples using daScript's existing bindings. It does not provide desktop API parity or an SDL GPU/WebGPU backend.

Build with Emscripten 5.0.3 using `web/build.cmd`, then serve the generated pages:

```powershell
python -m http.server 8080 --bind 127.0.0.1 --directory build/web/site
```

Open <http://localhost:8080/>. Full setup and browser requirements are in the [Web guide](web/README.md).

## Embedding and AOT

The [core SDK](docs/sdk.md) installs C++ libraries, headers, script modules, the standard library, CMake targets and an AOT generator. An external application can use:

```cmake
find_package(dasSDL3 CONFIG REQUIRED)
target_link_libraries(my_app PRIVATE dasSDL3::dasSDL3)
```

`dassdl3_add_aot(...)` adds compiled script registrations. The supported SDK profile is Windows x64, MSVC, single-config Release and `/MD`; companion libraries are not included. Consumers need neither LLVM nor Python. AOT applications still load script sources and standard-library resources; they are not source-free executables.

See the [SDK instructions](docs/sdk.md) and [standalone consumer](examples/sdk-consumer).

## Development

Bindings are selected in `tools/bindings.json`. CppGenBind/dasClangBind is the primary Windows generator; Python/Clang AST is the reference backend. Both use committed snapshots. Ownership, callbacks and array adapters are implemented explicitly.

- [Generator setup](docs/clangbind-setup.md) and [snapshot workflow](docs/clangbind-production.md)
- [Interpreter/AOT parity](docs/clangbind-parity.md)
- [API inventory](docs/api-inventory.md) and [record-field audit](docs/record-field-accessibility.md)
- [Architecture](docs/gpu-api-boundary.md) and [roadmap](docs/full-binding-roadmap.md)

Build the configured test targets before running CTest:

```powershell
cmake --build build/ninja --parallel 6
ctest --test-dir build/ninja --output-on-failure
```

Some tests require graphics drivers, devices or optional dependencies. Generator freshness and parity checks require the separately documented developer toolchain; the default build does not enable them.

## License

Original dasSDL3 code is [MIT licensed](LICENSE). Dependencies, adapted examples
and assets retain their own licenses; see [distribution notices](licenses/README.md).
The core/ImGui packages and standalone releases include these notices.
