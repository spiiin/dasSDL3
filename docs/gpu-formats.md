# GPU format queries and color transfers

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.

Batch 25, pinned SDL 3.2.18. Module: `sdl3_gpu_formats_boost` (re-exports texture
transfers). Native queries: `src/sdl3_gpu_formats.h`.

## Queries

- All texture-format, texture-type, sample-count and texture-usage constants
  from the pinned header are selected through the normal generator: 121 new
  constants, 174 total. Script values are uint, not new enum type annotations.
  This does not complete the generator's general enum-type ABI work.
- `gpu_format_block_bytes(format)` reports SDL's bytes per texel/block. A BC/ASTC
  block is not a single texel. INVALID and unknown numeric values are rejected.
- `gpu_format_bytes(format,w,h,depth_or_layers)` reports the tight size from
  SDL_CalculateGPUTextureFormatSize, including partial BC/ASTC edge blocks.
  Dimensions are 1..8192 and depth/layers 1..256. A Uint32 result overflow is
  rejected before SDL's final multiply. Row/block-row factors are obtained from
  bounded one-axis SDL queries, multiplied in uint64 and checked. This is not
  staging row pitch, native allocation size or a hardware capability limit.
  Depth sizes follow SDL's reported metadata (e.g. D32_FLOAT_S8_UINT = 5 bytes);
  they do not authorize depth texture uploads.
- `gpu_supports_format(device,format,type,usage)` and
  `gpu_supports_samples(device,format,sample_count)` distinguish unsupported
  (false) from invalid argument/dead device (panic; native result -1).
  Device queries require the main thread and a live scoped device. Known enum
  ranges/flag bits are validated; legal hardware combinations are delegated to
  SDL's query. Sample count uses SDL_GPU_SAMPLECOUNT_* constants, not 1/2/4/8.
  Pure size/block queries do not require SDL initialization or a GPU.

## Color transfers

`with_gpu_color_texture(w,h,layers,levels,format)` accepts the uncompressed color
formats in the pinned header, subject to SDL's SAMPLER support query. Native
format bytes (1/2/4/8/16) drive CPU row length, aligned staging pitch, SDL's
pixels_per_row and tight readback. All mip/layer data starts with zero bits.
There is no channel conversion, float packing, sRGB conversion or normalization
on the CPU. BGRA bytes remain BGRA; float/packed/integer formats require the
caller to supply their actual representation.

The existing `with_gpu_rgba_texture` and SDL_CreateGPUTransferTexture remain
RGBA8 compatibility wrappers. Their existing tests/examples are retained.
All limits, pitch/copy/lifetime rules from `gpu-texture-transfer.md` remain.
Texture-to-texture copies additionally require exactly matching formats, even
when SDL could support some compatible reinterpretations.

BC/ASTC/depth formats can be queried, but creation through this transfer factory
rejects them before SDL allocation. 3D/cube transfer resources, arbitrary usage,
MSAA creation, compressed block uploads, mip generation and blit remain pending.
Support queries do not imply that these higher-level operations exist.

## Tests

`tests/gpu_formats.das` checks every known format's nonzero block size, independent
BC1/BC3/ASTC/depth size fixtures, invalid values and overflow. Hardware tests use
seven required uncompressed formats covering all five byte widths, with finite
float patterns, odd input pitch, minimal last rows, copied input arrays, exact
readback, cropped copies, preserved neighbors/mips and mismatched-format rejection.
Two additional formats (RGBA16 UNORM and RGBA32 UINT) exercise optional support:
if SDL reports false, creation must fail and the test logs that case explicitly.
No successful roundtrip is claimed for a format whose support query rejected it.

## Verification (2026-09-20)

- Developer CTest: 90/90 passed; parity/interpreter/strict AOT: 197/197 passed.
- Standalone dasClangBind experiment: 4/4 passed. After restoring the developer
  configuration, snapshot freshness, inventory and Clang preflight: 5/5 passed.
- Example 25 passed on Vulkan and D3D12 in the LLVM-free consumer build with
  generators disabled and Clang/LLVM/Python package discovery disabled.
  Its build.ninja contains no libclang/libLLVM or binding-generator commands.
- Both backends passed required 1/2/4/8/16-byte color roundtrips. D3D12 rejected
  RGBA32 UINT SAMPLER through SDL's capability query; Vulkan passed that case.
  The completed main/parity logs contained no VUID, Validation Error or D3D12
  ERROR diagnostics. The known FPS Monitor layer filter remained process-local;
  this does not establish testing on Linux or Metal.
- Coverage: GPU 7 generated / 45 adapted / 40 pending. Adapted contracts remain
  explicitly partial; all-library totals are 60 generated / 54 adapted / 1112 pending.

Packages 26-29 extend the separate typed factory with BC and cube/array support;
see [gpu-texture-types.md](gpu-texture-types.md). The original color factory
contract above is unchanged; ASTC/depth/3D remain unsupported.
