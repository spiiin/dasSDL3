# GPU packages 26–29

Pinned SDL 3.2.18. `sdl3_gpu_utilities_boost` re-exports format and texture
transfer helpers. The four packages share one regression/build pass.

## 26: BC block transfers

`with_gpu_transfer_texture(width,height,layers,levels,format,texture_type)`
owns a checked texture ID, released by script defer on normal/early return. It accepts supported uncompressed color formats and
the pinned BC1–BC7 formats, including available sRGB variants. Existing color
factories still reject BC. ASTC has [separate restrictions](gpu-astc.md);
3D uses [volume helpers](gpu-volume.md). Depth transfers are outside this factory.

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
validation/call is not a guarantee that a debugger displays the name. Native
debug labels/groups are generated; D3D12 groups retain a pinned backend issue.

## Verification scope

`tests/gpu_texture_types.das`: odd pitch and minimal last rows, all pinned BC
formats (capability-gated), cropped block copies, partial edge and 1x1 mips,
independent array layers/faces, zero neighbors, invalid descriptors/regions,
stale/cross-device IDs, early-return cleanup and snapshot survival after source release.
Cube and cube-array color plus BC1 cube transfers are exercised.
`tests/gpu_utilities.das`: owned driver strings, invalid masks/indices,
resource-name bounds, cross-kind/device/stale IDs, Unicode/empty names.
Examples 26–29 demonstrate each package without a window.

Latest combined verification: [gpu-native-validation.md](gpu-native-validation.md).
Current function census: [api-coverage.md](api-coverage.md).
This page describes the checked subset. Full native pointers/arrays and scopes
are documented in [gpu-native-boost.md](gpu-native-boost.md); IDs and native
handles are separate. Other platforms and all hardware formats are not certified.
