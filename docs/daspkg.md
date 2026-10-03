# daspkg packages

## Platform readiness

The supported daScript client/source revision is
`ebac0ffe46ab30de6c9536f4b0af7a33ede45902`. Older SDKs, including the previous
reference and official v0.6.4 bundle, are no longer supported. Upstream still
reports `0.6.4`, so `package_min_sdk("0.6.4")` is only a version floor; exact
binary compatibility is checked by the SDK fingerprints.

The repository manifest declares `windows`, `darwin` and `linux`.
Linux supports core only; CMake rejects its ImGui profile. Staged binary/source
manifests declare the selected platform; the metadata regression checks these
lists for both core and ImGui. Native Mac packages require the matching locally
built dynamic SDK and fingerprint; see [Mac setup](macos.md).
There is no fallback for clients without platform metadata.

Windows validation on 2026-10-03 with this revision: root and staged binary/source
metadata for both profiles; core and ImGui native builds, actual daspkg
install/check, all included imports, source and repository installs,
relocation, rendering/resource cleanup and standalone releases with missing
dependency rejection. The core SDK mismatch negative test also passes.
The Windows runner passes 19 focused interpreter/API/lifecycle checks;
Linux passes all 15 `linux-core` interpreter/native/strict-AOT checks.
Both Windows generators pass deterministic freshness checks. Fifty focused
baseline/CppGenBind/strict-AOT tests pass, including native metadata parity,
generation errors and missing-AOT rejection. The relocated installed C++ SDK
also passes interpreter, strict AOT and missing-AOT checks with LLVM/Clang/Python
package discovery disabled. These are not hardware/API-wide runtime tests.

`.github/workflows/native.yml` runs the focused Windows tests plus core package
metadata/install/source/relocation checks and the Linux core and package suites. CI stages
against its own built SDK; exact reference binary fingerprints are checked
by the local repository-install tests. The initial hosted Linux run exposed
an implicit display requirement in the software-renderer test; that test now
explicitly uses SDL's dummy video driver.

| Package path | Platforms | Requirements |
| --- | --- | --- |
| Repository core / ImGui | `windows`, `darwin` | Matching native SDK fingerprint; MSVC x64 Release `/MD` AVX2 or native AppleClang Release |
| Repository core | `linux` | Ubuntu 24.04 x86_64, GCC 13.3, Release, exact SDK fingerprint |
| Staged binary / source | Selected `windows`, `darwin` or `linux` | Matching native dynamic SDK; source staging records its fingerprint |

Linux core checks cover actual binary/source/repository installation, all 63
boost imports, rendering with the dummy driver, package and SDK relocation,
SDK mismatch rejection, ELF path auditing and missing-runtime rejection.
Linux ImGui, standalone release, other distributions and architectures are not
validated. This dynamic daScript SDK is distinct from the installed dasSDL3 C++/AOT SDK.

## Linux core workflow

Use the pinned revision and install the dependencies from [Linux setup](linux.md).
Build a local SDK (a new output directory is required):

```sh
cmake -S . -B build/linux -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DDAS_ENABLE_PIC=ON -DDAS_PUGIXML_DISABLED=OFF
python3 tools/prepare_linux_daspkg_sdk.py --build build/linux --output build/linux-sdk
cmake -S src/package -B build/linux-package -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DDASLANG_DIR="$PWD/build/linux-sdk" -DDASSDL3_PACKAGE_FETCH_SDL=ON
cmake --build build/linux-package --parallel 6
ctest --test-dir build/linux-package --output-on-failure -R '^sdl3_daspkg_(manifest|consumer|source)$'
python3 tests/test_linux_daspkg_sdk.py --sdk build/linux-sdk \
  --module build/linux-package/module/dasSDL3.shared_module
```

The preparation script uses upstream installation and adds the complete pinned
public header tree: upstream's explicit install list omits transitive headers
such as `misc/das_asan.h`. No dependency sources are patched.

For your own SDK build, stage a source package with its exact fingerprint:

```sh
python3 tools/stage_daspkg.py --source --sdk build/linux-sdk --output build/linux-source/dasSDL3
```

