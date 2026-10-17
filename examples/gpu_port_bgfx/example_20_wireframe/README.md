# 20: wireframe — bgfx 28 port

Original: [bgfx 28-wireframe](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/28-wireframe).

- [main.das](main.das): interactive entry point, `--smoke-test` stops after three frames.
- [wireframe_app.das](wireframe_app.das): resources, rendering and input.
- [shaders/wireframe_shaders.das](shaders/wireframe_shaders.das): shader DSL.
- [Regression test](../../../tests/bgfx_wireframe.das): offscreen rendering and contract checks.

Barycentric shader wireframe over the original bunny mesh, with derivative-based line thickness. Mesh expansion happens once at load time, as in the original barycentric path; edge shading runs on the GPU. M cycles filled, filled+wire and wire-only; Space pauses rotation; R resets it. The newer bgfx storage-buffer vertex-pulling line-extrusion path is not included.

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_20_wireframe/main.das
```
For D3D12 set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. No external shader compiler is needed at launch. Metal has not been verified for these ports.
