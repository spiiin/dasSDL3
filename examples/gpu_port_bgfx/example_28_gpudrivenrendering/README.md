# 28: GPU-driven rendering — bgfx 37

Original: [bgfx 37-gpudrivenrendering](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/37-gpudrivenrendering).

Current-frame depth prepass, conservative maximum-depth pyramid, frustum/Hi-Z visibility, stable parallel prefix scan, compacted instance IDs, and indexed indirect draw all run on the GPU. No visibility or draw-count readback occurs in the interactive loop. M toggles culling/all instances; Space pauses the camera; R resets it. The scene uses 1024 cubes and one occluder. A 128x128 conservative base pyramid is packed into a storage buffer; every base cell includes all covered full-resolution pixels. This replaces upstream mipmapped textures, multiple prop types and matrix compaction with a single mesh and compacted IDs. Prefix scan uses 512 threads and 1024 elements. These are algorithm adaptations, not equal-work performance comparisons.

- [main.das](main.das): interactive entry point; `--smoke-test` exits after three frames.
- [gpudrivenrendering_app.das](gpudrivenrendering_app.das): resources, passes and input.
- [Shader DSL](shaders/gpudrivenrendering_shaders.das).
- [Regression test](../../../tests/bgfx_gpudrivenrendering.das): Checks reduced indirect instance count, visibility sum, stable/unique compacted IDs and culled-versus-unculled pixels.

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_28_gpudrivenrendering/main.das
```
D3D12: set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. Metal is unverified. Keyboard controls replace ImGui.
