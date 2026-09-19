# Per-instance RGBA

Example 19 draws 64 textured cubes with independent animated transforms and
colors in one indexed draw. `sdl3_gpu_instance_colors_boost` exports:

- `GpuColoredInstanceList`: owned `model_columns` and `colors` arrays.
- `gpu_colored_instance_add(list,model,color=float4(1.0))`.
- `with_gpu_colored_instanced_mesh(...,list) $(mesh) { ... }`.
- `gpu_update_colored_instances(device,mesh,list)`.

Draws use the existing `gpu_draw_instanced_mesh`. The native create/update
adapters take one float4 RGBA per model, with all channels finite and in 0..1.
Colors represent linear multipliers; white leaves the sampled texture unchanged.
Creation and update copy all values. After return source arrays can be cleared.
The 1..4096 instance limit and fixed-count full-update contract are unchanged.
Invalid data is rejected before GPU work; a failed submission requires a
successful full update before drawing again.

## Shader ABI and alpha

The supplied `colored_instances.*` assets extend the instance record to 128
bytes: four model columns at0..48, three normal columns at64..96, RGBA at112.
The color attribute is float4 at location10, in instance-rate buffer slot1.
`sizeof`/`offsetof` assertions protect the native record. Vertex stride48,
camera uniform64, light uniform16 and fragment sampler0 remain unchanged.
Color passes flat (nointerpolation) from vertex to fragment shader.

Output RGB = texture RGB * instance RGB * Lambert illumination.
Output alpha = texture alpha * instance alpha; lighting does not affect alpha.
Pipeline blending stays disabled and depth writes stay enabled. Thus alpha zero
does not discard a fragment or make it see-through; the alpha channel is written
to the target. Transparent compositing and depth sorting are separate future work.

The old `instances.*` stride112 ABI and examples 17–18 remain supported. Colored
and plain update functions reject a mesh with the opposite ABI. Recording,
release and device ownership are shared; ordinary non-instanced lit/scene draws
still reject both kinds of instanced mesh. Shader paths are trusted assets;
runtime shader reflection is not implemented, so callers must use matching assets.

Full model/color updates use the existing staging/destination cycling path from
[gpu-dynamic-instances.md](gpu-dynamic-instances.md). No script callback or explicit
CPU fence/idle wait is added to production recording. Resource release works on
normal exit, early return, panic and device destruction.

## Verification contract

`tests/gpu_instance_colors.das` and the native probe compare overlapping colored
triangles against the independent CPU projection/depth/normal reference. A
nonwhite texture with nonopaque alpha proves multiplication rather than color
replacement, across all four output channels. Tests cover copied creation/update
data, twelve alternating queued color snapshots, invalid count/range/NaN/Inf,
wrong update ABI, stale/foreign IDs, failed-submit recovery, resize, early return,
panic and a second device with its own updated resources.

Example 19 clears uploaded arrays and runs 60 deterministic frames in smoke mode.
Build shader assets offline using `tools/build_triangle_shaders.py --colored-instances`;
consumer builds use saved SPIR-V/DXIL and need no shader compiler.

From the repository root:

```powershell
.\build\ninja\bin\dasSDL3_runner.exe .\examples\19_gpu_instance_colors.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
```

The optional process-only filter addresses this machine's FPS Monitor overlay
conflict; see [gpu-multidevice.md](gpu-multidevice.md). Escape exits, resize works.

## Verified on 2026-09-19

- Main CTest suite: 65/65 passed, including both GPU backends and earlier examples.
- Baseline/CppGenBind/strict-AOT suite: 140/140 passed in the full run.
- Example 19: 60 frames each on Vulkan and D3D12 in the main runner, strict AOT
  (`main AOT=yes; fallback disabled`) and LLVM-free consumer build.
- Shader deterministic rebuild, SPIR-V validation and asset integrity passed.
  Full main/parity and example logs contain no `VUID-` or `Validation Error`.
- Generator snapshots were regenerated from policy; `git diff --check` passed.
  Only the known overlay layer was filtered in test processes; validation was
  not disabled globally or through the filter.
