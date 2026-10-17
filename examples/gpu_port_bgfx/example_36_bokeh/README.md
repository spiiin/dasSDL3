# 36: 45-bokeh

Original: [bgfx 45-bokeh](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/45-bokeh).

The original scene contains 120 animated hollow cubes (6×20), the same blue/purple/pink gradient, fieldstone normal mapping, checker ground, light and sky-blue clear color. Depth of field is entirely GPU-based: either a full-resolution golden-angle filter, or half-resolution color/CoC downsample → golden-angle filter → full-resolution combine. A separate full-resolution linear-depth pass preserves the original filtered-depth sampling contract. Signed CoC preserves foreground/background handling.

ImGui includes enable, full-resolution mode, debug CoC, blur radius, focal distance/scale, sample spacing, aperture lobes/pinch/rotation and sample-count/aperture preview. The small preview is CPU-generated draw-list geometry like upstream's CPU-generated preview texture; the actual image filter runs in fragment shaders. WASD and arrows move/look.

`tests/bgfx_bokeh.das` checks enabled/disabled, single/half-resolution, debug CoC and aperture/focus changes.

From the repository root (build with ImGui; D3D12 additionally needs shadercross):

```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_bgfx/example_36_bokeh/main.das
```

Use `SDL_GPU_DRIVER=direct3d12` for D3D12. The core runner does not contain ImGui.
`--smoke-test` performs a bounded startup run. Pixel/counter regressions are in
`tests/bgfx_bokeh.das`; GPU captures are opt-in through `DASSDL3_BGFX_CAPTURE`.
Windows Vulkan/D3D12 are tested; Metal and Web are not verified.

[Application](bokeh_app.das), [shader DSL](shaders/bokeh_shaders.das).
Assets/provenance: [manifest](../assets/ports40-45-manifest.json),
[group license](../LICENSE-bgfx.txt). No bgfx runtime dependency.
