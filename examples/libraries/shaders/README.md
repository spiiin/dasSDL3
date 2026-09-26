# SDL_ttf GPU example shaders

Original 2D shaders for example 05. Vertex layout is xy/uv (four float32 values,
16-byte stride); vertex uniform slot 0 contains width, height, origin x/y.
The fragment shader samples an alpha atlas and uses a fixed cyan foreground.
The pipeline applies straight-alpha blending. These shaders do not implement
color-glyph, fill or SDF rendering.

SDL_ttf supplies negative-down Y positions; the vertex shader converts them to
NDC once. HLSL register spaces follow SDL GPU's vertex-uniform and fragment-sampler
conventions. The same source generates both SPIR-V and DXIL.

```powershell
python tools/build_ttf_shaders.py
python tools/build_ttf_shaders.py --check
```

DXC and spirv-val are required only to rebuild/check binaries. `--dxc` and
`--spirv-val` accept explicit paths. `manifest.json` records source/binary SHA256.
Normal consumers use the committed binaries, copied to `assets/libraries/shaders`
beside the executable. The local toolchain is Vulkan SDK 1.3.296.0's DXC/spirv-val.
