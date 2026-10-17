# 34: 43-denoise

Original: [bgfx 43-denoise](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/43-denoise).

The original deterministic 100-model scene uses column, tree, hollowcube and bunny meshes, the original MWC random sequence, fieldstone albedo/normal map and ground cube. GPU passes: G-buffer (color, normal/roughness, velocity, depth), synthetic noisy lighting, optional normal-rejected temporal accumulation, 0–6 edge-aware à-trous spatial passes, albedo composition and optional TXAA. History remains on the GPU; temporal denoise reuses the first spatial pass, as upstream.

ImGui exposes none/dither/random noise, dynamic noise, temporal denoise, 3×3/5×5 kernels, pass count, depth/normal sigmas, TXAA, Mitchell filtering, feedback limits and slow-frame debugging. WASD and arrows move/look. TXAA uses the original eight-position jitter sequence, closest-depth motion selection, variance clipping and luminance feedback. History is reset after resize or toggling TXAA.

Normals are stored directly in RGBA16F instead of packed RGB, and color/velocity targets also use RGBA16F. `tests/bgfx_denoise.das` checks denoising, noise controls, both kernel extents and successive TXAA frames.

From the repository root (build with ImGui; D3D12 additionally needs shadercross):

```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_bgfx/example_34_denoise/main.das
```

Use `SDL_GPU_DRIVER=direct3d12` for D3D12. The core runner does not contain ImGui.
`--smoke-test` performs a bounded startup run. Pixel/counter regressions are in
`tests/bgfx_denoise.das`; GPU captures are opt-in through `DASSDL3_BGFX_CAPTURE`.
Windows Vulkan/D3D12 are tested; Metal and Web are not verified.

[Application](denoise_app.das), [shader DSL](shaders/denoise_shaders.das).
Assets/provenance: [manifest](../assets/ports40-45-manifest.json),
[group license](../LICENSE-bgfx.txt). No bgfx runtime dependency.
