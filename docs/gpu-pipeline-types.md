# GPU pipeline value types and raw samplers

This generation batch completes the named enums and pointer-free GPU records
in pinned SDL 3.2.18. The selection contains all 24 `SDL_GPU*` enum declarations
(230 values), with enum-scoped names, and 16 GPU value records. Four color-write
mask constants are exported as uint; `color_write_mask` itself is Uint8.
Pointer-bearing pipeline, shader, target and resource-binding records remain
outside this selection and need explicit ownership/array contracts.

Six records extend [GPU types](gpu-types.md):

- `SDL_GPUSamplerCreateInfo`: filter, addressing, LOD, anisotropy and comparison.
- `SDL_GPUStencilOpState`: stencil operations and comparison.
- `SDL_GPUColorTargetBlendState`: independent RGB/alpha equations and write mask.
- `SDL_GPUTransferBufferCreateInfo`: typed usage, size and properties ID.
- `SDL_GPUDepthStencilState`: depth controls and two nested stencil states.
- `SDL_GPUColorTargetDescription`: format and nested blend state.

Records and their nested fields are copied by value. Padding remains hidden.
Zero initialization is not validation: enabled comparison/blending needs valid
operations, stencil needs a compatible attachment, and sampler LOD/anisotropy
must obey SDL/backend requirements. No new general graphics pipeline or transfer
buffer constructor is implied by exposing its descriptor.

`SDL_CreateGPUSampler` and `SDL_ReleaseGPUSampler` are generated raw functions.
Creation borrows the descriptor for the duration of the call and returns an
opaque pointer, or null on failure. Release must use the creating device; release
each successful sampler once, before destroying its device. Do not use its pointer
after release. SDL defers physical destruction while submitted GPU work uses it.
These functions do not provide ID validation or automatic scoped ownership.
Existing mesh helpers still own and clean up their internal samplers; their
limited boost contract is unchanged. A checked standalone sampler/resource
binding facade remains part of general GPU resources.

Example [38](../examples/38_gpu_pipeline_descriptors.das) demonstrates all six
records without unsafe or a GPU device. `tests/gpu_pipeline_types.das` exercises
each leaf field across C++/script boundaries, nested assignments, independent
array copies and the 76 newly selected enum values. Previous tests cover the
other 154 values. Negative compilation tests reject wrong enum types and access
to hidden nested padding. Metadata parity compares enum/type/field declarations.

`tests/gpu_typed_queries.das` additionally creates and releases four real raw
samplers per backend: nearest, linear, comparison and anisotropic configurations.
It releases successful handles before assertions. This verifies creation and
release, not their sampled image output or general pipeline integration.

Generation totals: 66 functions, 26 records, 8 opaque types, 138 fields,
187 flat constants, 24 enums / 230 enum values. GPU function census is now
13 generated / 54 adapted / 25 pending; overall 66 / 63 / 1097. Two sampler
functions moved from adapted to generated, leaving pending unchanged.

Verification (2026-09-20, pinned Windows x64 toolchain): main suite 129/129,
baseline/CppGenBind/strict AOT suite 296/296, standalone Clang preflight 4/4.
No skips or Vulkan/D3D12 validation errors. Both backends exercised the raw
sampler configurations; image sampling behavior is not claimed by this test.
The LLVM/Python-disabled consumer built from saved snapshots and passed example
38 plus raw sampler/query tests on Vulkan and D3D12 (three successful runs).
Its build graph contains no libclang, LLVM or binding-generator dependency.

Update: example 41 now adds checked standalone sampler IDs/scopes above these
generated raw functions; see [samplers](gpu-samplers.md). General pipeline/pass
bindings are still pending.

Example 42 adds a generated selected-field SDL_GPUShaderCreateInfo view (seven
value fields, three pointer/size fields hidden). Selection: 27 records, 145 fields.
This does not increase the count of fully pointer-free GPU records. Contract:
[standalone shaders](gpu-shaders.md).

Example 43 generates selected fields of SDL_GPUGraphicsPipelineTargetInfo and
SDL_GPUGraphicsPipelineCreateInfo; hidden pointers/counts are built by the adapter
from copied arrays and shader IDs. Selection: 29 records / 153 fields. See
[graphics pipelines](gpu-pipelines.md).
