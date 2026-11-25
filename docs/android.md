# Android arm64

The core CMake target `dasSDL3` links the pinned daScript runtime and SDL 3.4.16.
The example in `android/` builds an SDLActivity APK for `arm64-v8a`, minimum
API 28 (Android 9), with a target SDK of 35. Its interpreter reads the packaged
daslib and dasSDL3 script modules through SDL. Its strict AOT code is generated
on the development computer and compiled with the Android NDK.

Verified on 2026-11-25 on a physical Redmi Note 13 (23124RA7EO), Android 15
(API 35), via wireless ADB. SDL selected the Android video driver and the
`opengles2` renderer. The device reported:

```text
dasSDL3 Android interpreter RGB (24, 96, 64) PASS
dasSDL3 Android strict AOT RGB (24, 96, 192) PASS
dasSDL3 Android missing AOT rejected
dasSDL3 Android smoke PASS
```

## Windows development environment

Use Visual Studio 2022 x64 with C++ build tools, Ninja, Android Studio's JDK 17
and the Android SDK command-line tools. Set `ANDROID_HOME` to the SDK and
`JAVA_HOME` to the JDK, or pass `-AndroidSdk` and `-JavaHome` to the build script.
Install the SDK packages from PowerShell:

```powershell
& "$env:ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager.bat" 'platform-tools' 'platforms;android-35' 'build-tools;35.0.1' 'cmake;3.31.6' 'ndk;28.2.13676358'
```

From an x64 VS developer shell at the repository root, build the Windows AOT
emitter. This target uses the committed CppGenBind snapshot:

```powershell
git submodule update --init --recursive
cmake -S . -B build/android-host -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DDASSDL3_FORGE_AOT=ON
cmake --build build/android-host --target forge_aot_tool --parallel 6
```

## Build and run on a phone

Enable USB debugging on the phone, connect it by USB and accept the computer's
RSA prompt on its unlocked screen. Check that ADB lists the phone as `device`.

```powershell
& "$env:ANDROID_HOME/platform-tools/adb.exe" devices -l
./tools/build_android.ps1 -AotTool build/android-host/bin/forge_aot_tool.exe -Run
```

Omit `-Run` to build the APK only. Use `-Serial <adb-serial>` to select a
particular phone, or `-SdlSource <SDL-3.4.16-source>` to reuse a local checkout.
The script uses the Gradle wrapper and Java sources from the same SDL release
as the native library. It writes the signed debug APK to
`build/android-apk/outputs/apk/debug/dasSDL3-smoke-debug.apk`.

For wireless debugging, put the phone and computer on the same Wi-Fi network.
On the phone, open **Developer options → Wireless debugging → Pair device with
pairing code**. Run `adb pair IP:PAIR_PORT` and enter the code at the prompt.
Then use `adb connect IP:CONNECT_PORT` with the address on the main wireless
debugging screen. Pass that connected address to the script with `-Serial`.
Some Redmi devices also ask for **Install via USB** or an on-screen installation
confirmation when installing over wireless ADB.

The script installs the APK and checks logcat for that launch. The daScript
entry clears the SDL renderer to RGB (24, 96, 64) in the interpreter and
(24, 96, 192) in strict AOT. The host reads the rendered pixel before each
presentation. A separate fixture must fail simulation with `missing_aot`.
The final `dasSDL3 Android smoke PASS` requires all three checks.

## Native consumers

Configure the including project with the Android NDK toolchain, `arm64-v8a`
and Release. Use `add_subdirectory(path/to/dasSDL3 dasSDL3 EXCLUDE_FROM_ALL)`
and `target_link_libraries(main PRIVATE dasSDL3)`, as in `android/CMakeLists.txt`.
Bundle the matching SDL Java classes, SDL3 shared library and C++ runtime.
The `android-apk` install component in the example stages the required files.
The host emitter is a dependency of this example's AOT fixture. Consumers
linking just the core library can build it directly.

For the selected raw API, Clang targeting Android arm64 reproduces the Linux
registration snapshot. Android uses an unsigned 32-bit native HID character.
To check the saved functions, types and metadata against the actual NDK:

```powershell
$llvm = "$env:ANDROID_HOME/ndk/28.2.13676358/toolchains/llvm/prebuilt/windows-x86_64"
python tools/generate_bindings.py --check --profile linux --sdl-include "$SdlSource/include" --clang "$llvm/bin/clang.exe" --clang-arg=--target=aarch64-linux-android28 "--clang-arg=--sysroot=$llvm/sysroot"
```

The device check exercises core SDL rendering through the script bindings.
Optional companion libraries, direct SDL GPU/Vulkan, camera, audio and input
devices need separate Android tests.
