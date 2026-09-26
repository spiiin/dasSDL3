# Standalone graphics pipelines

Example 43 and `sdl3_gpu_pipeline_boost` add graphics pipeline ownership independent
of other checked resource IDs. Shader IDs must belong to the same live scoped
device and have the vertex/fragment roles supplied. Creation copies descriptors,
vertex layouts and color targets; pipelines remain valid after releasing shaders.
The registry also snapshots shader resource counts for checked pass validation.

```das
device |> with_gpu_graphics_pipeline(vertex,fragment,
    SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(pipeline) {
    return gpu_graphics_pipeline_descriptor(device,pipeline)
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

Generated pipeline records now include native pointer/count fields. This checked
adapter accepts shader IDs and array inputs, returning selected value state;
it does not hand ownership of hidden native storage to script. For native
pipeline creation and full descriptor semantics see gpu-native-boost.md.

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
  use only RGBA bits. Other color formats and depth-only pipelines are outside this checked subset.
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
offline contract. This stage does not add shader reflection or native pass ownership. Multiple target/depth/sample settings are creation contracts; they do
not imply corresponding checked draw/binding coverage.

## Tests

`tests/gpu_pipeline.das` checks triangle pixels, source-color blending (squared
RGB CPU reference), R-only writes, and a textured quad using copied float2/float2
vertex attributes. Shader IDs are released and input arrays changed/cleared before
draw. A two-slot per-vertex/per-instance case verifies canonical ordering. Native
probes test bad enums, layouts, nonfinite bias, reserved state and hidden padding.
Lifetime tests cover nested SDL error results, early return, wrong kind/thread/device and
device-specific cleanup. Supported depth/stencil and MSAA combinations are created
and inspected by this test. MRT/depth/stencil/MSAA and indexed instance offsets
have additional pixel tests in gpu_native_adapters.das.

Latest combined verification: [gpu raw tests](gpu-raw-tests.md).
Current function census: [api-coverage.md](api-coverage.md).
This page describes the checked subset. Full native pointers/arrays and scopes
are documented in [gpu-native-boost.md](gpu-native-boost.md); IDs and native
handles are separate. Other platforms and all hardware formats are not certified.
