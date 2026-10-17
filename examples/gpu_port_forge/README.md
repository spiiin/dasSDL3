# forge-gpu lessons 10–14 in daScript

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

Change the example directory to select lessons 11–14. `--smoke-test` renders three
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
one draw per model; model parent transforms are baked offline. Lesson 10 animates
rotation and uses nonuniform positive scale to exercise normals. Scene cameras are
framed for 960×720. Lesson 14 uses a fullscreen direction reconstruction instead of
a skybox mesh, preserving the translation-free view and the same cubemap. Textures
are sampled as sRGB and calculations/output remain linear. No PBR or mip-filtered
IBL is added to the original Blinn–Phong environment example.

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

`tests/test_forge_shaders.py` checks all 10 shader stages, reflection counts,
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
