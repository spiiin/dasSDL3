# 23: particles — bgfx 32 port

Original: [bgfx 32-particles](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/32-particles).

Four CPU emitters, particle lifetime and Bezier/gravity motion, CPU depth sorting, and one instanced GPU billboard draw with the original sprite. Simulation stays on the CPU as in bgfx examples/common/ps; it is not the compute N-body example. M cycles sphere, hemisphere, circle, disc and rectangle; A switches additive/premultiplied-alpha blending; Space pauses; R resets. This adapts emitter shapes and motion, rather than reproducing every upstream curve, material and ImGui parameter. Capacity is 4096 particles.

- [main.das](main.das): interactive entry point; `--smoke-test` stops after three frames.
- [particles_app.das](particles_app.das): resources, rendering and input.
- [Shader DSL](shaders/particles_shaders.das).
- [Regression test](../../../tests/bgfx_particles.das).

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_23_particles/main.das
```
For D3D12 set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. Metal is unverified. The upstream ImGui interface is replaced by keyboard controls.
