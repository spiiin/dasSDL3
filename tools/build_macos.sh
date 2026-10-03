#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Optional local tools installed for this checkout; normal PATH also works.
if [[ -d "$root/build/local-tools/cmake/bin" ]]; then
    export PATH="$root/build/local-tools/cmake/bin:$root/build/local-tools:$PATH"
fi
if ! xcrun --find clang >/dev/null 2>&1 || ! xcrun --show-sdk-path >/dev/null 2>&1; then
    echo 'Install Apple Command Line Tools with xcode-select --install first.' >&2
    exit 1
fi
if [[ ! -f "$root/third_party/daScript/CMakeLists.txt" ]]; then
    git -C "$root" submodule update --init --recursive
fi
cmake -S "$root" -B "$root/build/macos" -G Ninja -DCMAKE_BUILD_TYPE=Release "$@"
cmake --build "$root/build/macos" --target dasSDL3_runner --parallel 6
