# 24: pom — bgfx 33 port

Original: [bgfx 33-pom](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/33-pom).

Normal, parallax, steep parallax and interpolated parallax occlusion mapping on the GPU, using the original diffuse/normal/height textures. M cycles flat, normal, parallax, steep and POM; Space pauses rotation; R resets it. A single rotating quad makes displacement easy to compare. Maps are decoded offline to RGBA8 base levels; the shader explicitly samples LOD 0 inside divergent ray marching. It does not reproduce upstream mip filtering, editable light/material controls or scene layout.

- [main.das](main.das): interactive entry point; `--smoke-test` stops after three frames.
- [pom_app.das](pom_app.das): resources, rendering and input.
- [Shader DSL](shaders/pom_shaders.das).
- [Regression test](../../../tests/bgfx_pom.das).

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_24_pom/main.das
```
For D3D12 set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. Metal is unverified. The upstream ImGui interface is replaced by keyboard controls.
