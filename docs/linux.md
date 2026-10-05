# Linux (Ubuntu 24.04 / WSL2)

The Linux core profile uses GCC, Ninja and committed Python/Clang-generated
Linux snapshots. Normal builds do not require Python, LLVM or Clang. SDL is
built from the pinned source; do not substitute a distribution SDL package.
The Windows CppGenBind and Python snapshots remain separate and unchanged.

## Build and run

In Ubuntu (including WSL2):

```sh
sudo apt update
sudo apt install build-essential cmake ninja-build git pkg-config \
  libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxfixes-dev \
  libxi-dev libxss-dev libxtst-dev libxkbcommon-dev \
  libwayland-dev libdecor-0-dev libgl1-mesa-dev libegl1-mesa-dev \
  libgles2-mesa-dev libdrm-dev libgbm-dev libasound2-dev libpulse-dev \
  libpipewire-0.3-dev libudev-dev libdbus-1-dev libibus-1.0-dev
mkdir -p ~/src
cd ~/src
git clone --recurse-submodules https://github.com/spiiin/dasSDL3.git
cd dasSDL3
cmake -S . -B build/linux -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
cmake --build build/linux --target dasSDL3_runner --parallel 6
./build/linux/bin/dasSDL3_runner examples/02_square.das
```

Keep the checkout in the WSL Linux filesystem, not `/mnt/c`. WSLg supplies
the display and audio integration; do not manually replace DISPLAY.
The runner is a native Linux executable without the `.exe` suffix.

## Regression profile

The focused `linux-core` label covers interpreter resource/event/filesystem/
process tests, native-width HID Unicode, strict AOT and a missing-AOT negative
test, plus Vulkan allocation/reallocation alignment and data preservation. Testing additionally needs Python 3, but not LLVM or Clang.

```sh
cmake -S . -B build/linux -DBUILD_TESTING=ON
cmake --build build/linux --target dasSDL3_runner linux_aot_runner linux_missing_aot linux_allocator_test --parallel 6
ctest --test-dir build/linux -L linux-core --output-on-failure
```

The complete historical CTest inventory is not a Linux validation claim:
it also contains Windows/D3D12, optional-library and hardware-specific tests.
Test GUI behavior with WSLg separately from tests using SDL's dummy driver.

## Platform contracts

* Windows-only DXGI, Direct3D9 and Windows message-hook functions are absent
  from the Linux raw module. `dxgi_output` returns an explicit unsupported error.
* `SDL_HidChar` is the script storage type for native HID wide strings: uint16
  on Windows and int32 on Linux. Use it for buffers passed to `SDL_hid_open`
  and the HID string getters. Buffer lengths remain counts of native characters.
  Copied HID metadata is UTF-8 on both platforms.
* Linux consumers inherit `-fno-rtti`, matching the pinned daScript build.
* `DASSDL3_INSTALL_SDK` remains the Windows C++/AOT SDK profile. Linux core
  also supports daspkg through a matching dynamic daScript SDK; see the
  [Linux package workflow](daspkg.md#linux-core-workflow). Linux ImGui and
  standalone application release still need their own validation.
* WSLg 2D success does not validate Vulkan hardware support. GPU examples
  require a working Vulkan device and compatible driver features.

## Regenerate Linux bindings

Only binding developers need Clang:

```sh
sudo apt install clang
python3 tools/generate_bindings.py --platform linux \
  --sdl-include build/linux/_deps/sdl3-src/include --output src/generated/linux
python3 tools/generate_bindings.py --platform linux \
  --sdl-include build/linux/_deps/sdl3-src/include --output src/generated/linux --check
```

The explicit platform exclusions live in `tools/bindings.json`. An unexpected
missing declaration still fails generation. The default generator profile
remains Windows for existing workflows; do not overwrite Windows snapshots
using a Linux AST.
