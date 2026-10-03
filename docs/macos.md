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
- The binding and its C++ consumers use `-fno-rtti` to match the pinned runtime.
- Vulkan needs a separately installed loader/MoltenVK. Native Metal works through
  SDL GPU; SPIR-V/DXIL shader assets do not become Metal shaders automatically.
  Shader-based examples need MSL/Metallib assets or optional shader translation.
- The installed SDK and daspkg package profiles still have their documented
  Windows restrictions. This native checkout profile does not change them.

## Development checks

```sh
cmake --build build/macos --target dasSDL3_macos_aot_runner --parallel 6
ctest --test-dir build/macos -R '^macos_' --output-on-failure
```

The Mac test group runs real Metal transfer/readback, texture/format, volume,
fence and swapchain contracts, MSL triangle pixels in interpreter/strict AOT,
and strict AOT HID/peripheral coverage. Unavailable Metal
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
