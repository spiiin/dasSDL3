# Native GPU follow-up validation — 2026-09-20

Scope: SDL 3.2.18, pinned daScript, Windows x64/MSVC, local Vulkan and D3D12.
The five follow-up steps are implemented: script-owned creation inputs, bounded
transfer bytes, native defer scopes, advanced GPU combinations, and public
examples plus interpreter/AOT/consumer checks. See gpu-native-boost.md.

## Results

- Production and parity/AOT builds passed (6 parallel jobs).
- Main project selection: 114 tests ran; 112 passed initially. The two clangbind
  infrastructure tests failed because the concurrent no-LLVM consumer configure
  changed shared daScript module configuration. After restoring production
  configuration both passed, together with snapshot freshness, inventory,
  inventory contracts and API boundary (6/6 gate run).
- Added array/ref operation test after that full run: Vulkan and D3D12 passed
  (2/2 targeted main tests). No other runtime source changed afterwards.
- Full legacy/CppGenBind/AOT parity suite: 305/305 passed. The subsequently added
  array/ref operation scenario passed its 9/9 interpreter/backend/AOT cases.
  These are a full run plus a targeted extension, not one 314-test invocation.
- Standalone clangbind validation: 4/4 passed, including missing-AOT negative test.
- No-LLVM/no-generator consumer built and ran examples 46 and 48–50 on both
  Vulkan and D3D12; removed-framework API boundary check passed.
- New shader assets reproduced byte-for-byte with the offline builder's
  `--check`; SPIR-V validation passed. Consumers use committed binaries.
- D3D12 debug output capture for `gpu_native_adapters.das` found no D3D12
  ERROR/CORRUPTION messages. GPU CTests reject Vulkan validation errors and
  D3D12 ERROR/CORRUPTION messages. Machine-specific RenderDoc layer filtering
  was process-local (`VK_LAYER_RENDERDOC_Capture`), not a global setting.

The advanced native test verifies two resolved MRT images pixel by pixel,
4x MSAA, depth/stencil rejection, load/store persistence, cycling, vertex/index
and instance offsets, temporary creation inputs, scope early returns and invalid
transfer spans. The array/ref test covers stage bindings, uniforms, descriptor
refs and out parameters while retaining independent GPU output oracles.

Examples 48–50 require only public modules, with no unsafe or private test
fixtures. SDL failures remain result values; cleanup uses script defer without
try/recover, native catch bridges or wrapper panic.

## Repeating affected checks

After configuring/building the corresponding tree:

```powershell
ctest --test-dir build/ninja --output-on-failure -R 'gpu_native|examples_4[89]|examples_50'
ctest --test-dir <parity-build> --output-on-failure -R 'gpu_native|examples_4[89]|examples_50'
./build/ninja/bin/dasSDL3_runner.exe examples/48_gpu_native_graphics.das
./build/ninja/bin/dasSDL3_runner.exe examples/49_gpu_native_compute.das
./build/ninja/bin/dasSDL3_runner.exe examples/50_gpu_native_transfer.das
```

Select a backend with `SDL_GPU_DRIVER=vulkan` or `direct3d12` in the process
environment. Add `--smoke-test` to bound example 48 to three frames.
Do not overlap consumer configuration with clangbind-dependent work: shared
module configuration must be restored before production clangbind gates.

## Limits retained

- Raw execution receipts cover 92/92 active Windows GPU functions on Vulkan,
  90/92 on D3D12. D3D12 debug groups remain excluded for SDL 3.2.18's invalid
  event metadata. See gpu-raw-tests.md; these are not silently skipped tests.
- D3D12 depth MSAA support querying uses the SRV format and reports false on
  this machine. Actual 4x texture creation and pixel validation pass; adapters
  preserve SDL's query result.
- Combined vertex/index/indirect buffer usage had a Vulkan output issue;
  dedicated buffers are used. No pinned SDL source was patched.
- Native handles have SDL lifetime/thread/device preconditions; transfer
  capacity must equal its real creation size. Array checks do not validate
  forged pointers, shader bytecode, or asynchronous completion.
- Scope cleanup covers ordinary/early returns, not application panic in the
  pinned daScript runtime. Borrowed scope handles must not escape or be freed
  by callbacks. Pending fences are not released after a failed wait.
- This validates local Vulkan/D3D12, not Metal, other operating systems or
  every hardware format. Full-library binding work remains (next: Properties).
