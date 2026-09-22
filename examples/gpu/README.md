# GPU application examples

## 01 — Metaballs

[01_metaballs.das](01_metaballs.das) ports the CPU marching-cubes / transient-vertex
scenario from [bgfx 02-metaballs](https://github.com/bkaradzic/bgfx/tree/81d81fba72c42d348c589514c774bbfe01e110fa/examples/02-metaballs)
to daScript and SDL GPU. No bgfx runtime or renderer framework is involved.
Original code and lookup table: Copyright 2011-2026 Branimir Karadzic;
[BSD-2-Clause license](LICENSE-bgfx.txt). The copied table is isolated in
[metaballs_tables.das](metaballs_tables.das); CPU field/triangulation is in
[metaballs_field.das](metaballs_field.das).

Run from the repository root after building `dasSDL3_runner`:

```powershell
.\build\ninja\bin\dasSDL3_runner.exe .\examples\gpu\01_metaballs.das
```

Select a backend with `$env:SDL_GPU_DRIVER='vulkan'` or `'direct3d12'`.
For the local RenderDoc-layer conflict, the optional runner argument
`--disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture` disables only that layer for
this process, not Vulkan validation.

Controls: Up/Down change ISO (0.1–4), Left/Right change grid size (8–32), Space
pauses animation, R resets settings, Escape/window close exits. The title shows
ISO, grid resolution, generated vertex count and CPU generation time. There is
no ImGui dependency. Rendering uses a fixed 640×480 color/depth target and scales
to the current window; non-4:3 windows stretch the image.

### What was preserved and adapted

- Sixteen animated metaballs, default 32³ grid and ISO=0.75, marching-cubes table,
  interpolated normals, spatial color gradient, rotating model and specular light.
- The field uses a sum of inverse squared distances, algebraically equivalent to
  bgfx's product recurrence, with a small denominator floor at a sphere center.
  Edge normals use one-sided differences rather than leaving boundary normals zero.
- The light clamps its dot product before fractional powers to avoid NaNs.
- Colors use float3 rather than normalized packed Uint8; vertex stride is 36 bytes.
- One persistent vertex buffer and upload transfer buffer replace bgfx transient
  allocation. Each upload cycles both transfer and vertex storage. There is no
  per-frame GPU resource creation and no per-frame wait-idle.
- Capacity covers the full marching-cubes upper bound for a 32³ grid (five
  triangles per cell), unlike the upstream 32K-vertex truncation.
- Shader binaries are supplied as SPIR-V and DXIL. Rebuild/verify with
  `python tools/build_metaballs_shaders.py [--check]` (DXC + spirv-val required
  only for rebuilding). HLSL and hashes are in [shaders](shaders/).

### What this revealed about the binding

Existing scopes cover device, shaders, pipeline, transfer/vertex buffers,
color/depth textures, copy/render passes and swapchain acquisition/submission.
Depth testing, buffer cycling, blit, fences and readback required no new raw SDL
functions. `sdl_scope`/`sdl_use` and `sdl_try` keep creation and failure cleanup
linear; `array(SDL_GPUColorTargetInfo(...))` and nested named initializers work.

Two narrow float-array adapters were missing and added:
`write_native_gpu_transfer_floats` and `push_native_gpu_vertex_uniforms`.
They copy contiguous native 32-bit floats synchronously, with byte-count overflow
checks. Capacity/offset are bytes; capacity must equal the actual transfer-buffer
allocation. Vertex layout and shader uniform layout remain the caller's contract.
These adapters do not serialize script objects or retain array pointers.
Arbitrary POD/struct-array byte views and mapped GPU memory views remain future
API work; this example deliberately uses a flat float array.

Remaining syntax friction:

- Native pointer values inserted into managed SDL descriptor fields require
  mutable (`var`) parameters; native pointer aliases still have SDL lifetimes.
- Raw bool-returning operations still need `sdl_status(...,"SDL_operation")`.
- Swapchain scopes have several output arguments, so an explicit trailing block
  is clearer here than forcing them into `sdl_use`.
- GPU shader format/stage, pipeline descriptors and buffer layout are explicit.
  They describe real SDL objects, not a new scene/mesh/material layer.
- Marching cubes is CPU work in daScript. Interpreter cost is visible in the
  title; lower the grid resolution or use AOT for performance comparisons.

### Verification

`--smoke-test` renders three deterministic animated frames, reads the last color
texture back through a fence and checks foreground coverage. Set environment
`DASSDL3_METABALLS_CAPTURE` to a writable filename to save that smoke image as
640×480 RGBA8 bytes. This is diagnostic output, not needed for normal execution.

[test_metaballs_field.das](test_metaballs_field.das) checks all 256 topology rows,
a radius-6 analytic sphere (positions/normals), empty isosurfaces and animation.
[GPU upload tests](../../tests/gpu_float_upload.das) check float bytes after GPU
roundtrip at nonzero offsets, rejected ranges/null handles, and a null uniform
command. The rendered example exercises positive uniform upload.

CTest registers Vulkan/Direct3D12 runs, plus interpreter/CppGenBind/AOT parity.
Tests reject Vulkan and D3D12 validation errors. No Metal or WebGPU execution is
claimed. The bundled shader formats target the two tested Windows backends.

Local Windows validation: Vulkan and Direct3D12 smoke/readback, independent CPU
field tests, float upload roundtrip, baseline/CppGenBind/AOT (fallback disabled),
and a consumer built with LLVM/Clang/Python discovery disabled all pass. The fixed
third frame contains 19,164 vertices and 47,324 foreground pixels; Vulkan and
Direct3D12 readback bytes matched exactly on the tested machine. These are local
results, not cross-driver pixel guarantees. The helper modules are explicitly
named `shared public` modules and each is registered in the AOT build.