Run the CLI script from the SDK root, or pass its full path and `-dasroot`:

```sh
build/linux-sdk/bin/daslang -dasroot "$PWD/build/linux-sdk" \
  build/linux-sdk/utils/daspkg/main.das -- install "$PWD/build/linux-source/dasSDL3" --root /path/to/consumer
```

For binary staging, replace `--source` with
`--module build/linux-package/module/dasSDL3.shared_module`.
The `.shared_module` suffix is intentional on Linux. Static SDL is built with PIC;
modules use `$ORIGIN`, and SDK `bin/daslang` uses `$ORIGIN/../lib`.
Runtime system libraries (glibc/libstdc++ and SDL platform dependencies) are not bundled.

Repository installs require the exact reference SDK described in
`src/package/profiles/reference-sdk-linux.json`; rebuilding the same source is
not guaranteed to reproduce its binary hashes. Download the [Linux reference SDK](https://github.com/spiiin/dasSDL3/releases/tag/sdk-ebac0ffe-linux-x86_64-r1)
and verify its archive checksum against the JSON descriptor. Linux core support is available on `main`. Use local source staging for your own SDK builds. `stage_reference_sdk.py` creates `tar.gz`, preserving
permissions and symlinks, and verifies the committed Linux fingerprint first.

## Existing Windows package workflow

### Download the supported SDK

Use the [reference SDK archive](https://github.com/spiiin/dasSDL3/releases/tag/sdk-ebac0ffe-windows-x64-r1).
It contains the exact runtime DLLs/import libraries/headers accepted by both
repository fingerprints, plus daslang, scripts and PUGIXML for the package CLI.
It is a focused SDK distribution, separate from the dasSDL3 release.

```powershell
curl.exe --fail --location --output sdk.zip https://github.com/spiiin/dasSDL3/releases/download/sdk-ebac0ffe-windows-x64-r1/dasSDL3-sdk-ebac0ffe-windows-x64-r1.zip
if ($LASTEXITCODE) { throw "SDK download failed" }
if ((Get-FileHash sdk.zip -Algorithm SHA256).Hash.ToLower() -ne "a268a7607f2879cc6edf77246e726dde6f08e45bad36ee59ae7925cef40389e5") { throw "SDK hash mismatch" }
Expand-Archive sdk.zip -DestinationPath reference-sdk
```

The SDK root is `reference-sdk/dasSDL3-sdk-ebac0ffe-windows-x64-r1`.
Run its `bin/daslang.exe utils/daspkg/main.das -- ...` from that root;
this archive needs no extra `-load_module` CLI helper. Install source packages
from a VS x64 developer shell with CMake and Ninja on PATH. Keep the archive's
directory layout intact. Its per-file `SDK-SHA256.json` also covers the included
notices. The archive URL, checksum and source revision are recorded in
`src/package/profiles/reference-sdk.json`.

Maintainers can stage another accepted build with
`python tools/stage_reference_sdk.py --sdk <built-sdk> --output <new-directory>`.
Staging verifies both checked-in fingerprints before copying any files.
The input must also provide the built PUGIXML module in its standard SDK path.

### Local builds

Local binary/source staging remains available. A root .das_package and a
consumer-SDK CMake entry point are now prepared for direct repository installs.
The core package contains SDL 3.4.16 statically
linked into dasSDL3.shared_module and 63 core boost scripts.
The interpreter discovers .das_module in the consumer's modules/dasSDL3;
scripts use ordinary require dassdl3/..., without an SDL-specific host or
-load_module flag.

Supported SDK: the reference DLL build of daScript `ebac0ffe46ab30de6c9536f4b0af7a33ede45902`.
The checked-in core and ImGui fingerprints identify complete SDK builds.
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

- Broaden SDK coverage only after validating each additional build. Older
  reference and official SDK profiles are not accepted.
- Define companion-library and live/widgets-v2 profiles separately, with their
  feature-specific dependency notices. Core and ordinary ImGui are covered below.
- Separate Windows execution now passes (user-reported core/GUI verification).
  A pristine VM and interactive/hardware rendering remain separate checks.
- Register in the package index only on an explicit publication request.

The root .das_package now selects cmake_build(). When daspkg supplies DASLANG_DIR,
the root CMake file takes the dedicated package entry and skips the developer SDK.

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
It uses the SDK ImGui binary rather than rebuilding or embedding that module. A source-only dasImgui directory is insufficient: CMake explicitly checks
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
sources and obtains unchanged ImGui backends from the matching built SDK.
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

## Direct repository installation (prepared, not published)

The root manifest declares github.com/spiiin/dasSDL3. With no explicit version,
resolve selects main; a requested version maps to v<version>. No release tag or
public package-index entry is created by this work. Until the entry files are
committed and pushed, test the prepared local source/export instead of assuming
the current remote branch contains them.

After publication, from a VS x64 developer PowerShell, using the same SDK:

~~~powershell
$env:CMAKE_GENERATOR = "Ninja"
$env:DASSDL3_PACKAGE_PROFILE = "core"
C:/path/to/daslang/bin/daslang.exe C:/path/to/daslang/utils/daspkg/main.das -- install github.com/spiiin/dasSDL3 --root C:/my-project
~~~

For GUI, set DASSDL3_PACKAGE_PROFILE to imgui before installation instead.
The manifest then declares the SDK dasImgui dependency, and CMake builds the
combined SDL + ImGui module. Use the matching built SDK; the minimal SDK's daspkg
CLI still needs the PUGIXML -load_module helper described above. Keep the profile
environment setting for subsequent package rebuilds; an unset value means core.
Only core/imgui are accepted by CMake; both require the pinned built SDK.

The upstream package manager supplies DASLANG_DIR. That routes root CMake to
src/package/repository.cmake before any bundled daScript configuration. Package
installation needs no initialized third_party submodule. Without DASLANG_DIR the
existing developer build stays unchanged. SDL is fetched unless SDL3_DIR selects
an existing exact-version static build.

The repository ships fixed fingerprints under src/package/profiles/: core.sha256
and imgui.sha256 for the reference SDK. Each profile must match in full. These hashes are not derived from the SDK being installed
against. Arbitrary releases/rebuilds remain rejected. ImGui's native
headers/sources/import library/module are covered in its local profile.

A build target depending on the native module installs .das_module at package
root, using project-relative registration paths. It also restores the descriptor
on an incremental build that does not relink the DLL. Core excludes unsupported companion/live/shader modules;
imgui additionally registers sdl3_imgui and its native backend. Build outputs
are ignored by Git.

Reproducible entry-point tests:

~~~powershell
cmake -S src/package -B build/daspkg-native
ctest --test-dir build/daspkg-native -R "^sdl3_daspkg_repository_" --output-on-failure
~~~

Run in a VS x64 developer shell. The tests use a clean git archive of HEAD,
overlay only the pending package entry files, and invoke real daspkg local
installation through the root manifest. No commit is created. They check source
build, script execution, GUI pixels (imgui) and relocation, with no SDK binaries
or prebuilt binding in the source export. This tests the repository layout/build
route; it is not a live GitHub URL installation. The separate network test above
already covers SDL download, so these tests reuse the existing SDL build.

## Licenses in packages and releases

Original dasSDL3 code is licensed under [MIT](../LICENSE). The root and staged
package manifests declare package_license("MIT"). Third-party code keeps its own
license; see the [notice inventory](../licenses/README.md) and its provenance/hash
manifest. This covers the pinned Windows core/ImGui profiles, including SDL's
bundled code, the daScript runtime dependencies, ImGui/default fonts, Clipboard
and FreeType. The FreeType acknowledgment is part of the shipped documentation.

Both binary and source staging include LICENSE and the complete licenses/
directory. The repository entry carries the same files without needing initialized
submodules. The package's release() hook ships them into
modules/dasSDL3/LICENSE and modules/dasSDL3/licenses/ in the standalone bundle.
Keep those files with the application. License files contain third-party terms;
shipping a notice does not imply that every listed component is enabled.

The install/relocation and standalone release tests compare every notice byte for
byte and validate the snapshot SHA-256 values. Dependency upgrades require a
review of these texts and their provenance. Optional companion libraries and
live/HTTP are not covered by this package profile; see the scope in licenses/README.md.
The static SDK install also includes the project LICENSE and curated notice set
under share/dasSDL3; this packaging change does not reconfigure the developer SDK.

## Verification on a separate Windows host

The recorded 2026-09-28 results below used the previous SDK. They do not
validate the updated SDK; the portable verification workflow remains available.

Prepare a portable kit from the two generated release directories:

~~~powershell
python tools/stage_windows_verification.py --core build/release-ready --imgui build/gui-release-ready --output build/windows-check
~~~

Choose a new output path; the stager refuses to overwrite the directory or its
adjacent ZIP. It verifies the expected native dependencies and current notices,
copies both profiles, omits link maps, and records SHA-256 for every payload file.
The ZIP contains the runner and needs no Python, SDK, LLVM, compiler or Git on
the target. Windows x64, AVX2 and the Microsoft VC runtime remain prerequisites.
The kit does not download or install prerequisites.

Transfer and extract the ZIP on a separate Windows machine or clean VM. From the
extracted directory, use 64-bit Windows PowerShell:

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\verify.ps1 -RunLabel "clean Windows VM"
~~~

The execution-policy override applies to this invocation only. The runner checks
file hashes (including licenses), creates an empty working directory per case,
clears inherited application environment variables and restricts PATH to System32.
Core must render and release its resources; GUI must additionally verify widget
pixels. Each process has a 30-second timeout. A new TEMP directory contains
report.json and core.log/imgui.log; its path is printed. Any failed check returns 1.
-OutputDirectory may specify a new report directory instead.

RunLabel is a human description, not certification of host isolation. The current
local test only validates the runner after ZIP extraction, plus deliberate
license corruption rejection. A user-reported separate-machine run also passed
(see below); Windows Sandbox was not found on the development host. Archive hashes detect accidental
changes, not authenticity. Hardware rendering, interactive input and Web are
outside this automatic dummy-driver check.

For a separate interactive check, launch imgui/sdl3_imgui_demo.exe and exercise
the counter, demo toggle, window resize and Escape. Keep the automated report and
record the Windows/VC runtime environment and interactive observations.

### Separate-machine result (2026-09-28)

The user ran windows-verification-ready on another Windows host from Downloads
using Windows PowerShell. Supplied console output reported:

~~~text
core : success=True, exit=0, timeout=False
imgui : success=True, exit=0, timeout=False
PASS: file hashes, core rendering, GUI pixels and resource cleanup.
~~~

This closes the separate-machine execution check for the tested core/ImGui kit.
Evidence is the user-supplied console transcript; report.json and profile logs
were generated on that host but have not been inspected here. The transcript
does not establish the installed SDK/tooling inventory, exact Windows/VC runtime
versions, or a pristine VM. Interactive input and hardware rendering were not
part of this dummy-driver run.

## Prepared release 0.1.0

See [draft release notes](releases/0.1.0.md) and the
[publication handoff](releases/publishing.md). VERSION defines the release number;
daspkg resolves explicit @0.1.0 through the future v0.1.0 tag. No tag or index
entry has been created. Manifest validation runs without publishing anything.

## Native macOS packages

Core and ImGui packages use native AppleClang Release builds, Mac ABI bindings
and dylib/shared-module linkage. Source staging uses `--platform macos`;
repository installs require `DASSDL3_PACKAGE_SDK_FINGERPRINT` and the matching
`DASSDL3_PACKAGE_PROFILE=core` or `imgui`. Windows fingerprints and the
Windows reference SDK download do not apply to native Mac binaries.

The earlier Mac package, live and standalone validations used the previous
35bf260 SDK. After merging the ebac0ffe SDK update, native core/ImGui modules were rebuilt.
All seven headless package checks passed: metadata (root and staged platforms),
binary/source consumers, repository core/ImGui installs, SDK fingerprint
rejection and relocation. Prior standalone bundles remain artifacts of their
original SDK revision; native GPU/live/standalone execution must be rerun
separately for ebac0ffe. See [Mac setup](macos.md).
