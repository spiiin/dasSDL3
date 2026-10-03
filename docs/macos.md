# macOS

The native development profile uses Apple Clang, SDL Cocoa/Metal and static
daScript/SDL libraries. Dependencies retain the same pinned revisions as Windows.
The saved Python/Clang snapshot under `src/generated/macos` describes the Mac ABI;
the Windows CppGenBind and reference snapshots remain separate.

## Setup

Install Apple Command Line Tools (`xcode-select --install`), Git, CMake 3.24+
and Ninja. Python 3 is needed for development tests, but not a consumer build
with `-DBUILD_TESTING=OFF`. LLVM/libclang and shader compilers are not required.

```sh
git clone --recurse-submodules https://github.com/spiiin/dasSDL3.git
cd dasSDL3
bash tools/build_macos.sh
./build/macos/bin/dasSDL3_runner examples/02_square.das --smoke-test
./build/macos/bin/dasSDL3_runner examples/02_square.das
```

To choose Python explicitly, pass `-DPython3_EXECUTABLE=/path/to/python3` to
the build script. Its optional local CMake/Ninja lookup also supports a checkout
configured without Homebrew. Scripts and the daScript standard library currently
remain in the source tree, as in the Windows development runner.

## ABI and platform differences

- Windows-only SDL message hooks and Direct3D/DXGI queries are absent from the
  Mac raw bindings. `SDL_HAS_DXGI_QUERY` permits conditional script code.
  The existing `dxgi_output` boost reports an SDL error on unsupported platforms.
- `SDL_HidChar` matches native HID storage: `uint16`/UTF-16 on Windows and
  `int`/UTF-32 on macOS. HID buffer counts are characters, not bytes. The Mac
  interpreter and AOT use explicit bridges because the pinned daScript maps
  C++ `wchar_t` to `uint16` even on Apple. Copied HID metadata remains UTF-8.
- The Mac AOT names for `SDL_LoadFile` and `SDL_LoadFile_IO` use explicit
  `size_t`/script-`uint64` output storage bridges. Their C++ pointer types differ
  even though both have eight-byte storage. Raw interpreter signatures, optional
  output pointers and failure sizes are preserved.
- The binding and its C++ consumers use `-fno-rtti` to match the pinned runtime.
- Vulkan needs a separately installed loader/MoltenVK. Native Metal works through
  SDL GPU; SPIR-V/DXIL shader assets do not become Metal shaders automatically.
  Shader-based examples need MSL/Metallib assets or optional shader translation.
- The installed core SDK supports native AppleClang and enforces one matching
  architecture. Dynamic daspkg modules require their own matching SDK fingerprint.

## Development checks

```sh
cmake --build build/macos --target dasSDL3_macos_aot_runner --parallel 6
ctest --test-dir build/macos -L macos-headless --output-on-failure
# Run this from a Terminal in a GUI login session:
ctest --test-dir build/macos -L macos-native --output-on-failure
```

The Mac test group runs real Metal transfer/readback, texture/format, volume,
fence and swapchain contracts in both interpreter and strict AOT, MSL triangle
pixels in both modes, and strict AOT HID/peripheral and filesystem coverage.
The three `macos-headless` cases check HID, filesystem and rejection of missing
AOT code. The seven native strict-AOT cases also passed through Cocoa/Metal.
AOT generation includes each imported boost module; the runner requires
`aot=true`, `fail_on_no_aot=true` and an AOT `main`, with fallback disabled. Unavailable Metal
is a test failure here, not a silent success. Use a GUI login session for graphics
tests. Dummy video tests are separate from native Cocoa/Metal evidence.
The native hit-test probe uses Windows messages and is registered only on Windows.
Window-state tests retain Cocoa's unsupported border-size result as an error.

Regenerate or check the Mac snapshot with the pinned SDL headers:

```sh
python3 tools/generate_bindings.py --profile macos \
  --sdl-include build/macos/_deps/sdl3-src/include --output src/generated/macos
python3 tools/generate_bindings.py --profile macos \
  --sdl-include build/macos/_deps/sdl3-src/include --output src/generated/macos --check
```

`DASSDL3_ENABLE_GENERATORS=ON` enables the same freshness check through CTest.
Use the native Mac Clang/SDK. Keep generated snapshots reproducible and do not
hand-edit them.

