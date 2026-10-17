# 19: terrain — bgfx 27 port

Original: [bgfx 27-terrain](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/27-terrain).

- [main.das](main.das): interactive entry point, `--smoke-test` stops after three frames.
- [terrain_app.das](terrain_app.das): resources, rendering and input.
- [shaders/terrain_shaders.das](shaders/terrain_shaders.das): shader DSL.
- [Regression test](../../../tests/bgfx_terrain.das): offscreen rendering and contract checks.

128x128 editable heightfield. CPU brush edits match the responsibility split of bgfx; mode 0 samples an R8 height texture in the vertex shader, mode 1 uploads displaced vertices. Left mouse raises, right lowers, M changes mode, R flattens, Space suspends painting. Brush placement intersects the camera ray with the base plane. The original separate static/dynamic buffer UI variants are represented by one cycling vertex-buffer path.

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_19_terrain/main.das
```
For D3D12 set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. No external shader compiler is needed at launch. Metal has not been verified for these ports.
