# Direct raw GPU execution tests

`tests/gpu_raw.das` invokes all 92 active Windows SDL_gpu.h entry points directly
from daScript. It deliberately uses `unsafe`/local addresses to test the original
C pointer/count signatures, not the checked-ID or array adapters. This is a test
fixture, not an example of the recommended public application style.

`tests/gpu_raw_probe.h` prepares CPU bytes and persistent descriptor backing
storage and reads mapped results. It issues no GPU operation under test. Property
allocation uses SDL's general Properties API because that binding is a separate
workstream. Shader and pipeline descriptors borrow fixture storage until the
direct native creation calls finish.

## Coverage and oracles

`tests/gpu_raw_coverage.json` enumerates every active GPU function. The Python
runner compares this set with the generated pinned-header census, checks shader
hashes, requires successful process completion and verifies `RAW_CALL` receipts
emitted after the actual script calls. An unavailable GPU fails these explicitly
selected backend tests; it does not silently skip them.

- Device creation through both constructors, properties/driver/format queries.
- Buffer/texture/transfer/sampler/shader/graphics and compute pipeline creation
  and corresponding releases; names and command debug markers.
- Mapped upload, buffer and texture copy, download and map/unmap. Downloaded
  float4 bytes must equal their CPU input, including the intermediate copy.
- One draw per scissor quadrant: direct, indexed, indirect and indexed indirect.
  All 64 pixels must match the expected RGBA values. The shaders consume vertex
  and fragment sampler, storage texture, storage buffer and uniform data. Blend
  constants use the by-value SDL_FColor ABI and affect the measured output.
- Mipmap generation down to 1x1 and a separate blit destination, both checked
  against the rendered color, not only successful command submission.
- Direct and indirect compute dispatches have separate readback snapshots with
  different uniforms: eight uint results must equal `14+i` and `24+i`. Sampled,
  read-only texture/buffer, uniform and read-write texture/buffer bindings all
  affect the output. The written texture is independently checked too.
- Fenced completion with the original pointer/count wait, query and release.
- Window claim/configuration/capability queries, both acquisition functions,
  non-null swapchain dimensions, clear passes, presentation, idle wait, window
  release, ordinary command submission and cancellation before acquisition.

Function execution coverage is not exhaustive parameter/state coverage. For
example this test calls stencil reference, but does not establish all stencil
operations; it does not cover every format, depth attachment, MSAA or MRT layout.

## Backend limitations

With SDL 3.4.16 both Vulkan and D3D12 exercise all 95 functions. The old
3.2.18 D3D12 BeginEvent metadata defect no longer requires exclusions: debug
groups use PIX and may no-op without its runtime DLL. The runtime matrix has
no backend exclusions. Execution does not prove labels are visible in a capture.
Validation is not disabled. See sdl-3.4-upgrade.md for current validation.

During test development a buffer combining VERTEX/INDEX/INDIRECT usage produced
the old compute result on Vulkan after indirect dispatch, while D3D12 passed.
Using separate vertex, index and indirect buffers produced the expected results.
The pinned Vulkan default buffer usage selection prioritizes VERTEX over INDIRECT;
the precise underlying synchronization issue has not been proven or repaired.
The passing test uses dedicated buffers and does not claim coverage of that
combined-usage case. No SDL source was changed.

## Running and shader maintenance

Main CTest names: `sdl3_gpu_raw_vulkan`, `sdl3_gpu_raw_direct3d12`.
Parity names: `{baseline,cppgenbind,parity_aot}_gpu_raw_{vulkan,direct3d12}`.
The AOT runner requires AOT execution with interpreter fallback disabled.
Existing generic per-script tests also include this script.

`tools/build_raw_gpu_shaders.py --dxc <dxc.exe> --spirv-val <spirv-val.exe>`
rebuilds the committed HLSL/SPIR-V/DXIL fixtures and hashes. Add `--check` to
verify reproducibility. Test/consumer builds do not invoke a shader compiler.
The current fixture targets vs/ps/cs_6_0 and SPIR-V Vulkan 1.0.

## Verified results (2026-09-20)

- Main raw/fence/type/boundary selection: 8/8 passed.
- Both generators, AOT, generic raw runs and metadata comparison: 10/10 passed.
- All six explicitly selected backend/runner pairs satisfied runtime coverage:
  Vulkan 92/92; D3D12 90/92 with the two documented debug-group exclusions.
- DXC rebuild comparison and SPIR-V validation passed for all three stages.
- D3D12 debugger capture exited 0 without ERROR/CORRUPTION messages. This does
  not claim the debug output contains no warnings.

Logs: task workspace work/raw-main-tests.log, raw-parity-tests.log,
raw-debug-d3d12.log. The subsequent full-suite/native-adapter results are in
[gpu-native-validation.md](gpu-native-validation.md).