Checked shader helpers accept MSL source and Metallib in addition to SPIR-V/DXIL.
MSL source is copied to owned storage with a guaranteed terminator before the
native call; embedded NULs are rejected. The Mac triangle fixtures use `main0`.
Pinned SDL Metal uploads use tight native rows/slices, so the checked transfer
helpers pack those separately from the 256-byte rows used on other drivers.

## Companion libraries

SDL_image, SDL_ttf, SDL_net, SDL_mixer, SDL_sound, ImGui and shadercross build
with the same pinned sources. Shadercross defaults to DXC disabled on Mac;
SPIR-V reflection and MSL/HLSL translation remain available. HLSL compilation
and DXIL need a separately supplied compatible DXC SDK.

```sh
cmake -S . -B build/macos-libraries -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DDASSDL3_WITH_IMAGE=ON -DDASSDL3_WITH_TTF=ON -DDASSDL3_WITH_NET=ON \
  -DDASSDL3_WITH_MIXER=ON -DDASSDL3_WITH_SOUND=ON -DDASSDL3_WITH_IMGUI=ON \
  -DDASSDL3_WITH_SHADERCROSS=ON
cmake --build build/macos-libraries --target dasSDL3_libraries_runner --parallel 6
./build/macos-libraries/bin/dasSDL3_libraries_runner examples/libraries/05_ttf_gpu.das
```

The TTF GPU example chooses saved MSL fixtures on Metal, with `main0` entrypoints.
They are generated from the saved SPIR-V by the pinned shadercross CLI:

```sh
python3 tools/generate_macos_shaders.py
python3 tools/generate_macos_shaders.py --check
```

Native verification on Apple Silicon/macOS 15.3.1 passed 24 companion tests,
including ImGui input/widgets/lifetimes, TTF GPU draw data and CPU pixel oracles,
image IO, text shaping, loopback networking and dummy-driver audio decoding/mixing.
Dummy audio proves the memory/decoder contracts, not physical audio output.

## Installed C++ / AOT SDK

```sh
cmake -S . -B build/macos-sdk-build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=OFF -DDAS_TOOLS_DISABLED=ON -DDASSDL3_INSTALL_SDK=ON
cmake --build build/macos-sdk-build --target dasSDL3_aot --parallel 6
cmake --install build/macos-sdk-build --prefix "$PWD/build/macos-sdk" --component dasSDL3SDK
cmake -S build/macos-sdk/share/dasSDL3/examples/sdk-consumer -B build/sdk-example \
  -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$PWD/build/macos-sdk"
cmake --build build/sdk-example --parallel 6
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy ctest --test-dir build/sdk-example --output-on-failure
```

Interpreter, strict AOT and rejection of missing AOT registrations passed after
moving the installed prefix. Consumers need no LLVM/Python or source checkout.
The scripts/standard library remain runtime resources, as described in [SDK](sdk.md).
Only the arm64 SDK has been executed here; the x86_64 profile needs its own machine.

## Dynamic daspkg core / ImGui profiles

Use the matching dynamic SDK built from the pinned submodule, not the installed
static SDK above. Core needs `daslang`; ImGui also needs the SDK's dynamic
ImGui/Clipboard modules. Build SDK configurations sequentially because upstream
outputs share the submodule's `lib`, `bin` and module directories.

```sh
cmake --build build/macos-libraries --target daslang --parallel 6
cmake -S src/package -B build/macos-package -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DDASLANG_DIR="$PWD/third_party/daScript" \
  -DSDL3_DIR="$PWD/build/macos-libraries/_deps/sdl3-build" \
  -DDASSDL3_DASPKG_CLI_SUPPORT=ON -DDASSDL3_PACKAGE_IMGUI=ON
cmake --build build/macos-package --parallel 6
ctest --test-dir build/macos-package -R '^sdl3_daspkg_(manifest|consumer|source|repository_core|repository_imgui|imgui_binary|imgui_source)$' \
  --output-on-failure
```

The tests run the real upstream installer, compile all package imports, verify
rendered pixels and cleanup, then move the source package and consumer directory.
Source staging fingerprints headers and native dylibs and tests rejection of an
altered fingerprint before compilation. Package output paths use `.shared_module`
for both platforms; the Mac ImGui backend links the matching SDK module directly.

