# GPU packages 26–29

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.

Pinned SDL 3.2.18. `sdl3_gpu_utilities_boost` re-exports format and texture
transfer helpers. The four packages share one regression/build pass.

## 26: BC block transfers

`with_gpu_transfer_texture(width,height,layers,levels,format,texture_type)`
owns a checked texture ID, with the same protected panic/return cleanup as the
older RGBA8/color scopes. It accepts supported uncompressed color formats and
the pinned BC1–BC7 formats, including available sRGB variants. Existing color
factories still reject BC; ASTC/depth/3D transfers remain unsupported.

BC base dimensions must be multiples of four. Mips may be smaller or have a
partial final block. Regions use pixel coordinates; origins must be multiples
of four, and dimensions must be block-aligned or terminate at the mip edge.
Pitch is bytes per row of encoded blocks, including arbitrary CPU padding.
Only `(block_rows-1)*pitch + tight_block_row_bytes` input bytes are required.
Uploads copy encoded bytes; no encoder, decoder, channel conversion or pixel
sampling API is implied. Zero initialization means zero encoded bits, not a
promise about decoded colors (in particular BC6/BC7).

Private staging has 256-byte row pitch, zero offset and texel-based SDL
pixels_per_row; single-layer rows_per_layer=0 avoids backend repacking.
Readback strips staging padding and returns full encoded edge blocks. Copies
require matching formats and distinct resources. Existing 64 MiB total mip/face
footprint, validity, cycling and deferred fence-retirement rules still apply.

D3D12 uses rounded physical block extents for native copies at mip edges;
Vulkan receives logical extents. Logical bounds are validated before this
conversion. The pinned SDL D3D12 direct-copy path constructs its source box
without rounding; a 2-pixel edge in a 6-pixel mip failed command-list closure.
The adapter handles that backend difference without modifying SDL or daScript.
Background: [Microsoft block-compression documentation](https://github.com/MicrosoftDocs/windows-dev-docs/blob/docs/uwp/graphics-concepts/block-compression.md)
describes physical padding in small mips.

## 27: cube and cube-array transfers

The typed scope accepts 2D (one layer), 2D_ARRAY, CUBE (six layers, square), and
CUBE_ARRAY (square, positive multiple of six layers). At most 256 layers are
allowed, so the largest cube array is 42 cubes. `uint2(mip,layer)` selects a face;
face order within each cube follows SDL: +X, -X, +Y, -Y, +Z, -Z. Cube `k` starts
at layer `6*k`. There is no direction-to-face sampling helper or new mesh ABI.
Every mip/face starts initialized. Copy/upload/readback share the region API.

## 28: driver discovery

`gpu_driver_names()` returns an owned array of copied strings for drivers
compiled into SDL, not physical adapters or a runtime-availability list.
`gpu_supports_shaders(formats, preferred_driver="")` validates a nonempty known
shader-format mask and returns false when unsupported. The empty string becomes
SDL's null preference. SDL's `SDL_GPU_DRIVER` hint/environment has priority over
the preferred name, including a non-existent name; the wrapper preserves this
behavior and never mutates process hints. An available driver does not prove a
particular shader/pipeline will compile. Discovery calls are main-thread only.

## 29: resource names

`device |> gpu_buffer_name(id,name)` names public data buffers;
`device |> gpu_texture_name(id,name)` names public transfer textures. Both check
the live scoped device, main thread, ID kind/owner and a 4096-byte limit before
SDL. Empty names are accepted. SDL copies names; the caller can discard its
string. IDs and contents are unchanged. SDL setters return void: successful
validation/call is not a guarantee that a debugger displays the name. Debug
groups/labels and names for internal mesh-bundle resources remain pending.

## Verification scope

`tests/gpu_texture_types.das`: odd pitch and minimal last rows, all pinned BC
formats (capability-gated), cropped block copies, partial edge and 1x1 mips,
independent array layers/faces, zero neighbors, invalid descriptors/regions,
stale/cross-device IDs, panic cleanup and snapshot survival after source release.
Cube and cube-array color plus BC1 cube transfers are exercised.
`tests/gpu_utilities.das`: owned driver strings, invalid masks/indices,
resource-name bounds, cross-kind/device/stale IDs, Unicode/empty names.
Examples 26–29 demonstrate each package without a window.

Combined verification on 2026-09-20:

- Main project: 102/102 CTest; parity/interpreter/strict AOT: 227/227.
- Standalone dasClangBind experiment: 4/4. All 12 selected BC formats ran on
  both Vulkan and D3D12 here; none took the unsupported-format branch.
- Examples 26–29 passed on both backends in the LLVM-free consumer build.
  Clang/LLVM/Python package discovery and generators were disabled; build.ninja
  has no libclang/libLLVM or binding-generator commands.
- Completed main/parity logs contain no VUID, Validation Error or D3D12 ERROR.
  The known FPS Monitor layer filter remains process-local. Linux/Metal and
  actual debugger display of resource names were not tested.
- Inventory: GPU 7 generated / 50 adapted / 35 pending; total SDL API
  60 generated / 59 adapted / 1107 pending. Existing adapted APIs remain partial.
- Developer generator configuration restored. Final snapshot/inventory/preflight
  checks plus example 28: 7/7. After clarifying that example's driver-preference
  output, its interpreter/AOT parity subset passed 5/5 and both consumer runs
  passed again. No implementation changes followed the combined suite.

3D color volumes are now available through a separate checked API and registry;
see [gpu-volume.md](gpu-volume.md). Existing 2D/array/cube factories retain their
original type restrictions. ASTC/depth transfers remain pending.

ASTC infrastructure (example 40): rectangular block extents/regions and guarded
transfer selection are implemented. Positive ASTC GPU roundtrip is unverified
locally; pinned Vulkan HDR is conservatively excluded after a validation failure.
See [ASTC limits and evidence](gpu-astc.md). G3 acceptance remains open.
