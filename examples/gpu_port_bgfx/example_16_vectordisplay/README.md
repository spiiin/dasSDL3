# 16: vectordisplay — bgfx 23 port

Original: [bgfx 23-vectordisplay](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/23-vectordisplay).

- [main.das](main.das): interactive entry point, `--smoke-test` stops after three frames.
- [vectordisplay_app.das](vectordisplay_app.das): resources, rendering and input.
- [shaders/vectordisplay_shaders.das](shaders/vectordisplay_shaders.das): shader DSL.
- [Regression test](../../../tests/bgfx_vectordisplay.das): offscreen rendering and contract checks.

CPU line tessellation and public-domain Hershey SIMPLEX strokes; GPU Gaussian blur, ping-pong phosphor history and composition. M selects glow+history, lines only, glow without history. Space freezes the rotating wheel; R clears history. The scene adapts the original test patterns; ImGui and the full original vector drawing API are not ported.

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_16_vectordisplay/main.das
```
For D3D12 set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. No external shader compiler is needed at launch. Metal has not been verified for these ports.
