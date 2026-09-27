# Local daspkg core pilot

Two local profiles are available: a **prebuilt binary package** and a **source
package built by daspkg against an explicitly fingerprinted SDK**. Neither is
published in the package index or directly installable from the repository URL. It contains SDL 3.4.16
statically linked into dasSDL3.shared_module and 63 core boost scripts.
The interpreter discovers .das_module in the consumer's modules/dasSDL3;
scripts use ordinary require dassdl3/..., without an SDL-specific host or
-load_module flag.

Supported/tested: Windows x64, MSVC Release, /MD, AVX2, matching daScript DLL SDK
at commit 35bf260c0d8a79b94c64005bd3d2435adcf7e261.
Do not load it into an unrelated SDK binary: matching source revision alone
does not guarantee DLL ABI/configuration compatibility. The SDL DLL is not needed;
the interpreter still needs its own daScript DLLs and VC runtime.

The static C++/AOT [installed SDK](sdk.md) remains a separate profile.
The default core profile excludes SDL_image/ttf/mixer/net/sound/shadercross,
ImGui, shader DSL and live demo code. An opt-in SDL + ImGui variant is described
below; other companions and live still need separate profiles.

## Build and test

From the repository root in a VS x64 developer shell, using the existing built
SDL and daScript SDK (no SDK reconfiguration, network fetch or code generation):

~~~powershell
cmake -S src/package -B build/daspkg-native -G Ninja -DCMAKE_BUILD_TYPE=Release -DDASLANG_DIR=C:/src/dasSDL3/third_party/daScript -DSDL3_DIR=C:/src/dasSDL3/build/ninja/_deps/sdl3-build -DDASSDL3_DASPKG_CLI_SUPPORT=ON
cmake --build build/daspkg-native --parallel 6
ctest --test-dir build/daspkg-native -R sdl3_daspkg_consumer --output-on-failure
~~~

DASSDL3_DASPKG_CLI_SUPPORT builds the unmodified upstream PUGIXML sources into
build/daspkg-native/cli, because upstream daspkg imports PUGIXML even for local
installs and our minimal SDK omits it. A complete SDK already providing PUGIXML
can leave this option OFF and omit the CLI-only -load_module argument below.
PUGIXML is not bundled in the SDL package or required by the SDL consumer.

The test invokes the real upstream daspkg install and check, executes the
consumer with SDL's dummy video driver, checks that SDL is shut down, then moves
both the package source and installed project and executes the relocated project.
Directories contain spaces. Logs and artifacts remain in a unique
build/daspkg check ... directory. This validates local discovery/relocation and
software rendering, not GPU hardware or Web support. Standalone release has a
separate optional test described below.

## Prepare and install locally

Run from the repository root. Choose new/empty directories; staging refuses to
overwrite an existing package.

~~~powershell
python tools/stage_daspkg.py --module build/daspkg-native/module/dasSDL3.shared_module --output build/packages/dasSDL3
New-Item -ItemType Directory -Path build/package-demo
Copy-Item examples/daspkg-consumer/main.das build/package-demo/main.das
.\third_party\daScript\bin\daslang.exe -dasroot third_party/daScript -load_module build/daspkg-native/cli third_party/daScript/utils/daspkg/main.das -- install C:/src/dasSDL3/build/packages/dasSDL3 --root C:/src/dasSDL3/build/package-demo
~~~

Then launch **from the consumer directory**, so the ordinary interpreter discovers
its modules directory:

~~~powershell
Set-Location C:/src/dasSDL3/build/package-demo
C:/src/dasSDL3/third_party/daScript/bin/daslang.exe -dasroot C:/src/dasSDL3/third_party/daScript main.das
~~~

The example creates a hidden window, clears/presents once and releases resources.
The generated .das_package uses no_build() because this is a prebuilt package.
profile.json records the required ABI profile, module hash and included scripts;
it is descriptive, not an automatic runtime ABI check. Registration paths use
project_path, with no absolute repository paths. Staging verifies the closure
of core dassdl3/ imports.

## Before public distribution

- Define the project's license (there is no root LICENSE yet), and include all
  applicable third-party license notices in the distributable.
- Generalize SDK compatibility beyond the exact reference snapshot after validating
  additional SDK builds. Do not let daspkg install this repository's existing root
  CMake project as if it were the staged source package.
- Define companion-library and live/ImGui profiles separately.
- Validate the release on a clean Windows machine; local relocation and dependency
  isolation checks pass, but do not replace a separate-machine test.
