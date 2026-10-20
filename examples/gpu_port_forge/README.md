# forge-gpu lessons 10–52 in daScript

Altered ports of [Nebulavenus/forge-gpu](https://github.com/Nebulavenus/forge-gpu),
pinned at `31f44fce9b69cb124b38c1bc90177ef17f1342c8`.
All shader source is daScript DSL using upstream dasSpirv; no HLSL or precompiled
shader binaries are required. SDL object ownership uses Result, sdl_try, sdl_scope,
sdl_use and defer. Shared application code stays in this example directory.

| Example | Content |
| --- | --- |
| [10 Basic lighting](example_10_basic_lighting/main.das) | Textured Suzanne; ambient, Lambert diffuse and Blinn specular; cofactor normal transformation under nonuniform scale |
| [11 Compute shaders](example_11_compute_shaders/main.das) | Original five-wave plasma and palette, 8×8 workgroups, write-only storage texture, then fullscreen sampling |
| [12 Shader grid](example_12_shader_grid/main.das) | CesiumMilkTruck, procedural world-space grid, fwidth antialiasing, frequency/distance fade and lighting |
| [13 Instanced rendering](example_13_instanced_rendering/main.das) | 47 BoxTextured objects and 256 Ducks; two instance-rate matrix buffers and two indexed instanced draws, plus grid |
| [14 Environment mapping](example_14_environment_mapping/main.das) | Space Shuttle, six Milky Way cubemap faces, sky background and reflect(-V,N) with adjustable reflection |
| [15 Cascaded shadow maps](example_15_cascaded_shadow_maps/main.das) | Three 2048² depth maps, logarithmic/linear splits, fitted light frusta, 3×3 PCF and cascade previews |
| [16 Blending](example_16_blending/main.das) | TransmissionOrderTest: OPAQUE, MASK/discard and sorted BLEND with depth writes disabled |
| [17 Normal maps](example_17_normal_maps/main.das) | NormalTangentMirrorTest: flat/smooth/mapped normals, supplied tangents, mirrored UV handedness and Gram–Schmidt TBN |
| [18 Blinn–Phong materials](example_18_blinn_phong_materials/main.das) | Five Suzanne instances: Gold, Red Plastic, Jade, Pearl and Chrome |
| [19 Debug lines](example_19_debug_lines/main.das) | Dynamic line-list buffer: grid, boxes, circles, axes, depth-tested and overlay pipelines |
| [20 Linear fog](example_20_linear_fog/main.das) | Truck/box scene with linear, exponential and exponential-squared distance fog |

The scene shaders are in [scene_shaders.das](common/scene_shaders.das); the compute
shader is [plasma_shaders.das](example_11_compute_shaders/plasma_shaders.das).
[scene_app.das](common/scene_app.das) shares the four mesh scenes; the compute
lesson has its own [plasma_app.das](example_11_compute_shaders/plasma_app.das).
[forge_support.das](common/forge_support.das) contains only example-local upload,
layout, matrix, binding and readback operations. It adds no public SDL abstraction.

## Run

From PowerShell in the repository root, with the existing developer build:

```powershell
$env:SDL_GPU_DRIVER = "vulkan"
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_port_forge/example_10_basic_lighting/main.das
```

Change the example directory to select lessons 11–20. `--smoke-test` renders three
frames at fixed time. The regular path runs until Escape or window close.
D3D12 uses the same DSL through optional shadercross:

```powershell
$env:SDL_GPU_DRIVER = "direct3d12"
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_forge/example_14_environment_mapping/main.das
```

The libraries runner needs DASSDL3_WITH_SHADERCROSS and its packaged compiler DLLs.
Direct Vulkan uses only the core runner. CMake copies checked-in assets into
`bin/assets/forge`; ordinary build/run performs no model download/conversion.

## Controls and changes from upstream

Mesh scenes: right-drag orbits, wheel zooms, W/S moves camera and target;
R resets. A/D decreases/increases ambient. G toggles the grid in 12/13;
Up/Down changes spacing; Left/Right changes reflection strength in 14.
Lesson 11: Space pauses/resumes the plasma. All on-screen strings are English.
These ports use explicit polling and lexical scopes instead of SDL callbacks and
upstream UI. Camera controls are an orbit/dolly variant of the original free camera.

The lighting, plasma and grid equations follow the original HLSL. Matrices and
uniforms are packed through the existing std140/std430 helpers. Instancing retains
one draw per model; model parent transforms are baked offline. Lesson 10 starts
with the original identity model transform; nonuniform scale remains available in
the example settings for normal-transform checks. Cameras use the original
right-handed convention; lesson 14 starts at the original yaw/pitch. Lesson 14 uses
a fullscreen direction reconstruction instead of a skybox mesh, preserving the translation-free view and the same cubemap. Textures
are sampled as sRGB, lighting remains linear, and SDR_LINEAR selects an sRGB
swapchain attachment for the final display encoding (when supported, as upstream).
Diffuse textures use a full mip chain and repeat sampling; the cubemap uses clamp.
No PBR or mip-filtered IBL is added to the original Blinn–Phong environment example.

## Assets and reproduction

`assets/sources.json` records the upstream revision, SHA256 input hashes and hashes
of prepared outputs. [prepare_forge_assets.py](../../tools/prepare_forge_assets.py)
requires NumPy and Pillow only when regenerating:

```powershell
python tools/prepare_forge_assets.py --upstream C:/path/to/forge-gpu
```

FGM1 is an example-local little-endian header (magic, vertex count, index count,
32-byte stride), followed by position/normal/UV float32 vertices and uint32 triangle
indices. glTF node transforms are baked, OBJ faces are triangulated and its UV V is
flipped as in the upstream loader. The truck's textured body/wheels and constant
linear glass/trim colors share an atlas with four extra rows. Atlas construction
and node baking are representation changes; no application mesh loader enters the
binding. Other PNGs and all 1024×1024 skybox faces are copied without resizing.

Code is Zlib, copyright Rosy Game Studio: [license](LICENSE-forge.txt).
Asset attribution and licenses are in [CREDITS.md](CREDITS.md).

## Validation

`tests/forge_pixels.das` renders offscreen and compares lighting, grid, instance
count and reflection changes. Compute writes only 257×193 pixels into a 264×200
sentinel-filled texture; every guard pixel must remain unchanged. The Python
oracle independently recomputes plasma colors at two times (tolerance 2/255),
checks output asset hashes and verifies captures. These checks compare behaviors;
they do not claim pixel identity with the original C application.

`tests/test_forge_shaders.py` checks all 26 shader stages, reflection counts,
deterministic compilation and optional SPIRV-Tools validation.

```powershell
ctest --test-dir build/ninja -R "^forge_" --output-on-failure
```

For strict AOT checks against the production snapshots (no Clang generator):

```powershell
cmake -S . -B build/ninja -DDASSDL3_FORGE_AOT=ON
cmake --build build/ninja --target forge_aot_runner --parallel 6
ctest --test-dir build/ninja -R "^forge_aot_" --output-on-failure
```

Validated on 2026-10-17: **25/25 focused CTests passed** on Windows x64 with
Vulkan and D3D12, including all five examples and pixel contracts in interpreter
and strict AOT (fallback disabled), plus deterministic shader compilation and
SPIRV-Tools. The separate plasma CPU oracle and asset hashes passed for both drivers. Metal, Linux and web
execution have not been checked for these ports. SDL GPU examples are desktop-only;
this work does not add a WebGPU backend.

## Original C comparison (2026-10-20)

The earlier port missed upstream's SDR_LINEAR swapchain setup, displaying linear
shader output as SDR values and making both scenes too dark. The camera convention
also mirrored the scenes. The comparison fixed these, the initial camera/model
and light parameters, diffuse mipmaps, sampler addressing and rasterizer state.
At 1280x720 with the initial camera, Vulkan RGB mean absolute error against the
unmodified original C captures is 0.0014/255 for lesson 10 and 0.0188/255 for lesson
14; over 99.99% of channels differ by at most 2/255.

`tests/forge_color.das` checks the actual swapchain format and the linear-to-sRGB
transfer for both scenes. The optional original comparison requires NumPy/Pillow
and capture executables built from upstream with FORGE_CAPTURE:

```powershell
cmake -S . -B build/ninja -DDASSDL3_FORGE_AOT=ON -DDASSDL3_FORGE_REFERENCE_BIN=C:/src/sdl_forge/build-comparison/bin
cmake --build build/ninja --target forge_aot_runner --parallel 6
ctest --test-dir build/ninja -R "^forge_" --output-on-failure
```

The reference executable directory is a local optional test input, never a build
or installation dependency. `tests/test_forge_color_reference.py` compares complete
RGB frames, allowing small rasterization/rounding differences; the standard suite
continues to work without a checkout of the original C lessons.

Validated on 2026-10-20: **33/33 focused CTests passed** on Windows x64,
including all five lessons, pixel contracts, sRGB/swapchain contracts and original
C frame comparisons on Vulkan and D3D12 in interpreter and strict AOT.


## Lessons 15–20

[advanced_app.das](common/advanced_app.das) contains the application's SDL passes,
transparent draw ordering, cascade fitting and camera controls.
[advanced_shaders.das](common/advanced_shaders.das) contains 16 additional DSL entry
points. [advanced_lines.das](common/advanced_lines.das) generates the original debug
shapes with tightly packed 28-byte vertices. These helpers are example-local;
no public scene, material or renderer API was introduced. PCF helpers name their
sampler globals explicitly because the current dasSpirv descriptor resolver does
not accept a sampler passed through a function parameter. Existing SDL bindings
were sufficient for this group.

All six start at the original 1280×720 camera/light/model configuration. Right-drag
orbits, wheel zooms, W/S moves, R resets, Escape exits. Additional controls:

| Lesson | Controls |
| --- | --- |
| 15 | E toggles shadows; 1/2/3 previews a cascade, 0 returns to the scene |
| 16 | E toggles alpha blending (comparison against depth-writing solid draws) |
| 17 | 1 = flat, 2 = vertex normals, 3 = normal mapped |
| 18 | E toggles colored specular highlights |
| 19 | E toggles overlay lines; Space pauses the rotating circle |
| 20 | 1 = linear, 2 = exponential, 3 = exponential squared; E toggles fog |

The original lessons 16/17 intentionally load diffuse textures as UNORM rather
than sRGB; these ports preserve that source behavior. Normal maps are always
linear data. Other textured lessons decode sRGB; all use SDR_LINEAR output when
supported. Lesson 16 preserves the original approximation of transmission as
alpha 0.5 (no screen-space refraction). Debug lines use D32 depth in place of upstream D24; their two depth/overlay modes
are preserved. Interactive controls use orbit/dolly rather
than upstream's free camera/UI.

### Assets and validation

`assets/advanced_sources.json` records input/output hashes. The additional FGM1
meshes retain separate primitives/materials and unbaked glTF node transforms;
normal-mapped vertices use 48 bytes (position, normal, UV, tangent.xyz/handedness).
`advanced_assets.das` is generated offline, not by CMake or at application startup:

```powershell
python tools/prepare_forge_advanced.py --upstream C:/src/sdl_forge
```

`tests/forge_advanced_pixels.das` exercises all six rendering paths, all three
cascade maps, normal modes, animated lines, and fog modes. The Python companion
checks asset hashes and independently evaluates the three fog equations on
161 unoccluded ground rays. Optional original-C comparisons use the same SDL
3.4.16 build and the original C/HLSL sources without modifications:

```powershell
# Run in a Visual Studio developer shell. Choose a fresh build directory.
cmake -S tests/forge_reference -B C:/src/sdl_forge/build-reference -G Ninja -DFORGE_SOURCE_DIR=C:/src/sdl_forge -DSDL3_DIR=C:/src/dasSDL3/build/ninja/_deps/sdl3-build
cmake --build C:/src/sdl_forge/build-reference --parallel 6
cmake -S . -B build/ninja -DDASSDL3_FORGE_AOT=ON -DDASSDL3_FORGE_REFERENCE_BIN=C:/src/sdl_forge/build-reference/bin
cmake --build build/ninja --target forge_aot_runner --parallel 6
ctest --test-dir build/ninja -R "^forge_" --output-on-failure
```

Initial Vulkan RGB mean absolute differences against original C captures (0–255):
15: 0.01662; 16: 0.00008; 17: 0.00036; 18: 0.00466; 20: 0.00045.
Lesson 19's animated circle advances wall time in upstream capture mode; its
comparison allows a small changing line footprint rather than claiming identical
animation times. No shader binaries from upstream are used by the ports.

Validated on 2026-10-20: **61/61 focused CTests passed** for lessons 10–20 on
Windows x64, Vulkan and D3D12, interpreter and strict AOT (fallback disabled).
This includes all 26 DSL stages with deterministic compilation and SPIRV-Tools,
original C frame comparisons, asset hashes and the independent fog/plasma oracles.
All 28 additional assets and the generated asset descriptions reproduced exactly.


## Remaining GPU lessons: 21–52

All 32 entry points use the idiomatic SDL wrapper and daScript shader DSL.
Application algorithms and small shared helpers live in this example directory;
there is no new public renderer/scene API. Source is pinned to
[31f44fce](https://github.com/Nebulavenus/forge-gpu/tree/31f44fce9b69cb124b38c1bc90177ef17f1342c8/lessons/gpu).

| Lesson | Entry point | Technique |
|---|---|---|
| 21 | [HDR tone mapping](example_21_hdr_tone_mapping/main.das) | RGBA16F scene; clamp / Reinhard / ACES |
| 22 | [Bloom](example_22_bloom/main.das) | Karis downsample, five levels, additive upsample |
| 23 | [Point-light shadows](example_23_point_light_shadows/main.das) | Four radial-depth cubemaps, 24 shadow views |
| 24 | [Gobo spotlight](example_24_gobo_spotlight/main.das) | Cone attenuation, gobo projection, shadow map, searchlight mesh |
| 25 | [Shader noise](example_25_shader_noise/main.das) | Value / Perlin / fBm / domain warp / terrain / IGN |
| 26 | [Procedural sky](example_26_procedural_sky/main.das) | Transmittance and multiscatter compute LUTs, atmosphere integration |
| 27 | [SSAO](example_27_ssao/main.das) | View-space normals/depth, 64-sample hemisphere, blur |
| 28 | [GPU UI](example_28_ui_rendering/main.das) | R8 font atlas, dynamic indexed geometry, interactive widgets |
| 29 | [Screen-space reflections](example_29_screen_space_reflections/main.das) | Ray marching, depth refinement, reflective ground |
| 30 | [Planar reflections](example_30_planar_reflections/main.das) | Mirrored camera, oblique clipping, cubemap, Fresnel water |
| 31 | [Transform animations](example_31_transform_animations/main.das) | glTF hierarchy/keyframes, driven truck and track, dirt and sky |
| 32 | [Skinning animations](example_32_skinning_animations/main.das) | CesiumMan; joint matrices in a uniform block |
| 33 | [Vertex pulling](example_33_vertex_pulling/main.das) | Vertex storage buffer plus indexed draws |
| 34 | [Stencil testing](example_34_stencil_testing/main.das) | Portal mask, stencil-limited world, expanded outline |
| 35 | [Projected decals](example_35_decals/main.das) | Depth reconstruction, oriented volumes, eight analytic alpha shapes |
| 36 | [Edges and X-ray](example_36_edge_detection/main.das) | Depth/normal Sobel plus occluded stencil silhouettes |
| 37 | [3D picking](example_37_3d_picking/main.das) | Color ID / stencil ID, asynchronous one-pixel fence readback |
| 38 | [Indirect drawing](example_38_indirect_drawing/main.das) | Compute frustum culling; camera and shadow indirect commands |
| 39 | [Pipeline processed assets](example_39_pipeline_processed_assets/main.das) | Actual FMSH v2/v3 versus raw glTF, split-screen comparison |
| 40 | [Scene renderer](example_40_scene_renderer/main.das) | Three spheres and animated torus, shared local drawing code |
| 41 | [Model loading](example_41_scene_model_loading/main.das) | Truck, Suzanne and Duck; node/material descriptions |
| 42 | [Texture compression](example_42_pipeline_texture_compression/main.das) | Chess scene, native BC7/BC5 FTEX mip uploads, payload stats |
| 43 | [Pipeline skinning](example_43_pipeline_skinned_animations/main.das) | CesiumMan / BrainStem / cube; joint storage buffer |
| 44 | [Morph animations](example_44_pipeline_morph_animations/main.das) | AnimatedMorphCube / SimpleMorph, weighted delta storage buffer |
| 45 | [Transparency sorting](example_45_scene_transparency_sorting/main.das) | Opaque pass, alpha-0.3 glass, sorted transparent pass |
| 46 | [Particle animations](example_46_particle_animations/main.das) | 4096-particle compute pool, atomic spawn budget, age atlas |
| 47 | [Texture atlas](example_47_texture_atlas_rendering/main.das) | 30 source materials; one atlas bind versus 30 individual binds |
| 48 | [Height-map terrain](example_48_height_map_terrain/main.das) | R32F displacement, central-difference normals, splatting, cross trees |
| 49 | [Imposters](example_49_imposters/main.das) | GPU eight-view tree bake, azimuth selection, mesh/billboard crossfade |
| 50 | [Grass rendering](example_50_grass_rendering/main.das) | Four density rings, wind, tiled terrain LOD and geomorph, wire view |
| 51 | [PBR shading](example_51_pbr_shading/main.das) | Blinn-Phong versus Cook–Torrance GGX; material sliders |
| 52 | [PBR textures](example_52_pbr_textures/main.das) | Six ambientCG materials, tangent normals, MR, AO and emissive |

Run from the repository root (Vulkan):

```powershell
$env:SDL_GPU_DRIVER = 'vulkan'
.\build\ninja\bin\dasSDL3_runner.exe examples/gpu_port_forge/example_49_imposters/main.das
# Bounded three-frame run:
.\build\ninja\bin\dasSDL3_runner.exe examples/gpu_port_forge/example_49_imposters/main.das --smoke-test
```

For D3D12 select `SDL_GPU_DRIVER=direct3d12` and use
`dasSDL3_libraries_runner.exe`, built with shadercross. Shader translation occurs
inside the explicit shadercross scope; upstream HLSL/compiled binaries are not loaded.
The larger animation examples specify `options stack = 262144` for their scoped
calls and joint-uniform temporaries.

Controls for the shared host: right drag = orbit, wheel = dolly, W/S = forward/back,
Space = pause, E = effect toggle, 1–9 = numbered display modes, +/- = exposure.
21–24 use 1/2/3 for clamp/Reinhard/ACES. 25 uses 1–6 noise modes, D dithering and
+/- noise scale. 26 uses left/right for sun elevation. 27 uses 1 = AO, 2 = composite,
3 = bypass; 29 uses 1–6 composite/reflection/normal/depth/world/bypass. 37 uses
left click to pick and Tab to switch ID methods. 39 uses 1 = processed, 2 = raw,
3 = split. 45 toggles sorting with E; 46 uses 1/2/3 = fountain/fire/smoke;
47 toggles atlas/individual with E; 49 toggles imposter LOD with E; 50 toggles wind
with E. UI panels in 28 and 51 accept the left mouse button; 28 also accepts text.

These are adaptations of the lesson techniques, not identical copies of the
ForgeScene engine. See [implementation differences and validation](../../docs/forge-ports-21-52.md)
for the exact scope, offline asset preparation and reproducible checks.


### Validation of 21–52 (Windows x64, 2026-10-20)

All 32 lessons passed on Vulkan and D3D12 in the interpreter and strict AOT.
There are 204 accepted GPU capture cases (including targeted reruns after fixes),
64 interpreter/AOT image comparisons, 89 deterministic SPIRV-Tools-validated stages,
and 462 checked manifest entries. Worst interpreter/AOT RGB mean error is below
0.0016 on the 0–255 scale; variable load-time text is excluded. These are correctness
checks, not frame-time benchmarks or comparisons against the original C renderer.

See the [machine-readable results](validation/2026-10-20.json) and
[overview of all 32 scenes](screenshots/21-52.jpg).
