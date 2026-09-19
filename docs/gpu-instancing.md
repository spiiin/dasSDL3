# GPU instancing

Example `17_gpu_instancing.das` draws 64 textured Lambert cubes with one
`SDL_DrawGPUIndexedPrimitives(indexCount,instanceCount,0,0,0)` per submitted frame.
Geometry, texture and material are shared. The camera and light can change each
frame. Example 17 uploads transforms once; explicit full updates are available
through `gpu_update_instances`, demonstrated in example 18. See
[gpu-dynamic-instances.md](gpu-dynamic-instances.md).

`GpuInstanceList` owns copied matrix columns. Build it with `gpu_instance_add`,
then pass it to `with_gpu_instanced_mesh`. Creation copies geometry, indices,
pixels and all model matrices. Clearing any source arrays afterwards is valid.
`gpu_draw_instanced_mesh` takes camera, world-space light direction and ambient.
Scopes use the same protected callback and catch/cleanup/rethrow mechanism as
other GPU resources, including early block return and panic.

The native adapter accepts 1..4096 affine invertible finite models (four float4
columns each). Every model is validated and its inverse-transpose normal matrix
prepared before GPU allocation. Empty/incomplete/oversized lists fail; there is
no fallback to a non-instanced draw. Models have the existing lit conditioning
threshold. Geometry/indices/RGBA8 limits remain those in [gpu-lit.md](gpu-lit.md).

Shader ABI for the supplied trusted `instances` HLSL/SPIR-V/DXIL assets:

| Input | Layout |
|---|---|
| Vertex buffer 0 | stride48: position float4 at0, normal float4 at16, UV float2 at32; locations0..2 |
| Vertex buffer 1 | stride112: four model columns at0..48, three padded normal columns at64..96; locations3..9; INSTANCE rate |
| Vertex uniform 0 | camera float4x4, 64 bytes, column-major |
| Fragment uniform 0 | normalized world light direction + ambient, 16 bytes |
| Fragment sampler 0 | shared nearest/clamp RGBA8 texture |

`instance_step_rate` is reserved by SDL and stays zero; rate is selected through
`input_rate`. See [SDL_GPUVertexBufferDescription](https://wiki.libsdl.org/SDL3/SDL_GPUVertexBufferDescription).
Draw offsets and first instance stay zero; see
[SDL_DrawGPUIndexedPrimitives](https://wiki.libsdl.org/SDL3/SDL_DrawGPUIndexedPrimitives).
The vertex shader applies model then camera. Normal columns retain one common
positive normalization factor, preserving inverse-transpose directions under
nonuniform and negative scale. SDL supplies the Vulkan viewport flip.

Instanced meshes share lit resource cleanup and the global checked ID namespace.
Ordinary lit and scene draws reject instanced IDs. Instanced draws reject ordinary
lit IDs. Shader filenames themselves are trusted assets, not runtime-reflected
ABI proofs. Camera/light validation happens before command acquisition. Depth
comes from actual drawable dimensions and uses existing resize/failure handling.
Recording contains no script callbacks. Acquired swapchains are submitted on
failure, never cancelled; NULL drawables skip without changing depth.

Tests in `gpu_instancing.das` and `gpu_instancing_probe.h` cover CPU-reference
pixels for three overlapping instances, independent inverse calculation,
nonuniform/negative scale, perspective and reversed instance order, invalid
lists/models, missing shaders, incompatible draw APIs, stale/foreign IDs,
resize, a second device, preflight/NULL drawable, panic and early-return cleanup.
Example 17 clears all input arrays after upload and runs 60 frames in smoke mode.

Per-instance RGBA is available through the separate stride128 API in
[gpu-instance-colors.md](gpu-instance-colors.md).

Arbitrary layouts, variable instance counts, per-instance textures/materials,
indirect draws, GPU culling and compute batching remain future work. This stage
does not change the number of raw SDL functions exposed.

## Verified on 2026-09-19

- Main project: 60/60 CTest checks passed. The subsequently strengthened
  instancing tests (copied data, maximum count, second-device ownership and exact
  panic message) passed in all three main configurations.
- Baseline/CppGenBind/strict-AOT suite: all 129 checks passed across the full
  run and rerun. Three AOT instancing checks initially saw an old generated test
  after its source was strengthened; regeneration and all three reruns passed.
- Example 17: 60 frames each on Vulkan and D3D12 in the main runner, strict AOT
  (`main AOT=yes; fallback disabled`) and LLVM-free consumer build.
- Shader deterministic rebuild, SPIR-V validation and asset hashes passed.
  Full parity and rerun GPU logs contained no `VUID-` or `Validation Error`.

This machine's known FPS Monitor layer conflict was filtered only in these
processes (`VK_LAYER_RENDERDOC_Capture`); validation was not disabled. Details:
[gpu-multidevice.md](gpu-multidevice.md).

Run from the repository root:

```powershell
.\build\ninja\bin\dasSDL3_runner.exe .\examples\17_gpu_instancing.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
```

The layer-filter option is specific to the affected local setup. The example
supports window resize and Escape to exit; its instance transforms stay fixed
while the camera orbits.
