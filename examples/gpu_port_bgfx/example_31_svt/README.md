# 31: 40-svt

Original: [bgfx 40-svt](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/40-svt).

The original 100×100 Mars plane, 8192² source, 128² tiles with one-pixel borders, 64² GPU feedback and 15×15 physical page cache (1950² atlas, as upstream's 2048/130 integer division). Fragment derivatives choose the mip; the shader resolves the page table and samples the atlas. Feedback is downloaded asynchronously through a fence. CPU code prioritizes coarse requested pages, streams PNG tiles and maintains an LRU cache with parent fallback; these are CPU tasks in bgfx too.

ImGui exposes page borders, mip colors and uploads per frame, plus live atlas/feedback previews. WASD and arrows move/look. The resident root page is pinned. Disk pages are independently losslessly compressed PNGs in three bounded chunks; the renderer seeks only requested pages. The page table packs seven levels into a 64×127 texture instead of a mipmapped texture; atlas lookups and feedback stay on the GPU. Diagnostic border/color overlays are applied while shading instead of rewriting cached page pixels.

Requires `DASSDL3_WITH_IMAGE=ON` in addition to ImGui. `--smoke-test` runs 20 frames. `tests/bgfx_svt.das` verifies feedback-driven uploads, root fallback, cache bookkeeping and changed output after streaming.

From the repository root (build with ImGui; D3D12 additionally needs shadercross):

```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_bgfx/example_31_svt/main.das
```

Use `SDL_GPU_DRIVER=direct3d12` for D3D12. The core runner does not contain ImGui.
`--smoke-test` performs a bounded startup run. Pixel/counter regressions are in
`tests/bgfx_svt.das`; GPU captures are opt-in through `DASSDL3_BGFX_CAPTURE`.
Windows Vulkan/D3D12 are tested; Metal and Web are not verified.

[Application](svt_app.das), [shader DSL](shaders/svt_shaders.das).
Assets/provenance: [manifest](../assets/ports40-45-manifest.json),
[group license](../LICENSE-bgfx.txt). No bgfx runtime dependency.
