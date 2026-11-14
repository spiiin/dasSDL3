# iPhone device smoke test

This experimental source build targets physical arm64 iPhones (iOS 15+ for
this profile). SDL 3.4.16 documents Metal GPU support on iOS 13+ with A9+
hardware. SDL GPU's Metal backend does not support the iOS simulator.
Verified on iPhone 16 with iOS 27.0.1: all three Metal examples passed in the
interpreter and in strict AOT with fallback disabled. The negative test also
confirmed rejection of a script without AOT code. The on-screen triangle
also ran in strict AOT: the device log recorded the first swapchain submission
and a new submission after each of two cycles (Home Screen and lock/unlock).
The triangle was visible after both returns. UIKit logged an unbalanced
appearance transition at startup, but the first frame and both resume checks
completed.

The existing `tests/filesystem.das` also passed in the interpreter and strict
AOT on the same phone. It runs in the app's writable preferences directory and
uses absolute paths because SDL 3.4.16 on iOS resolves some relative paths
against a different directory. The test checks directory creation, file
contents, copy/rename, enumeration and cleanup.

To check persistence, install the build once and use `devicectl device process
launch` with `--console` to start the app twice: pass `--persistence-write`
to the first launch and wait for it to exit, then pass `--persistence-read`
to the second. The first process writes seven binary bytes with the
interpreter. The second only reads and compares the bytes (using strict AOT
when the AOT tool is configured). Both phases must log PASS with different
process IDs. Do not reinstall the app between the two launches.

Verified on iPhone 16 (iOS 27.0.1): the interpreter wrote the fixture, then a
fresh strict AOT process read the same seven bytes after the writer exited.
Both processes exited successfully.

To check real touch and the on-screen keyboard, launch the installed app with
`--input-interpreter`, then repeat with `--input-aot` in a build with AOT.
Drag one finger and lift it, then type `42` on the phone's numeric keyboard.
The script must see down, motion and up from the same direct touch, then
receive the digits through SDL text input. The host checks that the keyboard
is shown during entry and hidden after stopping text input. Each mode exits
after reporting its own PASS.

Verified on iPhone 16 (iOS 27.0.1): direct touch down, motion and up,
text input from the on-screen numeric keyboard, and keyboard dismissal
passed in both the interpreter and strict AOT.

For the GPU Renderer smoke test, launch with `--gpu-renderer-smoke`.
The existing example 86 draws four frames with a custom MSL fragment shader
and updates its uniforms. An AOT build runs the example in both modes.

Launch with `--gpu-renderer` for continuous rendering of the same example.
The iPhone host uses SDL callbacks to run one frame at a time. The color of
the rectangle should keep changing. Go to the Home Screen, reopen the app
and check that the colors are changing again. Tap the screen to exit.
The console logs the first frame, a frame after foregrounding and cleanup.
The visual check confirms presentation because SDL Renderer can return
success even when the swapchain drawable is temporarily unavailable.
An AOT build runs this mode with strict AOT.

On iPhone 16 (iOS 27.0.1), the continuous example animated after launch
and after returning from the Home Screen. The strict AOT run released
its resources and exited with code zero.

For audio, launch with `--audio-interpreter` or `--audio-aot`. Example 08
loops its bundled WAV through CoreAudio. Listen for the tone, lock and
unlock the phone, then return to the app. When prompted, tap only if the
tone is audible again. The prompt requires the original stream to consume
queued audio after foregrounding. Queue progress and audible playback
are reported separately. This checks lock/unlock, not a phone call or
other system audio interruption.

Verified on iPhone 16 (iOS 27.0.1): example 86 completed on Metal in the
interpreter and strict AOT. In both CoreAudio runs, the existing stream
consumed newly queued data after lock/unlock, and the tester confirmed the
tone was audible. All three launches exited with code zero.

Use full Xcode, CMake and Ninja. Build the AOT emitter on macOS first:

```sh
cmake -S . -B build/ios-host -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
cmake --build build/ios-host --target dasSDL3_macos_aot_tool --parallel 6
```

Then configure the separate iPhone build:

