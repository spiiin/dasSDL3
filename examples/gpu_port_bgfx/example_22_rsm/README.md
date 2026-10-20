# 22: RSM — adaptation of bgfx 31

Original: [bgfx 31-rsm](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/31-rsm).

GPU reflective shadow maps and a camera G-buffer, with 64 virtual point-light samples gathered in the
final fragment shader. A Cornell room and six boxes replace the upstream 222-object scene. RSM is
256×256; explicit RGBA16F position/normal/flux targets replace the original compact formats. Fullscreen
gather replaces 1024 separate sphere draws (the original does **not** instance them).

This is a substantially different algorithm/workload. Its FPS cannot measure SDL/bgfx binding overhead.
See the [audit, complete differences table and benchmarks](../../../docs/bgfx-sky-rsm-audit.md).
RSM Amount mixes direct/indirect light as in upstream; no extra ambient or tone mapping is applied.
Radius cutoff and light azimuth/elevation affect rendering, but VPL falloff, light model and PCF differ.

The ImGui Settings panel has the original Amount (0–.7), VPL Radius (.25–20), Azimuth (0–360) and
Elevation (35–90) controls, plus display mode, pause and reset. M cycles direct+indirect/direct/flux;
Space pauses cubes; R resets. Core runners without ImGui use keyboard controls.

- [main.das](main.das): interactive entry point; `--smoke-test` stops after three frames.
- [rsm_gui.das](rsm_gui.das): optional ImGui integration.
- [rsm_app.das](rsm_app.das): resources, rendering and input.
- [Shader DSL](shaders/rsm_shaders.das).
- [Regression test](../../../tests/bgfx_rsm.das): indirect contribution, amount/radius/light controls and debug modes.

From the repository root, with ImGui enabled in the libraries runner:

```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_bgfx/example_22_rsm/main.das
```

D3D12: set `SDL_GPU_DRIVER=direct3d12`, with shadercross enabled. Vulkan and D3D12 rendering/panel smoke
tests pass; core rendering also passes strict AOT. Metal is unverified.
