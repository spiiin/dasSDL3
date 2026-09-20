# Standalone graphics pipelines

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.

Example 43 and `sdl3_gpu_pipeline_boost` add graphics pipeline ownership independent
of fixed mesh/material bundles. Shader IDs must belong to the same live scoped
device and have the vertex/fragment roles supplied. Creation copies descriptors,
vertex layouts and color targets; pipelines remain valid after releasing shaders.
The registry also snapshots shader resource counts for future pass validation.

```das
device |> with_gpu_graphics_pipeline(vertex,fragment,
    SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(pipeline) {
    var state : SDL_GPUGraphicsPipelineCreateInfo
    if (!gpu_graphics_pipeline_descriptor(device,pipeline,state)) { return }
}
```

The full overload takes a generated SDL_GPUGraphicsPipelineCreateInfo plus three
arrays: SDL_GPUVertexBufferDescription, SDL_GPUVertexAttribute and
SDL_GPUColorTargetDescription. The compact overload uses vertex-ID input (empty
layouts), a triangle list, fill/no culling, enabled depth clipping, sample 1 and
one color target without blending/depth. `gpu_color_target(format)` initializes
valid blend defaults. The getter returns normalized value state, not array views
or pointers. Caller array/descriptor mutations never modify a created pipeline.

## Generated views and ownership

Two selected-field records are generated: SDL_GPUGraphicsPipelineTargetInfo
(depth format, has-depth flag) and SDL_GPUGraphicsPipelineCreateInfo (topology,
raster/multisample/depth state, target info, props). Shader pointers, vertex input
pointer/count state and color pointer/count are hidden. Native output clears all
hidden fields. Padding and ignored disabled options are normalized. The generated
selection is now 29 records / 153 fields; functions and enums are unchanged.

Creation, lookup and release require main thread and live scoped device. IDs use
the shared monotonic namespace with a separate registry, rejecting stale IDs,
other resource kinds and foreign devices. Failed creation does not invoke the
block. Script defer cleans up on normal exit and early return; no catch boundary
is installed. Device cleanup releases unclosed pipeline
IDs only for that device. Shader scopes need not outlive the pipeline after its
successful creation. Do not manually release a scope-owned pipeline.

## Checked subset

- At most 16 vertex buffers and 16 attributes, as in pinned SDL_sysgpu.h. Array
  counts are checked as uint64 before copying or narrowing. Empty layouts support
  vertex-ID shaders. Every nonempty buffer description must have an attribute.
- Buffer slots must be dense and unique from zero. Input order may be arbitrary;
  the native copy is sorted by slot. Pinned D3D12 uses
  `vertex_buffer_descriptions[attribute.buffer_slot].input_rate` in
  SDL_gpu_d3d12.c; passing sparse or unordered descriptions directly is unsafe.
  This adapter normalizes order without modifying the caller array.
- Pitch 1..2048, per-vertex/per-instance rates, reserved instance_step_rate zero.
  Locations 0..15 unique; each attribute references an existing slot, fits inside
  pitch and has component-aligned offset/pitch. All 30 pinned element formats have
  checked sizes/alignment. This does not reflect the shader's actual inputs.
- 1..4 RGBA8/BGRA8 UNORM/SRGB color targets. All blend operations and factors are
  range checked; enabled blending rejects INVALID. Alpha factors SRC_COLOR,
  DST_COLOR and their inverses are excluded for D3D12 compatibility. Write masks
  use only RGBA bits. Other color formats and depth-only pipelines are pending.
- Fill rasterization only. Cull/front-face/topology enums checked. Bias requires
  finite constant within +/-65536, slope within +/-16, and clamp zero. Pinned
  Vulkan does not enable depthBiasClamp, so nonzero clamp is rejected. Wireframe
  is deferred because portable feature support is not exposed. Depth clipping
  follows SDL semantics (including documented D3D12 clamp behavior).
- Sample counts 1/2/4/8 are checked with SDL for every target format. Reserved
  sample masks must be disabled/zero. Depth formats D16/D24/D32 and D24S8/D32S8
  require actual format/sample support. Depth writes require depth testing;
  enabled stencil requires a stencil format and valid front/back operations.
  Testing/writing without a corresponding depth target is rejected.
- Extension props must be zero. Disabled depth/stencil/blend options are
  normalized; pointers into script data are never retained.

Shader binary ABI, matching vertex inputs/fragment outputs, point-size output for
point topology and correct resource declarations remain the caller's trusted
offline contract. This stage does not add shader reflection or public render-pass
recording. Multiple target/depth/sample settings are creation contracts; they do
not imply corresponding checked draw/binding coverage.

## Tests and next step

`tests/gpu_pipeline.das` checks triangle pixels, source-color blending (squared
RGB CPU reference), R-only writes, and a textured quad using copied float2/float2
vertex attributes. Shader IDs are released and input arrays changed/cleared before
draw. A two-slot per-vertex/per-instance case verifies canonical ordering. Native
probes test bad enums, layouts, nonfinite bias, reserved state and hidden padding.
Lifetime tests cover nested SDL error results, early return, wrong kind/thread/device and
device-specific cleanup. Supported depth/stencil and MSAA combinations are created
and inspected, not rendered in this stage. MRT pixel and instanced two-slot pixel
acceptance remain pending.

Rendering uses native test-only pass fixtures and existing CPU oracles. Example
43 only creates a pipeline. Next: native command-plan render operations, checked
buffer/texture/sampler bindings and target/pipeline compatibility at submission.
GPU function census remains 13 generated / 54 adapted / 25 pending; create/release
were already adapted. Their boost policy stays partial for the stated limits.

The nested pipeline descriptor exposed a legacy-generator initialization bug:
policy order registered its annotation before SDL_GPUDepthStencilState. The
legacy generator now orders registrations by selected field-type dependencies,
with a diagnostic for cycles. CppGenBind already emits a working declaration
order. Baseline module startup, type-error checks and metadata parity cover this
regression; changing policy order is not the workaround.

Validation run (2026-09-20): main CTest 150/150, standalone dasClangBind gates
4/4, full parity/AOT rerun after the registration-order fix 349/349 without skips.
Vulkan and D3D12 pixel oracles passed with released shaders and mutated arrays.
Both backends accepted four queried sample counts and four tested depth/stencil
formats, plus 2..4 color-target creation. These extra states remain creation-only
evidence. Full logs contain no Vulkan VUID or D3D12 validation errors.
The LLVM/libclang-free consumer built and ran example 43 on both backends;
its Ninja build graph contains no generator/LLVM references.

Public offscreen rendering is now provided by [render plans](gpu-render-plans.md),
for resource-free shaders and a matching single sample-1 color target. Other
layout/resource/attachment combinations remain creation-only at this stage.

Example 45 exercises standalone pipelines with interleaved, split and instance-rate
vertex layouts through public render plans; see [vertex/index plans](gpu-vertex-plans.md).
