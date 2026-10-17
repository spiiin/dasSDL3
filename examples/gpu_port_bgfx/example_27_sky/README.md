# 27: Perez sky — bgfx 36

Original: [bgfx 36-sky](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/36-sky).

Uses the upstream Preetham/Perez coefficients, xyY/XYZ conversion, sun disk and dithering, plus the original `test_scene.bin` landscape and `lightmap.ktx`. Terrain lighting evaluates direct sunlight and lightmap-modulated sky illumination on the GPU, with the upstream gamma conversion and interleaved gradient noise. Sky and landscape share camera orientation, sun direction, exposure and zenith luminance. The camera matches the original starting position and angles.

M selects clear, hazy or dithered sky; L toggles landscape; O toggles its lightmap; Space freezes the sun; R resets time. Geographic calendar controls and the full day/night luminance table remain outside this port; sun and zenith luminance use upstream noon values. Perez evaluation is per fragment, instead of interpolating the original screen grid.

Assets are converted offline into MSH2 and RGBA8, with source/output hashes in [sky-assets.json](../assets/sky-assets.json). Reproduce with `python tools/build_bgfx_sky_assets.py --bgfx C:/src/bgfx`; append `--check` to verify without writing. Runtime has no bgfx dependency.

- [main.das](main.das): interactive entry point; `--smoke-test` exits after three frames.
- [sky_app.das](sky_app.das): resources, passes and input.
- [Shader DSL](shaders/sky_shaders.das).
- [Regression test](../../../tests/bgfx_sky.das): Checks turbidity, sun motion, dithering, landscape/lightmap contribution, original index count and odd-resolution resizing.

From the repository root:
```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_bgfx/example_27_sky/main.das
```
D3D12: set `SDL_GPU_DRIVER=direct3d12` and use `dasSDL3_libraries_runner.exe` with shadercross. Metal is unverified. Keyboard controls replace ImGui.
