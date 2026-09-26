# Installed core SDK

Windows x64, MSVC, Ninja single-config Release, /MD only. Core SDL 3.4.16 and
pinned daScript are static; companion libraries are not part of this profile.
The SDK contains C++ libraries/headers, daScript modules, standard library,
licenses, CMake targets and a native AOT generator. No LLVM/Python is needed by
consumers. The SDK is relocatable; use the relocated prefix at configure time.

Build the core with BUILD_TESTING=OFF, DASSDL3_INSTALL_SDK=ON, all
DASSDL3_WITH_* options OFF, DAS_CLANG_BIND_DISABLED=ON and DAS_LLVM_DISABLED=ON.
For a fresh build directory, run from a VS x64 developer shell:

```powershell
cmake -S . -B build/sdk -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DDASSDL3_INSTALL_SDK=ON -DDASSDL3_ENABLE_GENERATORS=OFF -DDAS_CLANG_BIND_DISABLED=ON -DDAS_LLVM_DISABLED=ON
cmake --build build/sdk --target dasSDL3_aot --parallel 6
cmake --install build/sdk --prefix C:/sdk/dasSDL3 --component dasSDL3SDK
cmake -S C:/sdk/dasSDL3/share/dasSDL3/examples/sdk-consumer -B build/consumer -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=C:/sdk/dasSDL3
cmake --build build/consumer --parallel 6
ctest --test-dir build/consumer --output-on-failure
```

Consumers use find_package(dasSDL3 CONFIG REQUIRED) and dasSDL3::dasSDL3.
The example host accepts a script and SDK data directory at runtime. AOT adds
--aot and disables interpreter fallback. It still loads the source script and
standard library to compile/link AOT registrations; this is not a standalone
source-free executable. Copy these resources with your application.

dassdl3_add_aot(target SCRIPTS ... MODULES ...) compiles application scripts and
explicit shared modules. List every shared module used transitively (see sample).
DEPENDS accepts extra local imports/assets that should trigger regeneration.
AOT output is linked directly, avoiding discarded static registration objects.
The installed tool takes input.das output.cpp SDK_DATA_DIR. Pinned catch-order
lowering matches the existing parity compiler; no SDL wrapper catches errors.

Debug, DLL ABI, other compilers/platforms and installed companion libraries
remain separate work. Use the matching MSVC runtime; Windows system DLLs and
the Microsoft VC runtime remain platform prerequisites.

The SDK exposes its bundled dependencies under dasSDL3::, including libDaScript
and SDL3-static. Do not link a second independent copy of either runtime into the
same executable. The AOT generator runs on the build machine; cross-compilation
is not part of this profile. CMake rejects Debug, /MT, non-MSVC and non-x64 usage.

The `examples/sdk-consumer` project has three CTest
checks: interpreter, strict AOT and rejection of a missing AOT registration.
