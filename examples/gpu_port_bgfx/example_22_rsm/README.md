# 22: rsm — bgfx 31 port

Original: [bgfx 31-rsm](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/31-rsm).

Reflective shadow maps: position, normal and reflected flux MRTs from the light; camera G-buffer; shadowed direct illumination and 64 virtual point-light samples gathered in the final fragment shader. M cycles indirect+direct, direct only and reflected-flux preview; Space pauses cubes; R resets rotation. A Cornell-style room replaces the upstream scene. Fullscreen gathering replaces upstream instanced light-volume accumulation; both indirect lighting paths run on the GPU, but their quality and cost are not equivalent. RSM resolution is 256x256. A depth bias covers the low-resolution PCF footprint.

- [main.das](main.das): interactive entry point; `--smoke-test` stops after three frames.
- [rsm_app.das](rsm_app.das): resources, rendering and input.
- [Shader DSL](shaders/rsm_shaders.das).
- [Regression test](../../../tests/bgfx_rsm.das).

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_22_rsm/main.das
```
For D3D12 set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. Metal is unverified. The upstream ImGui interface is replaced by keyboard controls.
