# Asset attribution

These are altered example ports, not the original forge-gpu distribution.
Upstream snapshot: [31f44fce](https://github.com/Nebulavenus/forge-gpu/tree/31f44fce9b69cb124b38c1bc90177ef17f1342c8).

- Lesson code/HLSL equations: Rosy Game Studio, copyright 2025, Zlib;
  see [LICENSE-forge.txt](LICENSE-forge.txt).
- Suzanne mesh and textures: Blender Foundation, CC0 1.0, as credited by forge-gpu.
- BoxTextured: Khronos glTF Sample Assets, CC BY 4.0, as credited by forge-gpu.
- CesiumMilkTruck: Cesium, CC BY 4.0, as credited by forge-gpu.
- Duck: copyright 2006 Sony; SCEA Shared Source License 1.0,
  [full license](LICENSE-SCEA.txt), [upstream notice](LICENSE-Duck.txt).
- Space Shuttle model and diffuse texture: Microsoft, CC Attribution,
  [original asset](https://sketchfab.com/3d-models/space-shuttle-0b4ef1a8fdd54b7286a2a374ac5e90d7),
  as credited in forge-gpu lesson 14.
- Milky Way panorama/cubemap: ESO / S. Brunier,
  [The Milky Way panorama](https://www.eso.org/public/images/eso0932a/), CC BY 4.0,
  as credited in forge-gpu lesson 14. The six PNG faces are copied unchanged.

[CC BY 4.0 terms](https://creativecommons.org/licenses/by/4.0/),
[CC0 terms](https://creativecommons.org/publicdomain/zero/1.0/).

Changes: baked static node transforms, FGM1 vertex/index representation, OBJ UV
conversion, a material atlas for the truck, and SDL/daScript DSL application ports.
Input/output hashes and the pinned upstream commit are in assets/sources.json.

- TransmissionOrderTest mesh/textures: Ed Mackey; cloth backdrop: Adobe, CC0,
  as recorded in the source glTF asset copyright notice. See
  [upstream model](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/TransmissionOrderTest).
- NormalTangentMirrorTest mesh/textures: copyright 2017–2018 Analytical Graphics,
  Inc.; Ed Mackey, CC BY 4.0. See
  [upstream notice](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/NormalTangentMirrorTest).

Lessons 15–20 preserve separate primitive/material descriptions, supplied tangents,
node transforms and original PNGs; FGM1 serialization and generated daScript asset
metadata are representation changes. Additional hashes: assets/advanced_sources.json.


## Lessons 21–52

The pinned [upstream asset notices](LICENSE-assets-forge.md) are included unchanged.
Additional attribution:

- Shaderball: adalberto.torres.nikel, CC BY 4.0; [full notice](LICENSE-Shaderball.txt).
- ABeautifulGame: original assets by Moeen Sayed and Mujtaba Sayed for SideFX;
  distributed by Khronos glTF Sample Assets under CC BY 4.0.
- CesiumMan, BrainStem and AnimatedCube: see the model-specific entries in
  [upstream notices](LICENSE-assets-forge.md).
- [Boat 3D Low-Poly](https://sketchfab.com/3d-models/boat-3d-low-poly-cc4e4619d8994b71b1f9230033cd1947):
  shevchenkomr29, CC BY 4.0.
- [Low Poly Rock Cliffs](https://skfb.ly/oQVzB): navebackwards, CC BY 4.0.
- [Modular Track Roads Free](https://skfb.ly/orLos): Bedrill, CC BY 4.0.
- [Citrus Orchard Pure Sky](https://polyhaven.com/a/citrus_orchard_puresky):
  Jarod Guest / Poly Haven, CC0. Cubemap faces are copied unchanged.
- The six PBR texture sets in lesson 52: ambientCG, CC0, as credited in upstream.
  Metalness/roughness are repacked into B/G channels; normal maps are encoded BC5.
- Liberation Mono: Red Hat / Ascender, SIL OFL 1.1;
  [full license](assets/LICENSE-Liberation.txt). The R8 atlas is rasterized offline.

Changes to assets: FGM1 geometry, preserved glTF hierarchy/keyframes/weights in
JSON, separate skin and morph buffers, generated tangents, offline mip generation
and ISPC BC7/BC5 encoding in FTEX v1 containers. Atlas packing uses a padded 6×5
grid. Terrain, trees and particles use procedural data derived from the lesson
algorithms. Input/output hashes are recorded in `extended_sources.json`,
`pbr_sources.json`, `atlas_sources.json`, `terrain_sources.json` and
`misc_sources.json` inside assets.
