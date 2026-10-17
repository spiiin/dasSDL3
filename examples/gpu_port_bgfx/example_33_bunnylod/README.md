# 33: 42-bunnylod

Original: [bgfx 42-bunnylod](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/42-bunnylod).

Uses the original patched bunny and the progressive-mesh collapse algorithm by Stan Melax / Cloud Wu. The collapse map and permutation are generated offline using the unmodified upstream `progmesh.c`; interactive LOD walks the collapse map and updates the index buffer on the CPU, matching bgfx. Geometry rendering, derivative flat normals and lighting run on the GPU.

ImGui provides the LOD slider and vertex/triangle statistics. The slider's square determines the retained vertex fraction, matching the original. Rotation follows the original elapsed-time formula. The shader compensates for SDL framebuffer Y when deriving face normals.

`tests/bgfx_bunnylod.das` checks that the bunny is lit, triangle reduction affects the image, and returning to full LOD restores identical output. The upstream source hash is recorded in [ports40-45.json](../upstream/ports40-45.json). See [progressive mesh license](../assets/progmesh-LICENSE.txt).

From the repository root (build with ImGui; D3D12 additionally needs shadercross):

```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_bgfx/example_33_bunnylod/main.das
```

Use `SDL_GPU_DRIVER=direct3d12` for D3D12. The core runner does not contain ImGui.
`--smoke-test` performs a bounded startup run. Pixel/counter regressions are in
`tests/bgfx_bunnylod.das`; GPU captures are opt-in through `DASSDL3_BGFX_CAPTURE`.
Windows Vulkan/D3D12 are tested; Metal and Web are not verified.

[Application](bunnylod_app.das), [shader DSL](shaders/bunnylod_shaders.das).
Assets/provenance: [manifest](../assets/ports40-45-manifest.json),
[group license](../LICENSE-bgfx.txt). No bgfx runtime dependency.
