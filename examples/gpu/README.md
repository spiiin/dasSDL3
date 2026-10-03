# GPU application examples

Numbered scripts are interactive entry points. Their rendering implementation is
in adjacent `metaballs_app.das`, `raymarch_app.das`, `mesh_app.das`,
`cubes_app.das` (instancing/bump), `hdr_app.das`, `fontsdf_app.das`,
`lod_app.das`, `stencil_app.das` and `shadowvolumes_scene.das` modules.
They contain no smoke mode, pixel readback or capture output. The unused bool in
`main` is only the current runner entry-point convention.

GPU regression harnesses live in `tests/bgfx_metaballs.das`, `tests/bgfx_raymarch.das`
and the other `tests/bgfx_*.das` entry points; they import the application rendering functions and own
the deterministic loops, readback/fences, captures and pixel assertions. CTest
runs these harnesses, not the interactive entry points. Tests set up their own
resources; mesh tests also exercise offscreen output and automatic resize.

```powershell
.\build\ninja\bin\dasSDL3_runner.exe .\tests\bgfx_metaballs.das --smoke-test
```

## Shader DSL and backends

All ten examples use the 31 daScript shader entry points in [shaders](shaders/):
`metaballs_shaders.das`, `raymarch_shaders.das`, `bunny_shaders.das`,
`cube_shaders.das`, `hdr_shaders.das`, `fontsdf_shaders.das`,
`lod_shaders.das`, `stencil_scene_shaders.das` and `stencil_shaders.das`. They compile through upstream dasSpirv
when the script loads. Vertex layouts and uniforms retain their SDL contracts.

Vulkan uses the core runner:

```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_runner.exe examples/gpu/01_metaballs.das
```

D3D12 translates the same generated SPIR-V through shadercross. Build with
`DASSDL3_WITH_SHADERCROSS=ON` and use the libraries runner and its compiler DLLs:

```powershell
$env:SDL_GPU_DRIVER = 'direct3d12'
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu/06_hdr.das
```

Metal translates the same SPIR-V through the pinned shadercross build without DXC:

```sh
SDL_GPU_DRIVER=metal ./build/macos-libraries/bin/dasSDL3_libraries_runner examples/gpu/06_hdr.das
SDL_GPU_DRIVER=metal ctest --test-dir build/macos-libraries -R '^macos_metal_bgfx_' --output-on-failure
```

[shader_support.das](shader_support.das) imports shadercross only when the native
module is available. The core runner advertises SPIR-V only. There is no fallback
to old binaries and no per-frame compilation. HDR uses three fullscreen vertex
entry points to match each fragment stage's varyings on D3D12.

```powershell
ctest --test-dir build/ninja -R 'sdl3_tests_bgfx_|shader_dsl_gpu_examples_compiler' --output-on-failure
python tests/test_gpu_examples_dsl.py --runner build/ninja/bin/dasSDL3_runner.exe --spirv-val C:/VulkanSDK/<version>/Bin/spirv-val.exe
```

Tests check deterministic compilation of all 31 shaders, pixel readback, animation,
instanced versus individual draws and HDR luminance. For the first six ports,
migration captures match the previous HLSL images within 1 RGBA8 channel value on Vulkan and 2 on D3D12 (HDR).
This is a measured comparison, not a bit-exact guarantee across drivers.

The shader sources are the `.das` modules above. Upstream provenance and licenses
are retained. See [shader DSL](../../docs/shader-dsl.md).

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
- Shaders use [metaballs_shaders.das](shaders/metaballs_shaders.das).

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

The separate `tests/bgfx_metaballs.das` test renders three deterministic animated frames, reads the last color
texture back through a fence and checks foreground coverage. Set environment
`DASSDL3_METABALLS_CAPTURE` to a writable filename to save that smoke image as
640×480 RGBA8 bytes. This is diagnostic output, not needed for normal execution.