```sh
cmake -S . -B build/iphone -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
  -DBUILD_TESTING=OFF \
  -DDASSDL3_IOS_AOT_TOOL="$PWD/build/ios-host/bin/dasSDL3_macos_aot_tool" \
  -DDASSDL3_IOS_BUNDLE_ID=com.example.dassdl3-smoke \
  -DDASSDL3_IOS_TEAM=YOUR_TEAM_ID
```

Use your own bundle identifier and development team. Open the generated
`dasSDL3.xcodeproj`, select the `dasSDL3_iphone` scheme and your connected device,
and run with development signing. The device must trust the Mac and have
Developer Mode enabled. The same target also builds an unsigned device app
with Ninja and `-DCMAKE_BUILD_TYPE=Release`; use Xcode signing for installation.
The iOS GitHub Actions workflow runs `bash tools/verify_ios_ci.sh` on macOS
arm64. It builds the host AOT emitter, the `iphoneos` smoke app and a separate
consumer project. It checks both Mach-O binaries, the consumer's bundle ID,
AOT generation and bundled resources. Installation and rendering checks run
separately on a device.

## SDL_image

Enable `-DDASSDL3_WITH_IMAGE=ON` for both the macOS emitter and the iPhone
build. Build `dasSDL3_macos_libraries_aot_tool` on macOS and pass its path as
`DASSDL3_IOS_AOT_TOOL` to the iPhone build. This profile uses SDL_image's
built-in codecs.

Launch with `--image-smoke`. The app runs the existing
`tests/image.das` and `examples/libraries/02_image.das` in the interpreter
and, when configured, strict AOT. The test checks decoded PNG and SVG pixels,
alpha blending, PNG and JPEG round trips, GIF animation and IO ownership.
It writes temporary images to the app's preferences directory. The example
loads PNG and SVG textures from the bundle and renders three frames through
SDL's Metal renderer. On iPhone 16 (iOS 27.0.1), both scripts passed in
the interpreter and strict AOT, and the app exited with code zero.

## Build a small app from source

After building the host emitter above, configure the standalone example
as its own CMake project:

```sh
cmake -S examples/ios-consumer -B build/ios-hello -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
  -DBUILD_TESTING=OFF \
  -DDASSDL3_IOS_AOT_TOOL="$PWD/build/ios-host/bin/dasSDL3_macos_aot_tool" \
  -DCONSUMER_BUNDLE_ID=com.example.hello -DCONSUMER_TEAM=YOUR_TEAM_ID
```

Open `build/ios-hello/HelloDasSDL3.xcodeproj` and select `HelloDasSDL3` and
your device. The app runs its own strict-AOT script, which reads the blue
channel from the bundled `assets/color.txt` to set the window's background
color. To use the example from a different directory, copy its four files
and set `DASSDL3_SOURCE_DIR` to the absolute path to the dasSDL3 checkout.
The project links the core binding with `add_subdirectory` and
`target_link_libraries`. The same checkout supplies the runtime's script
library and the bundle file loader.

## Smoke app behavior

The app runs the existing examples without modifying their checks:
`44_gpu_render_pass.das` (triangle pixels), `46_gpu_texture_uniform_bindings.das`
(texture and uniform bindings with pixel readback), and `49_gpu_native_compute.das`
(compute output bytes). Each runs in the interpreter and strict AOT. The
existing `tests/macos_missing_aot.das` fixture is bundled without AOT code; the
strict host must report a missing-AOT error without invoking it.

After the automated checks pass, the app displays the triangle from
`48_gpu_native_graphics.das` on the Metal swapchain. A red status screen
indicates an automated check failed; see the device console for the specific
failure. Without `DASSDL3_IOS_AOT_TOOL`, the app runs in the interpreter only.

With the console attached, go to the Home Screen and reopen the app. Then
lock the device, unlock it and return to the app again. Check that the triangle
is visible each time. For each cycle, the console should report
`background: rendering paused`, `foreground: waiting for frame`, then
`swapchain resumed frame PASS`. The last message requires an actual swapchain
image and a successful submission; an unavailable drawable does not count.

The pinned runtime's desktop crash handler uses macOS-only Mach APIs, and its
desktop file I/O module includes subprocess APIs unavailable on iOS. The
iPhone profile uses the SDK's no-file-I/O build and reads packaged scripts
through a read-only host file system. SDL file APIs are separate. LLVM, desktop
package modules, and companion libraries other than SDL_image are outside
this profile.
