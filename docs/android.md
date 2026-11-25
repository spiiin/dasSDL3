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
cmake -S . -B build/android-host -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DDAS_LLVM_DISABLED=ON -DDASSDL3_BUILD_ANDROID_AOT_TOOL=ON -DDASSDL3_WITH_IMAGE=ON -DDASSDL3_WITH_TTF=ON -DDASSDL3_WITH_NET=ON -DDASSDL3_WITH_MIXER=ON -DDASSDL3_WITH_SOUND=ON
cmake --build build/android-host --target dasSDL3_android_aot_tool --parallel 6
```

## Build and run on a phone

Enable USB debugging on the phone, connect it by USB and accept the computer's
RSA prompt on its unlocked screen. Check that ADB lists the phone as `device`.

```powershell
& "$env:ANDROID_HOME/platform-tools/adb.exe" devices -l
./tools/build_android.ps1 -AotTool build/android-host/bin/dasSDL3_android_aot_tool.exe -WithImgui -WithCompanions -Run
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

## Device checks

Build with `-WithImgui` to include Dear ImGui, dasImgui v2, the keyboard probes
and the live development host. Install the rebuilt APK with `-Run -Serial`, then
run the individual modes against the same phone. The device runner marks each
launch in logcat and fails on a missing result.

```powershell
python tests/android/device.py --serial $serial smoke square square-aot storage-write storage-read
python tests/android/device.py --serial $serial vulkan
python tests/android/device.py --serial $serial vulkan-screen
python tests/android/device.py --serial $serial imgui imgui-v2 live-test
python tests/android/device.py --serial $serial imgui-input imgui-v2-input
python tests/android/device.py --serial $serial image ttf net mixer sound playback
```

Pass `--adb path/to/adb` if platform-tools is outside PATH. On the Redmi Note 13
with Android 15 the following checks passed on 2026-11-25.

| Mode | Observed result |
| --- | --- |
| `square`, `square-aot` | The shared lifecycle example drew at 2400×1080 and 1080×2400, went to the background and rendered another frame on return in the same process. The test restores the original rotation setting. |
| `lock` | With the strict-AOT square visible, locking and unlocking the Redmi stopped the Activity and then produced frame 1407 in the same process. The user confirmed the square continued moving. |
| `storage-write`, `storage-read` | A packaged WAV opened via SDL. A fresh strict-AOT process read the seven bytes previously written by the interpreter. |
| `vulkan` | All three SDL GPU examples passed in the interpreter and strict AOT. Example 44 checked triangle pixels, 46 checked texture and uniform bindings, and 49 checked compute readback against CPU values. |
| `imgui` | The existing Dear ImGui example passed its framebuffer text and widget pixel check. |
| `imgui-v2` | The existing daScript widget test passed framebuffer readback, synthetic clicks, the widget snapshot, slider updates and the yielding click command. |
| `imgui-input` | After a tap opened the screen keyboard, the native multiline field received exactly `привет` and a newline. |
| `imgui-v2-input` | The daScript multiline widget received the full UTF-8 sample, removed its last character with Backspace and received the expected string followed by a newline. |
| `image`, `ttf` | Image decode and save/load, font rendering, text shaping and GPU text draw-data tests passed in the interpreter and strict AOT. Generated pictures used the private application directory. |
| `net`, `mixer`, `sound` | Loopback networking, mixer tests and audio decoding passed in both execution modes. |
| `playback` | The real audio device consumed the bundled WAV and drained the stream in both modes. |
| `multitouch`, `unicode-input` | Two distinct contacts were observed. The second moved after the first lifted. In a separate keyboard run both script contexts matched 17 UTF-8 bytes (six Cyrillic letters, one space, four-byte waving hand) and the keyboard closed. |
| `camera-denied`, `microphone-denied` | Each permission request returned a denial from Android. The host left the corresponding device closed. |
| `camera`, `microphone` | After the user granted access, the camera produced three frames with increasing timestamps. The microphone produced at least 6,000 samples with a measured peak of at least 0.015. Both checks passed in the interpreter and strict AOT. |
| `sensors` | Both modes received timed accelerometer and gyroscope events, detected the phone's movement and read both devices directly. The user saw the live axis indicators move. |
| `consumer` | The separately built executable ran from an isolated ADB directory and passed its own strict-AOT platform/version check. |
| `live-test` | In one process and window, pixel readback changed from RGB (24, 96, 64) to (24, 96, 192). A syntax error left (24, 96, 192) on screen. The corrected script produced (24, 96, 128) and read the original session value from the live store. |

