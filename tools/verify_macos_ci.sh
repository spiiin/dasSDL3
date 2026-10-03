#!/usr/bin/env bash
# Headless arm64 checks only; Cocoa/Metal verification needs a GUI session.
set -euo pipefail
cd "$(dirname "$0")/.."
repo="$PWD"
if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
  echo "This profile requires native macOS arm64." >&2
  exit 1
fi
expected_sdk=35bf260c0d8a79b94c64005bd3d2435adcf7e261
if [[ "$(git -C third_party/daScript rev-parse HEAD)" != "$expected_sdk" ]]; then
  echo "Unexpected daScript revision; initialize the pinned submodule." >&2
  exit 1
fi
ci_root="${DASSDL3_CI_ROOT:-$repo/build/macos-ci}"
core="${DASSDL3_CI_CORE:-$ci_root/core}"
libraries="${DASSDL3_CI_LIBRARIES:-$ci_root/libraries}"
sdk_build="${DASSDL3_CI_SDK:-$ci_root/sdk-build}"
logs="$ci_root/logs"
mkdir -p "$logs"
common=(-G Ninja -DCMAKE_BUILD_TYPE=Release -DDAS_LLVM_DISABLED=ON
        -DDASSDL3_ENABLE_GENERATORS=OFF -DDASSDL3_BINDING_BACKEND=python)
features=(IMAGE TTF NET MIXER SOUND SHADERCROSS IMGUI LIVE)
core_flags=()
library_flags=()
for feature in "${features[@]}"; do
  core_flags+=("-DDASSDL3_WITH_$feature=OFF")
  if [[ "$feature" == LIVE ]]; then
    library_flags+=("-DDASSDL3_WITH_$feature=OFF")
  else
    library_flags+=("-DDASSDL3_WITH_$feature=ON")
  fi
done
export SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy
restore_core() {
  local result=$?
  trap - EXIT
  if ! cmake -S "$repo" -B "$core" "${common[@]}" "${core_flags[@]}" \
      -DBUILD_TESTING=ON > "$logs/restore.log" 2>&1; then
    cat "$logs/restore.log"
    if [[ "$result" == 0 ]]; then result=1; fi
  fi
  exit "$result"
}
trap restore_core EXIT
cmake -S "$repo" -B "$core" "${common[@]}" "${core_flags[@]}" -DBUILD_TESTING=ON \
  2>&1 | tee "$logs/core-configure.log"
cmake --build "$core" --target dasSDL3_runner dasSDL3_macos_aot_runner --parallel 6 \
  2>&1 | tee "$logs/core-build.log"
ctest --test-dir "$core" -L macos-headless --output-on-failure --no-tests=error \
  2>&1 | tee "$logs/core-tests.log"
python3 tools/generate_bindings.py --clang "$(xcrun --find clang)" --profile macos \
  --clang-arg=-isysroot "--clang-arg=$(xcrun --show-sdk-path)" \
  --sdl-include "$core/_deps/sdl3-src/include" --output src/generated/macos --check \
  2>&1 | tee "$logs/bindings.log"
python3 tools/audit_record_fields.py --check 2>&1 | tee "$logs/record-audit.log"
cmake -S "$repo" -B "$libraries" "${common[@]}" "${library_flags[@]}" \
  -DBUILD_TESTING=ON -DDASSDL3_SHADERCROSS_DXC=OFF 2>&1 | tee "$logs/libraries-configure.log"
cmake --build "$libraries" --target dasSDL3_macos_libraries_aot_runner \
  dasSDL3_macos_shader_dsl_aot_runner --parallel 6 2>&1 | tee "$logs/libraries-build.log"
ctest --test-dir "$libraries" -L macos-libraries-aot -E ttf_gpu --output-on-failure --no-tests=error \
  2>&1 | tee "$logs/libraries-tests.log"
ctest --test-dir "$libraries" -L 'macos-dsl-(headless|link)' --output-on-failure --no-tests=error \
  2>&1 | tee "$logs/dsl-tests.log"
# A separate no-LLVM SDK build runs only after all generated-AOT builds finish.
cmake -S "$repo" -B "$sdk_build" "${common[@]}" "${core_flags[@]}" \
  -DBUILD_TESTING=OFF -DDAS_TOOLS_DISABLED=ON -DDASSDL3_INSTALL_SDK=ON \
  -DCMAKE_DISABLE_FIND_PACKAGE_Python3=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_LLVM=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_Clang=TRUE 2>&1 | tee "$logs/sdk-configure.log"
cmake --build "$sdk_build" --target dasSDL3_aot --parallel 6 2>&1 | tee "$logs/sdk-build.log"
cmake --install "$sdk_build" --component dasSDL3SDK --prefix "$ci_root/sdk" \
  2>&1 | tee "$logs/sdk-install.log"
# Use a new prefix and consumer build on each run; avoid stale absolute paths.
relocated="$(mktemp -d "$ci_root/relocated SDK.XXXXXX")"
cp -R "$ci_root/sdk/." "$relocated/"
cmake -S "$relocated/share/dasSDL3/examples/sdk-consumer" -B "$relocated/consumer-build" \
  -G Ninja -DCMAKE_BUILD_TYPE=Release "-DCMAKE_PREFIX_PATH=$relocated" \
  -DCMAKE_DISABLE_FIND_PACKAGE_Python3=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_LLVM=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_Clang=TRUE 2>&1 | tee "$logs/consumer-configure.log"
cmake --build "$relocated/consumer-build" --parallel 6 2>&1 | tee "$logs/consumer-build.log"
ctest --test-dir "$relocated/consumer-build" --output-on-failure --no-tests=error \
  2>&1 | tee "$logs/consumer-tests.log"
echo "PASS: macOS headless core, companion/DSL strict AOT and relocated no-LLVM SDK"
