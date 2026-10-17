# 17: nbody — bgfx 24 port

Original: [bgfx 24-nbody](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/24-nbody).

- [main.das](main.das): interactive entry point, `--smoke-test` stops after three frames.
- [nbody_app.das](nbody_app.das): resources, rendering and input.
- [shaders/nbody_shaders.das](shaders/nbody_shaders.das): shader DSL.
- [Regression test](../../../tests/bgfx_nbody.das): offscreen rendering and contract checks.

GPU initialization, 512-thread shared-memory tiles for all-pairs gravity, Verlet integration, ping-pong buffers and additive instanced billboards. M selects sphere, cube or torus; Space pauses; R resets. Default count is 4096. The UI presets and optional indirect dispatch generator from bgfx are not ported; dispatch size is known on the CPU and particle state never returns to it during rendering. Simulation advances one explicit fixed step per rendered frame.

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_17_nbody/main.das
```
For D3D12 set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. No external shader compiler is needed at launch. Metal has not been verified for these ports.