- Register in the package index only on an explicit publication request.

No root .das_package is added yet: that would misleadingly advertise the whole
repository as installable through daspkg's default source-build path.

## Source package

The source profile copies native adapters, checked-in generated bindings and
the core scripts. It carries no prebuilt SDL binding. Its manifest calls
cmake_build(); upstream daspkg supplies DASLANG_DIR pointing to the interpreter's
SDK. LLVM, a shader compiler and Python are not required during installation.
Python is used only to stage the package.

From a VS x64 developer PowerShell (Ninja and CMake on PATH):

~~~powershell
python tools/stage_daspkg.py --source --sdk third_party/daScript --output build/source-packages/dasSDL3
$env:CMAKE_GENERATOR = "Ninja"
$env:SDL3_DIR = "C:/src/dasSDL3/build/ninja/_deps/sdl3-build"
New-Item -ItemType Directory -Path build/source-demo
Copy-Item examples/daspkg-consumer/main.das build/source-demo/main.das
.\third_party\daScript\bin\daslang.exe -dasroot third_party/daScript -load_module build/daspkg-native/cli third_party/daScript/utils/daspkg/main.das -- install C:/src/dasSDL3/build/source-packages/dasSDL3 --root C:/src/dasSDL3/build/source-demo
Set-Location C:/src/dasSDL3/build/source-demo
C:/src/dasSDL3/third_party/daScript/bin/daslang.exe -dasroot C:/src/dasSDL3/third_party/daScript main.das
~~~

With no SDL3_DIR supplied, CMake uses FetchContent to obtain SDL release-3.4.16
from the official Git repository and builds it statically. This requires network
access and Git. With SDL3_DIR it requires exactly 3.4.16 and the static target.
The default source integration test reuses the existing SDL build. A separate
opt-in network test downloads and builds SDL from scratch (see below).
Ninja compile concurrency is capped at six even when daspkg passes --parallel.

sdk.sha256 contains fingerprints of reference SDK headers (including fmt),
import libraries and both daScript runtime DLLs. CMake rejects missing or changed
files before fetching SDL or compiling. An identical SDK at a different path is
accepted. This deliberately strict check also rejects compatible rebuilds with
different binary hashes; it is not general ABI inference or a signature proving
the SDK's provenance. The stager records the SDK supplied by the caller, so use
the validated pinned SDK. Changes to the runtime after installation require
reinstallation; there is no runtime fingerprint enforcement in .das_module.

The binary profile remains available. Source integration test:

~~~powershell
ctest --test-dir build/daspkg-native -R sdl3_daspkg_source --output-on-failure
~~~

Run this test from a VS x64 developer shell. It stages a source-only package,
checks rejection of a deliberately mismatched SDK fingerprint, installs/builds
through upstream daspkg, checks the lockfile and runs the consumer before and
after relocation. Test output is retained in build/daspkg check ... .

## Standalone release (Windows)

The consumer example now has a .das_package release hook. Upstream daspkg release
generates an EXE and collects the SDL shared module and both daScript runtime DLLs.
No interpreter executable, .das sources or LLVM is required in that output.

**Building** this release does require LLVM: daslang -exe uses LLVM code generation,
unlike ordinary script execution and package installation. The minimal SDK can
stay unchanged. The tools used here are the official daScript prebuilt LLVM
22.1.5 Windows archive, with the hash pinned by this SDK's dasLLVM/CMakeLists.txt:

~~~powershell
New-Item -ItemType Directory -Force build/release-tools
curl.exe --fail --location --output build/release-tools/win64_llvm.tar.gz https://github.com/GaijinEntertainment/daScript/releases/download/llvm-v22.1.5/win64_llvm.tar.gz
$hash = (Get-FileHash build/release-tools/win64_llvm.tar.gz -Algorithm SHA256).Hash.ToLower()
if ($hash -ne "7f67cbfa1b8196d13b020f8fea721c4c586204b3d0f9f0c73b289514a888c899") { throw "LLVM archive hash mismatch" }
tar -xf build/release-tools/win64_llvm.tar.gz -C build/release-tools
~~~

In a VS x64 developer shell, enable and run the release check:

~~~powershell
cmake -S src/package -B build/daspkg-native -DDASSDL3_RELEASE_LLVM_DIR=C:/src/dasSDL3/build/release-tools
cmake --build build/daspkg-native --parallel 6
ctest --test-dir build/daspkg-native -R sdl3_daspkg_release --output-on-failure
~~~

