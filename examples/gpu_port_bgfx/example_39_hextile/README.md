# 49-hextile port

[Original bgfx example](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/49-hextile). See `../LICENSE-bgfx.txt` and `../upstream/ports47-49.json`.

Original 60×60 plane, moving camera with 30-degree FOV and `aerial_rocks_04_diff_2k.ktx`. The original BC7 blocks and all twelve mip levels are uploaded unchanged. The ImGui panel exposes regular tiling, diagnostic blend weights, pause, tile rate (2–25) and rotation strength (0–20).

The fragment DSL implements the original triangle-grid coordinates, hashes, per-tile rotations, luminance-weighted seventh-power barycentric blend and gain adjustment. All tiling/blending computations remain on the GPU. Matrix-vector products follow the GLSL column construction in the original shader; the plane is two-sided to accommodate SDL winding conventions.

**Sampling difference:** the installed DSL does not expose `textureGrad`. This port computes isotropic mip LOD from continuous UV derivatives before randomized offsets and uses `textureLod`; rotations preserve derivative lengths. This avoids discontinuity-induced mip seams, but does not reproduce anisotropic gradient sampling. No dependency is patched and no shader text is injected. Regression images cover regular/hex/weights/rotation/tile-rate modes.

Run from the repository root (ImGui-enabled libraries runner):

```powershell
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_bgfx/example_39_hextile/main.das
```

Add `--smoke-test` for a bounded launch. Verified: interpreter regression and ImGui smoke launches on Windows Vulkan/D3D12; strict AOT regression and main entry point on Vulkan (fallback disabled); deterministic DSL compilation and SPIRV-Tools validation. CMake registers the regressions. Other platforms require separate verification.
