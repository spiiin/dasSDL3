# 35: 44-sss

Original: [bgfx 44-sss](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/44-sss).

SSS here means **screen-space shadows**, not subsurface scattering. Uses the original 100-model MWC scene including spheres, columns, trees, hollowcubes and bunnies, fieldstone textures, ground cube and moving unlit light sphere. All shadow computations stay on the GPU: G-buffer → linear depth → view-space ray march toward the light → deferred lighting.

ImGui provides world/pixel radius, step count, hard/soft/very-soft contact shadows, random offset, animated noise, shadow-only view and light animation. WASD and arrows move/look. Normals use RGBA16F rather than the upstream encoded representation. `tests/bgfx_sss.das` checks all softness modes, shadow-only output and pixel-radius sampling.

From the repository root (build with ImGui; D3D12 additionally needs shadercross):

```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_bgfx/example_35_sss/main.das
```

Use `SDL_GPU_DRIVER=direct3d12` for D3D12. The core runner does not contain ImGui.
`--smoke-test` performs a bounded startup run. Pixel/counter regressions are in
`tests/bgfx_sss.das`; GPU captures are opt-in through `DASSDL3_BGFX_CAPTURE`.
Windows Vulkan/D3D12 are tested; Metal and Web are not verified.

[Application](sss_app.das), [shader DSL](shaders/sss_shaders.das).
Assets/provenance: [manifest](../assets/ports40-45-manifest.json),
[group license](../LICENSE-bgfx.txt). No bgfx runtime dependency.
