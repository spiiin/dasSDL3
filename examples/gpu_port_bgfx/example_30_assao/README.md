# 30: ASSAO adaptation — bgfx 39

Original: [bgfx 39-assao](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/39-assao).

All AO computations run on the GPU. The pass sequence follows upstream ASSAO:

1. Prepare four parity layers of view-space depth and supplied or depth-derived normals.
2. High/Adaptive: build three edge-aware depth mip levels above the base level.
3. Generate obscurance with the original progressive disk, radius/falloff, halo reduction, detail AO, depth/normal edges, edge packing and distance fade.
4. Adaptive: five-tap base pass; quarter-resolution importance generation; smoothing A/B; cleared atomic load counter; budget-limited additional taps that reuse the base result.
5. Zero to six blur passes: non-smart for Low/Lowest, smart and wide smart for higher quality.
6. Full-resolution compute apply: half-layer reconstruction for Lowest, non-smart for Low, edge-aware four-layer reconstruction for Medium/High/Adaptive. Fragment shading combines AO with lighting.

| Q quality | Samples (symmetric tap pairs) | Filtering |
| --- | --- | --- |
| -1 Lowest | 3, parity layers 0 and 3 only | At most one non-smart blur; half apply |
| 0 Low | 3, all layers | At most one non-smart blur; non-smart apply |
| 1 Medium | 5 | Detail/depth edges; smart blur/apply |
| 2 High | 12 | Depth mips, normal edges; smart blur/apply |
| 3 Adaptive | 5 base + up to 27 additional | Global GPU importance budget; at least one blur |

The **Settings** ImGui panel exposes the original enable, texturing/lighting, quality, normals, gutter, radius, strength, power, limit, horizon, fade, adaptive budget, blur, sharpness, temporal offsets and detail controls. It can be moved, resized and scrolled. **Reset settings** restores defaults. Keyboard shortcuts are ignored while ImGui captures keyboard input. Equal or inverted fade endpoints use a minimum 0.001 range to avoid division by zero.

Q cycles quality (default Adaptive); B cycles requested blur passes (default 2); N switches G-buffer/depth-derived AO normals; M selects lit AO, disabled, AO-only or an Adaptive shortcut; WASD moves the camera; arrows look around; R resets it. T toggles textured lighting, G toggles framebuffer gutter, and +/- changes the effect radius. `Settings.adaptive_limit` and `Settings.detail` expose the budget and detail strength.

The scene follows bgfx: 120 objects, the original cube/orb/column/bunny/tree/hollowcube meshes, MWC seeds and random-call order, original model scales and transforms, 16x tiled fieldstone ground, initial camera `(0, 1.5, 0)` and directional-light formula. The fieldstone mip chain is generated on the GPU. Default radius (1.2), strength (1.0 multiplied by 4.3), power (1.5), fade range (50–200), Adaptive quality, generated normals and framebuffer gutter match upstream. The expanded G-buffer preserves the visible 60-degree field of view; the final pass crops its border on the GPU.

`Settings` also exposes sharpness, horizon threshold, shadow clamp, fade range, sample rotation and sample scale. The render loop submits geometry and uniforms; AO, importance, filtering, mip generation and final composition stay on the GPU. Models are converted from the original OBJ sources offline; runtime has no bgfx dependency. Verify conversions with `python tools/build_bgfx_assao_assets.py --bgfx C:/src/bgfx --check`; hashes are in [assao-manifest.json](../assets/assao-manifest.json). Assets use the group's bgfx license.

Remaining implementation differences: storage buffers with explicit sampling replace image arrays/gathers; view positions use a floating-point G-buffer; border sampling clamps rather than mirrors; the renderer uses SDL GPU rather than bgfx. This is not a pixel-identical or performance-equivalent implementation.

- [main.das](main.das): interactive entry point; `--smoke-test` exits after three frames.
- [assao_gui.das](assao_gui.das): settings panel and SDL GPU overlay (uploads before a LOAD render pass).
- [assao_app.das](assao_app.das): resources, passes and input.
- [Shader DSL](shaders/assao_shaders.das).
- [Regression test](../../../tests/bgfx_assao.das): Checks all quality tap counts, bounded full-resolution AO, adaptive base reuse and zero-budget behavior, the atomic load counter against readback, blur variants, generated normals, lighting contribution, original MWC sequence, framebuffer gutter, textured/untextured modes and odd-resolution padding.

Build with `DASSDL3_WITH_IMGUI=ON`; use the libraries runner (the core runner has no ImGui). The offscreen ASSAO test still works with the core runner. [GUI regression test](../../../tests/bgfx_assao_gui.das) checks a checkbox click, mouse capture, overlay pixels, preservation of the scene and context cleanup.

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_bgfx/example_30_assao/main.das
```
D3D12: set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. Metal is unverified. The ImGui panel uses the upstream SDL GPU backend.
