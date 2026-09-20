# ASTC transfer infrastructure and capability limitation

Batch 40 adds rectangular block handling to the existing 2D/array/cube transfer
API. **Positive ASTC GPU transfers are not verified on this machine.** CPU layout
tests and unsupported-path checks pass; this is not completion of the ASTC GPU
acceptance gate or G3.

The related steps are block extent metadata, independent block axes, staging
footprints, region/mip validation, creation policy, upload/readback integration,
direct/command-plan copies, transfer capability checks and example/regressions.

## Interface and data contract

`gpu_format_block_extent(format)` returns uint2(width,height) in texels: 1x1 for
uncompressed formats, 4x4 for BC, and the pinned fourteen ASTC footprints for each
of UNORM, sRGB and FLOAT (42 formats). ASTC always occupies 16 encoded bytes per
block. `gpu_format_block_bytes` and `gpu_format_bytes` keep their prior semantics.
Metadata availability does not establish hardware support.

`device |> gpu_supports_texture_transfer(format,texture_type)` checks the bounded
2D/array/cube transfer contract, including backend exclusions. Unknown formats or
types fail; valid but unavailable formats, depth and 3D return false. 3D color
volumes use their separate API. Unlike `gpu_supports_format`, this query describes
the binding policy, not just SDL's capability answer. Positive support is still
subject to dimensions, total footprint and allocation limits.

`with_gpu_transfer_texture` now accepts ASTC when this policy and SDL support it.
Base width and height must be multiples of their respective block dimensions;
cubes must also be square. Region origins align to each axis independently.
Sizes align to blocks or end at the mip boundary; a 1x1 mip still stores a full
16-byte block. CPU row pitch is bytes per encoded block row, not texel row.
Private staging uses 256-aligned rows, texel-based pixels_per_row and zero
rows_per_layer for each single-layer transfer. Readback strips staging padding
and returns complete encoded blocks, including partial mip edges.

Upload, direct copy and command-plan copy share rectangular validation. Existing
ID/device checks, validity, cycling, scoped cleanup and retired fence behavior
remain in force. Color-only factories and 3D volumes still reject compressed
formats. This code does not encode, decode, transcode or sample ASTC. Initial
zero bits do not promise a valid compressed image or decoded black pixels.

## Pinned Vulkan false-positive query

Observed on 2026-09-20: SDL 3.2.18 reports 14/42 ASTC formats supported on Vulkan,
all FLOAT; D3D12 reports 0/42. Creating an ASTC_12x10_FLOAT texture and reading it
back completed, but Vulkan validation emitted
`VUID-VkImageCreateInfo-format-parameter` and
`VUID-VkImageViewCreateInfo-format-parameter`: the format requires
`VK_EXT_texture_compression_astc_hdr`, which was not enabled. Thus the apparent
successful readback is **not accepted as valid GPU support**.

SDL's Vulkan format query uses physical image-format properties without checking
this enabled-extension prerequisite. The binding cannot inspect enabled device
extensions through this pinned public SDL API. It therefore conservatively
rejects ASTC FLOAT on all pinned Vulkan devices before image creation, including
devices that might actually have the extension. This is an explicit binding
limitation, not a universal hardware claim. Raw SDL queries and
`gpu_supports_format` retain SDL's answer. No validation messages are suppressed,
and no SDL/daScript source is patched. Revisit this guard when the device extension
contract can be verified or the pinned SDL version is upgraded.

## Tests and remaining evidence

`gpu_astc_layout.das` and `gpu_astc_probe.h` check all 42 formats against SDL's
independent size API, 25 nonsquare/edge dimensions per format, aligned staging,
5x4 region axes, invalid origins/interior extents, partial mip edges and 1x1 mips.
These tests require no GPU. `gpu_astc.das` verifies actual capability/rejection
behavior and contains capability-gated padded upload, layer isolation, direct and
planned copies, edge mips and byte readback. The positive branch is compiled in
interpreter/AOT but remains unexecuted here: final output explicitly reports zero
ASTC GPU roundtrips. Tests pass for successful rejection; that does not imply a
successful ASTC transfer. Example 40 similarly reports unavailability instead of
silently substituting another format.

Hardware evidence still required: execute the positive branch on supported ASTC
UNORM/sRGB hardware, and FLOAT on an allowed backend with verified support.
Cube/array variations, sampling decoded pixels and Metal/Linux validation remain
unverified. Existing real BC, color, volume and command-plan regressions protect
the shared code paths. Function census remains 13 generated / 54 adapted / 25
pending; this batch changes supported descriptors and capability policy.

Verification on 2026-09-20: main suite 138/138, baseline/CppGenBind/strict AOT
suite 319/319, standalone Clang preflight 4/4. Final suites emitted no GPU
validation errors after the guard was added. ASTC tests passed their CPU and
capability/rejection assertions; both Vulkan and D3D12 completed **zero** positive
ASTC transfer roundtrips. That limitation is not represented as a CTest skip,
because the rejection checks themselves ran and passed.
The LLVM/Python-disabled consumer built from saved snapshots and ran example 40
on Vulkan and D3D12, reporting transfer unavailability and valid 5x4 block
metadata. Its build graph contains no LLVM/libclang or generator dependency.