[bgfx_metaballs_field.das](../../tests/bgfx_metaballs_field.das) checks all 256 topology rows,
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
.\build\ninja\bin\dasSDL3_runner.exe .\tests\bgfx_raymarch.das --smoke-test
```

Space pauses/resumes, R resets time, Escape/window close exits. Resize letterboxes
the fixed 640x360 render target, preserving the 16:9 ray aspect ratio. The separate test renders
times 0.6 and 1.2 and reads back both frames: grayscale foreground coverage,
background corner orientation and changed image hashes must pass. Optional
DASSDL3_RAYMARCH_CAPTURE writes the last RGBA8 image (640x360, top-down); the path
must be writable. Pixel checks cover color, not independent depth readback.

Shaders use [raymarch_shaders.das](shaders/raymarch_shaders.das).

### Wrapper ergonomics observed during this port

- DSL reflection and shader scopes compose well
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
maximum difference 1. DSL compilation and spirv-val passed. The legacy
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
.\build\ninja\bin\dasSDL3_runner.exe .\tests\bgfx_mesh.das --smoke-test
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

Shaders use [bunny_shaders.das](shaders/bunny_shaders.das).

The separate `tests/bgfx_mesh.das` test renders deterministic times 0.6 and 1.2 into RGBA8 640x360 targets, waits on
readback fences and checks foreground coverage, bright colored pixels, clear
corners and changing image hashes. It then renders directly to the swapchain and
resizes 960x540 to 800x600, requiring a changed depth-target size. Optional
`DASSDL3_MESH_CAPTURE` writes the last offscreen image as top-down RGBA8 bytes.
`tests/bgfx_mesh_data.das` tests valid decoding, missing files, truncated/extra payload,
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
needed. DSL compilation, spirv-val and deterministic OBJ conversion pass.
At time 1.2 the offscreen image has 29,774 foreground pixels on both tested GPU
backends. Keyboard controls are implemented but not automated; Metal is untested.

## 04_instancing — bgfx 05-instancing

[04_instancing.das](04_instancing.das) ports the
[upstream example](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/05-instancing).
The default 11x11 grid uses one indexed draw, with a real per-instance vertex
buffer: four float4 matrix columns and a float4 tint (80-byte stride). CPU code
updates the same animated XY rotations, positions and colors as bgfx. SDL upload
and destination buffers are cycled each frame; there is no wait-idle per frame.

I toggles between one instanced draw and one draw per cube using first_instance.
Up/Down adjust the grid from 1x1 to 32x32; the camera remains at z=-35. Space pauses,
R resets time, Escape closes. The title shows cube and draw counts. Rendering and
depth storage use the current swapchain size.

The shared cube has 24 vertices instead of bgfx's eight, because bump needs face
normals/UVs/tangents. Position colors still match the original eight corner colors.
Float4 vertex colors replace packed UNORM bytes. Persistent cycled buffers replace
bgfx's transient allocator. The comparison path uses the same instance data for
both modes so it isolates draw submission; ImGui/statistics menus are omitted.

## 05_bump — bgfx 06-bump

[05_bump.das](05_bump.das) ports the
[upstream example](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/06-bump).
Nine rotating cubes use the original fieldstone color/normal textures, four animated
colored point lights, radius/inner-radius attenuation, tangent-space normal
reconstruction, linear-light shading and gamma output. Face tangents are analytic
for the axis-aligned UV-mapped cube rather than computed by bgfx calcTangents.

N toggles normal mapping, I toggles instancing, Space pauses, R resets and Escape
closes. All nine cubes fit one instanced draw instead of the original three row
draws. Light positions are evaluated from time in the fragment shader; their
formulas/colors/radii are preserved. Textures use the original 512x512 TGA data
converted offline to RGBA8, with linear filtering and one mip level, rather than
the runtime compressed DDS/mip chain. No image decoding dependency is needed.

## 06_hdr — bgfx 09-hdr

[06_hdr.das](06_hdr.das) ports the
[upstream example](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/09-hdr).
The Uffizi cubemap surrounds the reflective/color-modulated Stanford bunny.
The camera orbits the bunny. The pass sequence is explicit SDL commands:

1. Skybox and depth-tested bunny into a full-resolution RGBA16F target.
2. Luminance at 128x128, then reductions to 64x64, 16x16, 4x4 and 1x1.
3. Half-resolution bright extraction using middle gray, white point and threshold.
4. Nine-tap vertical bloom filtering into an eighth-resolution texture.
5. Horizontal bloom filtering combined with luminance-scaled Reinhard tone mapping
   and gamma output to the swapchain.

Up/Down change middle gray; Left/Right change bloom threshold; W/S change white
point; B toggles bloom; Space pauses; R resets; Escape closes. Scene/depth and
relative-size postprocess targets are recreated on window resize. The fixed
luminance pyramid stays 128->64->16->4->1.

RGBA16F replaces RGBE8/RE8 packing. This preserves values above 1 without encoding
helpers, and avoids interpolating packed exponents. The 512x512x6 cubemap is
unpacked offline from the original KTX RGBA16F payload; source hashes are pinned.
Tiny negative source radiance values are clamped to zero. Fullscreen passes use
a vertex-ID triangle instead of a transient screen quad. Single-sample rendering
is used; the original ImGui, MSAA/VRS selectors and CPU luminance-readback UI are
omitted. There is no GPU readback or test mode in the application modules.

### Run and rebuild 04–06

From the repository root:

```powershell
.\build\ninja\bin\dasSDL3_runner.exe .\examples\gpu\04_instancing.das
.\build\ninja\bin\dasSDL3_runner.exe .\examples\gpu\05_bump.das
.\build\ninja\bin\dasSDL3_runner.exe .\examples\gpu\06_hdr.das
```

Use the backend-specific runners described above. Texture bytes are copied by
CMake; shaders compile from the DSL. No bgfx runtime or network is needed.
D3D12 requires shadercross.
`tests/test_gpu_examples_dsl.py` verifies the DSL shaders with optional spirv-val.
`tools/build_bgfx_next_assets.py --check` downloads the pinned sources and verifies
conversion; `--source-dir` uses an offline directory containing the two TGAs and
uffizi.ktx instead. Provenance: `shaders/bgfx-next-upstream.json` and
`textures/manifest.json`; code license: LICENSE-bgfx.txt. The bunny's separate
model terms remain in [models/README.md](models/README.md).

### Tests and API findings

`tests/bgfx_instancing.das` and `tests/bgfx_bump.das` call the same resource setup
and draw functions as the apps. They check visible coverage, animated images,
byte-identical instanced/individual output, and the effect of disabling normal
mapping. `tests/bgfx_hdr.das` checks finite nonnegative FP16 scene data with values
above 1, positive 1x1 luminance, bloom/exposure effects, animation and target resize.
Readback/fences live only in `tests/bgfx_capture.das`. Set `DASSDL3_BGFX_CAPTURE` to
an existing writable directory to retain raw test images: RGBA8 for final output,
RGBA16F for HDR intermediate buffers. Frames 0–3 are 640x480; HDR frame 4 is 800x600.

No public wrapper changes were necessary. Native array adapters support instance
streams, indexed draws, samplers and cubemap face uploads; builders cover shaders,
textures and pipeline state. `bgfx_support.das` contains only example-local SDL
helpers. Resource structs in the apps are scoped bookkeeping, not public owning
handles or a rendering framework. HDR records its passes directly without a graph
or command-plan layer. Ordinary error returns clean up partial allocations.

Remaining convenience gaps: upload setup and dynamic multi-target cleanup still
need explicit code; shader ABI/vertex layout must match manually. Small arrays of
float uniforms are now supported for vertex, fragment and compute stages through
`push_native_gpu_*_uniforms`. These ports still pass their fragment parameters
through flat varyings; changing that shader interface is optional. Shader/resource
choices remain visible, and no unsafe script pointers are used.

Local verification (Windows, 2026-09-26): all six main-runner tests and all 18
baseline/CppGenBind/strict-AOT tests passed across Vulkan and Direct3D 12.
All three interactive apps opened, rendered, resized and closed successfully on
both drivers. The existing no-LLVM consumer also passed the three Direct3D 12
tests. Official das-fmt verification and both asset/shader reproducibility checks
passed. Metal and other operating systems have not been validated here.

Shader DSL examples are in [gpu_dsl](../gpu_dsl/README.md).

## 07–10 — bgfx 11–14

These are adaptations of [bgfx at 7e3060c](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples),
using SDL GPU operations and daScript shader DSL. Existing example numbers stay
stable. Algorithms and geometry helpers are local to these examples, not public
binding abstractions. Keyboard controls replace bgfx's ImGui panels.

| Script | Demonstration | Controls |
| --- | --- | --- |
| [07_fontsdf.das](07_fontsdf.das) | SDF glyphs, derivative antialiasing, outline and soft shadow; scaling and rotation | Arrows: scale/rotate; O: outline; S: shadow; PageUp/PageDown: scroll; R: reset |
| [08_lod.das](08_lod.das) | Three original tree mesh levels, bark/leaves textures, alpha cutout and complementary 32-step screen-door transition | Up/Down: camera distance; T: transition; R: reset |
| [09_stencil.das](09_stencil.das) | A finite stencil-masked mirror and planar projected shadows | Tab: mirror/shadow; E: effect; Space: pause; R: reset |
| [10_shadowvolumes.das](10_shadowvolumes.das) | Two bgfx scenes, closed mesh volumes, colored lights, textures and fog | Tab/L/P/M: scene/lights/orbit/mesh; Z/E: algorithms; C/V/S: camera/volumes/shadows; Space: pause |

Escape/window close exits each example. The title shows active controls. Targets
follow the swapchain size. `bunny_shaders.das` is the vertex/fragment program of
03_mesh, not a hardware mesh-shader stage.

SDF requires `DASSDL3_WITH_TTF=ON` and the libraries runner:

```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu/07_fontsdf.das
./build/ninja/bin/dasSDL3_runner.exe examples/gpu/08_lod.das
./build/ninja/bin/dasSDL3_runner.exe examples/gpu/09_stencil.das
./build/ninja/bin/dasSDL3_runner.exe examples/gpu/10_shadowvolumes.das
```

For D3D12 use the libraries runner with shadercross enabled for all four.
The font atlas/layout comes from SDL_ttf rather than bgfx FontManager. The demo
uses the existing JetBrains Mono asset ([OFL](../libraries/assets/OFL.txt)).
The original Special Elite font remains in the pinned bgfx assets, but its complex
contours produced visible SDF artifacts in the pinned SDL_ttf/FreeType path;
clamping atlas UVs does not repair those distance fields. FreeType documents
[limitations for intersecting contours](https://freetype.org/freetype2/docs/reference/ft2-properties.html#spread).
SDL_ttf 3.2.2 explicitly disables the `sdf` overlap option internally; this example
does not patch dependency internals or add a FreeType-specific public API. SDL_ttf
3.2.2 tags FreeType's single-channel SDF glyphs as `IMAGE_ALPHA`; the example
explicitly enables and checks `TTF_GetFontSDF`, then handles ALPHA/SDF sequences
as distance data. Empty glyph sequences are skipped. Atlas textures are borrowed
only for the submitted text draw and released by the text engine. Text wraps to
the window width at the current scale, and scrolling stays within the text. Each
glyph carries UV bounds: filtering is clamped to its texel centers and displaced
shadow samples outside its rectangle are rejected, preventing atlas-neighbour bleed.

The stencil scenes use the bunny, original columns, tiled floor and textured cubes.
`10_shadowvolumes.das` reproduces bgfx 14's two scene compositions: the columned
platform/ceiling with a bunny and 18 orbiting cubes, and nine bunnies on a tiled
floor. It uses the original closed `bunny_decimated`, column and platform meshes,
figure/fieldstone textures, animated colored lights, specular highlights and fog.
One to five lights each get their own stencil clear, closed-volume draw and
additive lighting pass. Cached adjacency makes silhouette construction linear;
face-prism construction remains available for comparison. Local positions and
anchored face planes are prepared once when each mesh is loaded. Instances share
one immutable volume vertex buffer. Each frame computes inverse model matrices;
per-light CPU work transforms the light to model space, classifies faces and
emits uint32 indices. Reflected transforms account for reversed winding.
`shaders/shadowvolume_shaders.das` transforms positions and extrudes far vertices
on the GPU, retaining the 180-unit world-space extrusion under nonuniform scale.
Only indices are uploaded each frame (64 MiB limit, cycled between lights).
Pass and model uniforms use separate slots; packed model matrices are reused
across lights within the frame.

Tests retain the original CPU geometry oracle and exact cached/uncached world-space
comparisons. Model-space rendering is compared against these reference images;
classification checks cover nonuniform and negative scales. Reference rendering
paths remain available to tests and benchmark comparisons.

Tab switches scenes; L cycles lights; P changes their orbit; M switches bunny/cube;
Z selects depth-fail/depth-pass; E switches silhouette/face prisms; C changes camera;
V displays volumes; S toggles shadows; Space pauses; R resets; Escape closes.
Depth-pass still has its inherent limitation when the camera enters a volume.
The finite extrusion is 180 world units, with a far plane of 500.
The original mixed algorithm, texture-based counter, high-poly mesh selection,
ImGui controls and MSAA are not implemented. Scene 1 uses a centered 3x3 layout.

The smaller cube scene in `shadowvolumes_app.das` remains a regression fixture:
its independent CPU ray/box oracle tests both outside and inside cameras. The
new scene tests validate asset adjacency, compare the fast cube extrusion to
that reference, compare algorithms, and check shadows, lights, textures, specular,
animation, cameras, mesh selection, volume display and the second scene.

The original LOD/stencil/shadow-volume mesh and texture assets and Special Elite font are pinned in
[assets/manifest.json](assets/manifest.json). Conversion is reproducible with
`python tools/build_bgfx_11_14_assets.py`; an optional `--source-dir` uses an
offline source cache and `--check` compares generated bytes. Normal builds only
copy checked-in assets and never download/convert them. Font license:
[SpecialElite-LICENSE.txt](assets/SpecialElite-LICENSE.txt), Copyright 2010
Brian J. Bonislawsky DBA Astigmatic (AOETI); bgfx code/assets:
[LICENSE-bgfx.txt](LICENSE-bgfx.txt). SDF: Copyright 2013 Jeremie Roy;
LOD: Copyright 2013 Milos Tosic; stencil/volumes: Copyright 2013–2014 Dario Manesku.
The short Sherlock Holmes excerpt is public domain.

`tests/bgfx_fontsdf.das`, `bgfx_lod.das`, `bgfx_stencil.das` and
`bgfx_shadowvolumes.das` and `bgfx_shadowvolumes_scene.das` exercise deterministic offscreen draws. They check glyph
coverage/effects, layout margins and an adversarial empty-glyph atlas isolation
fixture, LOD thresholds/duration and complementary pixel selection,
reflection and shadow changes, closed volume topology, agreement of the volume
algorithms and an independent CPU segment/AABB shadow oracle, including a camera
inside the volume. Interpreter, CppGenBind and strict AOT use the same rendering
functions. These checks do not establish Metal or browser support.

### Stencil scene fidelity

`09_stencil.das` uses the original bgfx column OBJ, figure/flare DDS textures,
fieldstone albedo and bunny. The reflection scene contains four columns and a
rotating bunny; the projection scene contains the bunny and nine textured cubes.
Up to five animated colored point lights use distance attenuation, diffuse and
specular terms from bgfx 13. Light positions are reflected along with the geometry.
The floor uses a stencil mask and bgfx's multiplicative reflection compositing;
projected shadows use a separate cleared stencil and additive lighting pass per light.
The stone texture has ten GPU-generated mip levels to avoid distant shimmer.

Tab changes scene; E toggles reflection/shadows; L cycles 1–5 lights; Up/Down
change reflection strength; Space pauses animation; R resets time; Escape closes.
This port uses keyboard controls and single-sample rendering instead of bgfx's
ImGui panel and MSAA. Its camera and normalized bunny asset can differ from the
upstream image. All scene logic stays in the example, with explicit SDL passes.

`tests/bgfx_stencil.das` checks reflection confinement, shadows that cannot brighten
the reference, and visible texture/specular/light-count/animation changes. Captures
0–3 compare disabled/enabled reflections and shadows; 4–7 disable textures,
disable specular, select one light, and advance animation respectively.
`tools/build_bgfx_11_14_assets.py --check` verifies pinned column/texture conversions.