For binary staging, pass `--platform macos` to `tools/stage_daspkg.py`.
For a local source package and its SDK fingerprint:

```sh
python3 tools/stage_daspkg.py --source --platform macos \
  --sdk "$PWD/third_party/daScript" --with-imgui --output build/packages/dasSDL3
```

Direct repository installs on Mac require `DASSDL3_PACKAGE_SDK_FINGERPRINT`
to name that package's `sdk.sha256` and `DASSDL3_PACKAGE_PROFILE=core` or `imgui`.
Use a fingerprint staged with `--with-imgui` for the ImGui profile. The Windows
official SDK snapshots are preserved; an official Mac SDK archive has not been
validated. Standalone daspkg release packaging is described below.


## GPU examples

Examples 42–46, 48, 49 and 86 select saved MSL with `main0` on Metal.
The fixtures are regenerated by `tools/generate_macos_shaders.py`; ordinary
consumer builds need no shader compiler. GPU DSL examples 01–04 and the
application shader helper in `examples/gpu` use optional shadercross when the
native backend needs MSL or DXIL. Run them with `dasSDL3_libraries_runner` on
Metal. The core runner keeps direct SPIR-V independent of shadercross.

```sh
ctest --test-dir build/macos -R '^macos_metal_example_' --output-on-failure
ctest --test-dir build/macos-libraries -R '^(macos_metal_dsl_example_|shader_dsl_.*cross$)' --output-on-failure
```

Eight saved-MSL GPU examples and five shadercross CPU pixel/byte tests passed
on native Metal. All four DSL examples also passed after exposing the optional
shadercross import to generic callers.

All eleven advanced harnesses passed on native Metal, with the final three
stencil/shadow tests rerun after the fixes. The bgfx group covers metaballs, raymarch, mesh/resize,
instancing, normal mapping, HDR, SDF text, LOD, stencil and shadow volumes:

```sh
ctest --test-dir build/macos-libraries -R '^macos_metal_bgfx_' --output-on-failure
```

The reused CPU shadow-volume paths use the same three-lane normalization and
dot products as their independent reference, preserving exact geometry parity
on ARM and SSE. Metal stencil/debug volume passes use a negative depth bias
of 16 units to prevent coincident caps from producing self-shadowing through
CPU/GPU projection roundoff. Other backends retain their existing bias.
The translucent debug-overlay comparison on Metal additionally checks a
one-pixel neighbourhood in both directions, retaining the two-channel-value
colour tolerance and the 100-unmatched-sample budget. All ordinary shadow frames
retain the original per-pixel oracle, alongside cache equality, topology,
classification and scene-feature checks.

## Standalone .app bundles

Standalone compilation needs the matching LLVM runtime from the pinned SDK.
This is a separate build configuration; regular runners and installed consumers
remain LLVM-free. The pinned SDK fetches its matching LLVM runtime during this
configuration. Enable PUGIXML for daspkg's Info.plist writer.

```sh
cmake -S . -B build/macos-release -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=OFF -DDAS_LLVM_DISABLED=OFF -DDAS_PUGIXML_DISABLED=OFF \
  -DDASSDL3_WITH_IMGUI=ON
cmake --build build/macos-release --target daslang --parallel 6
# The pinned SDK's download step places LLVM.dll in the top-level lib directory.
export DAS_DLL_PATH="$PWD/lib"
third_party/daScript/bin/daslang third_party/daScript/utils/daspkg/main.das -- \
  release --root /path/to/installed/consumer --out "$PWD/build/release-out"
python3 tools/sign_macos_bundle.py build/release-out/sdl3_imgui_demo.app
```

The finalizer resolves native imports between nested modules using bundle-relative
`@loader_path` paths, moves license/version notices and the release manifest into
`Contents/Resources`, then seals the completed bundle with an ad-hoc signature.
The native executable and shared libraries remain in `Contents/MacOS`.
The ImGui release hook forces the SDK's `dasClipboard` shared module so daspkg
ships it under `modules/dasClipboard` and normalizes its Mach-O rpaths.
Windows retains its existing native DLL layout.