The test uses the real upstream package manager. It builds the release from an
installed package, moves the consumer away from its original build-time path and
copies only the distribution into a new directory under Windows TEMP, outside
the repository. The EXE runs from an empty working directory with PATH restricted
to System32 and no inherited DAS/SDK/compiler environment. It must render once
and report successful resource cleanup.

Three negative runs each hide one required component: libDaScriptDyn.dll,
libDaScriptDyn_runtime.dll, dasSDL3.shared_module. Each must fail instead of
silently finding it in the developer SDK. The test restores the files and leaves
the runnable bundle in TEMP; the exact path and logs appear in CTest output.
This is a local isolation check on the development machine, not a clean Windows VM.
Windows and the VC runtime remain prerequisites.

For an existing consumer, copy examples/daspkg-consumer/.das_package beside
main.das, then invoke release from that consumer directory. PowerShell example:

~~~powershell
$env:DAS_DLL_PATH = "C:/src/dasSDL3/build/release-tools"
$env:PATH = "C:/src/dasSDL3/build/release-tools;" + $env:PATH
C:/src/dasSDL3/third_party/daScript/bin/daslang.exe -dasroot C:/src/dasSDL3/third_party/daScript -load_module C:/src/dasSDL3/build/daspkg-native/cli C:/src/dasSDL3/third_party/daScript/utils/daspkg/main.das -- release --root . --out C:/src/dasSDL3/build/my-release
~~~

Ship the entire resulting sdl3_package_demo directory, not only the EXE.
The example is intentionally a hidden one-frame software-rendering smoke test.

### Registration regression found by release

Small C unsigned arguments are promoted to script uint in the native binding.
Previously, this changed the signature after insertion into the function index
without updating its mangled key. Ordinary interpretation worked, but standalone
initialization could not resolve SDL_SetRenderDrawColor. Registration now refreshes
changed keys and recomputes the built-in signature fingerprint. Public argument
types and native SDL calling conventions remain unchanged.

## Cold SDL download and build

The optional network test creates a new package consumer and removes inherited
SDL3/FETCHCONTENT environment overrides and CMAKE_PREFIX_PATH. It invokes the
same upstream daspkg install as a normal consumer, with no SDL3_DIR. CMake
downloads the official SDL release-3.4.16 Git tag and builds the static library
in the installed package's own _build/_deps directory.

From a VS x64 developer shell:

~~~powershell
cmake -S src/package -B build/daspkg-native -DDASSDL3_DASPKG_NETWORK_TESTS=ON
ctest --test-dir build/daspkg-native -R "^sdl3_daspkg_source_fetch$" --output-on-failure
~~~

This test is off by default in a fresh CMake configuration and carries the
network label. It requires Git and GitHub access and can take several minutes.
Once enabled, exclude network tests from ordinary runs with ctest -LE network,
or configure DASSDL3_DASPKG_NETWORK_TESTS=OFF again.

In addition to the source-package SDK rejection/install/check/relocation tests,
it verifies that the installed project contains its own SDL Git checkout and
SDL3-static.lib, that HEAD is the pinned release tag, and that origin is the
official SDL repository. The resolved commit is printed in the test log.
The daScript SDK itself is still the previously built reference SDK; this test
does not bootstrap a compiler or SDK on a clean machine.

## SDL + dasImgui profile

This is an alternative profile of the **same dasSDL3 package**, not a second
co-installable SDL runtime. Core bindings, the ImGui SDL platform backend and
SDLRenderer3 backend share one native module and one static SDL instance.
Use either core or GUI in a given consumer; do not install both variants under
different directory names.

The GUI profile adds sdl3_imgui (64 boost modules total), declares a dasImgui
dependency and uses the already built matching SDK dasImgui module/import library.
It does not build Dear ImGui from scratch or embed the upstream module in this
package. A source-only dasImgui directory is insufficient: CMake explicitly checks
that the SDK has its compiled module and import library.
ImGui widgets-v2/live helpers are excluded from this profile.

Build the variant in its own directory from a VS x64 developer shell:

~~~powershell
cmake -S src/package -B build/daspkg-imgui -G Ninja -DCMAKE_BUILD_TYPE=Release -DDASLANG_DIR=C:/src/dasSDL3/third_party/daScript -DSDL3_DIR=C:/src/dasSDL3/build/ninja/_deps/sdl3-build -DDASSDL3_PACKAGE_IMGUI=ON -DDASSDL3_DASPKG_CLI_SUPPORT=ON
cmake --build build/daspkg-imgui --parallel 6
ctest --test-dir build/daspkg-imgui -R "^sdl3_daspkg_imgui_" --output-on-failure
~~~

