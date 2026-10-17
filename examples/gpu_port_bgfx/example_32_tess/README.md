# 32: 41-tess

Original: [bgfx 41-tess](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/41-tess).

This is compute-based implicit subdivision, not fixed-function hardware tessellation. The original 4096² displacement map covers the same two coarse terrain triangles. Compute performs key-based binary split/merge, distance LOD and frustum culling, then writes indexed-draw and next-dispatch commands. Vertex shading reconstructs each visible keyed triangle, expands its barycentric patch and displaces it. No terrain subdivision or visible-list readback occurs on the CPU.

ImGui exposes wireframe, culling, subdivision freeze, pixels per edge, patch levels 0–3 and normal/diffuse shading. WASD and arrows move/look. CPU code uploads only the constant small barycentric grid when the patch level changes, as in bgfx.

Differences: one million nodes/depth 19 are an explicit bounded capacity; original keys allow depth 31. Original finite-difference slopes are evaluated from the height texture in the fragment shader instead of storing a 128 MiB slope texture. Dispatch arguments use a separate buffer to avoid simultaneous indirect-read/UAV-write state. SDL vertex instance attributes carry the visible key/primitive pair instead of vertex-stage storage reads. `--smoke-test` runs 20 frames.

`tests/bgfx_tess.das` checks GPU subdivision counts, indirect draw/dispatch contents, freeze, wireframe, normals and patch-level restart.

From the repository root (build with ImGui; D3D12 additionally needs shadercross):

```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_bgfx/example_32_tess/main.das
```

Use `SDL_GPU_DRIVER=direct3d12` for D3D12. The core runner does not contain ImGui.
`--smoke-test` performs a bounded startup run. Pixel/counter regressions are in
`tests/bgfx_tess.das`; GPU captures are opt-in through `DASSDL3_BGFX_CAPTURE`.
Windows Vulkan/D3D12 are tested; Metal and Web are not verified.

[Application](tess_app.das), [shader DSL](shaders/tess_shaders.das).
Assets/provenance: [manifest](../assets/ports40-45-manifest.json),
[group license](../LICENSE-bgfx.txt). No bgfx runtime dependency.