`tests/test_daspkg.py --release --llvm-dir lib` additionally checks `.app` metadata,
all native dependency/rpath entries, strict signatures after relocation, and
standalone execution with SDK/compiler search paths removed. Use
`--skip-missing-dependencies` during local runs to avoid the macOS crash dialogs
caused by deliberately hiding required libraries. The default retains those
negative isolation checks. Ad-hoc signing is for local execution; public
Mac distribution needs its own signing and notarization workflow.


Core and ImGui standalone apps passed relocation, native dependency/rpath audits,
and strict bundle signature verification. They also ran through native Cocoa;
the ImGui bundle verified 2926 bright pixels before releasing its resources.

## Live reload, HTTP/MCP and recording

The native live profile builds the pinned upstream host with Foundation and loads
SDL/ImGui, HTTP and STB as matching Mac `.shared_module` libraries. Build/run
commands and one-command APNG recording are in [the live guide](../examples/live/README.md#macos-build-and-run).
The ordinary development runner's lifecycle contract remains separate.

Headless Mac checks passed stdio state preservation/full reset, HTTP/MCP tool
discovery and commands, file watching, compile/runtime recovery, GUI pixel changes,
playwright scenarios and APNG frame-count/finalization checks. The launcher also
recorded 54 frames and verified exactly-once SDL cleanup. All eight CTest cases also passed through native Cocoa in a GUI login session.
The one-command launcher was checked headlessly, including immediate repeated
recording and rejection of an active listener on port 9090. Its Mac port probe
permits TCP TIME_WAIT from a previous recording.
The pinned stdio agent still reports the existing Channel/JobStatus/Feature leak;
SDL resources are released exactly once. HTTP transport reports no handle leaks.
The optional recording-port and visual-aids tests modify only disposable test
copies of upstream scripts, as on Windows; normal recording uses the pinned SDK.

## Companion strict AOT

`dasSDL3_macos_libraries_aot_tool` and `dasSDL3_macos_libraries_aot_runner` match
the enabled companion profile. Shared boost imports are discovered and included
in generation; source/import changes invalidate that source list and emitted code.
Run the `macos-libraries-aot` CTest label as described in [the library guide](../examples/libraries/README.md#native-mac-strict-aot).
The default shadercross example uses the committed SPIR-V fixture without DXC,
and still performs reflection/MSL translation; DXIL is requested only when supported.

Native verification on Apple Silicon/macOS 15.3.1 passed all 14 checks with
interpreter fallback disabled, including Metal SDL_ttf GPU text and ImGui
click coroutine yield/resume. Audio tests used the dummy driver; network tests
used loopback. The three affected interpreter checks also passed. The installed
no-LLVM SDK consumer passed interpreter, strict AOT and missing-AOT rejection
both before and after copying the SDK to a new prefix. Saved binding generation
and the 122-record/840-field policy audit remained current.

## Shader DSL and application strict AOT

With shadercross enabled, `dasSDL3_macos_shader_dsl_aot_runner` compiles the
shared Windows-parity source inventory against the native Mac binding. It also
includes the Mac backend-selection helper and follows shared boost imports.
Interpreter fallback is disabled. Source changes invalidate generated AOT code.

```sh
cmake --build build/macos-libraries --target dasSDL3_macos_shader_dsl_aot_runner --parallel 6
SDL_VIDEODRIVER=dummy ctest --test-dir build/macos-libraries -L 'macos-dsl-(headless|link)' --output-on-failure
# Ordinary Terminal in a GUI login session:
SDL_VIDEODRIVER=cocoa ctest --test-dir build/macos-libraries -L macos-dsl-native --output-on-failure
```

Headless checks execute resource metadata/lowering, std430 storage and std140
uniform byte contracts, plus missing-AOT rejection. Link checks load and simulate
each script with strict AOT policy, then verify its entry point without calling
it. They do not establish GPU execution. Native cases retain the existing CPU
pixel/byte oracles for five shadercross contracts, four DSL examples and eleven
application harnesses (SDF text requires TTF). Metal failures are not skipped.

On Apple Silicon/macOS 15.3.1 all 23 strict entry-point link checks, four
headless execution/negative checks and all 20 native Cocoa/Metal cases passed.
This includes five shadercross pixel/byte contracts, all four DSL examples and
eleven application harnesses, with interpreter fallback disabled. The existing
oracles remain unchanged. After updating the shared runner, 13 companion and
three restored core headless AOT regression checks also passed.