Stage a binary GUI package:

~~~powershell
python tools/stage_daspkg.py --module build/daspkg-imgui/module/dasSDL3.shared_module --with-imgui --sdk third_party/daScript --output build/gui-packages/dasSDL3
~~~

Or stage the source version (choose a separate new destination):

~~~powershell
python tools/stage_daspkg.py --source --with-imgui --sdk third_party/daScript --output build/gui-source-packages/dasSDL3
~~~

The source fingerprint additionally covers upstream ImGui C++ headers/sources,
the SDK ImGui module and import library. The package copies our SDL adapter
sources but obtains the unchanged ImGui backend sources from the matching SDK.
Its CMake flags match the pinned SDK's wchar32/FreeType configuration.

Install and run the binary version:

~~~powershell
New-Item -ItemType Directory -Path build/gui-package-demo
Copy-Item examples/daspkg-imgui-consumer/main.das build/gui-package-demo/main.das
.\third_party\daScript\bin\daslang.exe -dasroot third_party/daScript -load_module build/daspkg-imgui/cli third_party/daScript/utils/daspkg/main.das -- install C:/src/dasSDL3/build/gui-packages/dasSDL3 --root C:/src/dasSDL3/build/gui-package-demo
Set-Location C:/src/dasSDL3/build/gui-package-demo
C:/src/dasSDL3/third_party/daScript/bin/daslang.exe -dasroot C:/src/dasSDL3/third_party/daScript main.das
~~~

The interactive example supports clicking the counter, toggling the Dear ImGui
demo, moving the panel and resizing the window. Escape exits. It adapts the
existing libraries/01_imgui example without renumbering or changing it.
Append -- --smoke to run three hidden frames, read back pixels and verify visible
text/widgets, then check that SDL resources have been released.

Both package tests exercise actual daspkg install/check, pixel verification and
relocation. They use the dummy video driver/software rendering, not hardware
GPU validation or an automated interaction test. Standalone GUI shipping is covered by the separate release test below.

## Standalone GUI release

The GUI consumer has its own .das_package and produces sdl3_imgui_demo.exe.
Upstream release discovers dasImgui, but the pinned SDK's ImGui DLL also imports
dasModuleClipboard.shared_module as a native dependency. The example release hook
uses release_include_from to copy Clipboard beside the EXE, where the Windows
loader can resolve it. This is not a dependency patch or a new script API.

Using the separately prepared LLVM tools above, from a VS x64 developer shell:

~~~powershell
cmake -S src/package -B build/daspkg-imgui -DDASSDL3_RELEASE_LLVM_DIR=C:/src/dasSDL3/build/release-tools
ctest --test-dir build/daspkg-imgui -R "^sdl3_daspkg_imgui_release$" --output-on-failure
~~~

The verified GUI distribution contains:

- sdl3_imgui_demo.exe
- libDaScriptDyn.dll and libDaScriptDyn_runtime.dll
- dasModuleClipboard.shared_module beside the EXE
- modules/dasSDL3/dasSDL3.shared_module
- modules/dasImgui/dasModuleImgui.shared_module

Transfer the whole directory. It needs neither daslang.exe, .das scripts nor LLVM.
Windows and the Microsoft VC runtime remain prerequisites.

~~~powershell
C:\src\dasSDL3\build\gui-release-ready\sdl3_imgui_demo.exe
~~~

With no arguments this is the interactive GUI. With --smoke it checks three hidden
frames including widget pixel readback, then exits.

**Isolation detail:** the pinned standalone runtime can fall back to build-time
module paths when a bundled module is absent. The test shadows SDK ImGui with
an identical copy inside its disposable consumer before release, then moves that
consumer away. The build-time ImGui path is therefore unavailable. The runtime SDK
itself is not moved or modified. This is test isolation, not a change to upstream
fallback behavior. The copied distribution runs outside the repository, from an
empty working directory with a clean environment; removing any of the five native
dependencies listed above must fail. This does not replace a clean Windows VM test.

For your own GUI consumer, copy examples/daspkg-imgui-consumer/.das_package beside
main.das and run daspkg release as in the core instructions. The name changes to
sdl3_imgui_demo. The transient local ImGui copy is only needed by the strict
negative isolation test, not by normal release packaging.
