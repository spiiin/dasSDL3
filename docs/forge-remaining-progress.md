# Forge GPU 21–52 port progress

Source: `Nebulavenus/forge-gpu` at `31f44fce9b69cb124b38c1bc90177ef17f1342c8` (HEAD verified 2026-10-20).

All 32 ports are implemented. This checklist records verification, not exact visual parity with the C originals. Adaptations are listed in [implementation notes](forge-ports-21-52.md). The public SDL API remains unchanged.

| Lesson | Topic | Status |
|---|---|---|
| 21 | hdr-tone-mapping | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 22 | bloom | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 23 | point-light-shadows | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 24 | gobo-spotlight | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 25 | shader-noise | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 26 | procedural-sky | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 27 | ssao | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 28 | ui-rendering | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 29 | screen-space-reflections | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 30 | planar-reflections | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 31 | transform-animations | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 32 | skinning-animations | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 33 | vertex-pulling | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 34 | stencil-testing | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 35 | decals | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 36 | edge-detection | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 37 | 3d-picking | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 38 | indirect-drawing | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 39 | pipeline-processed-assets | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 40 | scene-renderer | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 41 | scene-model-loading | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 42 | pipeline-texture-compression | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 43 | pipeline-skinned-animations | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 44 | pipeline-morph-animations | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 45 | scene-transparency-sorting | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 46 | particle-animations | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 47 | texture-atlas-rendering | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 48 | height-map-terrain | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 49 | imposters | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 50 | grass-rendering | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 51 | pbr-shading | PASS: Vulkan / D3D12, interpreter / strict AOT |
| 52 | pbr-textures | PASS: Vulkan / D3D12, interpreter / strict AOT |


Completed on 2026-10-20, Windows x64:

- All 32 lessons on both backends, interpreter and strict AOT with fallback disabled.
- 70 interpreter capture cases per backend and 32 strict-AOT cases per backend: 204 accepted cases.
- 64 same-backend interpreter/AOT image comparisons; worst RGB MAE 0.001535 (0–255).
- All 89 DSL stages: deterministic bytecode, reflection and SPIRV-Tools PASS.
- CPU interpolation, hierarchy, animation, FTEX rejection, terrain, scalar-reference UI/PRNG contracts PASS.
- Both picking methods identify the same object with selection active.
- All 200 indirect commands match CPU frustum culling; GPU particle integration matches CPU Euler.
- 462 manifest entries checked; the four offline tools reproduce 392 generated/copied files,
  with 438 total files checked unchanged. The LF-stable misc asset generator was replayed after newline normalization.

Evidence: [validation JSON](../examples/gpu_port_forge/validation/2026-10-20.json),
[scene overview](../examples/gpu_port_forge/screenshots/21-52.jpg).
[Implementation notes](forge-ports-21-52.md) explicitly list the adaptations;
exact C-reference parity, Metal, Web and other operating systems are not claimed.
