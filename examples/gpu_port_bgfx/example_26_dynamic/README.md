# 26: Dynamic vertex buffers — bgfx 35

Original: [bgfx 35-dynamic](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/35-dynamic).

CPU updates vertex positions/colors and uploads selected persistent GPU buffers, as in bgfx. Rendering stays on the GPU. The default updates one of 121 cubes at 30 ticks/second; M switches to all 121. Space freezes updates and rotation; R resets the clock. Expanded indexed triangle lists replace the original shared triangle-strip indices. Upload buffers and destination storage are cycled explicitly through SDL; no per-frame buffer creation.

- [main.das](main.das): interactive entry point; `--smoke-test` exits after three frames.
- [dynamic_app.das](dynamic_app.das): resources, passes and input.
- [Shader DSL](shaders/dynamic_shaders.das).
- [Regression test](../../../tests/bgfx_dynamic.das): Checks GPU vertex bytes, exact update counts, frozen frames and full updates.

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_26_dynamic/main.das
```
D3D12: set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. Metal is unverified. Keyboard controls replace ImGui.
