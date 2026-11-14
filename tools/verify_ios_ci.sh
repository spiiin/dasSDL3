#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root="${DASSDL3_IOS_CI_ROOT:-$PWD/build/ios-ci}"
host="${DASSDL3_IOS_CI_HOST:-$root/host}"
device="${DASSDL3_IOS_CI_DEVICE:-$root/device}"
consumer="${DASSDL3_IOS_CI_CONSUMER:-$root/consumer}"
logs="$root/logs"
mkdir -p "$logs"
common=(-G Ninja -DCMAKE_BUILD_TYPE=Release -DDAS_LLVM_DISABLED=ON
        -DDASSDL3_ENABLE_GENERATORS=OFF -DDASSDL3_BINDING_BACKEND=python)

cmake -S . -B "$host" "${common[@]}" -DBUILD_TESTING=ON \
  2>&1 | tee "$logs/host-configure.log"
cmake --build "$host" --target dasSDL3_macos_aot_tool --parallel 6 \
  2>&1 | tee "$logs/host-build.log"

ios=(-DBUILD_TESTING=OFF -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphoneos
     -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0
     "-DDASSDL3_IOS_AOT_TOOL=$host/bin/dasSDL3_macos_aot_tool")
if [[ -n "${DASSDL3_CI_SDL_SOURCE:-}" ]]; then
  ios+=("-DFETCHCONTENT_SOURCE_DIR_SDL3=$DASSDL3_CI_SDL_SOURCE")
fi

check_device_binary() {
  local binary="$1" log="$2"
  test "$(xcrun lipo -archs "$binary")" = arm64
  xcrun vtool -show-build "$binary" | tee "$log"
  grep -Eq '^[[:space:]]*platform IOS[[:space:]]*$' "$log"
}

cmake -S examples/ios-consumer -B "$consumer" "${common[@]}" "${ios[@]}" \
  -DCONSUMER_BUNDLE_ID=org.dassdl3.ci.hello 2>&1 | tee "$logs/consumer-configure.log"
cmake --build "$consumer" --target HelloDasSDL3 --parallel 6 \
  2>&1 | tee "$logs/consumer-build.log"
app="$consumer/HelloDasSDL3.app"
check_device_binary "$app/HelloDasSDL3" "$logs/consumer-platform.log"
plutil -lint "$app/Info.plist"
test "$(plutil -extract CFBundleIdentifier raw -o - "$app/Info.plist")" = org.dassdl3.ci.hello
cmp examples/ios-consumer/hello.das "$app/scripts/hello.das"
cmp examples/ios-consumer/color.txt "$app/assets/color.txt"
test -s "$consumer/hello.aot.cpp"
echo "PASS: standalone CMake consumer with custom bundle ID, AOT unit and resources"

cmake -S . -B "$device" "${common[@]}" "${ios[@]}" 2>&1 | tee "$logs/device-configure.log"
cmake --build "$device" --target dasSDL3_iphone --parallel 6 \
  2>&1 | tee "$logs/device-build.log"

app="$device/src/dasSDL3_iphone.app"
check_device_binary "$app/dasSDL3_iphone" "$logs/device-platform.log"
cmp examples/86_gpu_renderer.das "$app/examples/86_gpu_renderer.das"
cmp examples/assets/shaders/render_state.frag.msl "$app/assets/shaders/render_state.frag.msl"
test -s "$device/src/iphone_examples_86_gpu_renderer.das.aot.cpp"
echo "PASS: iPhone device executable (arm64), AOT generation and bundled example 86 resources"
