# GPU format queries and color transfers

Batch 25, pinned SDL 3.2.18. Module: `sdl3_gpu_formats_boost` (re-exports texture
transfers). Native queries: `src/sdl3_gpu_formats.h`.

## Queries

- Checked helpers accept flat uint constants. Generated raw descriptors also
  expose typed enums; see [GPU types](gpu-types.md). Keep flags as bitmasks.
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
  and invalid input as false. The native Checked query retains -1/0/1
  to distinguish invalid input from unsupported and supported.
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
rejects them before SDL allocation. Cube/BC and volumes use separate checked
factories; ASTC positive roundtrip remains unverified. Native descriptors allow
other usages/MSAA, subject to SDL and hardware support.

## Tests

`tests/gpu_formats.das` checks every known format's nonzero block size, independent
BC1/BC3/ASTC/depth size fixtures, invalid values and overflow. Hardware tests use
seven required uncompressed formats covering all five byte widths, with finite
float patterns, odd input pitch, minimal last rows, copied input arrays, exact
readback, cropped copies, preserved neighbors/mips and mismatched-format rejection.
Two additional formats (RGBA16 UNORM and RGBA32 UINT) exercise optional support:
if SDL reports false, creation must fail and the test logs that case explicitly.
No successful roundtrip is claimed for a format whose support query rejected it.

Latest combined verification: [gpu-native-validation.md](gpu-native-validation.md).
Current function census: [api-coverage.md](api-coverage.md).
This page describes the checked subset. Full native pointers/arrays and scopes
are documented in [gpu-native-boost.md](gpu-native-boost.md); IDs and native
handles are separate. Other platforms and all hardware formats are not certified.
