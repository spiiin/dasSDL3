# Generated GPU types

This document records batch 37. Batch 38 extends the selection to all pinned
GPU enums and pointer-free records; current totals and raw sampler contracts
are in [gpu-pipeline-types.md](gpu-pipeline-types.md).

Pinned SDL 3.2.18, Windows x64: the selection now contains 64 functions,
20 records, 7 opaque types, 98 exposed fields, 183 flat constants and
8 typed enums with 154 values. Both the Python baseline and dasClangBind
generate the enum annotations; production uses the saved dasClangBind snapshot.

The new records are viewport, direct/indexed indirect draw commands, indirect
dispatch command, buffer/texture create info, vertex buffer description,
vertex attribute, rasterizer state and multisample state. Padding is hidden.
`SDL_GPUTextureCreateInfo.type` is exposed as `texture_type`.

Use `SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM` in typed fields.
Existing flat uint constants remain supported by checked boost APIs. daScript
rejects an implicit uint assignment or a different enum in a typed field.
Usage flags remain uint bitmasks. Zero initialization does not guarantee a valid
SDL descriptor: supply the required dimensions/format and preserve reserved
fields such as `instance_step_rate = 0` and `enable_mask = false`.

Four raw functions are now generated with typed signatures:
`SDL_GPUTextureFormatTexelBlockSize`, `SDL_CalculateGPUTextureFormatSize`,
`SDL_GPUTextureSupportsFormat`, `SDL_GPUTextureSupportsSampleCount`.
Prefer existing checked boost helpers for range, overflow and live-device
validation. Raw declarations preserve SDL's preconditions.

These value types prepare general GPU APIs; they do not implement arbitrary
pipeline creation, indirect drawing or compute dispatch. GPU function coverage
is 11 generated / 56 adapted / 25 pending. Overall coverage is
64 generated / 65 adapted / 1097 pending. The four queries moved from adapted
to generated; the pending function count is unchanged.

Generator policy requires an exact selected member set and unique script aliases.
Only four-byte enums with int32-range values are supported. Unsigned underlying
types use the unsigned Clang value getter for range validation. Generated C++
checks enum values, record size/alignment and field offsets against the compiler.
Malformed or changed declarations fail before publishing snapshots.

`tests/gpu_types.das` checks native-to-script and script-to-native values for
every exposed field of the ten records, array copies and all 154 enum values.
`tests/test_gpu_type_errors.py` checks rejected implicit conversions and hidden
padding. `tests/gpu_typed_queries.das` compares raw queries with checked helpers
on Vulkan/D3D12. Metadata parity includes enum names, aliases, base types and
values. Example `37_gpu_descriptors.das` needs no GPU and demonstrates the values.

Verification (2026-09-20): main suite 127/127, standalone Clang preflight 4/4.
Parity/interpreter/AOT suite passed 289/290 initially; the example's printing
change required refreshing its AOT, after which all three example variants
passed (3/3), closing all 290 checks. No GPU validation errors or skips.
The LLVM/Python-disabled consumer built from saved snapshots and passed example
37 plus typed queries on Vulkan and D3D12. Its build graph has no libclang,
LLVM or binding-generator dependency.
