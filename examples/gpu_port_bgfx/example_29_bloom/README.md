# 29: Bloom — bgfx 38

Original: [bgfx 38-bloom](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/38-bloom).

HDR scene followed by five downsample levels, weighted upsample accumulation and composition, entirely in GPU render passes. The 13-tap downsample and 9-tap upsample weights come from bgfx. Separate upsample targets replace additive blending into the downsample targets. M selects bloom, original scene or glow only; Space pauses; R resets rotation. A grid of emissive cubes replaces upstream geometry/textures. This port applies fixed bloom strength at final composition and exponential HDR mapping; it does not reproduce the original ImGui intensity controls.

- [main.das](main.das): interactive entry point; `--smoke-test` exits after three frames.
- [bloom_app.das](bloom_app.das): resources, passes and input.
- [Shader DSL](shaders/bloom_shaders.das).
- [Regression test](../../../tests/bgfx_bloom.das): Checks pyramid dimensions, glow contribution and isolated bloom output.

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_29_bloom/main.das
```
D3D12: set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. Metal is unverified. Keyboard controls replace ImGui.
