# 27: Perez sky — bgfx 36

Original: [bgfx 36-sky](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/36-sky).

Uses the original Preetham/Perez coefficients on the 32×32 vertex grid, calendar/latitude sun controller,
full day/night XYZ luminance tables, exposure, sun bloom and interleaved gradient noise. The original
landscape/lightmap and initial camera pose are retained. The camera is fixed. At fixed noon the Vulkan
reference capture matches with MAE 0.000750/255; see the [audit and benchmarks](../../../docs/bgfx-sky-rsm-audit.md).

The ImGui Settings panel exposes Time scale, Time, Latitude, Turbidity, Prevent color banding and Month,
plus Landscape, Lightmap, Paused and Reset. Space pauses, M toggles clear/hazy sky, R resets.
A core runner without ImGui falls back to keyboard controls (M cycles clear/hazy/dithered; L/O toggle landscape/lightmap).

Assets are converted offline into MSH2 and RGBA8, with hashes in [sky-assets.json](../assets/sky-assets.json).
Reproduce with `python tools/build_bgfx_sky_assets.py --bgfx C:/src/bgfx`; append `--check` to verify.
Runtime has no bgfx dependency. Rendering and shaders remain local to this example.

- [main.das](main.das): interactive entry point; `--smoke-test` exits after three frames.
- [sky_gui.das](sky_gui.das): optional ImGui integration.
- [sky_calendar.das](sky_calendar.das): upstream solar calculation and luminance tables.
- [sky_app.das](sky_app.das): resources, passes and keyboard fallback.
- [Shader DSL](shaders/sky_shaders.das).
- [Regression test](../../../tests/bgfx_sky.das): calendar/luminance/grid, haze, sun motion, dithering, landscape/lightmap and resizing.

From the repository root, with ImGui enabled in the libraries runner:

```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_bgfx/example_27_sky/main.das
```

D3D12: set `SDL_GPU_DRIVER=direct3d12`, with shadercross enabled. Vulkan and D3D12 rendering/panel smoke
tests pass; core rendering also passes strict AOT. Metal is unverified.
