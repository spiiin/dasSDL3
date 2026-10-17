# 18: occlusion — bgfx 26 port

Original: [bgfx 26-occlusion](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/26-occlusion).

- [main.das](main.das): interactive entry point, `--smoke-test` stops after three frames.
- [occlusion_app.das](occlusion_app.das): resources, rendering and input.
- [shaders/occlusion_shaders.das](shaders/occlusion_shaders.das): shader DSL.
- [Regression test](../../../tests/bgfx_occlusion.das): offscreen rendering and contract checks.

SDL GPU has no occlusion-query or conditional-render entry points. This adaptation renders an occluder depth prepass, conservatively projects cube bounds in compute, scans the covered depth rectangle, and writes indexed indirect commands (instance count 0 or 1). M toggles culling/all objects; Space pauses the camera; R resets it. It uses current-frame depth, no CPU visibility/readback, and is an algorithmic replacement, not an implementation of bgfx queries. The original query result HUD and auxiliary view are not reproduced.

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_18_occlusion/main.das
```
For D3D12 set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. No external shader compiler is needed at launch. Metal has not been verified for these ports.