Both GUI script tests and script replacement use the interpreter. For the
interactive keyboard tests, tap the field on the phone. Enter `привет` or
`café` and press Return for Dear ImGui. Enter `приветт` or `caféx`, press
Backspace once and then Return for dasImgui v2.

For `multitouch`, put down two fingers, lift the first, then move and lift the
second. The keyboard step accepts `Привет 👋`, `привет 👋` or `café`. Start
`unicode-input` to repeat just the keyboard step and see the matched byte count.
For `lock`, use the power button and unlock normally when the square appears.
For `sensors`, tilt and turn the phone until both the interpreter and strict
AOT checks finish. Each requires three samples per sensor, an acceleration
change of at least 1 m/s² and angular speed of at least 0.5 rad/s.

For the capture checks, run `camera-denied microphone-denied camera microphone`
on an install that can request both permissions. Deny the first two prompts,
allow the next two and speak briefly for the microphone check. The app checks
dimensions, timestamps and audio signal in memory. It saves no recording.

`vulkan-screen` leaves example 48 on the phone for visual inspection. It
requests the Vulkan driver, submits the triangle to the window's swapchain in
strict AOT, and reports the first submitted frame in logcat. Expect a triangle
with red, green and blue corners on a dark background. Back closes the example.

The NDK compiles the registered SDL enum names into a target type profile.
The host AOT emitter uses that profile when computing enum and record hashes.
This accounts for four-byte C enums whose signedness differs between MSVC and
Android. The regular desktop emitter invocation keeps its native types.

To edit a running script, launch the `live` mode of the debuggable APK. Start
from `android/live.das`. Send a complete replacement to the private app
directory, then rename it to publish the edit. For example, from a shell with
stdin redirection:

```sh
adb -s "$serial" shell am force-stop org.dassdl3.smoke
adb -s "$serial" shell am start -n org.dassdl3.smoke/.SmokeActivity --es mode live
adb -s "$serial" shell -T "run-as org.dassdl3.smoke sh -c 'cat > files/dassdl3-live.tmp && mv files/dassdl3-live.tmp files/dassdl3-live.das'" < android/live.das
```

The host watches this file while `live` runs. It retains the SDL window and
renderer, validates the replacement's exported `paint(renderer) : bool` and
keeps the current script on a compilation or signature error. The automatic
`live-test` uses a separate private file.

## Native consumers

Configure the including project with the Android NDK toolchain, `arm64-v8a`
and Release. Use `add_subdirectory(path/to/dasSDL3 dasSDL3 EXCLUDE_FROM_ALL)`
and `target_link_libraries(main PRIVATE dasSDL3)`, as in `android/CMakeLists.txt`.
Bundle the matching SDL Java classes, SDL3 shared library and C++ runtime.
The `android-apk` install component in the example stages the required files.
The host emitter is a dependency of this example's AOT fixture. Consumers
linking just the core library can build it directly.

`examples/android-consumer` is a separate CMake project with its own native
executable and script. It embeds daScript, checks the exported entry's strict
AOT flag and verifies the Android platform and pinned SDL version through
the binding. The executable runs from ADB without an Activity. To build it
from a different directory, supply `-DDASSDL3_SOURCE_DIR=<checkout>`.

```powershell
$emitter = (Resolve-Path build/android-host/bin/dasSDL3_android_aot_tool.exe).Path
$ndk = "$env:ANDROID_HOME/ndk/28.2.13676358"
cmake -S examples/android-consumer -B build/android-consumer -G Ninja "-DCMAKE_TOOLCHAIN_FILE=$ndk/build/cmake/android.toolchain.cmake" -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-28 -DANDROID_STL=c++_shared -DCMAKE_BUILD_TYPE=Release "-DDASSDL3_HOST_AOT_TOOL=$emitter"
cmake --build build/android-consumer --target android_consumer --parallel 6
cmake --install build/android-consumer --strip --component consumer --prefix build/android-consumer-stage
python tests/android/device.py --serial $serial consumer
```

The Android CI workflow builds the full APK and this consumer with pinned
SDK/NDK packages on Windows. Device tests use the separately connected phone.

For the selected raw API, Clang targeting Android arm64 reproduces the Linux
registration snapshot. Android uses an unsigned 32-bit native HID character.
To check the saved functions, types and metadata against the actual NDK:

```powershell
$llvm = "$env:ANDROID_HOME/ndk/28.2.13676358/toolchains/llvm/prebuilt/windows-x86_64"
python tools/generate_bindings.py --check --profile linux --sdl-include "$SdlSource/include" --clang "$llvm/bin/clang.exe" --clang-arg=--target=aarch64-linux-android28 "--clang-arg=--sysroot=$llvm/sysroot"
```
