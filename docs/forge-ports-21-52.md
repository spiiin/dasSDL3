# Forge GPU lessons 21–52

The ports live in [examples/gpu_port_forge](../examples/gpu_port_forge/README.md).
Source commit: `31f44fce9b69cb124b38c1bc90177ef17f1342c8`. No dependency patches,
public renderer objects, upstream shader binaries or new shader parser are used.
Resource scopes use existing `sdl_scope` / `sdl_use` and `sdl_try`; asynchronous
picking retains its fence until completion. Arbitrary application panic is not
made safe by a new exception bridge.

## Deliberate adaptations

- The source ForgeScene framework and free camera are replaced by example-local
  helpers and an orbit camera. Most source control panels are represented by
  keyboard controls; 28 has a small local UI and 42/51/52 have GPU UI panels.
  Camera, lighting, shadow framing, ground/sky treatment and some tessellation
  choices differ. No exact C-reference image or equal-performance claim is made
  for these 32 lessons. Earlier 10–20 reference results remain scoped to 10–20.
- 25 preserves the noise equations; 26 evaluates atmosphere view rays at 32 steps.
  SSAO noise directions are stored in a uniform array instead of a 4×4 texture.
- 28 demonstrates immediate GPU UI with a font atlas and working button, checkbox,
  sliders, radio group, text input, dropdown, draggable panels and RGB picker.
  It does not reimplement the entire upstream reusable UI toolkit or layout system.
- Static/animated primitives use the repository's FGM1 representation. Hierarchies,
  original animation interpolation, skin weights and morph deltas come from glTF.
  32 uploads joint uniforms; 43 uploads a joint storage buffer. 43/44 use offline
  FGM1 + JSON metadata rather than implementing the original `.fscene`, `.fskin`
  and `.fanim` runtime formats. The full Forge asset pipeline is not a dependency.
- 34/37 use a solid geometry floor rather than the source grid shader. Portal
  content uses the source stencil technique with a smaller scene. 35 uses analytic
  alpha shapes in the fragment shader rather than eight generated decal textures.
- 37 resolves stencil IDs into an RGBA ID target using stencil-equal passes before
  downloading one pixel. This avoids guessing a depth/stencil transfer byte layout.
  Selection uses a separate stencil bit and preserves the seven ID bits.
- 39 reads actual FMSH v2/v3 LOD/submesh tables and runtime raw glTF accessors for
  the supplied two models. The glTF path deliberately rejects files outside that
  comparison profile; it is not a general asset-loader API.
- 42 reads actual FTEX v1 headers/mip tables. BC7/BC5 are prepared with ISPC Texture
  Compressor instead of the source BasisU encoder. Payload statistics count bytes
  in the mip chains, not driver memory allocation. BC-format support is checked.
- 46 preserves the GPU pool, Euler integration, budget atomics, age atlas and
  additive/alpha blending. PRNG draw ordering for fire/smoke is adapted; the fountain
  trajectory is checked against a separate CPU calculation.
- 47 uses a padded 6×5 packing of the same 30 original images rather than the
  source packer's layout. The cube has face-local [0,1] UVs; the older BoxTextured
  test mesh has U up to 6 and is unsuitable for atlas sampling. Mips are generated
  by SDL. Atlas/individual RGB mean error is checked, allowing filtering borders.
- 48/49/50 use offline R32F heightmaps generated with the source Wang/Perlin fBm
  algorithm, seeds and per-lesson parameters. 49 uses the source fallback noise
  rather than requiring a separately generated pipeline image. Tree meshes retain
  the cylinder/cone dimensions; billboard trees use a small generated alpha mask.
  49 bakes eight real views on the GPU and uses screen-door crossfade. 50 uses CPU
  grass culling/density rings, source wind equations and terrain geomorphing;
  placement and shadow-detail choices are simplified. Adjacent tile seams are not
  a general crack-free terrain system.
- 51/52 keep the source direct-light PBR equations, including dark fully metallic
  materials without IBL. 52 packs metallic/roughness into B/G channels and decodes
  BC5 tangent normals. No extra renderer/material abstraction is exported.

## Reproducible assets

Runtime needs neither Python nor a shader compiler executable. Checked-in assets
are copied recursively by CMake, including the nested raw glTF comparison files.
Preparing them again requires the pinned upstream checkout, NumPy, Pillow and
`ispc_texcomp==1.0.1` (only the PBR compression tool needs that package):

```powershell
python tools/prepare_forge_extended_assets.py --upstream C:/src/sdl_forge
python tools/prepare_forge_misc.py --upstream C:/src/sdl_forge
python tools/prepare_forge_terrain.py
python tools/prepare_forge_pbr.py --upstream C:/src/sdl_forge
```

The manifests record input/output SHA-256 hashes. `.gitattributes` preserves their
prepared asset bytes and generated asset descriptions across Windows checkouts. Asset extraction preserves node
transforms, texture color roles and animation data; shared images are cached by
source image index. Attribution and included licenses are in
[CREDITS](../examples/gpu_port_forge/CREDITS.md).

## Verification

`tests/test_forge_shaders.py` checks all 89 DSL stages, deterministic bytecode,
reflection contracts and SPIRV-Tools validation. `forge_extended_contracts.das`
checks linear/step/cubic interpolation, quaternion sign handling, parent transforms,
real animation channels, malformed FTEX input, terrain placement and resource counts.
It also checks explicit scalar references: both the PRNG seed and slider value must
change in the caller (`var value : float&`); plain scalar `var` parameters are copies.

`test_forge_extended.py` launches every lesson, rejects Vulkan/D3D12 validation
messages, reads the actual GPU frame and checks visible geometry and controlled
effect changes. Capture mode is enabled only by `DASSDL3_FORGE_CAPTURE`; normal
execution still presents to the window. Indirect commands are compared with a CPU
frustum test, particle state with a CPU Euler calculation, and both picking methods
must identify the same known object even after the selection outline is drawn.

```powershell
python tests/test_forge_shaders.py --runner build/ninja/bin/dasSDL3_runner.exe --spirv-val spirv-val
python tests/test_forge_extended.py --runner build/ninja/bin/dasSDL3_runner.exe --variants
python tests/test_forge_extended.py --runner build/ninja/bin/dasSDL3_libraries_runner.exe --driver direct3d12 --variants
cmake --build build/ninja --target forge_aot_runner --parallel 6
python tests/test_forge_extended.py --runner build/ninja/bin/forge_aot_runner.exe --aot
```

Strict AOT uses `fail_on_no_aot`; it cannot silently fall back to the interpreter.
The test generator enables RTTI only for standalone `json_boost` compilation,
whose AST macros require it. Application RTTI policy is unchanged. The AOT target
also includes `spirv_builtins`, required by the particle shader's integer `atomicAdd` stub. Vulkan layer
filtering, if needed on this machine, is process-local and explicit through
`VK_LOADER_LAYERS_DISABLE=VK_LAYER_RENDERDOC_Capture`.

Saved captures can be compared without launching a GPU process using
`tests/test_forge_capture_parity.py --interpreter <captures> --aot <aot-captures>`.
`--overlay` selects corrected frames from a targeted rerun. The optional offline
rebuild check is `python tests/test_forge_asset_rebuild.py --upstream C:/src/sdl_forge`.

Current run results are recorded in [the progress checklist](forge-remaining-progress.md).
Windows validation does not establish Metal, Web or other operating-system support.
