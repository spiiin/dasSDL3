# 25: mvs — bgfx 34 port

Original: [bgfx 34-mvs](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/34-mvs).

Multiple vertex streams: positions in slot 0, colors in slot 1, explicit SDL vertex attributes and 121 rotating cubes. M switches only the color buffer; Space pauses; R resets rotation. The port uses an expanded triangle list instead of the upstream indexed strip. Position data is unchanged when switching colors; streams are never interleaved on the CPU.

- [main.das](main.das): interactive entry point; `--smoke-test` stops after three frames.
- [mvs_app.das](mvs_app.das): resources, rendering and input.
- [Shader DSL](shaders/mvs_shaders.das).
- [Regression test](../../../tests/bgfx_mvs.das).

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_25_mvs/main.das
```
For D3D12 set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. Metal is unverified. The upstream ImGui interface is replaced by keyboard controls.
