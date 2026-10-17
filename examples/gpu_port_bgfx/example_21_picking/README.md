# 21: picking — bgfx 30 port

Original: [bgfx 30-picking](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/30-picking).

GPU ID rendering and asynchronous one-pixel readback with a polled fence. Click a cube to select it; Space pauses rotation. Twelve cubes replace the original mesh collection. A full-resolution ID target and one-pixel query replace bgfx's tight 8x8 picking projection and majority vote. The interactive loop never waits for GPU completion.

- [main.das](main.das): interactive entry point; `--smoke-test` stops after three frames.
- [picking_app.das](picking_app.das): resources, rendering and input.
- [Shader DSL](shaders/picking_shaders.das).
- [Regression test](../../../tests/bgfx_picking.das).

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_21_picking/main.das
```
For D3D12 set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. Metal is unverified. The upstream ImGui interface is replaced by keyboard controls.
