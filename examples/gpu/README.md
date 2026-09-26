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

## 02_raymarch — bgfx 03-raymarch

Port of [bgfx 03-raymarch](https://github.com/bkaradzic/bgfx/tree/01dbbbc08c093f7ccf8adf7bd685739b344e9102/examples/03-raymarch),
BSD-2-Clause; see LICENSE-bgfx.txt and shaders/raymarch-upstream.json.
Preserves the rounded box and six spheres, 64-step sphere tracing, central-difference
normals, three-sample ambient occlusion, diffuse/specular/Fresnel lighting, gamma,
rotating model and light, interpolated four-color background, and distance/max-ray
depth output. Analytical near/far rays with inverse bx XY rotation replace the
inverse MVP matrix. Uniforms are updated on the CPU and consumed by the vertex
shader; interpolated endpoints feed the fragment shader. A six-vertex procedural
quad replaces transient vertex/index buffers. The bgfx/ImGui example-selector UI
is omitted. Miss tracing exits early to avoid unbounded distances. Depth comparison
is LESS_OR_EQUAL so background depth 1 passes the cleared depth target.

Run from the repository:

```powershell
.\build\ninja\bin\dasSDL3_runner.exe .\examples\gpu\02_raymarch.das
.\build\ninja\bin\dasSDL3_runner.exe .\examples\gpu\02_raymarch.das --smoke-test
```

Space pauses/resumes, R resets time, Escape/window close exits. Resize letterboxes
the fixed 640x360 render target, preserving the 16:9 ray aspect ratio. Smoke renders
times 0.6 and 1.2 and reads back both frames: grayscale foreground coverage,
background corner orientation and changed image hashes must pass. Optional
DASSDL3_RAYMARCH_CAPTURE writes the last RGBA8 image (640x360, top-down); the path
must be writable. Pixel checks cover color, not independent depth readback.

Rebuild shipped DXIL/SPIR-V with tools/build_raymarch_shaders.py (DXC and spirv-val
on PATH); --check verifies byte-for-byte reproducibility and the separate manifest.
Shader compilation is offline; the application requires neither LLVM nor DXC.
CTest registers both GPU backends in the main build and parity interpreter/AOT.

### Wrapper ergonomics observed during this port

- Shared gpu_shader options, uniform_buffers and native file scopes compose well
  with sdl_scope/sdl_use. No manual shader destruction or bytecode lifetimes.
- gpu_texture and the native topology/rasterizer/depth helpers remove repeated
  zero/default fields without introducing renderer objects.
- Typed float-array vertex uniforms avoid packing bytes or unsafe script code.
- Remaining repetition: native pipeline creation requires empty vertex-layout
  arrays for vertex-ID shaders. A narrow no-vertex-input overload could help.
- Native SDL pointer fields require mutable pointers when initializing structs;
  the resource function therefore takes var shader parameters. This is a daScript
  pointer-constness constraint, not transfer of ownership.
- Window/device claiming still uses explicit claim + defer release. A scoped
  claim helper could shorten it while preserving SDL's device/window lifetime.
- Readback remains verbose (transfer, copy pass, fence, bytes). It is deliberately
  example-local; a future generic texture readback helper should specify pitch,
  format and synchronization instead of assuming RGBA8.
- Float-array upload convenience currently covers vertex uniforms. This example
  naturally computes rays there; fragment/compute float overloads would be useful
  for other ports. No new public API was necessary for this example.

Local validation (2026-09-26): main CTest, CppGenBind interpreter and strict AOT
passed on Vulkan and Direct3D 12 (six tests total); rebuilt no-LLVM consumer passed
on Direct3D 12. At time 1.2, backend RGBA captures differed in 48 of 921600 bytes,
maximum difference 1. Shader rebuild --check and spirv-val passed. The legacy
baseline runner could not rebuild because SDL_GPUVulkanOptions lacked a registered
type in its snapshot; this unrelated baseline limitation is not counted as a pass.
Keyboard controls are implemented; automated checks cover smoke rendering rather
than synthetic input or interactive resize.

## 03_mesh — bgfx 04-mesh

[03_mesh.das](03_mesh.das) ports
[bgfx 04-mesh](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/04-mesh).
Preserves the Stanford bunny, rotating model, animated normal displacement,
position-dependent colors, diffuse/specular/Fresnel lighting and gamma correction.
Code/shaders: Branimir Karadzic, BSD-2-Clause (LICENSE-bgfx.txt).
The model has separate [provenance and terms](models/README.md).

```powershell
.\build\ninja\bin\dasSDL3_runner.exe .\examples\gpu\03_mesh.das
.\build\ninja\bin\dasSDL3_runner.exe .\examples\gpu\03_mesh.das --smoke-test
```

Space pauses, R resets time, Escape/window close exits. The application uploads
vertex and uint32 index buffers once, then issues one indexed draw per frame.
Interactive rendering targets the swapchain at its actual pixel resolution;
projection aspect and the D32 depth texture update on resize. No fixed-resolution
upscaling, per-frame geometry upload or per-frame wait-idle. Back-face culling uses
clockwise fronts for this OBJ and the port's left-handed projection.

The offline converter uses the original OBJ instead of decoding bgfx's compressed
binary mesh format. Normals are signed float3, not packed UNORM. The shader's model,
view and projection transforms are expressed directly; a float4 vertex uniform
contains time, aspect, near and far. Time reaches the fragment shader as a flat
varying. The ImGui example selector is omitted. This is a visual/application port,
not byte-for-byte compatibility with bgfx geometryc output.

DXIL/SPIR-V assets are included. `python tools/build_mesh_shaders.py --check`
recompiles and checks deterministic output with DXC/spirv-val; ordinary consumers
need neither tool. `tools/build_mesh_asset.py --check` checks model conversion.

Smoke renders deterministic times 0.6 and 1.2 into RGBA8 640x360 targets, waits on
readback fences and checks foreground coverage, bright colored pixels, clear
corners and changing image hashes. It then renders directly to the swapchain and
resizes 960x540 to 800x600, requiring a changed depth-target size. Optional
`DASSDL3_MESH_CAPTURE` writes the last offscreen image as top-down RGBA8 bytes.
`test_mesh_data.das` tests valid decoding, missing files, truncated/extra payload,
invalid header/counts/stride, non-finite vertices and out-of-range indices.

### Wrapper findings

No public API additions were required. Shader options, native resource scopes,
pipeline/depth/rasterizer helpers, byte transfer adapters and indexed drawing cover
this port. `sdl_use` keeps resource acquisition linear; `sdl_try` preserves cleanup
on file/upload failures. Mesh decoding stays in an example-local shared module.

Remaining friction: byte buffer upload needs transfer + command + copy scopes;
dynamic depth replacement needs explicit lifetime management; SDL bool calls need
`sdl_status`. Native pointers require mutable variables when placed in descriptors.
These are narrow convenience opportunities, not reasons to introduce public mesh,
material or renderer objects. The parser copies validated byte payloads; a bounded
byte-slice upload API could remove those copies if profiling warrants it.

Local validation (2026-09-26): main runner, legacy baseline, CppGenBind interpreter
and strict AOT (fallback disabled) pass Vulkan and Direct3D 12 smoke/readback and
resize tests. Decoder tests pass all four runners. The existing no-LLVM consumer
passes Direct3D 12 after copying the new runtime assets; no consumer rebuild was
needed. DXC rebuild comparison, spirv-val and deterministic OBJ conversion pass.
At time 1.2 the offscreen image has 29,774 foreground pixels on both tested GPU
backends. Keyboard controls are implemented but not automated; Metal is untested.
